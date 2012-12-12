.include "m8Adef.inc"
; �������� ������� 14,745���. 


; ���������
; ����������� ������ ������� ������� - 100/ 4800000 = 20.83���
; ���������� ������ ��� ������� 14,745��� ��� ������� 20.83��� = T / (1/F) = 20.83*14.745 = 307,13
; � ������������� = 2, ���������� 307/8 = 38 �������, ����������� 307,13/(38*8)-1 = +1% �� ������� 
.EQU	timer_max_value =  38  ; (x8) �������� ��� ������� ���������� ������������ �������
                               ; 38 - ���� ������������ ������ � ������������� �������� 4.8���
							   ; 19 - ���� ������������ ������ � ������������� �������� 9.6���

.equ	cmd_char		= 0x40  ; ������ @ - ������� "��������� � ��������". ����� ������� 6 ���� ������
.equ	cmd_inp_ready   = 0x3F  ; ������ ? - ���������� � ����� ������
.equ	cmd_pulselen	= 0x2A  ; ������ * - ������� "���������� ������ ��������". ����� ������� 1 ���� ������
.equ	cmd_ADC			= 0x3D  ; ������ = - ������� "���". ����� ������� 1 ���� - ����� ������ ���.
.equ	cmd_test		= 0x54  ; ������ T - ������� "test" - �������� ����������, ����� ������ ���� cmd_Ok. 
.equ	cmd_Ok			= 0x2B  ; ����� - ������� ���������
.equ	cmd_Fail		= 0x2D  ; ����� - ������� �� ����������


; ����� ��������.
.DEF ACCUM     = R25
.DEF ACCUM_INT = R1 ; ���������� ��� ����������
.DEF SREG_INT  = R2 ; ���������� ��� ����������

; �����������
#define cmd_port PINB3  ; ����� ����� ����� ������� ���������� �������

#define MODULE_data0	SBI PORTD , PIND7
#define MODULE_data1	CBI PORTD , PIND7
#define ADC_run			SBI ADCSRA, ADSC

;�������
.macro reset_timer    ; ������ ������� �� 0 �� OCR2...
  LDI   ACCUM, 0x00   ; 1 ����
  OUT   TCNT2, ACCUM  ; 1 ����
.endmacro

.macro wait_timer
 BST	STA, timer_int
 BRTC	PC-0x0001            // �� ���� ������� ����
 CLT
 BLD    STA, timer_int
.endmacro

.macro wait_adc
 SBIC	ADCSRA, ADSC
 RJMP	PC-0x0001
.endmacro

.include "..\common\RGBU-macros.inc"

; ����������� ����������

.DEF tmp1 = R3
.DEF tmp2 = R16

.DEF STA  = R4
; ������� ����������.
; 0 - ���������� �� �������
.equ timer_int  = 0

.DEF pulse_w	= R5

; �������� � ���������
.DEF cyclecount	= R17
.DEF tr_cnt		= R18
.DEF loopscount	= R19
.DEF send_byte_cnt = R20

; ======= ������ ������  =========== RAM ���������� � ������ 0x60-0x9F
; ��������� ��� ������
.EQU rcv_addr    = 0 + 0x60
.EQU rcv_cmd     = 1 + 0x60

; ======== ������ EEPROM ========
.EQU device_addr        = 0

; ������� �������� ����������.
.CSEG
.ORG 0

rjmp RESET 		; Reset Handler
 RETI			; IRQ0 Handler
 RETI			; IRQ1 Handler
rjmp TMR2INT	; Timer2 Compare Handler
 RETI 			; Timer2 Overflow Handler
 RETI			; Timer1 Capture Handler
 RETI 			; Timer1 CompareA Handler
 RETI 			; Timer1 CompareB Handler
 RETI 			; Timer1 Overflow Handler
 RETI 			; Timer0 Overflow Handler
 RETI 			; SPI Transfer Complete Handler
 RETI 			; USART RX Complete Handler
 RETI 			; UDR Empty Handler
 RETI 			; USART TX Complete Handler
 RETI 			; ADC Conversion Complete Handler
 RETI 			; EEPROM Ready Handler
 RETI 			; Analog Comparator Handler
 RETI 			; Two-wire Serial Interface Handler
 RETI 			; Store Program Memory Ready Handler

;=====================================================
;                   ���������� �� �������
;=====================================================
TMR2INT:
; ��������� ������� �������
 IN		SREG_INT, SREG
; PUSH	ACCUM
;------- 

 set_bit STA, timer_int
 INC             cyclecount

;-------
; POP	ACCUM
; ������������ ������� �������?
 OUT	SREG, SREG_INT
RETI


;=====================================================
;                PROGRAM BEGIN THERE!!!
;=====================================================
RESET:
; Set Stack Pointer to top of RAM
ldi r16,high(RAMEND)
out SPH,r16 
ldi r16,low(RAMEND)
out SPL,r16

; ���������� ����� �����-������
;                 76543210
 set_io DDRB,   0b11111111; 1 - �����, 0 - ����.
 set_io DDRC,   0b00000000; 1 - �����, 0 - ����.
 set_io DDRD,   0b11111100; 1 - �����, 0 - ����. PD0, PD1 - USART

; ��������� �������
 set_io TCCR2,	0b00001010  ; ����� ������� - CTC, ������ ������� c ����������� = 8.
 set_io	OCR2,	timer_max_value ; ������ ���������� �������
 set_io TIMSK,  0b10000000  ; ��������� ���������� �� �������(�� �������� �� OCR2).

; ��������� USART
; �������� ������� 14,745���. 
; �������� USART:
; 7 = 115200 
; 11 = 76800
; 15 = 57600
; 23 = 38400
; 31 = 28800
; 47 = 19200

 set_io	UBRRH,	0
 set_io	UBRRL,	7	  					; Set baud rate = 115200
 set_io	UCSRB,	(1<<RXEN)|(1<<TXEN)		; Enable receiver and transmitter
 set_io	UCSRC,	(1<<URSEL)|(3<<UCSZ0)	; Set frame format: 8data, 1stop bit

; ��������� ���
 set_io ADMUX,  0b11000000 ; ������� ���������� - ����������, 2.56�
 set_io ADCSRA, 0b10000111 ; ADC Enable, single-conversion mode, Fadc = 14.745���/128 = 115200


PRE_START:
 LDI	cyclecount, $00 
 set_reg pulse_w, 13
 
;------------------------------
; ���������� ��� ���� ���������
;------------------------------
START:

 sbis	UCSRA, RXC    ; ���� ���� �� �������� ������
 rjmp	USART_not_Receive
// ���� ������ �� �����!
 in		ACCUM, UDR ; ��������� ������ � �������

;------------------------------
 CPI	ACCUM, cmd_char
 BRNE	cmd_chk2
 // �������� ������� - ��������� � ���������.
 LDI	R27, 0x00 ; X = 0x0060
 LDI	R26, 0x60 ; ����� ������ ������ ���� ��������� �������� ������. (X+0..X+5)

 LDI	ACCUM, cmd_inp_ready
 RCALL	USART_Transmit

 RCALL	USART_Receive ; ����� ������������ ����������
 ST		X+, ACCUM
 RCALL	USART_Receive ; ������� ����������
 ST		X+, ACCUM
 RCALL	USART_Receive ; ������� ��������
 ST		X+, ACCUM
 RCALL	USART_Receive ; ������� ��������
 ST		X+, ACCUM
 RCALL	USART_Receive ; ������� ������
 ST		X+, ACCUM
 RCALL	USART_Receive ; ������� �����������
 ST		X+, ACCUM

 LDI	R27, 0
 LDI	R26, 0x60 ; ����� ������ ������ ������ ���������� ������. (X+0..X+5)
 RCALL	MODULE_send

 LDI	ACCUM, 0x2B ; ������ "+" - �������� �����������
 RCALL	USART_Transmit
 RJMP CMD_END

;------------------------------
cmd_chk2:
 CPI	ACCUM, cmd_pulselen
 BRNE	cmd_chk3
 // �������� ������� - ��������� �������� �������� ��������
 LDI	ACCUM, cmd_inp_ready
 RCALL	USART_Transmit

 RCALL	USART_Receive
 ANDI	ACCUM, 0x3F     ; ��������� ������� �������� ��������� 0-63(0,385..24,6���)
 INC	ACCUM
 MOV	pulse_w, ACCUM  ; ���������? = 13(1..64) ,������ �������� x0,385��� 

 LDI	ACCUM, cmd_Ok   ; ������ "+" - �����������
 RCALL	USART_Transmit
 
 RJMP CMD_END

;------------------------------
cmd_chk3:
 CPI	ACCUM, cmd_ADC
 BRNE	cmd_chk4
 // �������� ������� - ���
 LDI	ACCUM, cmd_inp_ready
 RCALL	USART_Transmit // ���������� � �����!

 RCALL	USART_Receive     ; ��������� ����� ������
 ANDI	ACCUM, 0x0F       ; ��������� ������� �������� ��������� 0-15
 ORI	ACCUM, 0b11000000
 OUT	ADMUX, ACCUM	  ; ����� ������ ���, ������� = �������. 2.56� 
 ADC_run
 wait_adc
 IN		ACCUM, ADCL
 RCALL	USART_Transmit
 IN		ACCUM, ADCH
 RCALL	USART_Transmit
 RJMP CMD_END

;------------------------------
cmd_chk4:
 CPI	ACCUM, cmd_test
 BRNE	cmd_chk5
  // �������� ������� - TEST
  // �������� Ok.
 LDI	ACCUM, cmd_Ok
 RCALL	USART_Transmit

 RJMP CMD_END
cmd_chk5:
// �������� ��������� �������?

cmd_not_impl:
 LDI	ACCUM, cmd_Fail ; ������ "-" - ������� �� ����������
 RCALL	USART_Transmit

CMD_END:
USART_not_Receive:
// ����� ����� ������ ������ ��������....



RJMP START






; =========  ������������  =================

USART_Transmit:
; Wait for empty transmit buffer
sbis UCSRA,UDRE
rjmp USART_Transmit
; Put data into buffer, sends the data
out UDR, ACCUM
ret

USART_Receive:
; Wait for data to be received
sbis UCSRA, RXC
rjmp USART_Receive
; Get and return received data from buffer
in ACCUM, UDR
ret






; ================= ������������ ������������ � �������� ===================
 
MODULE_send_start:

 MODULE_data1

 reset_timer
// �������� ������� ���������� � ������� ���������� �� �������
 clear_bit	STA	, timer_int 
 set_io		TIFR, 0b10000000 // ����� ���������� �� �������, 
                             // ������ ����� ��� ����� �����������
							 // ��� �� ���� ����� ������ �������� 
							 // ����� �� ����� ���������� ����������
 SEI // ��������� ����������
 
 wait_timer
 MODULE_data0
 wait_timer   // 4 ������� - ������������ ��������� ������������ ��� ��������� �������� ������ �� ������� ���������.
 wait_timer
 wait_timer
 wait_timer

ret



MODULE_send_byte:  ; �� ����� - ACCUM - ������ ��� ��������
// ������� ������� ������
 rCALL MODULE_send_half
// ������� �������
 rCALL MODULE_send_half
ret;

MODULE_send_half:
 MODULE_data1  // ��������� �������
 wait_timer

LDI tr_cnt, 0x04
sd_loop1h: 
 ROR ACCUM
 BRCC sd_data0    // ���� ������� = 0, �� �������� ������
 MODULE_data1     // ���� ������� = 1, �������� �������
 RJMP	sd_do
sd_data0:
 MODULE_data0
sd_do:
 wait_timer
 DEC tr_cnt
 BRNE sd_loop1h

 MODULE_data0     // ��� ����-����, ��� ��������� ������
 wait_timer 
 wait_timer 
ret







MODULE_send:  ; �� ����� ������� X - ����� ������ ������ � ������� ���������� ��������� ������ ��� ��������(X+0..X+5)

 LDI send_byte_cnt, 6 // �������� 6 ����, ������� � ������ X
 CLR tmp1	 // �������� ����������� �����

 RCALL MODULE_send_start  // ����������, ������������� � ��������� �������

// �������� ��� ����� �� �������
M_send_loop:
 LD		ACCUM, X+
 ADD	tmp1, ACCUM
 RCALL	MODULE_send_byte
 DEC	send_byte_cnt
 BRNE	M_send_loop

 COM	tmp1
 MOV	ACCUM, tmp1
 RCALL MODULE_send_byte	// �������� ����������� �����

 CLI 					// �������� ���������, ���������� �� ������� ����������
ret
