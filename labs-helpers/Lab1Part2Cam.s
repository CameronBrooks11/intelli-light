@ Your first program
.global _start

.data
array: .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

@ now start the code
.text
_start:
	@ initialize registers here as necessary
	ldr r0, =array 
	ldr r1, SW_BASE
	ldr r2, HEX3_HEX0_BASE
	ldr r5, DELAY_LENGTH

	
@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ START OF MAIN PROGRAM @@	
_main_loop:
	bl _read_switches
	bl _display_hex
	@bl _delay_loop
	
	@ loop endlessly
	b _main_loop
@@@ END OF MAIN PROGRAM @@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@	


@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ START OF SUBROUTINES @@@	
_read_switches:
	@ load the switches value into register r3
	ldr r3, [r1]
	AND r3, #0x0F
	@ return from subroutine
	bx lr

_display_hex:
	@@@ access the nth byte in array at r0, where n is in register r3, and stores this to r4
	ldrb r4, [r0, r3]
	str r4, [r2]
	@ return from subroutine

	@@@ note that the offset can even be a register
	@ ldrb r0, [r1, r2]
	@@@ this accesses the nth byte in array at r1, where n is in register r2

	bx lr

@ do nothing for a while
_delay_loop:
	str r7, [r2]
	@ check if counter reached 0
	cmp r5, #0
	@ branch back to main loop if it is zero
	beq _main_loop
	@ otherwise reduce loop counter by one
	sub r5, #1
	@ cycle through delay loop again
	b _delay_loop


@@@ END OF SUBROUTINES @@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@
	

@ labels for constants and addresses
LED_BASE:		.word	0xFF200000
HEX3_HEX0_BASE:	.word	0xFF200020
SW_BASE:		.word	0xFF200040
@array_adr:	.word 0xFF200060
DELAY_LENGTH:	.word	05000000

