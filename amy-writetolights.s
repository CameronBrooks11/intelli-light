.global _start

.data
@ look up tables, one number for each of the 10 possibilties of the hex write value 
@ the direct number of 1's that needs to be written to the LEDs
LOOK_UP_TABLE2:  .word 0b0000000000, 0b0000000001, 0b0000000011, 0b0000000111, 0b0000001111, 0b0000011111, 0b0000111111, 0b0001111111, 0b0011111111, 0b0111111111, 0b1111111111

.text

_start:

@@@@@@@@@@@@@@@@@@@@
@@ initialization @@
@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@ ASSUMPTIONS FOR TESTING @@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ ASSUMING "PERSON" variable is in r10
@@ ASSUMING "HIGHBRIGHT" variable is in r11 
@@ ASSUMING "DECVALUE"  variable is in r12
@@@@@@ hardcoding these for testing purposes @@@@@@@@
mov r10, #0
mov r11, #0x08
mov r12, #0x02

@ write GPIO to be all output (for LEDs)
ldr r0, GPIO                                    @ load GPIO address into register 
ldr r1, =0xffffffff                             @ set everything high (output)
str r1, [r0, #4]                                @ store in direction control register - base shifted by 4

mov r2, r11         @ put highbright value into r2 - this is the value we'll write to LEDs



@@@@@@@@@@@@@@@@@@@@
@@@ main loop @@@@@@
@@@@@@@@@@@@@@@@@@@@

@ check if person variable is 0 (ie: if switch is low)
cmp r10, #0             @ is person = 0? 
subeq r2, r12           @ if no person (0), decrement brightness value 

ldr r3, =LOOK_UP_TABLE2     @ put address of lookup table into register 
lsl r2, #2 					@ account for word offset 
ldr r4, [r3,r2]             @ shift by the hex value we want to write - gives us a binary code
ldr r5, GPIO                @ put address of GPIO into register 
str r4, [r5]                @ write the binary code to the GPIO address (data register is at base so no shift)

@ set the "last state" variable 
mov r3, r10 


GPIO:       .word   0xFF200060