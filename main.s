.global _start
/* --------------------- */
/* -----Data Values----- */
/* --------------------- */
.data
@ This is an array of bytes corresponding to numbers of the 7-segment display
HEX_TABLE:	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111, 0b01110111, 0b01111100, 0b00111001, 0b01011110, 0b01111001, 0b01110001

/* FOR READ BRIGHTNESS
look up tables, one number for each of the 16 possibilties of 4 MSBs from 
potentiometer the bottom 6 values leave the light off at 0 the rest of them 
select anywhere from 1 to all 10 lights on (0 to A in hex) */
LOOK_UP_TABLE1:	.word 	0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xa
LOOK_UP_TABLE2:  .word 0b0000000000, 0b0000000001, 0b0000000011, 0b0000000111, 0b0000001111, 0b0000011111, 0b0000111111, 0b0001111111, 0b0011111111, 0b0111111111, 0b1111111111

@ Memory space to hold the total hours (0-24 hours)
TOTAL_HOURS: .word 0x00000017	@ Start at 0x17 = 23 decimals hours (demonstration purposes)

@ Memory 
ACTIVE_TIME1:	.word   0x00000000
ACTIVE_TIME2:	.word   0x00000000

.text

/* ----------------------- */
/* -----Initialization---- */
/* ----------------------- */
_start: 
	ldr r5, =0x00000000 		@ Initially display all zeros
	ldr r2, =HEX_TABLE  		@ Address to hex table 
	mov r0, #0			@ set timer to start as stopped 

	mov r4, r5			@ send zeros from r5 into r4


	@ Initialize timer to display all zeros 
	mov r1, r4			@ Putting the zeros into the input to display register 
	
	@ Putting appropriate 0 (left) or 1 (right) into each spot 	
	mov r3, #0
	bl _display_hex_21		@ Digit 1 - hundreth of second

	mov r3, #1
	bl _display_hex_21 		@ Digit 2 - tenth of a second

	mov r3, #0
	bl _display_hex_43		@ Digit 3 - second

	mov r3, #1
	bl _display_hex_43 		@ Digit 4 - ten seconds

	mov r3, #0
	bl _display_hex_65		@ Digit 5 - minute

	mov r3, #1
	bl _display_hex_65		@ Digit 6 - ten minutes 

	@ Initialize clock for time interval
    ldr r8 , A9_TIMER       @ Loading in address of timer
	ldr r1, =200		    @ Hex number for interval of 100th of a second (200MHz -> 200 000 000cycles/second divided by 100 to get 100ths)
	str r1, [r8]			@ Sending to address of timer 
	mov r1, #1			    @ Initial timer state is zero
	lsl r1, #1			
	str r1, [r8, #8]		@ Putting into the continue bit of timer
	b _main



/* ------------------------------ */
/* -----Register Assignments----- */
/* ------------------------------ */
@r0 - timer on/off  @ We could store this state to memory if needed...
@r1 - input to display, used to update time @@ Questionable if we can use this or not... - Kyle
@r2 - 
@r3 - identify which digit of timer unit (1 for left digit (larger), 0 for right (smaller))
@r3 - also used as working register throughout
@r4 - display 
@r5 - lap time switch state, current time (apparently needed for proper display -Kyle)
@r6 - check if we are adding one to timer unit 
@r7 - high bright value 
@r8 - FREE
@r9 - FREE
@r10 - FREE
@r11 - FREE
@r12 - FREE

@ CONTROLS
@ Push button 0 -> start
@ Push button 1 -> stop
@ Push button 2 -> BLANK???
@ Push button 3 -> RESET

/* ------------------ */
/* -----MAIN LOOP---- */
/* ------------------ */
_main:


_wait_for_start:
	@ To check buttons for clear command
    ldr r9, KEY_BASE       @ Load address for push buttons
	ldr r3, [r9]			@ Address for push buttons
	and r3, #0b1000			@ Clear everything except bit 3 (clear button)
	cmp r3, #0b1000			@ Check if clear button high 

	moveq r5, #0			@ Clear the current time if the button was high
	moveq r4, r5
	beq _write_display 		@ Write this new cleared time onto the display 
	
	bl _check_start_stop		@ Check if the start/stop buttons are pressed 
	
    ldr r8, A9_TIMER
	ldr r3, [r8, #8]		@ Putting enable of timer into r3 
	orr r3, r0			@ Setting the enable of the timer to either 1 or 0 depending on start or stop, keep in r3 
	str r3, [r8, #8]		@ Store the value in r3 back into enable bit 

	mov r3, #0			@ Put zero into r3
	cmp r3, r0			@ Check if r3 and r0 are both 0
beq _wait_for_start			@ If so - don't start yet - wait for start... keep looping until the enable is 1 
	

_wait_for_timer: 
    ldr r8 , A9_TIMER
	ldr r3, [r8, #12]		@ Put timeout bit into r3 
	cmp r3, #0			    @ Is the timeout bit 0? (ie: is the timer not done yet?) 
	beq _wait_for_timer 	@ If not done yet, check again and keep looping
	str r3, [r8, #12]		@ Eventually, store r3 back in timeout 

	mov r1, r5			@ Put current time into input to display 
	bl _update_time		@update the time with the value in r1 
	mov r5, r1			@ Eventually move r1 output of branch back into r5 to update time 
	mov r4, r5			@ Put the current time into the write to display register 
	bl _read_brightness
    bl _check_switch
    bl _write_lights


@ Branch here to access display writing (clear, stop, write time)
_write_display: 		
mov r1, r5				@ Put the time into the display input register 
mov r3, #0				@ First display - left digit of first pair 
bl _display_hex_21

mov r1, r5
mov r3, #1				@ Second display - right digit of first pair 
bl _display_hex_21

mov r1, r5
mov r3, #0				@ Third display - left digit of second pair 
bl _display_hex_43

mov r1, r5
mov r3, #1				@ Forth display - right digit of second pair 
bl _display_hex_43

mov r1, r5
mov r3, #0				@ Fifth display - left digit of third pair 
bl _display_hex_65

mov r1, r5
mov r3, #1				@ Sixth display - right digit of third pair 
bl _display_hex_65

@ loop back to beginning
b _main

/* --------------------- */
/* -----SUB ROUTINES---- */
/* --------------------- */
_check_switch:
    push {r4 - r11, lr}

	ldr r4, SW_BASE         @ Take address for switches 
	ldr r10, [r4]           @ Load value from switch 1 into r10
	ldr r5, =PERSON1
	str r10, [r5]
	cmp r10, #1
	beq _add_to_active
	pop {r4 - r11, lr}   				@ Popping original registers back off before linking back to main
	bx lr

_add_to_active:
    push {r4 - r11, lr}

	ldr r5, =ACTIVE_TIME1
	str r4, [r5]
	add r4, r4, #200
	str r4, [r5]

	pop {r4 - r11, lr}   				@ Popping original registers back off before linking back to main
	bx lr

_read_brightness:
    push {r4 - r6, r8 - r11, lr}

	ldr r10, ADC_BASE 		@ Loading the base address of the ADC 
	mov r9, #1			@ Value of 1 to write to channel 1 
	str r9, [r10, #4] 		@ Channel 1 is 4 offset from the base 

	ldr r2, =LOOK_UP_TABLE1 
	
	@READ POTENTIOMETER
	@ set r2 to be one and lsl by 15 - to use for bitmasking with the update bit 
	mov r11, #1
	lsl r11, #16		@ ** for simulator do 16 **

	adc_loop:
	ldr r4, [r10]		@ Address for channel 0 
	and r5, r4, r11		@ Check bit 15 with the mask 
	cmp r5, r11	
	bne adc_loop		@ Conversion's not done yet - try again 

	sub r4, r11		@ Take out bit 15 from the data 
	
	mov r5, #0b111100000000			@ We only want top 4 of 12 bits (16 possible values) 
	and r4, r5
	lsr r4, #8				        @ now there's a value between 0000 and 1111 in r4 

	lsl r4, #2				        @ equiv to multiplying by 4 to account for offset 
	ldr r7, [r2, r4]			    @ Take the corresponding value from look up table and place it in r1

	pop {r4 - r6, r8 - r11, lr}   				@ Popping original registers back off before linking back to main
	bx lr

 _write_lights:
    push {r4 - r6, r8 - r11, lr}

	@ Hardcodes for testing 
	@ Mov r10, #0			@ Person
	@ Mov r11, #0x08			@ high bright 
	mov r12, #0x02			@ dec value 

	@ Write GPIO to be all output (for LEDs)
	ldr r0, GPIO                                    @ Load GPIO address into register 
	ldr r1, =0xffffffff                             @ set everything high (output)
	str r1, [r0, #4]                                @ store in direction control register - base shifted by 4

	mov r8, r7         @ Put highbright value into r2 - this is the value we'll write to LEDs

	ldr r5, PERSON1
	ldr r10, [r5]
	cmp r10, #0             @ Is person = 0? 
	subeq r8, r12           @ If no person (0), decrement brightness value 


	ldr r3, =LOOK_UP_TABLE2     @ Put address of lookup table into register 
	lsl r2, #2 					@ Account for word offset 
	ldr r4, [r3,r8]             @ shift by the hex value we want to write - gives us a binary code
	ldr r5, GPIO                @ Put address of GPIO into register 
	str r4, [r5]                @ Write the binary code to the GPIO address (data register is at base so no shift)

	pop {r4 - r6, r8 - r11, lr}  				@ Popping original registers back off before linking back to main
	bx lr

@ To check buttons for stop/start
_check_start_stop:
	push {r4 - r11, lr}		@ Push registers to the stack  

    ldr r9 , KEY_BASE       @ Load address for push buttons
	ldr r3, [r9]			@ Address for push buttons
	and r3, #0b0001			@ Clear all but bit 0 (start button)
	cmp r3, #0b0001			@ Check if start button is high 
	moveq r0, #1			@ If it is, assign start/stop with high 

	ldr r3, [r9]			@ Address for push buttons 
	and r3, #0b0010			@ Clear all but bit 1 (stop button)
	cmp r3, #0b0010			@ Check if stop button is high 
	moveq r0, #0 			@ If it is, assign start/stop with low 

	pop {r4 - r11, lr}		@ Pop registers back from stack 
	bx lr 

@ Check values of digits to see if we need to add to next place value 
_update_time: 
	push {r4 - r11, lr} 		@ Push registers to the stack  
		
	@ Is first digit a 9? 
	mov r6, r1			@ Put value of current time into r6 
	and r6, #0x09			@ Bit mask with a 9 in respective column 
	cmp r6, #0x09			@ Check if it's a 9

	beq _add_to_2 			@ If it is, add to second digit 
	b _add_one			@otherwise, add one to this digit 

		_add_one:
			add r1, #0x01			@ Increment by 1 
			b _update_done			@ Exit to end of subroutines in this section

		_add_to_2:
			add r1, #0x10			@ Increment by 1 in 2nd place value 
			mov r6, #0xfffffff0		@ Put all ones except for last byte into r6
			and r1, r6				@ Bit mask so everything stays the same and just clears that farthest byte

	@ Is second digit a 10? 
	mov r6, r1
	and r6, #0xa0
	cmp r6, #0xa0					

	beq _add_to_3
	b _update_done

		_add_to_3:
			add r1, #0x0100
			mov r6, #0xffffff0f
			and r1, r6

	@ Is third digit a 10? 
	mov r6, r1
	and r6, #0x0a00
	cmp r6, #0x0a00

	beq _add_to_4 
	b _update_done
	
		_add_to_4:
			add r1, #0x1000
			mov r6, #0xfffff0ff
			and r1, r6

	@ Is fourth digit 6? 
	mov r6, r1
	and r6, #0x6000
	cmp r6, #0x6000

	beq _add_to_5
	b _update_done 
			
		_add_to_5:
			add r1, #0x00010000
			mov r6, #0xffff0fff
			and r1, r6

	@ Is fifth digit a 10? 
	mov r6, r1
	and r6, #0x000a0000
	cmp r6, #0x000a0000

	beq _add_to_6
	b _update_done
	
		_add_to_6:
			add r1, #0x00100000
			mov r6, #0xfff0ffff
			and r1, r6

	@ Is sixth digit 6? 
	mov r6, r1
	and r6, #0x600000
	cmp r6, #0x600000
    beq _add_hour
	b _update_done


        _add_hour: @ Add hour and reset the display
            ldr r8, =TOTAL_HOURS    @ Load in address of hours for the day
            ldr r12, [r8]           @ Load the current value at this address
            add r12, #1             @ Add 1 to the hour count
            moveq r5, #0			@ Clear the current time (since 1 hour has passed)
			cmp r12, #24            @ Check is 24 hours has passed
            movge r12, #0           @ Set counter to 0 if 24 hours has passed
            str r12, [r8]           @ Store the (0-23) value to TOTAL_HOURS address
			bge _set_decrement_brightness  @@@ XX uncomment later
	        b _write_display 		@ Write this new cleared time onto the display 
         
		_update_done:
			pop {r4 - r11,lr} 		@ Pop back the original registers
			bx lr 

@ Takes the traffic time from that day and averages it against the other light to 
@ see if it is a high or low traffic area
_set_decrement_brightness:
	push {r4 - r11, lr}				@ Push registers to the stack  

    ldr r4, =ACTIVE_TIME1			@ Loads the total active time for the day for light 1
    ldr r5, =ACTIVE_TIME2			@ Loads the total active time for the day for light 2

    add r6, r4, r5					@ Add r4 and r5 then put in r6
	lsr r7, r2, #1					@ Unsigned divide r2 by 2, store result in r7
    cmp r4, r7						@ Compare r1 and r2
    movlt r4, #0					@ If r5 < r7 (lower), set r0 to 0
    movge r4, #1					@ If r5 >= r7 (higher or equal), set r0 to 1 
    cmp r5, r7						@ Compare r1 and r2
    movlt r5, #0					@ If r5 < r7 (lower), set r0 to 0
    movge r5, #1					@ If r5 >= r7 (higher or equal), set r0 to 1 
	ldr r10, LIGHT1_TRAFFIC			@ Load LIGHT1_TRAFFIC address into r10
	str r4, [r10]					@ Write the traffic status (0 or 1) to LIGHT1_TRAFFIC
	ldr r11, LIGHT2_TRAFFIC			@ Load LIGHT1_TRAFFIC address into r11
	str r5, [r11]					@ Write the traffic status (0 or 1) to LIGHT2_TRAFFIC
	mov r7, #0						@ Set both of the active time counting registers to zero
	mov r8, #0						@ This way we are resetting the total time for each new day

	pop {r4 - r11,lr} 				@ Pop back the original registers
	bx lr 


@ To display hex (for places 1 and 2 - miliseconds)
_display_hex_21: 					

	push {r4 - r11, lr}
	
	cmp r3, #1						@ Check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@ This input is just on first number 
	andne r1, r9						@ Bitmask with r1 to select only that portion
	
	moveq r9, #0x0000000f				
	lsl r9, #4						@ This input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

    ldr r5, =HEX_TABLE
	mov r4, r5 						@ Store Hex table in r4
	ldrb r6, [r4, r1]   					@ Storing the value r4 shifted by r1 (one byte) to access right digit, and storing in r3
	lsleq r6, #8						@ If it was a one above, we more over two bytes to access the left digit 

    ldr r10, HEX3_HEX0_BASE             @ Load address for bottom 4 segments
	ldr r7, [r10]							@ Load in current value on display 

	ldrne r9, =0xffffff00						@ Bit masking to change only first digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0xffff00ff						@ Bit masking to change only second digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r10]							@ Write back to display 

	pop {r4 - r11, lr}   						@ Popping original registers back off before linking back to main
	bx lr

@ To display hex (for places 3 and 4 - seconds)

_display_hex_43:
	push {r4 - r11, lr}
	
	lsr r1, #8 						@ Moving over so we're in minutes place now 

	cmp r3, #1						@ Check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@ This input is just on first number 
	andne r1, r9

	moveq r9, #0x0000000f				
	lsl r9, #4						@ This input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

    ldr r5, =HEX_TABLE
	mov r4, r5 						@ Store Hex table in r4
	ldrb r6, [r4, r1]   			@ Storing the value r4 shifted by r1 to access right digit, and storing in r3
	lsl r6, #16						@ Moving over 4 bytes to get to the 4 and 3 portion of this address
	lsleq r6, #8						@ If it's equal to 1 (ie if it's the left digit) we move over two more bytes to get to the appropriate spot

    ldr r10, HEX3_HEX0_BASE             @ Load address for bottom 4 segments
	ldr r7, [r10]							@ Load in current value on display 

	ldrne r9, =0xff00ffff						@ Bit masking to change only third digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0x00ffffff						@ Bit masking to change only fourth digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r10]							@ Write back to display 

	pop {r4 - r11, lr}   						@ Popping original registers back off before linking back to main
	bx lr

@ To display hex (for places 5 and 6 - minutes)

_display_hex_65: 					

	push {r4 - r11, lr}
	lsr r1, #16						@ Shifting to work with minutes 
	
	cmp r3, #1						@ Check if we're accessing the right or left digit 
	
	movne r9, #0x0000000f					@ This input is just on first number 
	andne r1, r9

	moveq r9, #0x0000000f				
	lsl r9, #4						@ This input is just on second number 	
	andeq r1, r9
	lsreq r1, #4

    ldr r5, =HEX_TABLE
	mov r4, r5 						@ Store Hex table in r4
	ldrb r6, [r4, r1]   					@ Storing the value r4 shifted by r1 to access right digit, and storing in r3
	lsleq r6, #8

    ldr r11, HEX6_HEX5_BASE             @ Load address for top 2 segments
	ldr r7, [r11]							@ Load in current value on display (NOTICE this is going to a different address than the others) 

	ldrne r9, =0xffffff00						@ Bit masking to change only first digit 
	andne r7, r9
	orrne r7, r6

	ldreq r9, =0xffff00ff						@ Bit masking to change only second digit 
	andeq r7, r9
	orreq r7, r6 

	str r7, [r11]							@ Write back to display 

	pop {r4 - r11, lr}   						@ Popping original registers back off before linking back to main
	bx lr

/* -------------------- */
/* -----Data Labels---- */
/* -------------------- */
HEX3_HEX0_BASE:		.word	0xFF200020
HEX6_HEX5_BASE:		.word	0xFF200030
SW_BASE:		    .word	0xFF200040
KEY_BASE:		    .word   0xff200050
A9_TIMER: 		    .word   0xfffec600
ADC_BASE: 	.word	0xFF204000
GPIO:       .word   0xFF200060
PERSON1: .word
LIGHT1_TRAFFIC: .word
LIGHT2_TRAFFIC: .word