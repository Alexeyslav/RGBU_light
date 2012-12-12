;-----------------------------------------
; Прерывание по изменению состояния порта
;-----------------------------------------

CHANGE_INT:
 IN		SREG_INT, SREG

 SBIS	PINB, cmd_port   ; равен 1?
 RJMP	CH_INT_exit
// Уровень на входе = 1, начало передачи
// set_bit STA, 0
 set_bit 	STA, rcv_start
// Запретить прерывание по изменению уровня!
 disable_change_int  ; Запретить прерывание по изменению уровня
CH_INT_exit:
OUT             SREG, SREG_INT
RETI