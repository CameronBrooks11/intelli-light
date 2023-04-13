.global start
/* --------------------- */
/* -----Data Values----- */
/* --------------------- */
.data
@ This is a look up table for writing to the parallel port to display how many lights should be lit up
LOOKUP_TABLE:  .word 0b0000000000000000, 0b0000000000000001, 0b0000000000000001, 0b0000000000000011, 0b0000000000000111, 0b0000000000001111, 0b0000000000001111,  0b0000000000011111, 0b0000000000111111, 0b0000000001111111, 0b0000000001111111 , 0b0000000011111111, 0b0000000011111111, 0b0000000111111111, 0b0000001111111111, 0b0000001111111111 ,0b0000001111111111 
@ This is an array of bytes corresponding to numbers of the 7-segment display
HEX_TABLE:	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111, 0b01110111, 0b01111100, 0b00111001, 0b01011110, 0b01111001, 0b01110001


.text
/*
UPDATES [Tues., April 11]:
    Hour counter for 0-24 hours is now stored to memory address "TOTAL_HOURS", see end of code.
    Added proper address loading for peripheral activity.
        Thus, registers r7 through r12 are now free
		r2 is also free
		{We can try and free more registers, but it may get messy}

	Refrained from pushing and popping r12 so we can still visualize the hour count
	although register r12 should be free as it stores to memory
	Note: manually setting the hour counter via register 12 will not work anymore,
			r12 will always pull from memory counter...
*/

.text

/* ----------------------- */
/* -----Initialization---- */
/* ----------------------- */
_start: 
	ldr r5, =0x00000000 		@initially display all zeros
	ldr r2, =HEX_TABLE  		@address to hex table 
	mov r0, #0			@ set timer to start as stopped 

	mov r4, r5			@ send zeros from r5 into r4


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
    ldr r8 , A9_TIMER       @ Loading in address of timer
	ldr r1, =200		    @hex number for interval of 100th of a second (200MHz -> 200 000 000cycles/second divided by 100 to get 100ths)
	str r1, [r8]			@sending to address of timer 
	mov r1, #1			    @initial timer state is zero
	lsl r1, #1			
	str r1, [r8, #8]		@putting into the continue bit of timer



/* ------------------------------ */
/* -----Register Assignments----- */
/* ------------------------------ */
@r0 - timer on/off  @ We could store this state to memory if needed...
@r1 - input to display, used to update time @@ Questionable if we can use this or not... - Kyle
@r2 - FREE
@r3 - identify which digit of timer unit (1 for left digit (larger), 0 for right (smaller))
@r3 - also used as working register throughout
@r4 - display 
@r5 - lap time switch state, current time (apparently needed for proper display -Kyle)
@r6 - check if we are adding one to timer unit 
@r7 - FREE
@r8 - FREE
@r9 - FREE
@r10 - FREE
@r11 - FREE
@r12 - FREE

@CONTROLS
@ push button 0 -> start
@ push button 1 -> stop
@ push button 2 -> BLANK???
@ push button 3 -> RESET

/* ------------------ */
/* -----MAIN LOOP---- */
/* ------------------ */
_main:


_wait_for_start:
	@to check buttons for clear command
    ldr r9, KEY_BASE       @ load address for push buttons
	ldr r3, [r9]			@address for push buttons
	and r3, #0b1000			@clear everything except bit 3 (clear button)
	cmp r3, #0b1000			@check if clear button high 

	moveq r5, #0			@clear the current time if the button was high
	moveq r4, r5
	beq _write_display 		@write this new cleared time onto the display 
	
	bl _check_start_stop		@check if the start/stop buttons are pressed 
	
    ldr r8, A9_TIMER
	ldr r3, [r8, #8]		@putting enable of timer into r3 
	orr r3, r0			@setting the enable of the timer to either 1 or 0 depending on start or stop, keep in r3 
	str r3, [r8, #8]		@store the value in r3 back into enable bit 

	mov r3, #0			@put zero into r3
	cmp r3, r0			@are r3 and r0 both 0? 
beq _wait_for_start			@if so - don't start yet - wait for start... keep looping until the enable is 1 
	


_wait_for_timer: 
    ldr r8 , A9_TIMER
	ldr r3, [r8, #12]		@put timeout bit into r3 
	cmp r3, #0			    @is the timeout bit 0? (ie: is the timer not done yet?) 
	beq _wait_for_timer 	@if not done yet, check again and keep looping
	str r3, [r8, #12]		@eventually, store r3 back in timeout 

	mov r1, r5			@put current time into input to display 
	bl _update_time		@update the time with the value in r1 
	mov r5, r1			@eventually move r1 output of branch back into r5 to update time 
	mov r4, r5			@put the current time into the write to display register 
    bl _read_brightness
    bl _person_detect
    bl _write_lights



_write_display: 		@ branch here to access display writing when needed for lap and clear
					    @ after updating the time, write to the displays

mov r1, r5			@put the time into the display input register 
mov r3, #0				@first display - left digit of first pair 
bl _display_hex_21

mov r1, r5
mov r3, #1				@second display - right digit of first pair 
bl _display_hex_21

mov r1, r5
mov r3, #0				@third display - left digit of second pair 
bl _display_hex_43

mov r1, r5
mov r3, #1				@forth display - right digit of second pair 
bl _display_hex_43

mov r1, r5
mov r3, #0				@fifth display - left digit of third pair 
bl _display_hex_65

mov r1, r5
mov r3, #1				@sixth display - right digit of third pair 
bl _display_hex_65

@ loop back to beginning
b _main




@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@subroutines
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
_read_brightness:
    push {r4 - r11, lr}



	pop {r4 - r11, lr}   				@ popping original registers back off before returning to main loop
	bx lr

_person_detect:
    push {r4 - r11, lr}



	pop {r4 - r11, lr}   				@ popping original registers back off before returning to main loop
	bx lr

 _write_lights:
    push {r4 - r11, lr}



	pop {r4 - r11, lr}   				@ popping original registers back off before returning to main loop
	bx lr

@to check buttons for stop/start
_check_start_stop:
	push {r4 - r11, lr}		@push registers to the stack 

    ldr r9 , KEY_BASE       @ load address for push buttons
	ldr r3, [r9]			@address for push buttons
	and r3, #0b0001			@clear all but bit 0 (start button)
	cmp r3, #0b0001			@check if start button is high 
	moveq r0, #1			@if it is, assign start/stop with high 

	ldr r3, [r9]			@address for push buttons 
	and r3, #0b0010			@clear all but bit 1 (stop button)
	cmp r3, #0b0010			@check if stop button is high 
	moveq r0, #0 			@if it is, assign start/stop with low 

	pop {r4 - r11, lr}		@pop registers back from stack 
	bx lr 

_update_time: 
	push {r4 - r11, lr} 		@push registers to the stack 
	
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
            ldr r8, =TOTAL_HOURS    @ Load in address of hours for the day
            ldr r12, [r8]           @ Load the current value at this address
            add r12, #1             @@ XX add 1 to the hour count
            moveq r5, #0			@ clear the current time (since 1 hour has passed)
	        // moveq r4, r5
			cmp r12, #24            @ Check is 24 hours has passed
            movge r12, #0           @ Set counter to 0 if 24 hours has passed
            str r12, [r8]           @ Store the (0-23) value to TOTAL_HOURS address
			bge _set_decrement_brightness  @@@ XX uncomment later
			@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@@ CAM NEEDS TO POINT BACK HERE @@@@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@ after _set_decrement_brightness @@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@@ just use bx lr (kisses xoxo) @@@@@@@@@@@@@@@@@
			@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	        b _write_display 		@write this new cleared time onto the display 
            @ check if the hour count is greater than or equal to 24 (bc we have an add 12 hours button)
            
              

		_update_done:
			pop {r4 - r11,lr} 		@pop back original registers
			bx lr 

_set_decrement_brightness:
	push {r4 - r11, lr} 		@push registers to the stack 

    ldr r4, =ACTIVE_TIME1          // Loads the total active time for the day for light 1
    ldr r5, =ACTIVE_TIME2          // Loads the total active time for the day for light 2

    add r6, r4, r5        // Add r4 and r5 then put in r6
    udiv r7, r2, #2       // Unsigned divide r2 by 2, store result in r7
    cmp r4, r7            // compare r1 and r2
    movlt r4, #0        // if r5 < r7 (lower), set r0 to 0
    movge r4, #1         // if r5 >= r7 (higher or equal), set r0 to 1 
    cmp r5, r7            // compare r1 and r2
    movlt r5, #0        // if r5 < r7 (lower), set r0 to 0
    movge r5, #1         // if r5 >= r7 (higher or equal), set r0 to 1 
    mov r8, #0
    add r8, r8, r4
    lsl r8, #1
    add r8, r8, r5
    str r8, =TRAFFIC_STATUS

	pop {r4 - r11,lr} 		@pop back original registers
	bx lr 


@ to display hex (for places 1 and 2 - miliseconds)

_display_hex_21: 					

	push {r4 - r11, lr}
	
	cmp r3, #1						@check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@this input is just on first number 
	andne r1, r9						@bitmask with r1 to select only that portion

	moveq r9, #0x0000000f				
	lsl r9, #4						@this input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

    ldr r5, =HEX_TABLE
	mov r4, r5 						@Store Hex table in r4
	ldrb r6, [r4, r1]   					@storing the value r4 shifted by r1 (one byte) to access right digit, and storing in r3
	lsleq r6, #8						@if it was a one above, we more over two bytes to access the left digit 

    ldr r10, HEX3_HEX0_BASE             @ load address for bottom 4 segments
	ldr r7, [r10]							@load in current value on display 

	ldrne r9, =0xffffff00						@bit masking to change only first digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0xffff00ff						@bit masking to change only second digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r10]							@write back to display 

	pop {r4 - r11, lr}   						@ popping original registers back off before returning to main loop
	bx lr

@ to display hex (for places 3 and 4 - seconds)

_display_hex_43:
	push {r4 - r11, lr}
	
	lsr r1, #8 						@moving over so we're in minutes place now 

	cmp r3, #1						@check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@this input is just on first number 
	andne r1, r9

	moveq r9, #0x0000000f				
	lsl r9, #4						@this input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

    ldr r5, =HEX_TABLE
	mov r4, r5 						@Store Hex table in r4
	ldrb r6, [r4, r1]   					@storing the value r4 shifted by r1 to access right digit, and storing in r3
	lsl r6, #16						@moving over 4 bytes to get to the 4 and 3 portion of this address
	lsleq r6, #8						@if it's equal to 1 (ie if it's the left digit) we move over two more bytes to get to the appropriate spot

    ldr r10, HEX3_HEX0_BASE             @ load address for bottom 4 segments
	ldr r7, [r10]							@load in current value on display 

	ldrne r9, =0xff00ffff						@bit masking to change only third digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0x00ffffff						@bit masking to change only fourth digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r10]							@write back to display 

	pop {r4 - r11, lr}   						@ popping original registers back off before returning to main loop
	bx lr

@ to display hex (for places 5 and 6 - minutes)

_display_hex_65: 					

	push {r4 - r11, lr}
	lsr r1, #16						@shifting to work with minutes 
	
	cmp r3, #1						@check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@this input is just on first number 
	andne r1, r9

	moveq r9, #0x0000000f				
	lsl r9, #4						@this input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

    ldr r5, =HEX_TABLE
	mov r4, r5 						@Store Hex table in r4
	ldrb r6, [r4, r1]   					@storing the value r4 shifted by r1 to access right digit, and storing in r3
	lsleq r6, #8

    ldr r11, HEX6_HEX5_BASE             @ load address for top 2 segments
	ldr r7, [r11]							@load in current value on display (NOTICE this is going to a different address than the others) 

	ldrne r9, =0xffffff00						@bit masking to change only first digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0xffff00ff						@bit masking to change only second digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r11]							@write back to display 

	pop {r4 - r11, lr}   						@ popping original registers back off before returning to main loop
	bx lr
	


@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@labels 

HEX3_HEX0_BASE:		.word	0xFF200020
HEX6_HEX5_BASE:		.word	0xFF200030
SW_BASE:		    .word	0xFF200040
KEY_BASE:		    .word   0xff200050
A9_TIMER: 		    .word   0xfffec600
TOTAL_HOURS:        .word   0x00000017             @ Initialize value at this arbitrary address as 0, for demo to 23 (0x17)
TRAFFIC_STATUS:     .byte   0b00111111
ACTIVE_TIME1:	    .word   0x00000000
ACTIVE_TIME2:	    .word   0x00000000

