.global _start

.data
LOOKUP_TABLE:  .word 0b0000000000000000, 0b0000000000000001, 0b0000000000000001, 0b0000000000000011, 0b0000000000000111, 0b0000000000001111, 0b0000000000001111,  0b0000000000011111, 0b0000000000111111, 0b0000000001111111, 0b0000000001111111 , 0b0000000011111111, 0b0000000011111111, 0b0000000111111111, 0b0000001111111111, 0b0000001111111111 ,0b0000001111111111 

.text

/* QUICK REFERENCE
LABELS AND CONSTANTS
    SW_BASE:		.word	0xFF200040
    JP1_BASE: .word  0xFF200060
    ADC_BASE:       .word  0xFF204000
*/
/* A/D Conveter function
• To update all channels write any value to the Channel 0 register.
• To have all channels auto-update write any value to the Channel 1 register.
• To read from a channel, read from the corresponding Channel n register. The lowest 12 bits are the converted data.
• To check if conversion is complete, check bit 15 after reading from the channel. If that bit is set to one, the 
conversion was complete. If it is zero, the conversion was incomplete.
• Bit 15 is automatically cleared after the channel is read.
*/

/* DEV NOTES
• Removed "ldr r3 , =LOOK_UP_TABLE" from initialization due to redundancy
• 
• 
*/



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



/* -----MAIN LOOP OF PROGRAM----- */
_main_loop:
    @ Starting point
    @ Next four lines are checking if first switch is held on or off using bit masking
    ldr r0, SW_BASE
    ldr r3, [r0]
    and r3, #0b0001
    cmp r3, #0b0001

    beq _ch1_process @ If switch is ON then process signal from CH1
    b _ch0_process  @ If switch is OFF then process signal from CH0


/* The processing block for CH0 to read and write to the GPIO */
_ch0_process:
    bl _ADC_READ_CH0    @ The value of the CH0 ADC is now in r2
    b _process_main

/* The processing block for CH1 to read and write to the GPIO */
_ch1_process:
    bl _ADC_READ_CH1    @ The value of the CH1 ADC is now in r2
    b _process_main

_process_main:
    @ looking at only the top 4 bits which will give 16 states for the LEDS to work with
    mov r6, #0b00000111100000000
    and r2, r6
    lsr r2, #8

    ldr r3 , =LOOKUP_TABLE

    lsl r2, #2 @ Analogous to multiplying by 4 to take into account the offset
    ldr r1, [r3, r2]

    ldr r0, JP1_BASE
    str r1, [r0]

    b _process_end  @ Branch to end of main loop


/* Branch end point for looping back to main */
_process_end:
    b _main_loop



/* -----SUBROUTINEs----- */

/* Subroutine for reading CH0 of the ADC */
_ADC_READ_CH0:
    push {r4 - r9, lr} @ pushing registers to stack

    ldr r0, ADC_BASE @ loading base address of ADC

    @ setting r4 to be one and lsl by 15 to use for bitmasking
    mov r4, #1
    lsl r4 , #15 @ bit mask for bit 15
/* Continues on to the loop portion to check if conversion is done */

_ADC0_loop:
    ldr r2 , [r0] @ read CH0
    and r3 , r2 , r4 @ check bit 15
    cmp r3 , r4
    bne _ADC0_loop @ conversion not done yet

    sub r2, r4 @ remove bit 15 from data
    @ The register r2 now holds the data from the ADC

    pop {r4 - r9, lr}   @ Popping original registers back off before returning to themain loop
    bx lr

/* Subroutine for reading CH1 of the ADC */
_ADC_READ_CH1:
    push {r4 - r9, lr} @ pushing registers to stack
    ldr r0, ADC_BASE @ loading base address of ADC

    @ setting r4 to be one and lsl by 15 to use for bitmasking
    mov r4, #1
    lsl r4 , #15 @ bit mask for bit 15
    
/* Continues on to the loop portion to check if conversion is done */
_ADC1_loop:
    ldr r2 , [r0, #4] @ Reads CH1
    and r3, r2, r4 @ Checks bit 15
    cmp r3 , r4
    bne _ADC1_loop @ Branch if the conversion is not done yet

    sub r2, r4 @ remove bit 15 from data
    @ The register r2 now holds the data from the ADC

    pop {r4 - r9, lr}   @ Popping original registers back off before returning to themain loop
    bx lr

/* Labels for constants and addresses*/
SW_BASE:		.word	0xFF200040  @ Switch base address
JP1_BASE:       .word  0xFF200060   @ 32-pin GPIO expansion port base address
ADC_BASE:       .word  0xFF204000   @ ADC base address