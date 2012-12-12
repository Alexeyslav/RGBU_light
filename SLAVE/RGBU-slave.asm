.include "tn13Adef.inc"
; Предполагаемая тактовая частота - 4.8Мгц(можно еще 9.6Мгц)
; Fuses - CKSEL0=1, CKSEL1=0, SUT0=0, SUT1=1, CKDIV8=1, WDTON=1, 
;         EESAVE=1, RSTDISBL=1, BODLEVEL0=1, BODLEVEL1=1, SPMEN=1
; 0 - programmed, 1 - unprogrammed.

; Константы
.EQU timer_max_value  = 100 ; Значение при котором происходит переполнение таймера(=100, 95 - скорректированное значение)
.EQU st_syn_delay     = 3*timer_max_value/5  ; максимальная длительность стартового импульса, = 3 кванта.
.EQU sync_pause_delay = 8  ; Константа величина необходимой паузы в передаче в квантах.
.EQU st_pause_delay   = 6*timer_max_value/5   // максимальная длительность стартовой паузы = 6 квант.
                         // Это значение не трогать! 
						 // От него зависит индекс таблицы корректирующих коэфициентов!
; Общие регистры.
.DEF ACCUM     = R25
//.DEF ACCUM_INT = R7	; для прерывания TIMER_INT
.DEF SREG_INT	= R8	; для прерывания TIMER_INT
.DEF SREG_CHG	= R9	; для прерывания CHG
.DEF ACCUM_CHG	= R7	; для прерывания CHG

;#define DBG true

; Определения
#define cmd_port PINB3  ; номер порта через который получаются команды

#define led_r_on  SBI PORTB, PINB2
#define led_r_off CBI PORTB, PINB2

#define led_g_on  SBI PORTB, PINB1
#define led_g_off CBI PORTB, PINB1

#define led_b_on  SBI PORTB, PINB0
#define led_b_off CBI PORTB, PINB0

#define led_u_on  SBI PORTB, PINB4
#define led_u_off CBI PORTB, PINB4

#define enable_change_int  set_io GIMSK,  0b00100000  ; Разрешить прерывание по изменению уровня на PB3
#define disable_change_int set_io GIMSK,  0b00000000  ; Разрешить прерывание по изменению уровня на PB3

#define reset_timeout      clr    loopscount

;Макросы
.include "..\common\RGBU-macros.inc"
.macro reset_timer    ; Таймер считает от 0 до OCR0A...
  LDI   ACCUM, 0x00   ; 1 такт
  OUT   TCNT0, ACCUM  ; 1 такт
.endmacro

.macro if_no_timerint      ; Если не было прерывания от таймера - переход на метку,
  test_bit STA, timer_int  ; Если есть прерывание - сбрасываем признак и продолжаем дальше
  BRTC   @0                ; чтобы зациклить ожидание в качестве метки указать "PC-1"
  clear_bit STA, timer_int
.endmacro

; Регистровые переменные

.DEF LEDrV = R1    ; Яркость по каждому каналу
.DEF LEDgV = R2
.DEF LEDbV = R3
.DEF LEDuV = R4
.DEF rcv        = R10
.DEF tmp1       = R11

.DEF STA   = R13
; битовая переменная.
; 0 - изменение в порту, хостом была передана 1.
.equ port_value = 0
; 1 - прерывание от таймера
.equ timer_int  = 1
; 2 - Окончание цикла
.equ Cycle_end  = 2    ; цикл = 256 прерываний таймера, 1 прерывание таймера = Fosc/100 = 48K
; 3 - Признак начала передачи пакета
.equ rcv_start  = 3
; 4 - Признак ошибки приема
.equ rcv_err    = 4
; 5 - Признак начала передачи
.equ first_receive = 5





; Счетчики в регистрах
.DEF cyclecount = R16
.DEF rcv_cnt    = R17
.DEF loopscount = R18
.DEF tmp2       = R19 ; с возможностью непосредственной загрузки значения через LDI
.DEF timeout    = R20
.DEF loopscount2= R21







; ======= Ячейки памяти  =========== RAM начинается с адреса 0x60-0x9F
; временные для приема
.EQU rcv_addr    = 0 + 0x60
.EQU rcv_cmd     = 1 + 0x60
.EQU rcv_dr      = 2 + 0x60
.EQU rcv_dg      = 3 + 0x60
.EQU rcv_db      = 4 + 0x60
.EQU rcv_du      = 5 + 0x60
.EQU rcv_timeout = 2 + 0x60
.EQU rcv_ndevaddr= 2 + 0x60

; рабочие ячейки
.EQU ndevaddr        = 10 + 0x60
.EQU ndevaddr_count  = 11 + 0x60
.EQU speed_index     = 12 + 0x60

; ТАБЛИЦА ВЕКТОРОВ ПРЕРЫВАНИЙ.
.CSEG
.ORG 0

rjmp RESET              ; Reset Handler
 RETI                   ;rjmp EXT_INT0 ; IRQ0 Handler
rjmp CHANGE_INT ;PCINT0 Handler
 RETI                   ;Timer0 Overflow Handler
 RETI                   ;rjmp EE_RDY ; EEPROM Ready Handler
 RETI                   ;rjmp ANA_COMP ; Analog Comparator Handler
rjmp TMR0INT    ;rjmp TIM0_COMPA ; Timer0 CompareA Handler
 RETI                   ;rjmp TIM0_COMPB ; Timer0 CompareB Handler
 RETI                   ;rjmp WATCHDOG ; Watchdog Interrupt Handler
 RETI                   ;rjmp ADC ; ADC Conversion Handler


;-----------------------------------------
; Прерывание по изменению состояния порта
;-----------------------------------------
.include "RGBU-slave_chg_int.asm"


;------------------------------------
; Прерывание по переполнению таймера
;------------------------------------
.include "RGBU-slave_timer_int.asm"

;=====================================================
;                PROGRAM BEGIN THERE!!!
;=====================================================

RESET:
 set_io SPL, low(RAMEND)
 LDI             cyclecount, $00

; установить порты ввода-вывода
 set_io DDRB,   0b00010111  ; 1 - выход, 0 - вход. PINB3 - вход, остальные выходы

 set_io PCMSK,  0b00001000  ; Разрешить прерывание по изменению уровня на PB3
 set_io GIMSK,  0b00100000  ; Разрешить прерывание по изменению уровня порта

; настройка таймера
 set_io TCCR0A, 0b00000010  ; режим таймера - 02, Clear-On-Compare
 set_io TCCR0B, 0b10000001      ; Регистр сравнения OCRA указывает максимальное значение счетчика
                                                        ; Счетчик работает от тактовой частоты без делителя.
 set_io OCR0A,  timer_max_value ; Период прерываний таймера

 set_io TIMSK0, 0b00000100  ; разрешаем прерывание от таймера(по сранению на OCRA).

SEI                         ; разрешаем общие прерывания.

PRE_START:

.include "RGBU-slave_calibrate.asm"

 set_reg LEDrV, 0x10
 set_reg LEDgV, 0x10
 set_reg LEDbV, 0x10
 set_reg LEDuV, 0x10
 
 set_io EEAR, device_timeout
 SBI    EECR, 0      ; Команда чтения
 IN     timeout, EEDR


; Собственно сам цикл программы
START:

wait_cmd:
 test_bit  STA, cycle_end;
 BRTC  not_loop          ; флажок не поднят - цикл не окончен.
 INC   loopscount2       ; Событие cycle_end происходит 48000/256 = 187 раз в секунду
 ; Проверить счетчик не прошло ли время таймаута в течение которого не поступало команд?
 CPI   loopscount2, 19
 BRLO  loops_noend
 clr   loopscount2   // Сюда доберемся 10 раз в секунду.
 inc   loopscount
 CP    loopscount, timeout
 BRLO  loops_noend
  set_reg LEDrV, 0x00 // Обнулить все переменные текущей яркости.
  set_reg LEDgV, 0x00
  set_reg LEDbV, 0x00
  set_reg LEDuV, 0x00

loops_noend:
 clear_bit      STA, cycle_end;
not_loop:

; Поступила ли на вход команда?
 test_bit       STA, rcv_start
 BRTC           Wait_cmd             ; флажок не поднят - команды небыло.
; на входе зарегестрирован импульс, признак наличия команды!
 clear_bit      STA, rcv_err
 clear_bit      STA, rcv_start
 CLI
// Ожидать когда закончится 1, если нет ответа более 255 итераций - проблема синхронизации.
// Максимальная длительность импульса синхронизации - 2 кванта, для надежности возьмем 3, а это 300 тактов процессора
// Длительность итерации = 5 тактов, константа = 300/5 = 60 -> st_syn_delay

 LDI    tmp2, st_syn_delay
 DEC    tmp2          ;<+
 BREQ   bad_sync      ; |
 SBIC   PINB, cmd_port; |
 RJMP   PC-0x0003     ;-+
// SEI
 
 // Начинаем прием данных!
; Последовательность приема:
;       0. адрес
;       1. команда
;       2. яркость/скорость R  (timeout, секунд(?) - для команды установки таймаута)
;       3. яркость/скорость G  (значение игнорируется для команды установки таймаута)
;       4. яркость/скорость B  (значение игнорируется для команды установки таймаута)
;       5. яркость/скорость U  (значение игнорируется для команды установки таймаута)
;       6. контрольный.
 CLR tmp1 // перед накоплением контрольной суммы!!!

 set_bit STA, first_receive   // Начало передачи!
; ------- начало блока приема данных -------
; Первым идет адрес
 rcall  receive_byte    ; в регистре rcv - принятое значение, признак C=1 - ошибка приема. используется: ACCUM, tmp2
 STS    rcv_addr, rcv   ; в память

 BRCC   no_addr_error

 RJMP bad_sync
no_addr_error:
 ADD            tmp1, rcv

; команда
 rcall          receive_byte
 STS            rcv_cmd, rcv
 BRCC           no_cmd_error

 RJMP bad_sync
no_cmd_error:
 ADD            tmp1, rcv

; красный
 rcall          receive_byte
 STS            rcv_dr, rcv
 BRCC           no_dr_error
 RJMP bad_sync

no_dr_error:
 ADD            tmp1, rcv

; зеленый
 rcall          receive_byte
 STS            rcv_dg, rcv
 BRCC           no_dg_error

 RJMP bad_sync
no_dg_error:
 ADD            tmp1, rcv

; синий
 rcall          receive_byte
 STS            rcv_db, rcv
 BRCC           no_db_error

 RJMP bad_sync
no_db_error:
 ADD            tmp1, rcv

; фиолетовый
 rcall          receive_byte
 STS            rcv_du, rcv
 BRCC           no_du_error

 RJMP bad_sync
no_du_error:
 ADD            tmp1, rcv

; контрольный
 rcall          receive_byte
 BRCC           no_cntrl_error
 RJMP bad_sync
no_cntrl_error:

 COM            tmp1
 CP             tmp1, rcv       ; Сверим контрольную сумму
 BRNE           rcv_error_det   ; Не совпала? игнорируем данные.
// В этом месте имеем в памяти актуальные данные, которые необходимо применить.
 rcall          Do_cmd

.IFDEF DBG
  reset_timeout // Сброс таймаута
  rcall set_leds_speedval
.ENDIF

 set_io     GIFR, 0b00100000 ; сброс флага прерывания
 enable_change_int                       ; Приготовились к приему следующего пакета
 
//clr           loopscount  - пока пусть послужит отладочной цели.
RJMP START

bad_sync: // Ошибка синхронизации в процессе приема
// Дождаться отсутствия сигналов на линии и продолжить дальше
                                                                ; Максимальная длительность естественной паузы(лог.0) в
                                                                ; процессе нормальной передачи - 6 квантов,
                                                                ; для надежности можно взять 10 квантов - это
                                                                ; будет примерно 1000 тактов процессора
 SEI ; процедура ожидания может быть длительной - нельзя прекращать работу ШИМ надолго.
     ; прерывание может быть запрещено, если вдруг создалась ситуация ошибки синхронизации

// test_bit STA, timer_int
// BRTC     // нет прерывания
// clear_bit STA, timer_int

 LDI    ACCUM, sync_pause_delay  // сброс счетчика "1"
 MOV    tmp1, ACCUM
bs_re_start:
 LDI    tmp2, sync_pause_delay   // сброс счетчика "0"
 bs_wait_pause:
 SBIC   PINB, cmd_port ; Пока 0
 RJMP   bs_wait_noz    ; порт = 1
 if_no_timerint bs_wait_pause    // нет прерывания
 LDI    ACCUM, sync_pause_delay  // сброс счетчика "1"
 MOV    tmp1, ACCUM
 DEC    tmp2                     // Счет "0"
 BRNE   bs_wait_pause // если tmp2 насчитает больше sync_pause_delay квантов - выход
 RJMP   bs_wait_end
bs_wait_noz:
 if_no_timerint bs_re_start     // нет прерывания, обходим счет стороной
 DEC    tmp1                                    // Счет "1"
 BRNE   bs_re_start   // если tmp1 насчитает больше sync_pause_delay квантов - выход
bs_wait_end:
// Сюда программа попадет в случае когда на линии непрерывно будет "1" или "0" в течение sync_pause_delay квантов


rcv_error_det: // Не сошлась контрольная сумма, или ошибка синхронизации
 set_reg LEDrV, 0xFF

 CLI
 set_io     GIFR, 0b00100000 ; сброс флага прерывания
 enable_change_int           ; Приготовились к приему следующего пакета
 SEI
; ------- конец блока обработки команд -------
.IFDEF DBG
  reset_timeout // Сброс таймаута
  rcall set_leds_speedval
.ENDIF

RJMP START

.IFDEF DBG
set_leds_speedval:
 LDS tmp1, speed_index

 ROR tmp1
 BRCS slsv_setr
 set_reg LEDrV, 0x00
 rjmp slsv_ifg
slsv_setr:
 set_reg LEDrV, 0x80

slsv_ifg:
 ROR tmp1
 BRCS slsv_setg
 set_reg LEDgV, 0x00
 rjmp slsv_ifb
slsv_setg:
 set_reg LEDgV, 0x80

slsv_ifb:
 ROR tmp1
 BRCS slsv_setb
 set_reg LEDbV, 0x00
 rjmp slsv_ifu
slsv_setb:
 set_reg LEDbV, 0x80

slsv_ifu:
 ROR tmp1
 BRCS slsv_setu
 set_reg LEDuV, 0x00
 rjmp slsv_end
slsv_setu:
 set_reg LEDuV, 0x80

slsv_end:
ret
.ENDIF










;========================================
; Подпрограмма приема байта
;========================================

receive_byte: // rcv - принятый байт, признак С=1 - ошибка приема. используется: ACCUM, tmp2
; Прием первой половины
 rCall  receive_half ; (rcv, C)
 BRCS rb_error ; если С=1 - выход
; Прием второй половины
 rCall  receive_half ; (rcv, C)
rb_error: // Ашипка!!!
 ret

receive_half: // (выход: rcv, C используется: ACCUM, tmp2)
; в регистре rcv - принятое значение, признак C=1 - ошибка синхронизации - неверный стоп-бит.
; Чисто теоретически прием можно было бы сделать исключительно на фиксированных задержках
; без задействования таймера, но за время приема будут пропущены циклы обработки ШИМ
; по 5 пропусков за прием половины байта всего 5*14 пропусков на прием одного пакета
; если пакеты будут следовать достаточно плотно друг за другом это серьезно отразится
; на яркости светодиодов!

; Ждать условие начала приема. (переход напряжения с 0 на 1 - это будет момент начала отсчета временныхъ интервалов)
; Для первого пакета можно зафиксировать длительность нуля и синхронизировать скорость приема.
 CLI
 LDI    rcv_cnt, 0x05
 LDI    tmp2,    st_pause_delay   // Ожидание не более 600 тактов, 600/5 = 120 
rh_wait_start: // цикл ожидания= 5 тактов на итерацию.
 SBIC   PINB, cmd_port ; Пока 0
 RJMP   rh_run_receive
 DEC    tmp2           ; крутимся до наступления 1
 BRNE   rh_wait_start
 // Ошибка! Нет начала более 40 итераций(в 2 раза больше нормы - это не стартовый импульс)
 SEC ; установка признака ошибки
 SEI
    ret ;внутренний выход с признаком ошибки
 
rh_run_receive:
// Сброс таймера для устранения влияния ошибки скорости
 LDI   ACCUM, 0x04    ; Или сколько? Смещение таймера для точной синхронизации процесса.
 OUT   TCNT0, ACCUM   ; возможное смещение 3-7 такта!

// Если уст.признак первого прохода, анализировать значение tmp2 на предмет отклонения скорости от номинала!
 test_bit STA, first_receive
 BRTC rh_run_notfirst
 clear_bit STA, first_receive

// Вычесть из tmp2 базу
// Из EEPROM по индексу загрузить корректирующий коэфициент

 SUBI   tmp2, 35
rh_run_checklow:
 BRCC rh_run_checkhigh
 CLR    tmp2     // Если возник перенос - значение индекса меньше нуля, ограничим его нулем.
rh_run_checkhigh:
 CPI    tmp2, 17 // Проверка на верхнюю границу 
 BRLO rh_run_checkok
 LDI    tmp2, 16
rh_run_checkok:
 STS    speed_index, tmp2
 LDI    ACCUM, ee_correction
 
 ADD    tmp2,  ACCUM  ; Добавим к смещению базовый адрес таблицы

 OUT    EEAR,  tmp2   ; Адрес ЕЕПРОМ
 SBI    EECR,  0      ; Команда чтения
 IN     tmp2,  EEDR   ; читаем
 OUT	OCR0A, tmp2   ; Установить период таймера

rh_run_notfirst:
 // Сбросить прерывание от таймера!!!! 
 SEI // Тут может возникнуть обработка прерывания от таймера, ничего страшного(а может все-таки зря???).
 nop // Если прерывание возникло когда оно было запрещено, эта команда выполнится
    // в любом случае до того как вызовется обработчик! А нам надо сбросить признак после обработки
clear_bit STA, timer_int // Подавить признак возможного неожиданного прерывания, нам нужно только свежее прерывание

rh_wait_tmr:
 test_bit STA, timer_int
 BRTC     PC-1             ; Ждем прерывания от таймера.
 clear_bit STA, timer_int  ; Готовим к приему следующее событие
 test_bit  STA, port_value ; передана лог.1?
 SEC                       ; Для переноса готовим 1
 BRTS   lbl_is1
 CLC               ;Нет, все-таки 0
lbl_is1:
 ROR    rcv        ; Продвигаем принятый бит
 DEC    rcv_cnt
 BRNE   rh_wait_tmr
 ROL    rcv ; возвращаем последний принятый бит на место
 // В этом месте в признаке С содержится значение первого стоп-бита, если он ноль - то все нормально
ret


























// =======================================================================
//
//                                                      Обработка принятой команды
//
// =======================================================================

.EQU    cmd_setvalues   = 0x21
.EQU    cmd_settimeout  = 0x14
.EQU    cmd_setdevaddr  = 0x5A

Do_cmd:
; Принята команда и пакет успешно прошел верификацию, необходимо расшифровать и выполнить
; Используемые ячейки памяти:
; rcv_addr      0. адрес
; rcv_cmd       1. команда
; rcv_dr        2. яркость/скорость R  (timeout, секунд(?) - для команды установки таймаута)
; rcv_dg        3. яркость/скорость G  (значение игнорируется для команды установки таймаута)
; rcv_db        4. яркость/скорость B  (значение игнорируется для команды установки таймаута)
; rcv_du        5. яркость/скорость U  (значение игнорируется для команды установки таймаута)

// Проверяем адрес
 LDI    tmp2,   device_addr
 OUT    EEARL,  tmp2 // Адрес ячейки
 SBI    EECR,   EERE // команда чтения ЕЕПРОМ
 IN     tmp1,   EEDR // Содежимое ячейки

 LDS    tmp2,   rcv_addr // Из памяти получаем адрес которому адресованы данные.
 CP     tmp2,   tmp1
 BREQ   addr_match       // Адрес совпал - анализируем принятые данные дальше
 CPI    tmp2,   0xFF     // Адрес 0xFF - общий для всех устройств
 BRNE   cmd_error
addr_match:
 reset_timeout  // Обнуляем счетчик таймаута
 LDS    tmp2,   rcv_cmd
 CPI    tmp2,   cmd_setvalues  // Команда setvalues?
 BRNE   ch_cmdtimeout
 // Выполняем команду setvalues
 RCALL cmd_set_values
 RJMP ch_cmdend
ch_cmdtimeout:
 CPI    tmp2,   cmd_settimeout  // Команда settimeout?
 BRNE   ch_cmddevaddr
 // Выполняем команду settimeout
 LDS  timeout, rcv_timeout
 RJMP ch_cmdend
ch_cmddevaddr:
 CPI    tmp2,   cmd_setdevaddr  // Команда setdevaddr?
 BRNE   cmd_error  // Ни одна команда не совпала - ошибка.
 // Выполняем команду setdevaddr
 RCALL cmd_set_devaddr

 RJMP ch_cmdend
cmd_error:
// clr            loopscount
// set_reg        LEDgV, 0xFF
ch_cmdend:
 ret

cmd_set_values:
// Переместить из ячеек памяти rcv_dr, rcv_dg, rcv_db, rcv_du в регистры LEDrV, LEDgV, LEDbV, LEDuV.
 LDS  LEDrV, rcv_dr
 LDS  LEDgV, rcv_dg
 LDS  LEDbV, rcv_db
 LDS  LEDuV, rcv_du
 ret


cmd_set_devaddr:
 // Если новый адрес не совпадает с предыдущим его значением ndevaddr - сбросить счетчик ndevaddr_count
 // Если совпадает - прибавить 1 к ndevaddr_count
 // если при этом ndevaddr_count > 3 - запомнить адрес в EEPROM и включить зеленый канал.
 // Устанавливаемый адрес находится в ячейке rcv_dr
 LDS tmp2, rcv_ndevaddr
 LDS ACCUM, ndevaddr
 CP  ACCUM, tmp2
 BRNE cmd_sda_exit
 LDS ACCUM, ndevaddr_count
 INC ACCUM
 STS ndevaddr_count, ACCUM
 CPI ACCUM, 3 // 3-я передача команды установки адреса
 BREQ cmd_do_set
 RET
cmd_do_set:
 sbic EECR,EEPE ; Wait for completion of previous write
 rjmp cmd_do_set
 ldi ACCUM, (0<<EEPM1)|(0<<EEPM0) ; Set Programming mode
 out EECR, ACCUM
; Set up address (r17) in address register
 ldi ACCUM, device_addr
 out  EEARL, ACCUM ; Адрес ячейки
 out  EEDR, tmp2   ; Данные для записи
 sbi  EECR,EEMPE
 sbi  EECR,EEPE    ; Start Writing

 sbic EECR,EEPE    ; Ждем окончания записи
 rjmp PC-1

 CLR tmp2  ; Сбросить адрес

cmd_sda_exit:
 CLR ACCUM
 STS ndevaddr_count, ACCUM
 STS ndevaddr, tmp2 // Запомним адрес
ret

.IFDEF DBG
.warning "DEBUG MODE SOURCE compiled!"
.ENDIF



; ======== Ячейки EEPROM ========
.ESEG

device_addr:
.DB $FE  ; Адрес устройства в сети
device_timeout:
.DB $32  ; Таймаут по-умолчанию. должно быть примерно 5 сек.

ee_correction:
// 110(5.3Mhz) 109 107 106 105 104 103 101 100 99  97  96  95  94  93  91  90(4.3Mhz) 
.DB 0x6E, 0x6D, 0x6B, 0x6A, 0x69, 0x68, 0x67, 0x65, 0x64, 0x63, 0x61, 0x60, 0x5F, 0x5E, 0x5D, 0x5B, 0x5A

ee_calibration:
.DB 0x40 ; 00-7F

; Выборка из EEPROM
; Выбрать первое значение
; OUT             EEAR, phasecnt  ; Адрес ЕЕПРОМ
; SBI             EECR, 0                 ; Команда чтения
; IN              LED1V, EEDR             ; Значение читаем куда нам нужно
