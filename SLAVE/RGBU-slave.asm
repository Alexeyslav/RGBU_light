.include "tn13Adef.inc"
; �������������� �������� ������� - 4.8���(����� ��� 9.6���)
; Fuses - CKSEL0=1, CKSEL1=0, SUT0=0, SUT1=1, CKDIV8=1, WDTON=1, 
;         EESAVE=1, RSTDISBL=1, BODLEVEL0=1, BODLEVEL1=1, SPMEN=1
; 0 - programmed, 1 - unprogrammed.

; ���������
.EQU timer_max_value  = 100 ; �������� ��� ������� ���������� ������������ �������(=100, 95 - ����������������� ��������)
.EQU st_syn_delay     = 3*timer_max_value/5  ; ������������ ������������ ���������� ��������, = 3 ������.
.EQU sync_pause_delay = 8  ; ��������� �������� ����������� ����� � �������� � �������.
.EQU st_pause_delay   = 6*timer_max_value/5   // ������������ ������������ ��������� ����� = 6 �����.
                         // ��� �������� �� �������! 
						 // �� ���� ������� ������ ������� �������������� ������������!
; ����� ��������.
.DEF ACCUM     = R25
//.DEF ACCUM_INT = R7	; ��� ���������� TIMER_INT
.DEF SREG_INT	= R8	; ��� ���������� TIMER_INT
.DEF SREG_CHG	= R9	; ��� ���������� CHG
.DEF ACCUM_CHG	= R7	; ��� ���������� CHG

;#define DBG true

; �����������
#define cmd_port PINB3  ; ����� ����� ����� ������� ���������� �������

#define led_r_on  SBI PORTB, PINB2
#define led_r_off CBI PORTB, PINB2

#define led_g_on  SBI PORTB, PINB1
#define led_g_off CBI PORTB, PINB1

#define led_b_on  SBI PORTB, PINB0
#define led_b_off CBI PORTB, PINB0

#define led_u_on  SBI PORTB, PINB4
#define led_u_off CBI PORTB, PINB4

#define enable_change_int  set_io GIMSK,  0b00100000  ; ��������� ���������� �� ��������� ������ �� PB3
#define disable_change_int set_io GIMSK,  0b00000000  ; ��������� ���������� �� ��������� ������ �� PB3

#define reset_timeout      clr    loopscount

;�������
.include "..\common\RGBU-macros.inc"
.macro reset_timer    ; ������ ������� �� 0 �� OCR0A...
  LDI   ACCUM, 0x00   ; 1 ����
  OUT   TCNT0, ACCUM  ; 1 ����
.endmacro

.macro if_no_timerint      ; ���� �� ���� ���������� �� ������� - ������� �� �����,
  test_bit STA, timer_int  ; ���� ���� ���������� - ���������� ������� � ���������� ������
  BRTC   @0                ; ����� ��������� �������� � �������� ����� ������� "PC-1"
  clear_bit STA, timer_int
.endmacro

; ����������� ����������

.DEF LEDrV = R1    ; ������� �� ������� ������
.DEF LEDgV = R2
.DEF LEDbV = R3
.DEF LEDuV = R4
.DEF rcv        = R10
.DEF tmp1       = R11

.DEF STA   = R13
; ������� ����������.
; 0 - ��������� � �����, ������ ���� �������� 1.
.equ port_value = 0
; 1 - ���������� �� �������
.equ timer_int  = 1
; 2 - ��������� �����
.equ Cycle_end  = 2    ; ���� = 256 ���������� �������, 1 ���������� ������� = Fosc/100 = 48K
; 3 - ������� ������ �������� ������
.equ rcv_start  = 3
; 4 - ������� ������ ������
.equ rcv_err    = 4
; 5 - ������� ������ ��������
.equ first_receive = 5





; �������� � ���������
.DEF cyclecount = R16
.DEF rcv_cnt    = R17
.DEF loopscount = R18
.DEF tmp2       = R19 ; � ������������ ���������������� �������� �������� ����� LDI
.DEF timeout    = R20
.DEF loopscount2= R21







; ======= ������ ������  =========== RAM ���������� � ������ 0x60-0x9F
; ��������� ��� ������
.EQU rcv_addr    = 0 + 0x60
.EQU rcv_cmd     = 1 + 0x60
.EQU rcv_dr      = 2 + 0x60
.EQU rcv_dg      = 3 + 0x60
.EQU rcv_db      = 4 + 0x60
.EQU rcv_du      = 5 + 0x60
.EQU rcv_timeout = 2 + 0x60
.EQU rcv_ndevaddr= 2 + 0x60

; ������� ������
.EQU ndevaddr        = 10 + 0x60
.EQU ndevaddr_count  = 11 + 0x60
.EQU speed_index     = 12 + 0x60

; ������� �������� ����������.
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
; ���������� �� ��������� ��������� �����
;-----------------------------------------
.include "RGBU-slave_chg_int.asm"


;------------------------------------
; ���������� �� ������������ �������
;------------------------------------
.include "RGBU-slave_timer_int.asm"

;=====================================================
;                PROGRAM BEGIN THERE!!!
;=====================================================

RESET:
 set_io SPL, low(RAMEND)
 LDI             cyclecount, $00

; ���������� ����� �����-������
 set_io DDRB,   0b00010111  ; 1 - �����, 0 - ����. PINB3 - ����, ��������� ������

 set_io PCMSK,  0b00001000  ; ��������� ���������� �� ��������� ������ �� PB3
 set_io GIMSK,  0b00100000  ; ��������� ���������� �� ��������� ������ �����

; ��������� �������
 set_io TCCR0A, 0b00000010  ; ����� ������� - 02, Clear-On-Compare
 set_io TCCR0B, 0b10000001      ; ������� ��������� OCRA ��������� ������������ �������� ��������
                                                        ; ������� �������� �� �������� ������� ��� ��������.
 set_io OCR0A,  timer_max_value ; ������ ���������� �������

 set_io TIMSK0, 0b00000100  ; ��������� ���������� �� �������(�� �������� �� OCRA).

SEI                         ; ��������� ����� ����������.

PRE_START:

.include "RGBU-slave_calibrate.asm"

 set_reg LEDrV, 0x10
 set_reg LEDgV, 0x10
 set_reg LEDbV, 0x10
 set_reg LEDuV, 0x10
 
 set_io EEAR, device_timeout
 SBI    EECR, 0      ; ������� ������
 IN     timeout, EEDR


; ���������� ��� ���� ���������
START:

wait_cmd:
 test_bit  STA, cycle_end;
 BRTC  not_loop          ; ������ �� ������ - ���� �� �������.
 INC   loopscount2       ; ������� cycle_end ���������� 48000/256 = 187 ��� � �������
 ; ��������� ������� �� ������ �� ����� �������� � ������� �������� �� ��������� ������?
 CPI   loopscount2, 19
 BRLO  loops_noend
 clr   loopscount2   // ���� ��������� 10 ��� � �������.
 inc   loopscount
 CP    loopscount, timeout
 BRLO  loops_noend
  set_reg LEDrV, 0x00 // �������� ��� ���������� ������� �������.
  set_reg LEDgV, 0x00
  set_reg LEDbV, 0x00
  set_reg LEDuV, 0x00

loops_noend:
 clear_bit      STA, cycle_end;
not_loop:

; ��������� �� �� ���� �������?
 test_bit       STA, rcv_start
 BRTC           Wait_cmd             ; ������ �� ������ - ������� ������.
; �� ����� ��������������� �������, ������� ������� �������!
 clear_bit      STA, rcv_err
 clear_bit      STA, rcv_start
 CLI
// ������� ����� ���������� 1, ���� ��� ������ ����� 255 �������� - �������� �������������.
// ������������ ������������ �������� ������������� - 2 ������, ��� ���������� ������� 3, � ��� 300 ������ ����������
// ������������ �������� = 5 ������, ��������� = 300/5 = 60 -> st_syn_delay

 LDI    tmp2, st_syn_delay
 DEC    tmp2          ;<+
 BREQ   bad_sync      ; |
 SBIC   PINB, cmd_port; |
 RJMP   PC-0x0003     ;-+
// SEI
 
 // �������� ����� ������!
; ������������������ ������:
;       0. �����
;       1. �������
;       2. �������/�������� R  (timeout, ������(?) - ��� ������� ��������� ��������)
;       3. �������/�������� G  (�������� ������������ ��� ������� ��������� ��������)
;       4. �������/�������� B  (�������� ������������ ��� ������� ��������� ��������)
;       5. �������/�������� U  (�������� ������������ ��� ������� ��������� ��������)
;       6. �����������.
 CLR tmp1 // ����� ����������� ����������� �����!!!

 set_bit STA, first_receive   // ������ ��������!
; ------- ������ ����� ������ ������ -------
; ������ ���� �����
 rcall  receive_byte    ; � �������� rcv - �������� ��������, ������� C=1 - ������ ������. ������������: ACCUM, tmp2
 STS    rcv_addr, rcv   ; � ������

 BRCC   no_addr_error

 RJMP bad_sync
no_addr_error:
 ADD            tmp1, rcv

; �������
 rcall          receive_byte
 STS            rcv_cmd, rcv
 BRCC           no_cmd_error

 RJMP bad_sync
no_cmd_error:
 ADD            tmp1, rcv

; �������
 rcall          receive_byte
 STS            rcv_dr, rcv
 BRCC           no_dr_error
 RJMP bad_sync

no_dr_error:
 ADD            tmp1, rcv

; �������
 rcall          receive_byte
 STS            rcv_dg, rcv
 BRCC           no_dg_error

 RJMP bad_sync
no_dg_error:
 ADD            tmp1, rcv

; �����
 rcall          receive_byte
 STS            rcv_db, rcv
 BRCC           no_db_error

 RJMP bad_sync
no_db_error:
 ADD            tmp1, rcv

; ����������
 rcall          receive_byte
 STS            rcv_du, rcv
 BRCC           no_du_error

 RJMP bad_sync
no_du_error:
 ADD            tmp1, rcv

; �����������
 rcall          receive_byte
 BRCC           no_cntrl_error
 RJMP bad_sync
no_cntrl_error:

 COM            tmp1
 CP             tmp1, rcv       ; ������ ����������� �����
 BRNE           rcv_error_det   ; �� �������? ���������� ������.
// � ���� ����� ����� � ������ ���������� ������, ������� ���������� ���������.
 rcall          Do_cmd

.IFDEF DBG
  reset_timeout // ����� ��������
  rcall set_leds_speedval
.ENDIF

 set_io     GIFR, 0b00100000 ; ����� ����� ����������
 enable_change_int                       ; ������������� � ������ ���������� ������
 
//clr           loopscount  - ���� ����� �������� ���������� ����.
RJMP START

bad_sync: // ������ ������������� � �������� ������
// ��������� ���������� �������� �� ����� � ���������� ������
                                                                ; ������������ ������������ ������������ �����(���.0) �
                                                                ; �������� ���������� �������� - 6 �������,
                                                                ; ��� ���������� ����� ����� 10 ������� - ���
                                                                ; ����� �������� 1000 ������ ����������
 SEI ; ��������� �������� ����� ���� ���������� - ������ ���������� ������ ��� �������.
     ; ���������� ����� ���� ���������, ���� ����� ��������� �������� ������ �������������

// test_bit STA, timer_int
// BRTC     // ��� ����������
// clear_bit STA, timer_int

 LDI    ACCUM, sync_pause_delay  // ����� �������� "1"
 MOV    tmp1, ACCUM
bs_re_start:
 LDI    tmp2, sync_pause_delay   // ����� �������� "0"
 bs_wait_pause:
 SBIC   PINB, cmd_port ; ���� 0
 RJMP   bs_wait_noz    ; ���� = 1
 if_no_timerint bs_wait_pause    // ��� ����������
 LDI    ACCUM, sync_pause_delay  // ����� �������� "1"
 MOV    tmp1, ACCUM
 DEC    tmp2                     // ���� "0"
 BRNE   bs_wait_pause // ���� tmp2 ��������� ������ sync_pause_delay ������� - �����
 RJMP   bs_wait_end
bs_wait_noz:
 if_no_timerint bs_re_start     // ��� ����������, ������� ���� ��������
 DEC    tmp1                                    // ���� "1"
 BRNE   bs_re_start   // ���� tmp1 ��������� ������ sync_pause_delay ������� - �����
bs_wait_end:
// ���� ��������� ������� � ������ ����� �� ����� ���������� ����� "1" ��� "0" � ������� sync_pause_delay �������


rcv_error_det: // �� ������� ����������� �����, ��� ������ �������������
 set_reg LEDrV, 0xFF

 CLI
 set_io     GIFR, 0b00100000 ; ����� ����� ����������
 enable_change_int           ; ������������� � ������ ���������� ������
 SEI
; ------- ����� ����� ��������� ������ -------
.IFDEF DBG
  reset_timeout // ����� ��������
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
; ������������ ������ �����
;========================================

receive_byte: // rcv - �������� ����, ������� �=1 - ������ ������. ������������: ACCUM, tmp2
; ����� ������ ��������
 rCall  receive_half ; (rcv, C)
 BRCS rb_error ; ���� �=1 - �����
; ����� ������ ��������
 rCall  receive_half ; (rcv, C)
rb_error: // ������!!!
 ret

receive_half: // (�����: rcv, C ������������: ACCUM, tmp2)
; � �������� rcv - �������� ��������, ������� C=1 - ������ ������������� - �������� ����-���.
; ����� ������������ ����� ����� ���� �� ������� ������������� �� ������������� ���������
; ��� �������������� �������, �� �� ����� ������ ����� ��������� ����� ��������� ���
; �� 5 ��������� �� ����� �������� ����� ����� 5*14 ��������� �� ����� ������ ������
; ���� ������ ����� ��������� ���������� ������ ���� �� ������ ��� �������� ���������
; �� ������� �����������!

; ����� ������� ������ ������. (������� ���������� � 0 �� 1 - ��� ����� ������ ������ ������� ���������� ����������)
; ��� ������� ������ ����� ������������� ������������ ���� � ���������������� �������� ������.
 CLI
 LDI    rcv_cnt, 0x05
 LDI    tmp2,    st_pause_delay   // �������� �� ����� 600 ������, 600/5 = 120 
rh_wait_start: // ���� ��������= 5 ������ �� ��������.
 SBIC   PINB, cmd_port ; ���� 0
 RJMP   rh_run_receive
 DEC    tmp2           ; �������� �� ����������� 1
 BRNE   rh_wait_start
 // ������! ��� ������ ����� 40 ��������(� 2 ���� ������ ����� - ��� �� ��������� �������)
 SEC ; ��������� �������� ������
 SEI
    ret ;���������� ����� � ��������� ������
 
rh_run_receive:
// ����� ������� ��� ���������� ������� ������ ��������
 LDI   ACCUM, 0x04    ; ��� �������? �������� ������� ��� ������ ������������� ��������.
 OUT   TCNT0, ACCUM   ; ��������� �������� 3-7 �����!

// ���� ���.������� ������� �������, ������������� �������� tmp2 �� ������� ���������� �������� �� ��������!
 test_bit STA, first_receive
 BRTC rh_run_notfirst
 clear_bit STA, first_receive

// ������� �� tmp2 ����
// �� EEPROM �� ������� ��������� �������������� ����������

 SUBI   tmp2, 35
rh_run_checklow:
 BRCC rh_run_checkhigh
 CLR    tmp2     // ���� ������ ������� - �������� ������� ������ ����, ��������� ��� �����.
rh_run_checkhigh:
 CPI    tmp2, 17 // �������� �� ������� ������� 
 BRLO rh_run_checkok
 LDI    tmp2, 16
rh_run_checkok:
 STS    speed_index, tmp2
 LDI    ACCUM, ee_correction
 
 ADD    tmp2,  ACCUM  ; ������� � �������� ������� ����� �������

 OUT    EEAR,  tmp2   ; ����� ������
 SBI    EECR,  0      ; ������� ������
 IN     tmp2,  EEDR   ; ������
 OUT	OCR0A, tmp2   ; ���������� ������ �������

rh_run_notfirst:
 // �������� ���������� �� �������!!!! 
 SEI // ��� ����� ���������� ��������� ���������� �� �������, ������ ���������(� ����� ���-���� ���???).
 nop // ���� ���������� �������� ����� ��� ���� ���������, ��� ������� ����������
    // � ����� ������ �� ���� ��� ��������� ����������! � ��� ���� �������� ������� ����� ���������
clear_bit STA, timer_int // �������� ������� ���������� ������������ ����������, ��� ����� ������ ������ ����������

rh_wait_tmr:
 test_bit STA, timer_int
 BRTC     PC-1             ; ���� ���������� �� �������.
 clear_bit STA, timer_int  ; ������� � ������ ��������� �������
 test_bit  STA, port_value ; �������� ���.1?
 SEC                       ; ��� �������� ������� 1
 BRTS   lbl_is1
 CLC               ;���, ���-���� 0
lbl_is1:
 ROR    rcv        ; ���������� �������� ���
 DEC    rcv_cnt
 BRNE   rh_wait_tmr
 ROL    rcv ; ���������� ��������� �������� ��� �� �����
 // � ���� ����� � �������� � ���������� �������� ������� ����-����, ���� �� ���� - �� ��� ���������
ret


























// =======================================================================
//
//                                                      ��������� �������� �������
//
// =======================================================================

.EQU    cmd_setvalues   = 0x21
.EQU    cmd_settimeout  = 0x14
.EQU    cmd_setdevaddr  = 0x5A

Do_cmd:
; ������� ������� � ����� ������� ������ �����������, ���������� ������������ � ���������
; ������������ ������ ������:
; rcv_addr      0. �����
; rcv_cmd       1. �������
; rcv_dr        2. �������/�������� R  (timeout, ������(?) - ��� ������� ��������� ��������)
; rcv_dg        3. �������/�������� G  (�������� ������������ ��� ������� ��������� ��������)
; rcv_db        4. �������/�������� B  (�������� ������������ ��� ������� ��������� ��������)
; rcv_du        5. �������/�������� U  (�������� ������������ ��� ������� ��������� ��������)

// ��������� �����
 LDI    tmp2,   device_addr
 OUT    EEARL,  tmp2 // ����� ������
 SBI    EECR,   EERE // ������� ������ ������
 IN     tmp1,   EEDR // ��������� ������

 LDS    tmp2,   rcv_addr // �� ������ �������� ����� �������� ���������� ������.
 CP     tmp2,   tmp1
 BREQ   addr_match       // ����� ������ - ����������� �������� ������ ������
 CPI    tmp2,   0xFF     // ����� 0xFF - ����� ��� ���� ���������
 BRNE   cmd_error
addr_match:
 reset_timeout  // �������� ������� ��������
 LDS    tmp2,   rcv_cmd
 CPI    tmp2,   cmd_setvalues  // ������� setvalues?
 BRNE   ch_cmdtimeout
 // ��������� ������� setvalues
 RCALL cmd_set_values
 RJMP ch_cmdend
ch_cmdtimeout:
 CPI    tmp2,   cmd_settimeout  // ������� settimeout?
 BRNE   ch_cmddevaddr
 // ��������� ������� settimeout
 LDS  timeout, rcv_timeout
 RJMP ch_cmdend
ch_cmddevaddr:
 CPI    tmp2,   cmd_setdevaddr  // ������� setdevaddr?
 BRNE   cmd_error  // �� ���� ������� �� ������� - ������.
 // ��������� ������� setdevaddr
 RCALL cmd_set_devaddr

 RJMP ch_cmdend
cmd_error:
// clr            loopscount
// set_reg        LEDgV, 0xFF
ch_cmdend:
 ret

cmd_set_values:
// ����������� �� ����� ������ rcv_dr, rcv_dg, rcv_db, rcv_du � �������� LEDrV, LEDgV, LEDbV, LEDuV.
 LDS  LEDrV, rcv_dr
 LDS  LEDgV, rcv_dg
 LDS  LEDbV, rcv_db
 LDS  LEDuV, rcv_du
 ret


cmd_set_devaddr:
 // ���� ����� ����� �� ��������� � ���������� ��� ��������� ndevaddr - �������� ������� ndevaddr_count
 // ���� ��������� - ��������� 1 � ndevaddr_count
 // ���� ��� ���� ndevaddr_count > 3 - ��������� ����� � EEPROM � �������� ������� �����.
 // ��������������� ����� ��������� � ������ rcv_dr
 LDS tmp2, rcv_ndevaddr
 LDS ACCUM, ndevaddr
 CP  ACCUM, tmp2
 BRNE cmd_sda_exit
 LDS ACCUM, ndevaddr_count
 INC ACCUM
 STS ndevaddr_count, ACCUM
 CPI ACCUM, 3 // 3-� �������� ������� ��������� ������
 BREQ cmd_do_set
 RET
cmd_do_set:
 sbic EECR,EEPE ; Wait for completion of previous write
 rjmp cmd_do_set
 ldi ACCUM, (0<<EEPM1)|(0<<EEPM0) ; Set Programming mode
 out EECR, ACCUM
; Set up address (r17) in address register
 ldi ACCUM, device_addr
 out  EEARL, ACCUM ; ����� ������
 out  EEDR, tmp2   ; ������ ��� ������
 sbi  EECR,EEMPE
 sbi  EECR,EEPE    ; Start Writing

 sbic EECR,EEPE    ; ���� ��������� ������
 rjmp PC-1

 CLR tmp2  ; �������� �����

cmd_sda_exit:
 CLR ACCUM
 STS ndevaddr_count, ACCUM
 STS ndevaddr, tmp2 // �������� �����
ret

.IFDEF DBG
.warning "DEBUG MODE SOURCE compiled!"
.ENDIF



; ======== ������ EEPROM ========
.ESEG

device_addr:
.DB $FE  ; ����� ���������� � ����
device_timeout:
.DB $32  ; ������� ��-���������. ������ ���� �������� 5 ���.

ee_correction:
// 110(5.3Mhz) 109 107 106 105 104 103 101 100 99  97  96  95  94  93  91  90(4.3Mhz) 
.DB 0x6E, 0x6D, 0x6B, 0x6A, 0x69, 0x68, 0x67, 0x65, 0x64, 0x63, 0x61, 0x60, 0x5F, 0x5E, 0x5D, 0x5B, 0x5A

ee_calibration:
.DB 0x40 ; 00-7F

; ������� �� EEPROM
; ������� ������ ��������
; OUT             EEAR, phasecnt  ; ����� ������
; SBI             EECR, 0                 ; ������� ������
; IN              LED1V, EEDR             ; �������� ������ ���� ��� �����
