.global _main

/* -----Data Values----- */
.data
@ This is a look up table for writing to the parallel port to display how many lights should be lit up
LOOKUP_TABLE:  .word 0b0000000000000000, 0b0000000000000001, 0b0000000000000001, 0b0000000000000011, 0b0000000000000111, 0b0000000000001111, 0b0000000000001111,  0b0000000000011111, 0b0000000000111111, 0b0000000001111111, 0b0000000001111111 , 0b0000000011111111, 0b0000000011111111, 0b0000000111111111, 0b0000001111111111, 0b0000001111111111 ,0b0000001111111111 
@ This is an array of bytes corresponding to numbers of the 7-segment display
HEX_TABLE:	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111, 0b01110111, 0b01111100, 0b00111001, 0b01011110, 0b01111001, 0b01110001

.text

/* -----Register Assignments----- */
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


/* -----Initialization---- */
_start:
    @ Writing parallel port1 to all be output
    ldr r0, JP1_BASE
    ldr r1, =0xffffffff
    str r1, [r0, #4]

    @ Setting ADC to auto update by writting a value of 1 (could be any value) to channel 1
    ldr r0, ADC_BASE
    mov r4 , #1
    str r4 , [r0, #4] @ set ADC to auto-update

/* -----Main Loop---- */
_main:



/* -----Data Labels---- */
@ labels for constants and addresses
@ from manual
LED_BASE:		.word	0xFF200000  @ LED base address (not used)
HEX3_HEX0_BASE:	.word	0xFF200020  @ Hex 1 to 4 base address
HEX6_HEX5_BASE:	.word	0xFF200030  @ Hex 5 to 6 base address
SW_BASE:		.word	0xFF200040  @ Slide switch base address
BTN_BASE:		.word   0xFF200050  @ Push button base address
A9_TIMER: 		.word   0xFFFEC600
JP1_BASE:       .word   0xFF200060   @ 32-pin GPIO expansion port base address
ADC_BASE:       .word   0xFF204000   @ ADC base address