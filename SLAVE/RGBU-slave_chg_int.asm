;-----------------------------------------
; ���������� �� ��������� ��������� �����
;-----------------------------------------

CHANGE_INT:
 IN		SREG_INT, SREG

 SBIS	PINB, cmd_port   ; ����� 1?
 RJMP	CH_INT_exit
// ������� �� ����� = 1, ������ ��������
// set_bit STA, 0
 set_bit 	STA, rcv_start
// ��������� ���������� �� ��������� ������!
 disable_change_int  ; ��������� ���������� �� ��������� ������
CH_INT_exit:
OUT             SREG, SREG_INT
RETI