.global _start

.data

.text

_start:

@@@@@@@@@@@@@@@@@@@@
@@ initialization @@
@@@@@@@@@@@@@@@@@@@@

@@@@@@@@@@@@@@@ ASSUMPTIONS FOR TESTING @@@@@@@@@@@@@@@@@@@@@@@@@@@@22
@@ ASSUMING WE'RE USING r10 for current person
@@ ASSUMING WE'RE USING r9 for last state person 
@@ ASSUMING CURRENT TIME VALUE is in r5 
@@ ASSUMING START TIME HELD IN r1 (this should be in memory)
@@ ASSUMING END TIME IN r2
@@ ASSUMING TOTAL TIME TODAY in r3 (this should be in memory)

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ hardcoding for testing @
mov r10, #1
mov r9, #0
mov r5, #250
mov r1, #10
mov r3, #0

@@@@@@@@@@@@@@@@@@@@@
@@ kinda main loop @@
@@@@@@@@@@@@@@@@@@@@@

@ read switch and set current person variable 

ldr r4, SW_BASE         @ take address for switches 
ldr r10, [r4]           @ load value from switch 1 into r10
cmp r10, r9             @ compare with last state 
@ yes they're same (ie: no state change)
beq _write_light        @ if yes, branch to write lights (take r10 value with you!) - continue in program

@ no they're not the same (ie: state change)
@ now check if it's a person leaving (1 change)
cmp r9, #1
beq _record_end_time_and_branch 
bne _record_start_time


@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@ subroutines @@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@

_record_start_time: 
mov r1, r5              @ putting start time into r1 
b _write_light          @ continue in program 

_record_end_time_and_branch: 
mov r2, r5              @ putting end time into r2 
sub r8, r2, r1          @ final - initial, into r5 to hold 
add r3, r8              @ increasing today's total (r3) 
b _write_light          @ continue in program




SW_BASE:		.word	0xFF200040
