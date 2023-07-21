.INCLUDE "M32DEF.INC"
.ORG 0
RJMP main

.ORG $200
.DB $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F

.ORG $002	; External Interupt 0 (INT0) / Increment time by 1
RJMP INCREMENT

.ORG $004	; External Interupt 1 (INT1) / Make light2 red
RJMP LIGHT1_SW

.ORG $006	; External Interupt 2 (INT2) / Make light1 red
RJMP LIGHT2_SW

.ORG $014	; Timer0 Compare Match Interupt
RJMP wait_1s

main:		; Configure Stack Pointer
			LDI R16, $00
			OUT SPL, R16
			LDI R16, $01
			OUT SPH, R16
			; Configure input and output ports
			CLR R31
			OUT SFIOR, R31
			LDI R31, $FF
			OUT DDRA, R31	; 7 Segments
			LDI R31, $FB
			OUT DDRB, R31	; LED outputs and INT2 input
			LDI R31, $04
			OUT PORTB, R31	; Enable INT2 pullup resistor
			LDI R31, $3F
			OUT DDRC, R31	; 7 Segments control and setting button
			LDI R31, $C0
			OUT PORTC, R31	; Enable pullup resistor
			LDI R31, $F3
			OUT DDRD, R31	; Setting LED and INT0/INT1 input
			LDI R31, $0C
			OUT PORTD, R31	; Enable INT0/INT1 pullup resistor
			; Enable timer0 and external interupts (int0, int1 and int2)
			SEI
			LDI R16, $0A
			OUT MCUCR, R16
			CLR R16
			OUT MCUCSR, R16
			LDI R16, $E0
			OUT GICR, R16
			LDI R16, $02
			OUT TIMSK, R16
			; Initial Setting Values
			LDI R16, 10	; Red light duration
			LDI R17, 2	; Yellow light duration
			MOV R21, R16; Red light time counter (Equals to Red light duration at the start)
			CLR R22		; Counter in timer0 interupt
			LDI R23, 1	; Turn - Light '1' is green at the start
			LDI R31, $1C; Make light 1 green and light 2 red
			OUT PORTB, R31
			RJMP rout2

rout1:		DEC R21		; Decrease timer by 1s
			CLR R26		; Flag - 1 second is passed since last time
			CP R21, R17	; Turn yellow light on when R17 seconds left
			BREQ YellowOn
rout2:		IN R26, PINC
			SBRC R26, 6 ; Is setting button enabled?
			RCALL SETTING
			CLR R27		; Clear setting flag
			CPI R21, -1	; Time to make green light, red; and red light, green
			BREQ Switch
			; Set 1 second timer
			LDI R31, $C3
			OUT OCR0, R31
			LDI R31, $0D
			OUT TCCR0, R31
			; 7segment stuff
			LDI R31, $04	; Setting the higher value bits of address
			; Get digits of timer (R21)
			MOV R24, R21	; Make a copy of R21 (Will be the right digit)
			CLR R25			; Left digit
SUB1:		CPI R24, 10
			BRLO CON1
			SUBI R24, 10
			INC R25
			RJMP SUB1
CON1:		MOV R30, R25
			LPM R28, Z
			MOV R30, R24
			LPM R27, Z

rout3:		; Show numbers on 7segments
			; Display light1-1 and light2-1
			CBI PORTC, 0
			SBI PORTC, 1
			CBI PORTC, 2
			SBI PORTC, 3
			SBI PORTC, 4
			SBI PORTC, 5
			OUT PORTA, R28
			RCALL WAIT_40ms
			; Display light1-2 and light2-2
			SBI PORTC, 0
			CBI PORTC, 1
			SBI PORTC, 2
			CBI PORTC, 3
			SBI PORTC, 4
			SBI PORTC, 5
			OUT PORTA, R27
			RCALL WAIT_40ms
			CPI R26, $FF; Flag - Is 1 second passed?
			BREQ rout1
			RJMP rout3	; Keep showing numbers on 7segments

YellowOn:	CPI R23, 1	; If light 1 is green
			BREQ YellowOn1	; Make light 1 yellow
			RJMP YellowOn2	; Make light 2 yellow

YellowOn1:	LDI R25, $16; Make light 1 yellow
			OUT PORTB, R25
			RJMP rout2	; Continue routine

YellowOn2:	LDI R25, $25; Make light 2 yellow
			OUT PORTB, R25
			RJMP rout2	; Continue routine

Switch:		MOV R21, R16
			CPI R23, 1
			BREQ Switch1
			RJMP Switch2

Switch1:	LDI R25, $45; Make light 1 red
			OUT PORTB, R25
			LDI R23, 2	; Light 2 is green now
			RJMP rout2	; Continue routine

Switch2:	LDI R25, $1C; Make light 2 red
			OUT PORTB, R25
			LDI R23, 1	; Light 1 is green now
			RJMP rout2	; Continue routine

wait_1s:	INC R22
			CPI R22, 5	; Repeated 5 times, so 1s passed
			BREQ passed_1s
			RETI

passed_1s:	CLR R22		; Reset timer0 counter
			CLR R25
			OUT TCCR0, R25 ; Cancel timer
			LDI R26, $FF ; ba R22 ham mishe va niaz be flage joda nist
			RETI

LIGHT1_SW:	CPI R23, 1
			BREQ SKIP1
			MOV R21, R17 ; Set the timer to yellow light time
			INC R21 ; rout1 code will decrease it by 1, so I increment it by 1 here
SKIP1:		RETI

LIGHT2_SW:	CPI R23, 2
			BREQ SKIP2
			MOV R21, R17 ; Set the timer to yellow light time
			INC R21 ; rout1 code will decrease it by 1, so I increment it by 1 here
SKIP2:		RETI

SETTING:	; Turn off LEDs and 7 Segments
			CBI PORTB, 0
			CBI PORTB, 1
			CBI PORTB, 3
			CBI PORTB, 4
			CBI PORTB, 5
			CBI PORTB, 6
			SBI PORTC, 0
			SBI PORTC, 1
			SBI PORTC, 2
			SBI PORTC, 3
			CLR R25
			OUT TCCR0, R25 ; Cancel light timer
			LDI R31, $04 ; For reading from memory
			LDI R27, 201 ; Flag - Increment red time when INT0 comes in
			SBI PORTD, 0 ; Turn setting's red led on
SETTING_RED:; Show red timer on display
			MOV R24, R16
			CLR R25
SUB2:		CPI R24, 10
			BRLO CON2
			SUBI R24, 10
			INC R25
			RJMP SUB2
CON2:		MOV R30, R25
			LPM R25, Z
			CBI PORTC, 4
			SBI PORTC, 5
			OUT PORTA, R25
			RCALL WAIT_40ms
			MOV R30, R24
			LPM R25, Z
			SBI PORTC, 4
			CBI PORTC, 5
			OUT PORTA, R25
			RCALL WAIT_40ms
			IN R26, PINC
			SBRS R26, 6 ; Skip if setting is still enabled
			RJMP RETURN
			RJMP SETTING_RED

RETURN:		CBI PORTD, 0
			LDI R23, 1	; Turn - Light '1' is green at the start
			LDI R31, $1C; Make light 1 green and light 2 red
			OUT PORTB, R31
			MOV R21, R16 ; Set the new timer
			RET

INCREMENT:	CPI R27, 201
			BREQ INC_RED
			RETI
INC_RED:	INC R16
			CPI R16, 61
			BRSH RED_OVF
			RETI

RED_OVF:	LDI R16, 10
			RETI

WAIT_40ms:	LDI R29, 40
			OUT OCR2, R29
			LDI R29, $0F
			OUT TCCR2, R29
rr:			IN R29, TIFR
			SBRS R29, 7 ; Skip next line if flag bit is one
			RJMP rr ; Keep waiting
			LDI R29, $80
			OUT TIFR, R29 ; Reset timer flag
			CLR R29
			OUT TCCR2, R29 ; Cancel timer
			RET