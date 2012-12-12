TMR0INT:
; сохранить регистр статуса
IN      SREG_INT, SREG
PUSH	SREG_INT
;MOV     ACCUM_INT, ACCUM
set_bit STA, 1
;----
sei    // Во время обработки может случайно возникнуть прерывание по изменению уровня - оно имеет приоритет

INC             cyclecount
; Проверяем совпадения c установленными уровнями яркости.
;----- начало блока проверок ------
; ==== КРАСНЫЙ ====
TSTLEDr:
 CP     cyclecount,     LEDrV  ; результат = cyclecount - LEDrV
 BRSH   TSTLEDr_off        ; Переход больше или равно, cyclecount >= LEDrV
 led_r_on
 rjmp   TSTLEDg
TSTLEDr_off:
 led_r_off

; ==== ЗЕЛЕНЫЙ ====
TSTLEDg:
 CP             cyclecount,     LEDgV  ; результат = cyclecount - LEDrV
 BRSH   TSTLEDg_off        ; Переход больше или равно, cyclecount >= LEDrV
 led_g_on
 rjmp   TSTLEDb
TSTLEDg_off:
 led_g_off

; ==== СИНИЙ ====
TSTLEDb:
 CP             cyclecount,     LEDbV  ; результат = cyclecount - LEDrV
 BRSH   TSTLEDb_off        ; Переход больше или равно, cyclecount >= LEDrV
 led_b_on
 rjmp   TSTLEDu
TSTLEDb_off:
 led_b_off

; ==== ФИОЛЕТОВЫЙ ====
TSTLEDu:
 CP             cyclecount,     LEDuV  ; результат = cyclecount - LEDrV
 BRSH   TSTLEDu_off        ; Переход больше или равно, cyclecount >= LEDrV
 led_u_on
 rjmp   TSTLED_end
TSTLEDu_off:
 led_u_off

TSTLED_end:
;----- конец блока проверок ------
 CLT
 SBIC		PINB, cmd_port
 SET
 BLD		STA, port_value

 TST        cyclecount
 BRNE       cycle_not_end
 Set_bit    STA,    cycle_end
cycle_not_end:
CLI
; восстановить регистр статуса?
;MOV             ACCUM, ACCUM_INT
POP		SREG_INT
OUT     SREG, SREG_INT
RETI