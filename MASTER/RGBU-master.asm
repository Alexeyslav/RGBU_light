.include "m8Adef.inc"
; Тактовая частота 14,745Мгц. 


; Константы
; Необходимый период отсчета таймера - 100/ 4800000 = 20.83мкс
; количество тактов при частоте 14,745Мгц для времени 20.83мкс = T / (1/F) = 20.83*14.745 = 307,13
; с предделителем = 2, необходимо 307/8 = 38 отсчета, погрешность 307,13/(38*8)-1 = +1% по частоте 
.EQU	timer_max_value =  38  ; (x8) Значение при котором происходит переполнение таймера
                               ; 38 - если используются модули с установленной частотой 4.8Мгц
							   ; 19 - если используются модули с установленной частотой 9.6Мгц

.equ	cmd_char		= 0x40  ; символ @ - команда "загрузить и передать". далее следует 6 байт данных
.equ	cmd_inp_ready   = 0x3F  ; символ ? - готовность к вводу данных
.equ	cmd_pulselen	= 0x2A  ; символ * - команда "установить ширину импульса". далее следует 1 байт данных
.equ	cmd_ADC			= 0x3D  ; символ = - команда "АЦП". далее следует 1 байт - номер канала АЦП.
.equ	cmd_test		= 0x54  ; символ T - команда "test" - проверка соединения, ответ должен быть cmd_Ok. 
.equ	cmd_Ok			= 0x2B  ; Ответ - команда выполнена
.equ	cmd_Fail		= 0x2D  ; Ответ - команда не определена


; Общие регистры.
.DEF ACCUM     = R25
.DEF ACCUM_INT = R1 ; сохраненка для прерывания
.DEF SREG_INT  = R2 ; сохраненка для прерывания

; Определения
#define cmd_port PINB3  ; номер порта через который получаются команды

#define MODULE_data0	SBI PORTD , PIND7
#define MODULE_data1	CBI PORTD , PIND7
#define ADC_run			SBI ADCSRA, ADSC

;Макросы
.macro reset_timer    ; Таймер считает от 0 до OCR2...
  LDI   ACCUM, 0x00   ; 1 такт
  OUT   TCNT2, ACCUM  ; 1 такт
.endmacro

.macro wait_timer
 BST	STA, timer_int
 BRTC	PC-0x0001            // На одну команду выше
 CLT
 BLD    STA, timer_int
.endmacro

.macro wait_adc
 SBIC	ADCSRA, ADSC
 RJMP	PC-0x0001
.endmacro

.include "..\common\RGBU-macros.inc"

; Регистровые переменные

.DEF tmp1 = R3
.DEF tmp2 = R16

.DEF STA  = R4
; битовая переменная.
; 0 - прерывание от таймера
.equ timer_int  = 0

.DEF pulse_w	= R5

; Счетчики в регистрах
.DEF cyclecount	= R17
.DEF tr_cnt		= R18
.DEF loopscount	= R19
.DEF send_byte_cnt = R20

; ======= Ячейки памяти  =========== RAM начинается с адреса 0x60-0x9F
; временные для приема
.EQU rcv_addr    = 0 + 0x60
.EQU rcv_cmd     = 1 + 0x60

; ======== Ячейки EEPROM ========
.EQU device_addr        = 0

; ТАБЛИЦА ВЕКТОРОВ ПРЕРЫВАНИЙ.
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
;                   Прерывание от таймера
;=====================================================
TMR2INT:
; сохранить регистр статуса
 IN		SREG_INT, SREG
; PUSH	ACCUM
;------- 

 set_bit STA, timer_int
 INC             cyclecount

;-------
; POP	ACCUM
; восстановить регистр статуса?
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

; установить порты ввода-вывода
;                 76543210
 set_io DDRB,   0b11111111; 1 - выход, 0 - вход.
 set_io DDRC,   0b00000000; 1 - выход, 0 - вход.
 set_io DDRD,   0b11111100; 1 - выход, 0 - вход. PD0, PD1 - USART

; настройка таймера
 set_io TCCR2,	0b00001010  ; режим таймера - CTC, работа таймера c прескалером = 8.
 set_io	OCR2,	timer_max_value ; Период прерываний таймера
 set_io TIMSK,  0b10000000  ; разрешаем прерывание от таймера(по сранению на OCR2).

; Настройка USART
; Тактовая частота 14,745Мгц. 
; Делитель USART:
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

; Настройка АЦП
 set_io ADMUX,  0b11000000 ; Опорное напряжение - внутренний, 2.56В
 set_io ADCSRA, 0b10000111 ; ADC Enable, single-conversion mode, Fadc = 14.745Мгц/128 = 115200


PRE_START:
 LDI	cyclecount, $00 
 set_reg pulse_w, 13
 
;------------------------------
; Собственно сам цикл программы
;------------------------------
START:

 sbis	UCSRA, RXC    ; Ждем пока не поступят данные
 rjmp	USART_not_Receive
// Есть данные от хоста!
 in		ACCUM, UDR ; Считываем данные с буффера

;------------------------------
 CPI	ACCUM, cmd_char
 BRNE	cmd_chk2
 // получена команда - загрузить и выполнить.
 LDI	R27, 0x00 ; X = 0x0060
 LDI	R26, 0x60 ; Адрес первой ячейки куда загрузить принятые данные. (X+0..X+5)

 LDI	ACCUM, cmd_inp_ready
 RCALL	USART_Transmit

 RCALL	USART_Receive ; Адрес подчиненного устройства
 ST		X+, ACCUM
 RCALL	USART_Receive ; Команда устройству
 ST		X+, ACCUM
 RCALL	USART_Receive ; Яркость красного
 ST		X+, ACCUM
 RCALL	USART_Receive ; Яркость зеленого
 ST		X+, ACCUM
 RCALL	USART_Receive ; Яркость синего
 ST		X+, ACCUM
 RCALL	USART_Receive ; Яркость фиолетового
 ST		X+, ACCUM

 LDI	R27, 0
 LDI	R26, 0x60 ; Адрес первой ячейки откуда передавать данные. (X+0..X+5)
 RCALL	MODULE_send

 LDI	ACCUM, 0x2B ; Символ "+" - передача произведена
 RCALL	USART_Transmit
 RJMP CMD_END

;------------------------------
cmd_chk2:
 CPI	ACCUM, cmd_pulselen
 BRNE	cmd_chk3
 // получена команда - загрузить значение величины импульса
 LDI	ACCUM, cmd_inp_ready
 RCALL	USART_Transmit

 RCALL	USART_Receive
 ANDI	ACCUM, 0x3F     ; Ограничим входной параметр значением 0-63(0,385..24,6мкс)
 INC	ACCUM
 MOV	pulse_w, ACCUM  ; константа? = 13(1..64) ,ширина импульса x0,385мкс 

 LDI	ACCUM, cmd_Ok   ; Символ "+" - установлено
 RCALL	USART_Transmit
 
 RJMP CMD_END

;------------------------------
cmd_chk3:
 CPI	ACCUM, cmd_ADC
 BRNE	cmd_chk4
 // получена команда - АЦП
 LDI	ACCUM, cmd_inp_ready
 RCALL	USART_Transmit // Готовность к вводу!

 RCALL	USART_Receive     ; считываем номер канала
 ANDI	ACCUM, 0x0F       ; Ограничим входной параметр значением 0-15
 ORI	ACCUM, 0b11000000
 OUT	ADMUX, ACCUM	  ; Выбор канала АЦП, опорное = встроен. 2.56В 
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
  // получена команда - TEST
  // Ответить Ok.
 LDI	ACCUM, cmd_Ok
 RCALL	USART_Transmit

 RJMP CMD_END
cmd_chk5:
// Проверка следующей команды?

cmd_not_impl:
 LDI	ACCUM, cmd_Fail ; Символ "-" - Команда не распознана
 RCALL	USART_Transmit

CMD_END:
USART_not_Receive:
// Здесь можно делать другие проверки....



RJMP START






; =========  ПОДПРОГРАММЫ  =================

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






; ================= Подпрограммы коммуникации с модулями ===================
 
MODULE_send_start:

 MODULE_data1

 reset_timer
// сбросить признак прерывания и признак прерывания от таймера
 clear_bit	STA	, timer_int 
 set_io		TIFR, 0b10000000 // сброс прерывания от таймера, 
                             // скорей всего оно будет установлено
							 // нам не надо чтобы таймер сработал 
							 // сразу же после разрешения прерываний
 SEI // Разрешаем прерывания
 
 wait_timer
 MODULE_data0
 wait_timer   // 4 периода - длительность интервала используется для настройки скорости приема на стороне приемника.
 wait_timer
 wait_timer
 wait_timer

ret



MODULE_send_byte:  ; На входе - ACCUM - данные для передачи
// Младшая тетрада вперед
 rCALL MODULE_send_half
// старшая тетрада
 rCALL MODULE_send_half
ret;

MODULE_send_half:
 MODULE_data1  // Стартовый импульс
 wait_timer

LDI tr_cnt, 0x04
sd_loop1h: 
 ROR ACCUM
 BRCC sd_data0    // Если перенос = 0, не передаем ничего
 MODULE_data1     // Если перенос = 1, передаем импульс
 RJMP	sd_do
sd_data0:
 MODULE_data0
sd_do:
 wait_timer
 DEC tr_cnt
 BRNE sd_loop1h

 MODULE_data0     // Два стоп-бита, для надежного зазора
 wait_timer 
 wait_timer 
ret







MODULE_send:  ; На входе регистр X - адрес ячейки памяти с которой начинается структура данных для передачи(X+0..X+5)

 LDI send_byte_cnt, 6 // Передаем 6 байт, начиная с адреса X
 CLR tmp1	 // Очистить контрольную сумму

 RCALL MODULE_send_start  // Подготовка, синхронизация и стартовый импульс

// передаем все байты по очереди
M_send_loop:
 LD		ACCUM, X+
 ADD	tmp1, ACCUM
 RCALL	MODULE_send_byte
 DEC	send_byte_cnt
 BRNE	M_send_loop

 COM	tmp1
 MOV	ACCUM, tmp1
 RCALL MODULE_send_byte	// передаем контрольную сумму

 CLI 					// Передача закончена, прерывания от таймера прекратить
ret
