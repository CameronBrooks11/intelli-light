.global _start


.data
	@ data array for hex table 
	HEX_TABLE: .byte 0b00111111 ,0b00000110 ,0b01011011 ,0b01001111 ,0b01100110 ,0b01101101 ,0b01111101 ,0b00000111 ,0b01111111 ,0b01100111 ,0b01110111 ,0b01111100 ,0b00111001 ,0b01011110 ,0b01111001 ,0b01110001

.text
_start: 
	@initialize registers 
	ldr r8 , A9_TIMER		@address to access timer
	ldr r9 , KEY_BASE		@address to access buttons 
	ldr r10, HEX3_HEX0_BASE		@address to accces botton 4 segments
	ldr r11, HEX6_HEX5_BASE		@address to access top 2 segments
	ldr r12, =0x00		@hour count initialized at zero

    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    @ R12 must be protected at all costs... this is the hour counter @
    @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	
	ldr r5, =0x00000000 		@initially display all zeros
	ldr r2, =HEX_TABLE  		@address to hex table 
	mov r0, #0			@set timer to start as stopped 

	mov r4, r5			@send zeros from r5 into r4


	@initialize timer to display all zeros 
	mov r1, r4			@putting the zeros into the input to display register 
	
	@putting appropriate 0 (left) or 1 (right) into each spot 	
	mov r3, #0
	bl _display_hex_21		@digit 1 - hundreth of second

	mov r3, #1
	bl _display_hex_21 		@digit 2 - tenth of a second

	mov r3, #0
	bl _display_hex_43		@digit 3 - second

	mov r3, #1
	bl _display_hex_43 		@digit 4 - ten seconds

	mov r3, #0
	bl _display_hex_65		@digit 5 - minute

	mov r3, #1
	bl _display_hex_65		@digit 6 - ten minutes 

	@initialize clock for time interval
	ldr r1, =200		@hex number for interval of 100th of a second (200MHz -> 200 000 000cycles/second divided by 100 to get 100ths)
	str r1, [r8]			@sending to address of timer 
	mov r1, #1			@initial timer state is zero
	lsl r1, #1			
	str r1, [r8, #8]		@putting into the continue bit of timer


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@register tracker
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@r0 - timer on/off
@r1 - input to display, used to update time 
@r2 - hex array 
@r3 - identify which digit of timer unit (1 for left digit (larger), 0 for right (smaller))
@r3 - also used as working register throughout
@r4 - display 
@r5 - lap time switch state, current time
@r6 - check if we are adding one to timer unit 
@r7 - current lap value
@r8 - address of timer
@r9 - address of push buttons
@r10 - address for hex 1 to 4 (0 to 3)
@r11 - address for hex 5 to 6 (4 to 5)
@r12 - hour count 


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@main program
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

_main_loop:


@check buttons to see if we are holding lap value 
	ldr r3, [r9]			@put address of buttons into working register 
	and r3, #0b0100			@bit mask - clear everything to zero except bit 2 - keep same to check 
	cmp r3, #0b0100			@is bit 2 = 1? if yes, that means the lap button is pressed 

@if lap button pressed: 
	moveq r7, r5 			@putting the current time into lap register 

@to check lap switch	
	@ ldr r3, [r12]			@put address of switches into working register 
	and r3, #0b0001			@bit mask - clear everything except for bit 0 - the switch we're checking 
	cmp r3, #0b0001			@if bit 0 = 1, the switch is high, so we want to display the lap value 
	
	beq _wait_for_timer1		@if it's equal, we wait for the timer to complete current cycle 
	b _ignore			@otherwise continue as usual 


@to wait for timer to finish cycle 
_wait_for_timer1:
	ldr r3, [r8, #12]		@load the value of the timeout bit in the timer into r3 
	cmp r3, #0			@is the timeout 0 (ie: is the timer still counting?) 
	beq _wait_for_timer1		@if it is, continue to wait and check again 
	str r3, [r8, #12] 		@put the timeout flag back - this will restart timer 

	@otherwise update timer time 
	mov r1, r5			@put the current time into r1 (input to display) ???????????????THIS BLOCK 
	bl _update_time			@branch to update time subroutine
	mov r5, r1			@move back 
	mov r4, r5 			@put current time into display register 

	mov r4, r7 			@move the current lap value into the display register 
	b _write_display		@write the lap time to the display 

_ignore:				@do nothing 



_wait_for_start:
	@to check buttons for clear command

	ldr r3, [r9]			@address for push buttons
	and r3, #0b1000			@clear everything except bit 3 (clear button)
	cmp r3, #0b1000			@check if clear button high 

	moveq r5, #0			@clear the current time if the button was high
	moveq r4, r5
	beq _write_display 		@write this new cleared time onto the display 
	
	bl _check_start_stop		@check if the start/stop buttons are pressed 
	
	ldr r3, [r8, #8]		@putting enable of timer into r3 
	orr r3, r0			@setting the enable of the timer to either 1 or 0 depending on start or stop, keep in r3 
	str r3, [r8, #8]		@store the value in r3 back into enable bit 

	mov r3, #0			@put zero into r3
	cmp r3, r0			@are r3 and r0 both 0? 
beq _wait_for_start			@if so - don't start yet - wait for start... keep looping until the enable is 1 
	


_wait_for_timer2: 
	ldr r3, [r8, #12]		@put timeout bit into r3 
	cmp r3, #0			    @is the timeout bit 0? (ie: is the timer not done yet?) 
	beq _wait_for_timer2 	@if not done yet, check again and keep looping
	str r3, [r8, #12]		@eventually, store r3 back in timeout 

	mov r1, r5			@put current time into input to display 
	bl _update_time		@update the time with the value in r1 
	mov r5, r1			@eventually move r1 output of branch back into r5 to update time 
	mov r4, r5			@put the current time into the write to display register 

_write_display: 		@ branch here to access display writing when needed for lap and clear
					    @ after updating the time, write to the displays

mov r1, r4				@put the time into the display input register 
mov r3, #0				@first display - left digit of first pair 
bl _display_hex_21

mov r1, r4
mov r3, #1				@second display - right digit of first pair 
bl _display_hex_21

mov r1, r4
mov r3, #0				@third display - left digit of second pair 
bl _display_hex_43

mov r1, r4
mov r3, #1				@forth display - right digit of second pair 
bl _display_hex_43

mov r1, r4
mov r3, #0				@fifth display - left digit of third pair 
bl _display_hex_65

mov r1, r4
mov r3, #1				@sixth display - right digit of third pair 
bl _display_hex_65

@ loop back to beginning
b _main_loop




@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@subroutines
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



@to check buttons for stop/start
_check_start_stop:
	push {r4 - r9, lr}		@push registers to the stack 


	ldr r3, [r9]			@address for push buttons
	and r3, #0b0001			@clear all but bit 0 (start button)
	cmp r3, #0b0001			@check if start button is high 
	moveq r0, #1			@if it is, assign start/stop with high 

	ldr r3, [r9]			@address for push buttons 
	and r3, #0b0010			@clear all but bit 1 (stop button)
	cmp r3, #0b0010			@check if stop button is high 
	moveq r0, #0 			@if it is, assign start/stop with low 

	pop {r4 - r9, lr}		@pop registers back from stack 
	bx lr 

@to update numbers 
_update_time: 
	push {r4 - r9, lr} 		@push registers to the stack 
	
	@check values of digits - see if we need to add to next place value 
	@is first digit a 9? 
	mov r6, r1			@put value of current time into r6 
	and r6, #0x09			@bit mask with a 9 in respective column 
	cmp r6, #0x09			@check if it's a 9

	beq _add_to_2 			@if it is, add to second digit 
	b _add_one			@otherwise, add one to this digit 

		_add_one:
			add r1, #0x01			@increment by 1 
			b _update_done			@exit to end of subroutines in this section

		_add_to_2:
			add r1, #0x10			@increment by 1 in 2nd place value 
			mov r6, #0xfffffff0		@put all ones except for last byte into r6
			and r1, r6			@bit mask so everything stays the same and just clears that farthest byte

	@is second digit a 10? 
	mov r6, r1
	and r6, #0xa0
	cmp r6, #0xa0					

	beq _add_to_3
	b _update_done

		_add_to_3:
			add r1, #0x0100
			mov r6, #0xffffff0f
			and r1, r6

	@is third digit a 10? 
	mov r6, r1
	and r6, #0x0a00
	cmp r6, #0x0a00

	beq _add_to_4 
	b _update_done
	
		_add_to_4:
			add r1, #0x1000
			mov r6, #0xfffff0ff
			and r1, r6

	@is fourth digit 6? 
	mov r6, r1
	and r6, #0x6000
	cmp r6, #0x6000

	beq _add_to_5
	b _update_done 
			
		_add_to_5:
			add r1, #0x00010000
			mov r6, #0xffff0fff
			and r1, r6

	@is fifth digit a 10? 
	mov r6, r1
	and r6, #0x000a0000
	cmp r6, #0x000a0000

	beq _add_to_6
	b _update_done
	
		_add_to_6:
			add r1, #0x00100000
			mov r6, #0xfff0ffff
			and r1, r6

	@is sixth digit 6? 
	mov r6, r1
	and r6, #0x600000
	cmp r6, #0x600000
	// beq _start      @@@@@ XX instead of branching to start, lets add 1 to a register and then clear the entire timer
    beq _add_hour
	b _update_done      @@@ XX instead of finishing, reset the system


        _add_hour: @ add hour and reset the display
            add r12, #1 @@ XX add 1 to the hour count
            moveq r5, #0			@clear the current time if the button was high
	        // moveq r4, r5
			cmp r12, #24
            movge r12, #0 
			// bge _set_decrement_brightness  @@@ XX uncomment later
			@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@@ CAM NEEDS TO POINT BACK HERE @@@@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@ after _set_decrement_brightness @@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@@ just use bx lr (kisses xoxo) @@@@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	        b _write_display 		@write this new cleared time onto the display 
            @ check if the hour count is greater than or equal to 24 (bc we have an add 12 hours button)
            
              

		_update_done:
			pop {r4 - r9,lr} 		@pop back original registers
			bx lr 


@ to display hex (for places 1 and 2 - miliseconds)

_display_hex_21: 					

	push {r4 - r9, lr}
	
	cmp r3, #1						@check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@this input is just on first number 
	andne r1, r9						@bitmask with r1 to select only that portion

	moveq r9, #0x0000000f				
	lsl r9, #4						@this input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

	mov r4, r2 						@Store Hex table in r4
	ldrb r6, [r4, r1]   					@storing the value r4 shifted by r1 (one byte) to access right digit, and storing in r3
	lsleq r6, #8						@if it was a one above, we more over two bytes to access the left digit 

	ldr r7, [r10]							@load in current value on display 

	ldrne r9, =0xffffff00						@bit masking to change only first digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0xffff00ff						@bit masking to change only second digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r10]							@write back to display 

	pop {r4 - r9, lr}   						@ popping original registers back off before returning to main loop
	bx lr

@ to display hex (for places 3 and 4 - seconds)

_display_hex_43:
	push {r4 - r9, lr}
	
	lsr r1, #8 						@moving over so we're in minutes place now 

	cmp r3, #1						@check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@this input is just on first number 
	andne r1, r9

	moveq r9, #0x0000000f				
	lsl r9, #4						@this input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

	mov r4, r2 						@Store Hex table in r4
	ldrb r6, [r4, r1]   					@storing the value r4 shifted by r1 to access right digit, and storing in r3
	lsl r6, #16						@moving over 4 bytes to get to the 4 and 3 portion of this address
	lsleq r6, #8						@if it's equal to 1 (ie if it's the left digit) we move over two more bytes to get to the appropriate spot

	ldr r7, [r10]							@load in current value on display 

	ldrne r9, =0xff00ffff						@bit masking to change only third digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0x00ffffff						@bit masking to change only fourth digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r10]							@write back to display 

	pop {r4 - r9, lr}   						@ popping original registers back off before returning to main loop
	bx lr

@ to display hex (for places 5 and 6 - minutes)

_display_hex_65: 					

	push {r4 - r9, lr}
	
	lsr r1, #16						@shifting to work with minutes 
	
	cmp r3, #1						@check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@this input is just on first number 
	andne r1, r9

	moveq r9, #0x0000000f				
	lsl r9, #4						@this input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

	mov r4, r2 						@Store Hex table in r4
	ldrb r6, [r4, r1]   					@storing the value r4 shifted by r1 to access right digit, and storing in r3
	lsleq r6, #8

	ldr r7, [r11]							@load in current value on display (NOTICE this is going to a different address than the others) 

	ldrne r9, =0xffffff00						@bit masking to change only first digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0xffff00ff						@bit masking to change only second digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r11]							@write back to display 

	pop {r4 - r9, lr}   						@ popping original registers back off before returning to main loop
	bx lr
	


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@labels 

HEX3_HEX0_BASE:		.word	0xFF200020
HEX6_HEX5_BASE:		.word	0xFF200030
SW_BASE:		.word	0xFF200040
KEY_BASE:		.word   0xff200050
A9_TIMER: 		.word   0xfffec600
	
	