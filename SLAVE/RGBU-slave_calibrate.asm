// ��������� ������������� ��������� � ������� ����������
// ��������� ��������� � EEPROM, �� ������ ee_calibration
;
 set_io EEAR, ee_calibration // �����
 SBI    EECR, 0              ; ������� ������
 IN     ACCUM,  EEDR         ; �������� ������ ���� ��� ����� 
 OUT	OSCCAL, ACCUM        ; ������� ����������

; ���� ���� � ��������� "1" ������ ����� ������� ���������, ��� ���������� �����.

 set_reg LEDrV, 0x80
 set_reg LEDgV, 0x40
 set_reg LEDbV, 0x20
 set_reg LEDuV, 0x10

 
dbg_st_loop:

 test_bit  STA, cycle_end;
 BRTC  dbg_not_trig          ; ������ �� ������ - ���� �� �������.
 INC   loopscount2       ; ������� cycle_end ���������� 48000/256 = 187 ��� � �������
 ; ��������� ������� �� ������ �� ����� �������� � ������� �������� �� ��������� ������?
 CPI   loopscount2, 19
 BRLO  dbg_noend
 clr   loopscount2   // ���� ��������� 10 ��� � �������.
 inc   loopscount
 CPI   loopscount, 5
 BRLO  dbg_noend

 LDI ACCUM, 0x88
 ADD LEDbV, ACCUM
dbg_noend:
 clear_bit STA, cycle_end;


dbg_not_trig:

 SBIC   PINB, cmd_port
 RJMP   dbg_st_loop
