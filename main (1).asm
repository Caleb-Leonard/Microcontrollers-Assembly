;-------------------------------------------------------------------------------
; MSP430 Assembler Code Template for use with TI Code Composer Studio
;
;
;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Include device header file
            
;-------------------------------------------------------------------------------
            .def    RESET                   ; Export program entry-point to
                                            ; make it known to linker.
;-------------------------------------------------------------------------------
            .text                           ; Assemble into program memory.
            .retain                         ; Override ELF conditional linking
                                            ; and retain current section.
            .retainrefs                     ; And retain any sections that have
                                            ; references to current section.

;-------------------------------------------------------------------------------
RESET       mov.w   #__STACK_END,SP         ; Initialize stackpointer
StopWDT     mov.w   #WDTPW|WDTHOLD,&WDTCTL  ; Stop watchdog timer


;-------------------------------------------------------------------------------
; Main loop here
;-------------------------------------------------------------------------------
; Variable Initialization
;Mul Operand 1 .equ R4
;Mul Operand 2 .equ R5
;Mul Resultant LO 1 .equ R6
;Mul Resultant HI 2 .equ R7
BUTTON_LAP   .equ P1IN ; Assuming the lap button is connected to Port 1
LAP_TIME     .equ R10   ; Register to store lap time
DEBOUNCE     .equ 1    ; Adjust this value based on your needs
LAP_SAVED    .equ R11   ; Flag to indicate if lap time is saved
BUTTON_PRESSED .equ R12 ; Flag to track button presses
COUNT .equ R14
DIREC_COUNT .equ R15
PRD .equ 1250 ; Clk Flag inital
; debounce delay
REFRESH .equ 130 ; delay for refresh rate of seven seg display (62500 = 1s)
CERO .equ 00111111b
ONE .equ 00000110b
TWO .equ 01011011b
THREE .equ 01001111b
FOUR .equ 01100110b
FIVE .equ 01101101b
SIX .equ 01111101b
SEVEN .equ 00000111b
EIGHT .equ 01111111b
NINE .equ 01101111b
EMPTY .equ 00000000b

DISPLAY .macro cathode, sseg ;...
	.newblock
	CMP.B #cathode, &P3OUT ; TEST CATHODE 4
	JNZ $1
	MOV.B (SSEG+sseg), &P2OUT
	RETI
$1:
	.newblock
	.endm


	CLR &PM5CTL0

;-------------------------------------------------------------------------------
; LCD Setup
LCD_INIT:
	MOV   #(VLCD_8 | LCDCPEN | VLCDREF_0), LCDCVCTL
    MOV   #0xFFFF, LCDCPCTL0
    MOV   #0xFC3F, LCDCPCTL1
    MOV   #0x0FFF, LCDCPCTL2
    MOV   #LCDCPCLKSYNC, LCDCCPCTL
    MOV   #LCDCLRM, LCDCMEMCTL
    MOV   #0x041F, LCDCCTL0

;-------------------------------------------------------------------------------
; ADC Setup Subroutine
ADC_SETUP:
	; Configure P8.4 (A7) for ADC conversion
	MOV.B #0xFB, 	&P9DIR		;
	MOV.B #0x04, 	&P9SELC 	; Set P8.4 to ADC A7 mode (11b)

	; Configure ADC12CTLx Registers
	BIS	#1010b<<8,  &ADC12CTL0 ; sample hold time = 512 x MODOSC (4.8 MHz) ~=100 uS
	BIS	#ADC12MSC,	&ADC12CTL0 ; enable repeated conversion

	BIS	#11b<<13,	&ADC12CTL1 ; CLK predivider = x64 (SHT = 512 x 64 x MODOSC ~=6.8 mS)
	BIS #1<<9,		&ADC12CTL1 ; sample hold pulse mode = 1 (coversion start trigger = end of previous)
	BIS #10b<<1,	&ADC12CTL1 ; Conversion Sequence = 10b (repeat single channel mode(

	BIS #7,			&ADC12CTL3 ; Conversion Start Address = 7 (ADC12MEM7 used)

	; Configure ADC12MCTL7 Register
	BIS #10,		&ADC12MCTL7 ; set input channel select = A10

	; Start ADC12 Module
	BIS #ADC12ON,	&ADC12CTL0 ; turn module on
	BIS #ADC12ENC,	&ADC12CTL0 ; enable conversion
	BIS #ADC12SC,	&ADC12CTL0 ; start conversions

;-------------------------------------------------------------------------------
; IO Port Interrupt Setup Subroutine
	; Configure IO
	MOV.B #0x7F, 	&P4DIR 		; 0111 1111 - P4.7 = input
	BIS.B #1<<7, 	&P4REN		; 0100 0000 - P4.7 = Resistor Enable
	CLR.B &P4OUT 				; P4OUT initializes to random values, this clears it
	BIS.B #1<<7, 	&P4OUT 		; 1000 0000 - Enables P4.7 Pullup Resistor

	CLR &PM5CTL0				; Unlocks I/O pin from High Impedence State

	BIS.B #1<<1, 	&P4IES		; PORT4 Edge Select High to Low
	BIS.B #1<<1, 	&P4IE		; PORT4 Enables Interrupt
	CLR.B &P4IFG 				; Clears p4 Interrupt flags

	MOV.B #0xD7, 	&P1DIR 		; 1101 0111 - P1.3 & P1.5 = input
	BIS.B #0x28, 	&P1REN		; 0010 1000 - P1.3 & P1.5 = Resistor Enable
	CLR.B &P1OUT 				; P1OUT initializes to random values, this clears it
	BIS.B #0x28, 	&P1OUT 		; 0010 1000 - Enables P1.3 & P1.5 Pullup Resistor

	CLR &PM5CTL0				; Unlocks I/O pin from High Impedence State

	BIS.B #0x28, 	&P1IES		; PORT1 Edge Select High to Low
	BIS.B #0x28, 	&P1IE		; PORT1 Enables Interrupt
	CLR.B &P1IFG 				; Clears p1 Interrupt flags


	; initialize registers
	CLR COUNT

	; Enable GIE
	NOP
	EINT
	NOP



START:
    MOV #0, COUNT        ; Initialize counter to 0
    MOV #0, LAP_TIME     ; Initialize lap time to 0
    CLR LAP_SAVED        ; Clear the lap saved flag
    CLR BUTTON_PRESSED   ; Clear the button pressed flag
;-------------------------------------------------------------------------------
; Port1 ISR Subroutine


	JMP MAIN_LOOP


PORT1_ISR:                  ;subroutine for button 2 and button 3



;	Button 2 (P1.3) takes precedence over Button 3 (P1.5)
;	Interrupt Flag P1.3
	BIT.B #0x28,	&P1IFG
	MOV #0000, COUNT          ;executes button twos need
	BIC.B #0<<3, &P1IFG               ;clear button two
	JMP MAIN_LOOP               ;jumps back to main loop
	BIT.B #0x08,	&P1IFG

	JEQ MAIN_LOOP

;	Interrupt Flag P1.5
Button3:
	BIT.B #0x28,	&P1IFG
	MOV #0000, COUNT

;button two old interrupt
;S2_CLOSED:
	;BIC	#BIT1, FLAGS
	;MOV #0000, COUNT
	;RETI



MAIN_LOOP:
    ; Check for lap button press
    BIT #BIT2, BUTTON_LAP ;

    JMP NO_LAP_BUTTON_PRESS ; Jump if lap button is not pressed

    ; Lap button is pressed, debounce
    MOV #DEBOUNCE, R8 ; Counter for debounce

DEBOUNCE_LOOP_LAP:
    DEC R8
    JZ DEBOUNCE_DONE_LAP ; Jump out of debounce loop if counter reaches zero
    NOP                 ; Adjust NOPs based on your clock speed and debounce needs
    NOP
    JMP DEBOUNCE_LOOP_LAP

DEBOUNCE_DONE_LAP:
    ; Check the lap button again after debounce
    BIT #BIT2, BUTTON_LAP
    JZ NO_LAP_BUTTON_PRESS ; Jump if lap button is not pressed after debounce

    ; Lap button is pressed
    MOV BUTTON_PRESSED, R9
    JZ FIRST_PRESS ; Jump to FIRST_PRESS if the button was not pressed before

    ; Second button press, clear lap time
    CLR LAP_TIME
    CLR LAP_SAVED
    CLR BUTTON_PRESSED
    JMP MAIN_LOOP ; Jump back to the main loop

FIRST_PRESS:
    ; First button press, save the current count value as lap time
    MOV COUNT, LAP_TIME
    BIS.B #BIT0, LAP_SAVED ; Set the lap saved flag
    BIS.B #BIT0, BUTTON_PRESSED ; Set the button pressed flag

    JMP MAIN_LOOP ; Jump back to the main loop

NO_LAP_BUTTON_PRESS:
    ; Your main program logic goes here



	CLR &PM5CTL0 ; Clear LOCKLPM5 to turn off high impediance
    ; Increment or decrement the counter as needed
    ; Example increment:
    ADD DIREC_COUNT, COUNT

    ; Example decrement:
    ; DEC COUNT

    ; Your other program logic goes here

    JMP MAIN_LOOP ; Jump back to the main loop

NOP


	INC COUNT
	BIC #1<<1, &P1IFG ; reset interrupt flag

	RETI
;-------------------------------------------------------------------------------
; Port1 ISR Subroutine

PORT4_ISR:
	CALL FLIP_DIRECTION
	CLR.B &P4OUT
	RETI
;-------------------------------------------------------------------------------
; Multiply Subroutine
MUL:
	CLR R6
	CLR R7

	; To increase efficiency, ensure R4 < R5 (keep # of loops low)
	CMP R4, R5 ; R5 - R4
	JHS SKIP_FLIP
		; IF R4 > R5; Swap Registers, reduces number of loops
	PUSH R4
	MOV R5, R4
	POP R5

SKIP_FLIP:
	; lower boundary case - check if R4 == 0
	TST R4
	JN NEG_LOOP_MUL
	JZ SKIP ; skip loop if R4 == 0

POS_LOOP_MUL:
	ADD R5, R6
	ADC R7

	DEC R4
	JNZ POS_LOOP_MUL
	NOP
	RET;

NEG_LOOP_MUL:
	SUB R5, R6
	SBC R7

	INC R4
	JNZ NEG_LOOP_MUL
	NOP
	RET;

SKIP:
	NOP
	RET ; return from subroutine
;-------------------------------------------------------------------------------
; Counter Flip Subroutine
FLIP_DIRECTION:
;
	MOV #-1, R4
	MOV DIREC_COUNT, R5
	CALL #MUL
	MOV R6, DIREC_COUNT

;-------------------------------------------------------------------------------
; Onboard LCD Subroutine
DISPLAY_LCD:
	MOV #0x12, LCDM19	;Put letter "z" in A4
	MOV #0x08, LCDM20	;Put letter "z" in A4
	MOV #0x6F, LCDM4	;Put letter "H" in A3
;-------------------------------------------------------------------------------
; Stack Pointer definition
;-------------------------------------------------------------------------------
            .global __STACK_END
            .sect   .stack
            
;-------------------------------------------------------------------------------
; Interrupt Vectors
;-------------------------------------------------------------------------------
            .sect   ".reset"                ; MSP430 RESET Vector
            .short  RESET

           ; .sect	".int44"				;Timer0_A0 Interrupt Vector
           ; .short  TA0CCR0_ISR

          	.sect	".int37"				;Port1 Interrupt Vector
         	.short	PORT1_ISR

          	.sect	".int30"				;Port4 Interrupt Vector
         	.short	PORT4_ISR
