
; Created: 6/10/2019 10:55:08 PM

.def empty				= R0
.def pincval			= R1
.def portcval			= R2
.def digit_first		= R3
.def digit_second		= R4
.def opstorage			= R5
.def decval				= R6
.def ascval				= R7
.def comdigit_second	= R8
.def temp				= R16
.def check				= R17
.def comdigit_first		= R18
.def keypad				= R19
.def counter			= R20
.def maximum			= R21
.def lcdstorage			= R22

reset:
   rjmp Start
   reti      ; Addr $01
   reti      ; Addr $02
   reti      ; Addr $03
   reti      ; Addr $04
   reti      ; Addr $05
   reti      ; Addr $06        Use 'rjmp myVector'
   reti      ; Addr $07        to define a interrupt vector
   reti      ; Addr $08
   reti      ; Addr $09
   reti      ; Addr $0A
   reti      ; Addr $0B        This is just an example
   reti      ; Addr $0C        Not all MCUs have the same
   reti      ; Addr $0D        number of interrupt vectors
   reti      ; Addr $0E
   reti      ; Addr $0F
   reti      ; Addr $10

;***********************************************************

Start:
	;init stack pointer
	LDI	TEMP,  HIGH(RAMEND)
	OUT	SPH, TEMP
	LDI	TEMP,  LOW(RAMEND)
	OUT	SPL, TEMP

	CALL	Init_UART
	CALL	Init              	;Initialise the system.

Main:
		;read for first digit
		CALL ReadKP_outer
		MOV lcdstorage, keypad
		CALL Send_UART
		CALL LongDelay
		CALL ConvToDec
		PUSH decval
		CALL Errorcheck

		;read for second digit
		CALL ReadKP_outer
		MOV lcdstorage, keypad
		CALL Send_UART
		CALL LongDelay
		CALL ConvToDec
		PUSH decval
		CALL Errorcheck

		;combine first two digits
		POP digit_second
		POP digit_first
		CALL Combine
		PUSH digit_first ; store the first combined digit

		;clear some registers to be reused
		CLR digit_first
		CLR digit_second

		;read for third digit
		CALL ReadKP_outer
		MOV lcdstorage, keypad
		CALL Send_UART
		CALL LongDelay
		CALL ConvToDec
		PUSH decval
		CALL Errorcheck

		;read for fourth digit
		CALL ReadKP_outer
		MOV lcdstorage, keypad
		CALL Send_UART
		CALL LongDelay
		CALL ConvToDec
		PUSH decval
		CALL Errorcheck

		;combine last two digits
		POP digit_second
		POP digit_first
		CALL Combine
		PUSH digit_first ; store the first combined digit
		;now the stack should have both of the combined digits!

		POP comdigit_second ; take the newest value and store it to this register
		POP comdigit_first	; take the previous value and store it to this register
		;stack should be empty now

		;read for fifth digit
		CALL ReadKP_outer
		MOV lcdstorage, keypad
		CALL Send_UART
		CALL LongDelay
		CPI keypad, 0x2A ; if asterisk is pressed
		BREQ Increase
		CPI keypad, 0x23 ; if hash is pressed
		BREQ Decrease
		CPI keypad, 0x2A ; if anything else is pressed
		BRNE Go_Err

Increase:
	;read for sixth digit
	CLR keypad
	CALL ReadKP_outer
	MOV lcdstorage, keypad
	CALL Send_UART
	CALL LongDelay
	CPI keypad, 0x2A ; if asterisk is pressed
	BREQ Go_Add
	CPI keypad, 0x23 ; if hash is pressed
	BREQ Go_Mult
	CPI keypad, 0x2A ; if anything else is pressed
	BRNE Go_Err

Decrease:
	;read for sixth digit
	CALL ReadKP_outer
	MOV lcdstorage, keypad
	CALL Send_UART
	CALL LongDelay
	CPI keypad, 0x23 ; if hash is pressed
	BREQ Go_Sub
	CPI keypad, 0x2A ; if asterisk is pressed
	BREQ Go_Div
	CPI keypad, 0x2A ; if anything else is pressed
	BRNE Go_Err
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;FUNCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Go_Add:
	JMP Addition

Go_Sub:
	JMP Subtraction

Go_Mult:
	JMP Multiplication

Go_Div:
	JMP Division

Go_Err:
	JMP Error

Init_UART:
	;set baud rate
	CLR temp
	LDI temp, 0x4D

	OUT UBRRH, empty
	OUT UBRRL, temp

	;set UCSR registers
	CLR temp
	LDI temp, (1<<URSEL)|(0<<USBS)|(1 << UCSZ0)|(1 << UCSZ1) ;0x86
	OUT UCSRC, temp

	CLR temp
	LDI temp, (1<<RXEN)|(1<<TXEN) ;0x18
	OUT UCSRB, temp
	CLR temp
	RET

Send_UART:
	;check if UDRE is set or not
	SBIS UCSRA, UDRE
	RJMP Send_UART
	;if set (1), do this
	OUT UDR, lcdstorage
	RET

Init:
	CLR digit_first
	CLR digit_second
	CLR comdigit_first
	CLR comdigit_second
	CLR empty		
	CLR temp
	CLR counter
	CLR maximum
	CLR keypad
	CLR decval
	CLR ascval
	CLR lcdstorage

	LDI maximum, 0x63		; this is 99, which is the max keypad value
	LDI temp, 0xFF
	OUT DDRB, temp			; initialize DDRB
	LDI temp, 0x15
	OUT DDRC, temp			; initialize DDRC
	LDI temp, 0xEA
	OUT PORTC, temp			; initialize PORTC

	LDI lcdstorage, 0x0C	; clear LCD
	CALL Send_UART
	CALL LongDelay

	LDI lcdstorage, 0x80	; cursor on start
	CALL Send_UART
	CALL LongDelay
	
	OUT PORTB, empty
	CALL LongDelay
	RET

ReadKP_outer:
			CLR check
			CLR keypad
			JMP While
Content:	LDI temp, 0xFB ; column 1
			OUT PORTC, temp
			CALL Delay
			CLR pincval
			CLR portcval
			IN pincval, PINC
			IN portcval, PORTC
			CP pincval, portcval
			BRNE ReadKP_inner

			LDI temp, 0xFE ; column 2
			OUT PORTC, temp
			CALL Delay
			CLR pincval
			CLR portcval
			IN pincval, PINC
			IN portcval, PORTC
			CP pincval, portcval
			BRNE ReadKP_inner

			LDI temp, 0xEF ; column 3
			OUT PORTC, temp
			CALL Delay
			CLR pincval
			CLR portcval
			IN pincval, PINC
			IN portcval, PORTC
			CP pincval, portcval
			BRNE ReadKP_inner
			JMP While				; jump back to while to see if the condition is true or false

While:
	CPI check, 0x00
	BREQ Content			
	RET

ReadKP_inner:
	LDI ZH, high(Table<<1)
	LDI ZL, low(Table<<1)
	ADD ZL, pincval
	CLR empty
	ADC ZH, empty
	LPM keypad, Z
	LDI check, 0x01
	JMP While

ConvToDec:
	CLR decval
	LDI ZH, high(DecTable<<1)
	LDI ZL, low(DecTable<<1)
	ADD ZL, keypad
	CLR empty
	ADC ZH, empty
	LPM decval, Z
	RET

Combine:
	CALL Mult_ten
	ADD digit_first, digit_second
	RET

Mult_ten:						; multiply by 10
		CLR counter
		CLR opstorage
		MOV opstorage, digit_first
Mult:	INC counter
		ADD digit_first, opstorage
		CPI counter, 0x09
		BRNE Mult
		RET

Addition:
	CLR counter
	ADD comdigit_first, comdigit_second
	CALL Result

Subtraction:
	CLR counter
	SUB comdigit_first, comdigit_second
	CPI comdigit_first, 0x00 ; check if lower than 0
	BRLT Go_Neg
	CALL Result

Multiplication:
	CLR counter
	CLR opstorage
	MOV opstorage, comdigit_first
	INC counter
M:	ADD comdigit_first, opstorage
	BRCS Go_Exceed	; if carry is set, it means value exceeds 255
	INC counter
	CP counter, comdigit_second
	BRNE M
	CALL Result

Division:
		CLR counter
D1:		SUB comdigit_first, comdigit_second
		CPI comdigit_first, 0x00 ; check if lower than 0
		BRLT zero
		INC counter
		CP comdigit_first, comdigit_second
		BRLO D2
		RJMP D1
D2:		MOV comdigit_first, counter
		CALL Result
zero:	CLR comdigit_first
		CALL Result

Go_Exceed:
	JMP Exceed

Go_Neg:
	JMP Negative

Result:
		CPI comdigit_first, 0x0A	; less than 10
		BRLO Onedig					; means 1 digit
		CPI comdigit_first, 0x64	; less than 100
		BRLO Twodig					; means 2 digit
		CPI comdigit_first, 0xFF	; less than 255
		BRLO Threedig				; means 3 digit
		JMP Error					; else, error

Onedig:							; if result only 1 digit
		CLR temp
		PUSH comdigit_first
		CALL LongDelay
		LDI lcdstorage, 0x3D	; display =
		CALL Send_UART
		POP temp
		CALL ConvToAsc
		MOV lcdstorage, ascval	; display the first result digit
		CALL Send_UART
		JMP Restart		

Twodig:							; if result is two digits
		CLR temp
		CLR counter					
loop:	SUBI comdigit_first, 0x0A	; simulate divide by 10
		INC counter					; store division result
		CPI comdigit_first, 0x0A	; see if it is lower than 10 yet
		BRLO next					; if it is, go to next step
		RJMP loop					; else, do the subtraction again
next:	PUSH comdigit_first			; store the remainder into the stack (this will be third digit)
		PUSH counter				; store the second digit into the stack
		CALL LongDelay
		LDI lcdstorage, 0x3D	; display =
		CALL Send_UART
		POP temp
		CALL ConvToAsc
		MOV lcdstorage, ascval	; display the first result digit
		CALL Send_UART
		POP temp
		CALL ConvToAsc
		MOV lcdstorage, ascval	; display the second result digit
		CALL Send_UART
		JMP Restart

Threedig:							; if result is three digits
		CLR temp
		CLR counter
loop1:	SUBI comdigit_first, 0x0A	; simulate divide by 10
		INC counter					; store the division result
		CPI comdigit_first, 0x0A	; see if it is lower than 10 yet
		BRLO next1					; if it is, go to next step
		RJMP loop1					; else, do the subtraction again
next1:	PUSH comdigit_first			; store the remainder into the stack (this will be third digit)
		MOV comdigit_first, counter	; move the amount of subtraction that happened (which is division result) to corresponding register
		CLR counter					; so counter can be reused
loop2:	SUBI comdigit_first, 0x0A	; simulate divide by 10
		INC counter					; store division result
		CPI comdigit_first, 0x0A	; see if it is lower than 10 yet
		BRLO next2					; if it is, go to next step
		RJMP loop2					; else, do the subtraction again
next2:	PUSH comdigit_first			; store the second remainder into the stack (this will be second digit)
		PUSH counter				; store the first digit into the stack
		CALL LongDelay
		LDI lcdstorage, 0x3D	; display =
		CALL Send_UART
		POP temp
		CALL ConvToAsc
		MOV lcdstorage, ascval	; display the first result digit
		CALL Send_UART
		POP temp
		CALL ConvToAsc
		MOV lcdstorage, ascval	; display the second result digit
		CALL Send_UART
		POP temp
		CALL ConvToAsc
		MOV lcdstorage, ascval	; display the second result digit
		CALL Send_UART
		JMP Restart

ConvToAsc:
	CLR ascval
	LDI ZH, high(AscTable<<1)
	LDI ZL, low(AscTable<<1)
	ADD ZL, temp
	CLR empty
	ADC ZH, empty
	LPM ascval, Z
	RET

Errorcheck:
	CP maximum, decval ;if greater than 99
	BRLO Error
	RET

Error:
	LDI lcdstorage, 0x21	; display exclamation mark
	CALL Send_UART
	LDI lcdstorage, 0x45	; display E
	CALL Send_UART
	LDI lcdstorage, 0x52	; display R
	CALL Send_UART
	LDI lcdstorage, 0x52	; display R
	CALL Send_UART
	LDI lcdstorage, 0x4F	; display O
	CALL Send_UART
	LDI lcdstorage, 0x52	; display R
	CALL Send_UART
	LDI lcdstorage, 0x21	; display exclamation mark
	CALL Send_UART
	RJMP Restart

Negative:
	LDI lcdstorage, 0x21	; display exclamation mark
	CALL Send_UART
	LDI lcdstorage, 0x4E	; display N
	CALL Send_UART
	LDI lcdstorage, 0x45	; display E
	CALL Send_UART
	LDI lcdstorage, 0x47	; display G
	CALL Send_UART
	LDI lcdstorage, 0x21	; display exclamation mark
	CALL Send_UART
	RJMP Restart

Exceed:
	LDI lcdstorage, 0x3D	; display =
	CALL Send_UART
	LDI lcdstorage, 0x32	; display 2
	CALL Send_UART
	LDI lcdstorage, 0x35	; display 5
	CALL Send_UART
	LDI lcdstorage, 0x35	; display 5
	CALL Send_UART
	LDI lcdstorage, 0x2B	; display +
	CALL Send_UART
	RJMP Restart
	

Restart:
	CLR keypad
	CALL ReadKP_outer
	CPI keypad, 0x23
	BREQ Go_Start
	RJMP Restart

Go_Start:
	JMP Start

Delay:							; 256*256*L1 cycle, so around 262144 cycles /  20 ms.
         PUSH temp				; save R16 and 17 as we're going to use them
         PUSH counter			; as loop counters
         PUSH empty				; we'll also use R0 as a zero value
         CLR empty
         CLR temp				; init inner counter
         CLR counter				; and outer counter
L1:      DEC temp				; counts down from 0 to FF to 0
		 CPSE temp, empty		; equal to zero?
		 RJMP L1				; if not, do it again
		 CLR temp				; reinit inner counter
L2:      DEC counter
         CPSE counter, empty	; is it zero yet?
         RJMP L1				; back to inner counter
         POP empty				; done, clean up and return
         POP counter
         POP temp
         RET

LongDelay:							; should be around 200 ms, so 10 times normal delay.
		CLR counter
		CLR empty
		LDI counter, 0x0B			; this is 11
LD1:	DEC counter
		CALL Delay
		CPSE counter, empty
		RJMP LD1
		RET
		
Table:
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 0 - 15
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 16 - 31
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 32 - 47
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 48 - 63
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 64 - 79
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 80 - 95
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 96 - 111
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 112 - 127
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 128 - 143
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63		; 144 - 159
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 54		; 160 - 175
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 52, 63, 63, 53, 63		; 176 - 191
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 57		; 192 - 207
	.DB		63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 55, 63, 63, 56, 63		; 208 - 223
	.DB		63, 63, 63, 63, 63, 63, 63, 35, 63, 63, 63, 63, 63, 51, 63, 63		; 224 - 239
	.DB		63, 63, 63, 42, 63, 63, 48, 63, 63, 49, 63, 63, 50, 63, 63, 63 		; 240 - 255

DecTable:
	.DB		100, 100, 100, 100, 100, 100, 100, 100		; 0 - 7
	.DB		100, 100, 100, 100, 100, 100, 100, 100		; 8 - 15
	.DB		100, 100, 100, 100, 100, 100, 100, 100		; 16 - 23
	.DB		100, 100, 100, 100, 100, 100, 100, 100		; 24 - 31
	.DB		100, 100, 100, 100, 100, 100, 100, 100		; 32 - 39
	.DB		100, 100, 100, 100, 100, 100, 100, 100		; 40 - 47
	.DB		0, 1, 2, 3, 4, 5, 6, 7						; 48 - 55
	.DB		8, 9, 100, 100, 100, 100, 100, 100			; 56 - 63

AscTable:
	.DB		48, 49, 50, 51, 52, 53, 54, 55, 56, 57		; 0 - 9





