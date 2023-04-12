.global _main
/* --------------------- */
/* -----Data Values----- */
/* --------------------- */
.data
@ This is a look up table for writing to the parallel port to display how many lights should be lit up
LOOKUP_TABLE:  .word 0b0000000000000000, 0b0000000000000001, 0b0000000000000001, 0b0000000000000011, 0b0000000000000111, 0b0000000000001111, 0b0000000000001111,  0b0000000000011111, 0b0000000000111111, 0b0000000001111111, 0b0000000001111111 , 0b0000000011111111, 0b0000000011111111, 0b0000000111111111, 0b0000001111111111, 0b0000001111111111 ,0b0000001111111111 
@ This is an array of bytes corresponding to numbers of the 7-segment display
HEX_TABLE:	.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111, 0b01100110, 0b01101101, 0b01111101, 0b00000111, 0b01111111, 0b01100111, 0b01110111, 0b01111100, 0b00111001, 0b01011110, 0b01111001, 0b01110001

.text
/* ------------------------------ */
/* -----Register Assignments----- */
/* ------------------------------ */
@ r0 = timer running/stopped state (0 for stopped, 1 for running) (low v stop, high
@ r1 = input number into display function (THE BOARD ITSELF)
@ r2 = array of hex values (has to be in R2!!! and passed down each subrourine)
@ r3 = for first/second digit in each time unit (minutes, seconds, miliseconds) (1 for second digit, 0 for first)
@ r4 = first 4 displays (6  5  4  3  2  1)
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

/* ----------------------- */
/* -----Initialization---- */
/* ----------------------- */
_start:
    @ Writing parallel port1 to all be output
    ldr r0, JP1_BASE
    ldr r1, =0xffffffff
    str r1, [r0, #4]

    @ Setting ADC to auto update by writting a value of 1 (could be any value) to channel 1
    ldr r0, ADC_BASE
    mov r4 , #1
    str r4 , [r0, #4] @ set ADC to auto-update

    @ Initializing the data labels
    ldr r8, A9_TIMER
    ldr r9, BTN_BASE
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

/* ------------------ */
/* -----MAIN LOOP---- */
/* ------------------ */
_main:

/* Timer */
_timer:

/* Set decrement from traffic */
_calcDec:

/* Read environment brightness */
_readBrightness:

/* Person detection */
_detectPpl:

/* Write brightness of light */
_writeLights:
{push r4 - r9, lr}                              @ push to stack 
@@ assumption - r10 holds person (1 or 0)

@@ r5 - hex value value we're writing 
@@ r4 - will hold binary value we're writing 

@ load in the dec and high brightness values from memory 
ldr r6, DEC_VALUE           @ put dec value into r7
ldr r7, [r6]                
ldr r8, HIGH_BRIGHT         @ put high bright value into r5
ldr r5, [r8]

@ check if person variable is 0 (ie: if switch is low)
cmp r10, #0                 @ is person = 0? 
    @yes
    subeq r5, r7                @ if no person (0), decrement brightness value 
    @no - do nothing  

@ actually writing to lights 
ldr r3, =LOOK_UP_TABLE2         @ put address of lookup table into register 
lsl r5, #2 					    @ multiply hex value by 4 to account for word offset 
ldr r4, [r3,r5]                 @ shift by the hex value we want to write - gives us a binary code
ldr r6, GPIO                    @ put address of GPIO into register 
str r4, [r6]                    @ write the binary code to the GPIO address (data register is at base so no shift)

@ set the "last state" variable 
str r10, LAST_STATE 
@ branch back to start

{push r4 - r9, lr}
b main

/* -------------------- */
/* -----Data Labels---- */
/* -------------------- */
LED_BASE:		.word	0xFF200000  @ LED base address (not used)
HEX3_HEX0_BASE:	.word	0xFF200020  @ Hex 1 to 4 base address
HEX6_HEX5_BASE:	.word	0xFF200030  @ Hex 5 to 6 base address
SW_BASE:		.word	0xFF200040  @ Slide switch base address
BTN_BASE:		.word   0xFF200050  @ Push button base address
A9_TIMER: 		.word   0xFFFEC600  @ A9 private timer base address
JP1_BASE:       .word   0xFF200060  @ 32-pin GPIO expansion port base address
ADC_BASE:       .word   0xFF204000  @ ADC base address
HIGH_BRIGHT:    .word
DEC_VALUE:      .word
LAST_STATE:     .word
TODAY_TOTAL_TIME: .word