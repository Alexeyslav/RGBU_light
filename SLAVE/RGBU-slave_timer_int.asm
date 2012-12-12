TMR0INT:
; ��������� ������� �������
IN      SREG_INT, SREG
PUSH	SREG_INT
;MOV     ACCUM_INT, ACCUM
set_bit STA, 1
;----
sei    // �� ����� ��������� ����� �������� ���������� ���������� �� ��������� ������ - ��� ����� ���������

INC             cyclecount
; ��������� ���������� c �������������� �������� �������.
;----- ������ ����� �������� ------
; ==== ������� ====
TSTLEDr:
 CP     cyclecount,     LEDrV  ; ��������� = cyclecount - LEDrV
 BRSH   TSTLEDr_off        ; ������� ������ ��� �����, cyclecount >= LEDrV
 led_r_on
 rjmp   TSTLEDg
TSTLEDr_off:
 led_r_off

; ==== ������� ====
TSTLEDg:
 CP             cyclecount,     LEDgV  ; ��������� = cyclecount - LEDrV
 BRSH   TSTLEDg_off        ; ������� ������ ��� �����, cyclecount >= LEDrV
 led_g_on
 rjmp   TSTLEDb
TSTLEDg_off:
 led_g_off

; ==== ����� ====
TSTLEDb:
 CP             cyclecount,     LEDbV  ; ��������� = cyclecount - LEDrV
 BRSH   TSTLEDb_off        ; ������� ������ ��� �����, cyclecount >= LEDrV
 led_b_on
 rjmp   TSTLEDu
TSTLEDb_off:
 led_b_off

; ==== ���������� ====
TSTLEDu:
 CP             cyclecount,     LEDuV  ; ��������� = cyclecount - LEDrV
 BRSH   TSTLEDu_off        ; ������� ������ ��� �����, cyclecount >= LEDrV
 led_u_on
 rjmp   TSTLED_end
TSTLEDu_off:
 led_u_off

TSTLED_end:
;----- ����� ����� �������� ------
 CLT
 SBIC		PINB, cmd_port
 SET
 BLD		STA, port_value

 TST        cyclecount
 BRNE       cycle_not_end
 Set_bit    STA,    cycle_end
cycle_not_end:
CLI
; ������������ ������� �������?
;MOV             ACCUM, ACCUM_INT
POP		SREG_INT
OUT     SREG, SREG_INT
RETI