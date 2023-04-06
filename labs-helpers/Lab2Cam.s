.global _start

.data

HEX_TABLE:	.byte 0b00111111 ,0b00000110 ,0b01011011 ,0b01001111 ,0b01100110 ,0b01101101 ,0b01111101 ,0b00000111 ,0b01111111 ,0b01100111 ,0b01110111 ,0b01111100 ,0b00111001 ,0b01011110 ,0b01111001 ,0b01110001

.text


@ THE TIMER PROGRAM




@ REGISTER ASSIGNMENTS

@ Assembly


@ r0 = timer running/stopped state (0 for stopped, 1 for running) (low v stop, high
@ r1 = input number into display function (THE BOARD ITSELF)
@ r2 = array of hex values 
@ (has to be in R2!!! and passed down each subrourine)
@ r3 = for first/second digit in each time unit (minutes, seconds, miliseconds) (1 for second digit, 0 for first)
@ r4 = first 4 displays (6  5  4  3  2    1)
@ r5 = lap time 
@ da display state
@ r6 = is a helper value to check to add 1 or not
@ r7 = storing current lap
@ r8  = address private timer
@ r9  = address push buttons
@ r10 = hex base address 1 to 4
@ r11 = hex base address 5 to 6
@ r12 = switch base address for lap switch, switch between lap and current


@CONTROLS
@ push button 0 -> start
@ push button 1 -> stop
@ push button 2 -> takes lap time
@ push button 3 -> RESET
@ switch 0 -> shows lap time, hit again to toggle between between lap time and current time
@ don'ts
@ if you hit 3 then 0, timer will just start, hitting zero doesnt do anything...
@
@ 

_start:
	
@@@ INITIALIZING THE DATA @@@


ldr r8 , A9_TIMER
ldr r9 , BTN_BASE
ldr r10, HEX3_HEX0_BASE
ldr r11, HEX6_HEX5_BASE
ldr r12, SW_BASE

ldr r5, =0x00000000 
ldr r2, =HEX_TABLE
mov r0, #0

mov r4, r5

@ initializing the timer display 
@ First, second, third display etc, etc


mov r1, r4	
mov r3, #0				@first
bl _display_hex_21			@first

mov r1, r4				@second 
mov r3, #1				@second 
bl _display_hex_21

mov r1, r4
mov r3, #0				@third 
bl _display_hex_43			@third 

mov r1, r4
mov r3, #1				@forth 
bl _display_hex_43			@forth 

mov r1, r4
mov r3, #0				@fifth 
bl _display_hex_65			@fifth

mov r1, r4
mov r3, #1				@sixth 
bl _display_hex_65			@sixth


@ INITIALIZING THE CLOCK FOR AN INTERVAL OF TIME AND TO not start counting

ldr r1 , =2000000  @ hex number to load in the timer for an interval of (1) second(s)
str r1 , [ r8 ]

mov r1, #1		@ init timer state = zero
lsl r1, #1
str r1, [r8, #8]

@ main program
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


_main_loop:
@ start of loop



@storing/displaying lap times


@ str bit



ldr r3, [r9]
and r3, #0b0100
cmp r3, #0b0100

@ storing value in register 7 / storing the current time value 
@ value always held in r5


moveq r7, r5


@ check to see if first switch is held on or off

ldr r3, [r12]
and r3, #0b0001
cmp r3, #0b0001

beq _wait_for_timer1
b _ignore

@ wait until timer stat flag is hit


_wait_for_timer1:
ldr r3, [ r8 , #12 ]
cmp r3, #0			@ cmp with status flag to see if timer finished interval
beq _wait_for_timer1

@ restart the a9 timer

str r3 , [ r8 , #12 ]

@ updating the time before displaying it again below


mov r1, r5
bl _update_time
mov r5, r1
mov r4, r5


mov r4, r7
b _write_display


_ignore:

@ START/STOP TIMER


_wait_for_start:

@ checking buttons for CLR 


ldr r3, [r9]
and r3, #0b1000
cmp r3, #0b1000

@ clearing current count/cnt if CLR was high value


moveq r5, #0 		 
moveq r4, r5
beq _write_display


@ sub routine to check buttons and update r0, 
@ then store r0 into timer enable
bl _check_buttons

ldr r3, [r8, #8]	 @ bit mask to change the enable and keep
orr r3, r0		 @ the continous count bit. if no bit mask
str r3, [r8, #8]	 @ then continous count bit is cleared and timer will only count 1/2 miliseconds

mov r3, #0			 @ checking to see if r0 is 0, if true
				 @ then loop back and wait for a 1
cmp r3, r0			 @ start timer
beq _wait_for_start




@ assmebly to contin count  ^^^^^ (up)

@ wait until timer status flag is hit


_wait_for_timer2:
ldr r3 , [ r8 , #12 ]
cmp r3 , #0			@ cmp with status flag to see if timer finished interval
beq _wait_for_timer2


@ restart the a9 timer
str r3 , [ r8 , #12 ]


@ updating the time before displaying it again below


mov r1, r5
bl _update_time
mov r5, r1
mov r4, r5


_write_display: 

@ branch here to access display writing when needed for lap and clear


@ after updating time
@ write to the displays or display the value


mov r1, r4	
mov r3, #0				@first 
bl _display_hex_21			@first

mov r1, r4
mov r3, #1				@second 
bl _display_hex_21			@second

mov r1, r4
mov r3, #0				@third 
bl _display_hex_43			@third 

mov r1, r4
mov r3, #1				@forth 
bl _display_hex_43			@forth 

mov r1, r4
mov r3, #0				@fifth 
bl _display_hex_65			@fifth

mov r1, r4
mov r3, #1				@sixth 
bl _display_hex_65			@sixth

@ loop back to beginning
b _main_loop







  
@SUB ROUTINES
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ sub routine to check lap swtch


_check_lap_switch:
push {r4 - r9, lr} @ pushing registers to stack



pop {r4 - r9, lr}   

@ pop original registers back off before returning to main loop

bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@ sub routine to check buttons and update register 0


_check_buttons:
push {r4 - r9, lr} 

@ pushregisters to stack

@ check first two buttons for start/stop


ldr r3, [r9]
and r3, #0b01
cmp r3, #0b01

moveq r0, #1

ldr r3, [r9]
and r3, #0b10
cmp r3, #0b10

moveq r0, #0


pop {r4 - r9, lr}   

@ pop original registers back off before returning to main loop


bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


@ sub routine to update numbers

_update_time:
push {r4 - r9, lr} 

@ pushing registers to stack

@ check to see if first digit is a nine


mov r6, r1
and r6, #0x00000009 @ HEX NINE
cmp r6, #0x00000009 @ HEX NINE

beq _add_to_next2
b _add_by_one

_add_by_one:
add r1, #0x00000001
b _update_done

_add_to_next2:
add r1, #0x00000010
mov r6, #0xfffffff0
and r1, r6		

@ adding to second digit



@ check to see if second digit is a nine


mov r6, r1
and r6, #0x000000a0
cmp r6, #0x000000a0

beq _add_to_next3
b _update_done

_add_to_next3:
add r1, #0x00000100
mov r6, #0xffffff0f
and r1, r6		


@ adding to third digit



@ check to see if third digit is a nine



mov r6, r1
and r6, #0x00000a00
cmp r6, #0x00000a00

beq _add_to_next4
b _update_done

_add_to_next4:
add r1, #0x00001000
mov r6, #0xfffff0ff
and r1, r6		

@ add to forth digit



@ check to see if forth digit is a 5


mov r6, r1
and r6, #0x00006000
cmp r6, #0x00006000

beq _add_to_next5
b _update_done

_add_to_next5:
add r1, #0x00010000
mov r6, #0xffff0fff
and r1, r6		

@ add to fifth digit



@ check to see if fifth digit is a 9


mov r6, r1
and r6, #0x000a0000
cmp r6, #0x000a0000

beq _add_to_next6
b _update_done

_add_to_next6:
add r1, #0x00100000
mov r6, #0xfff0ffff
and r1, r6		

@ add to sixth digit

b _update_done

_update_done:
pop {r4 - r9, lr}   

@ pop original registers back off before returning to main loop
@ branch to link register, use with POP

bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

@ display hex subroutine (for millisecond)

_display_hex_21:


push {r4 - r9, lr} 

cmp r3, #1


movne r9, #0x0000000f
andne r1, r9

@ make sure the input is only working on the 1st number ^

@ make sure the input is only working on the 2nd number (below)


moveq r9, #0x0000000f
lsl r9, #4
andeq r1, r9
lsreq r1, #4

mov r4, r2 

@ storing table of hex numbers in r4
ldrb r6, [r4, r1]   @ store the value r4 shifted by r1 and storing in r3
lsleq r6, #8

@ load in current value on display to change it w/ masking


ldr r7, [r10]

@ bit masking to only change the first digit
ldrne r9, =0xffffff00
andne r7, r9
orrne r7, r6

@ bit masking to only change second digit

ldreq r9, =0xffff00ff
andeq r7, r9
orreq r7, r6 

@ writing it back to the display
str r7, [r10]

pop {r4 - r9, lr}   @ popping original registers back off before returning to main loop
bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ display hex subroutine (for seconds) @

_display_hex_43:

@pushing all of the 
push {r4 - r9, lr} @ pushing registers to stack

@ shifting down to work with the min digits


lsr r1, #8

cmp r3, #1

@ make sure the input is only working on the first number


movne r9, #0x0000000f
andne r1, r9

@ make sure the input is only working on the second number

moveq r9, #0x0000000f
lsl r9, #4
andeq r1, r9
lsreq r1, #4

mov r4, r2 @ storing table of hex numbers in r4
ldrb r6, [r4, r1]   @ storing the value r4 shifted by r1, and storing in r3
lsl r6, #16
lsleq r6, #8

@ loading in current value on display to change it w/ masking
ldr r7, [r10]

@ bit masking to only change the first digit
ldrne r9, =0xff00ffff
andne r7, r9
orrne r7, r6

@ bit masking to only change second digit

ldreq r9, =0x00ffffff
andeq r7, r9
orreq r7, r6

@ writing it back to the display
str r7, [r10]

pop {r4 - r9, lr}   @ popping original registers back off before returning to main loop
bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ display hex subroutine (for MIN) @


_display_hex_65:

@pushing all of the 
push {r4 - r9, lr} @ pushing registers to stack

@ shifting down to work with the minute digits
lsr r1, #16

cmp r3, #1

@ making sure the input is only working on the first number
movne r9, #0x0000000f
andne r1, r9

@ making sure the input is only working on the second number
moveq r9, #0x0000000f
lsl r9, #4
andeq r1, r9
lsreq r1, #4

mov r4, r2 @ storing table of hex numbers in r4
ldrb r6, [r4, r1]   @ storing the value r4 shifted by r1, and storing in r3
lsleq r6, #8

@ loading in current value on display to change it via bit masking


ldr r7, [r11] @ accessing the current value at the last two displays at 0xff200030


ldrne r9, =0xffffff00
andne r7, r9
orrne r7, r6



ldreq r9, =0xffff00ff
andeq r7, r9
orreq r7, r6

@ writing back to the display


str r7, [r11]

pop {r4 - r9, lr}   
bx lr

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@




@ labels for constants and addresses
@ from manual
LED_BASE:		.word	0xFF200000
HEX3_HEX0_BASE:	.word	0xFF200020
HEX6_HEX5_BASE:	.word	0xFF200030
SW_BASE:		.word	0xFF200040
BTN_BASE:		.word   0xff200050
A9_TIMER: 		.word   0xfffec600



	