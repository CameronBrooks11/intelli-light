.global _start

.data
@ look up tables, one number for each of the 16 possibilties of 4 MSBs from potentiometer
@ the bottom 6 values leave the light off at 0 
@ the rest of them select anywhere from 1 to all 10 lights on (0 to A in hex)
@ 0x0:0, 1:0, 2:0, 3:0, 4:0, 5:0, 6:0x1, 7:0x2, 8:0x3, 9:0x4, 10:0x5, 11:0x6, 12:0x7, 13:0x8, 14:0x9, 15:0xa
LOOK_UP_TABLE1:	.word 	0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xa

.text

_start:

@@@@@@@@@@@@@@@@@@@@
@@ initialization @@
@@@@@@@@@@@@@@@@@@@@

@ setting ADC to auto update 
@ done by writing 1 to channel 1 


@@@@@@@@@@@@@@@@@@@@
@@@ main loop @@@@@@
@@@@@@@@@@@@@@@@@@@@

_main_loop: 

bl _READ_ADC_POTENTI			@ get the value from ADC in r4
mov r5, #0b111100000000			@ we only want top 4 of 12 bits (16 possible values) 
and r4, r5
lsr r4, #8				        @ now there's a value between 0000 and 1111 in r4 

lsl r4, #2				        @ equiv to multiplying by 4 to account for offset 
ldr r1, [r2, r4]			    @ take the corresponding value from look up table and place it in r1
@ldr r1, [HIGH_BRIGHT, r4]      @ replace line above once its done as an address 

b _main_loop
@@@
@ passing: r1 holding value between 0000000000 and 1111111111 to write to lights 
@@@

@@@ 
@ INSERT APPROPRIATE BRANCH @
@@@

@@@@@@@@@@@@@@@@@@@@
@@@@ subroutine @@@@
@@@@@@@@@@@@@@@@@@@@

_READ_ADC_POTENTI:
push {r5 - r12, lr}

@ set r2 to be one and lsl by 15 - to use for bitmasking with the update bit 
mov r3, #1
lsl r3, #15		@ ** for simulator do 16 **

adc_loop:
ldr r4, [r0]		@ address for channel 0 
and r5, r4, r3		@ check bit 15 with the mask 
cmp r5, r3	
bne adc_loop		@ conversion's not done yet - try again 

sub r4, r3		@ take out bit 15 from the data 

@ now the data from appropriate potentiometer is in r4

pop {r5 - r12, lr}
bx lr 


@@@ addresses @@@
ADC_BASE: 	.word	0xFF204000
HIGH_BRIGHT: .word