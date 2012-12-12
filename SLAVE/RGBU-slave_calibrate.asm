// Загрузить калибровочную константу в регистр калибровки
// Константа находится в EEPROM, по адресу ee_calibration
;
 set_io EEAR, ee_calibration // адрес
 SBI    EECR, 0              ; Команда чтения
 IN     ACCUM,  EEDR         ; Значение читаем куда нам нужно 
 OUT	OSCCAL, ACCUM        ; заносим калибровку

; Пока порт в состоянии "1" держим старт запуска программы, это отладочный режим.

 set_reg LEDrV, 0x80
 set_reg LEDgV, 0x40
 set_reg LEDbV, 0x20
 set_reg LEDuV, 0x10

 
dbg_st_loop:

 test_bit  STA, cycle_end;
 BRTC  dbg_not_trig          ; флажок не поднят - цикл не окончен.
 INC   loopscount2       ; Событие cycle_end происходит 48000/256 = 187 раз в секунду
 ; Проверить счетчик не прошло ли время таймаута в течение которого не поступало команд?
 CPI   loopscount2, 19
 BRLO  dbg_noend
 clr   loopscount2   // Сюда доберемся 10 раз в секунду.
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
