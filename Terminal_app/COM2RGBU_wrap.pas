unit COM2RGBU_wrap;

interface
uses Classes, windows, SyncObjs;
CONST HLCMD_test    = $54;{T}
      HLCMD_load    = $40;{T}
      HLCMD_SUCCESS = $2B;{+}
      HLCMD_FAILED  = $2D;{-}
      HLCMD_INPUT   = $3F;{?}
      HLCMD_ADC     = $3D;{=}

//.EQU    set_values   = 0x21
//.EQU    set_timeout  = 0x14
//.EQU    set_devaddr  = 0x5A

type
 TRGBU_linkstate  = (com_notopened = 0,com_porterror = 1,com_Ready = 2,com_Executing = 3,com_WaitReply = 4);
 TRGBU_protostat  = (prt_notrespond = 0, prt_active = 1);
 TRGBU_COM_result = (cr_sucess = 0, cr_errcmd = 1, cr_unknown = 2, cr_timeout = 3, cr_linkfail = 4);
 TRGBU_cmdtype    = (cmd_test = 0, cmd_loadvalue = 1, cmd_readadc = 2, cmd_pause = 3);

 TBaudRate =
      (br110 = CBR_110,
       br300 = CBR_300,
       br600 = CBR_600,
       br1200 = CBR_1200,
       br2400 = CBR_2400,
       br4800 = CBR_4800,
       br9600 = CBR_9600,
       br14400 = CBR_14400,
       br19200 = CBR_19200,
       br38400 = CBR_38400,
       br56000 = CBR_56000,
       br57600 = CBR_57600,
       br115200 = CBR_115200,
       br128000 = CBR_128000,
       br256000 = CBR_256000);


 TRGBU_cmd = packed record
//   state: (st_none,st_new,st_executing,st_executed,st_error);
   id      : integer; // для результата
   rpt     : integer;
   executed: boolean;
   command : TRGBU_cmdtype;
   data    : array[0..7] of byte;
  end;
 TRGBU_cmdlist = array of TRGBU_cmd;

 TRGBU_result = packed record
   id       : integer;
   valid    : boolean;
   case typ : byte of
   0: (resb : array[0..7] of byte);
   1: (resw : array[0..3] of word);
 end;
 TRGBU_reslist = array of TRGBU_result;

type
  TCOM_RGBU = class(TThread)
  private
   deviceHandle : Thandle;
   Dcb          : TDcb;
   COMMTIMEOUTS : TCommTimeouts;
   fOpened      : boolean;
//   fCOMMError : integer;
//   fprotoerror  : integer;
   fPortNum     : integer;
   fCOMSpeed    : TBaudRate;
   fstat        : TRGBU_linkstate;
   fprotostat   : TRGBU_protostat;
   fmax_repeat  : integer;
   cmd_list     : TRGBU_cmdlist;
   res_list     : TRGBU_reslist;
   fcur_cmd     : TRGBU_cmd;
   fcur_res     : TRGBU_result;
   cmd_lock     : TCriticalSection;
   res_lock     : TCriticalSection;
   cmd_load_ev  : Tevent;
   Function  Read_cmd:boolean; // Читает очередную команду в fcur_cmd и удаляет из очереди. если успешно - возвращает true
   Procedure write_result(res:TRGBU_result);
   Procedure Flush_RX;
   Function  COM_read_byte(var dt:byte):TRGBU_COM_result;
   Function  COM_send_byte(    dt:byte):TRGBU_COM_result;
   procedure add_command(cmd:TRGBU_cmd); // Добавляет команду в очередь
   function frun_testcmd  :TRGBU_COM_result;   // обработка команд из fcur_cmd в fcur_res.
   function frun_loadvalue:TRGBU_COM_result;
   function frun_readadc  :TRGBU_COM_result;
   function frun_pause    :TRGBU_COM_result;

  protected
   Procedure Execute; override;
  public
   STATE        : longint; // !!!! УДАЛИТЬ
   COM_rdy      : boolean; // устройство готово к приему команд, false - выполняется очередь команд.
   COM_error    : integer; // количество ошибок подключения к порту
   COM_retry    : integer; // количество повторов коммуникации с устройством

   procedure Open(Pnum: integer; speed:TBaudRate);  // Открывает соединение
   procedure Close;			    // Закрывает соединение и очищает очереди
   procedure flush_cmd;         // очищает очередь команд и результатов
   procedure flush_results;
   function  get_results(var res:TRGBU_result):boolean; // Возвращает очередной результат выполнения команды, если команда предполагает наличие результата
   Procedure add_command_test;
   Procedure add_command_RGBU(adr,cmd,r,g,b,u:byte);
   Procedure add_command_readADC(id,ch:byte);
   Procedure add_command_pause(ms:byte);
  published
   property Opened    : boolean read fOpened;
//   property COMMError : integer read fCOMMError;
   property COM_stat  : TRGBU_linkstate read fstat;
   property Protocol_stat: TRGBU_protostat read fprotostat;
   property max_repeat   : integer read fmax_repeat write fmax_repeat;
 end;
Var Module : TCOM_RGBU;

implementation
uses SysUtils;

// ===================================
// =================================================================
// ===================================

   Procedure TCOM_RGBU.Execute;
   var re: TRGBU_COM_result;
       b : byte;
    begin
     cmd_lock    := TCriticalSection.Create;
     res_lock    := TCriticalSection.Create;
     cmd_load_ev := Tevent.Create(nil,true,false,''); // security:default, automatic_reset,

     COM_rdy    := false;
     COM_error  :=0;
     COM_retry  :=0;
     fstat      := com_notopened;
     fprotostat := prt_notrespond;
     COM_rdy    := false;
     fcur_cmd.executed:= true; // Первую команду считать выполненной

     while (not Terminated) do
      begin
       If fstat = com_porterror then
	begin
	 inc(COM_error);
	 FileClose(deviceHandle);
	 deviceHandle := INVALID_HANDLE_VALUE;
	 fstat := com_notopened;
	 fprotostat   := prt_notrespond;
	 COM_rdy      := false;
	 sleep(20); // Пауза перед попыткой...
	end;

       If (fopened = true) and (fstat = com_notopened) then
	begin  // Если должен быть открыт но еще не открыт - открыть порт.
	 deviceHandle:=CreateFile(PChar('\\.\COM'+IntToStr(fPortNum)), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
	 If deviceHandle = INVALID_HANDLE_VALUE then fstat := com_porterror
      else
       begin // Порт открыт успешно, идет настройка порта.
	GetCommState(deviceHandle, Dcb);
	Dcb.BaudRate := DWORD(fCOMSpeed);
	Dcb.Parity := NOPARITY;
	Dcb.ByteSize := 8;
	Dcb.StopBits := ONESTOPBIT;
	SetCommState(deviceHandle, Dcb);
	// Указать таймауты
//	GetCommTimeouts(deviceHandle,COMMTIMEOUTS);
	COMMTIMEOUTS.ReadIntervalTimeout := 15; //4
	COMMTIMEOUTS.ReadTotalTimeoutMultiplier  := 4; //1
	COMMTIMEOUTS.ReadTotalTimeoutConstant    := 20;  //10
	COMMTIMEOUTS.WriteTotalTimeoutMultiplier := 4; //1
	COMMTIMEOUTS.WriteTotalTimeoutConstant   := 20;  //10
	SetCommTimeouts(deviceHandle,COMMTIMEOUTS);
	fstat := com_Ready;
       end;
     //Dcb.BaudRate := DWORD(BaudRate);
	end;

       If (fopened = false) and (fstat <> com_notopened) then
	begin // если должен быть закрыт но еще открыт - закрыть порт.
	 FileClose(deviceHandle);
	 deviceHandle := INVALID_HANDLE_VALUE;
	 fstat := com_notopened;
	 fprotostat := prt_notrespond;
	 COM_rdy   := false;
	end;

       If (fstat = com_ready) and (fprotostat = prt_notrespond) then
	begin
	 inc(COM_retry);
	 //Провести проверку связи - если есть ответ, изменить статус.
	 FLUSH_RX;
	  // 1. Передаем команду "TEST";
	 If COM_send_byte(HLCMD_test) = cr_linkfail then fstat := com_porterror
	 else
	  begin
	   // 2. ждем ответа
	   fstat := com_WaitReply;
	   re := COM_read_byte(b);
	   case re of // Возможные ответы
	    cr_sucess  :{Ответ есть         }
	       begin
		If b = HLCMD_SUCCESS then fprotostat := prt_active
				     else begin fprotostat := prt_notrespond; sleep(10);end;
		fstat := com_ready;     
	       end;
	    cr_timeout :{не поступил вовремя} begin fprotostat := prt_notrespond; sleep(10); fstat := com_ready end;
			{но порт в порядке  }
	    cr_linkfail,{ошибка записи в порт, скорей всего порт более не существует}
	    cr_unknown : begin fprotostat := prt_notrespond; fstat := com_porterror end;
	   end;
	  end;
	 If fprotostat = prt_active then COM_rdy := true;
	end;

	If (fstat = com_ready) and  (fprotostat = prt_active)
	    // если порт валидный и устройство отвечает, то...
	   then
	 If length(cmd_list)>0 then
	 begin  // если есть команды в очереди...
	  COM_rdy := false;
	  // Считываем имеющиеся команды из очереди выполняем их и удаляем успешные
	  while Read_cmd and (not Terminated)do
	   begin
	    // считанная команда находится в fcur_cmd
	    fillchar(fcur_res,sizeof(fcur_res),0);
	    fcur_res.valid := false;
	    Case fcur_cmd.command of
	     cmd_test     : re:=frun_testcmd;
	     cmd_loadvalue: re:=frun_loadvalue;
	     cmd_readadc  : re:=frun_readadc;
         cmd_pause    : re:=frun_pause
         else         re:=cr_errcmd;
	    end;
	    inc(fcur_cmd.rpt);
	    case re of
	     cr_sucess: begin fcur_cmd.executed := true; end;
	     cr_errcmd: begin
			 fcur_cmd.executed := true;
			 fcur_res.valid    := true;
			 fcur_res.id := -1;
			 fcur_res.resb[1] := ord(fcur_cmd.command);
			 fcur_res.resb[7] := $FF;
			end; // Команда не распознана, но её всеравно стоит удалить из очереди
	     cr_unknown:begin
			 fcur_cmd.executed := true;
			 fcur_res.valid    := true;
			 fcur_res.id := -1;
			 fcur_res.resb[1] := ord(fcur_cmd.command);
			 fcur_res.resb[6] := $FF;
			end; // непонятная ошибка, команду стоит удалить из очереди
	     cr_timeout:begin
			 fprotostat := prt_notrespond;
			 fcur_cmd.executed := false;
			 fcur_res.valid    := true;
			 fcur_res.id := -1;
			 fcur_res.resb[1] := ord(fcur_cmd.command);
			 fcur_res.resb[5] := $FF;
			 fcur_res.resb[2] := length(cmd_list);
			 write_result(fcur_res);
			 break; // Прервать цикл и восстановить связь
			end; // таймаут, команду повторить
	     cr_linkfail:begin
			 fstat:= com_porterror;
			 fprotostat := prt_notrespond;
			 fcur_cmd.executed := false;
			 fcur_res.valid    := true;
			 fcur_res.id := -1;
			 fcur_res.resb[1] := ord(fcur_cmd.command);
			 fcur_res.resb[4] := $FF;
			 fcur_res.resb[2] := length(cmd_list);
			 write_result(fcur_res);
			 break; // Прервать цикл и восстановить подключение
			end; // линк упал, восстановить и повторить команду
	    end;

	    If fcur_res.valid then write_result(fcur_res);

	  // Если возникает ошибка при чтении из порта - устанавливаем
	  // состояние fstat = com_porterror и выходим из текущего блока(continue)
	  // Если устройство не отвечает вовремя
	  // устанавливаем fprotostat = prt_notrespond и выходим из текущего блока(continue)
	   end;


      //CancelIO(deviceHandle); // Прерывает последнюю асинхронную операцию
	  COM_rdy := true;
	 end;

       inc(STATE);
       If cmd_load_ev.WaitFor(4) = wrSignaled then cmd_load_ev.ResetEvent;
//      wrTimeout, wrAbandoned, wrError
      end;

      If deviceHandle <> INVALID_HANDLE_VALUE then
       FileClose(deviceHandle);
       cmd_lock.Destroy;
       res_lock.Destroy;
       cmd_load_ev.Destroy;
    end;
// ------------------------------------------------------------------------
//   cmd_lock     : TCriticalSection;
//   res_lock     : TCriticalSection;
   Function  TCOM_RGBU.Read_cmd:boolean; // Читает очередную команду в fcur_cmd и удаляет из очереди. если успешно - возвращает true
    var i: integer;
    begin
     // Если команда не выполнена из-за сбоя, новую не загружать! Если более 10 сбоев подряд - пропустить.
     If (not fcur_cmd.executed) AND (fcur_cmd.rpt < fmax_repeat) then begin result := true; exit end;
     result := false;
     cmd_lock.Acquire; { доступ к списку команд заблокирован }
     try
      If length(cmd_list) > 0 then
      begin
       fcur_cmd.id      := cmd_list[0].id;
       fcur_cmd.executed:= false;
       fcur_cmd.rpt :=0;
       fcur_cmd.command := cmd_list[0].command;
       fcur_cmd.data[0] := cmd_list[0].data[0];
       fcur_cmd.data[1] := cmd_list[0].data[1];
       fcur_cmd.data[2] := cmd_list[0].data[2];
       fcur_cmd.data[3] := cmd_list[0].data[3];
       fcur_cmd.data[4] := cmd_list[0].data[4];
       fcur_cmd.data[5] := cmd_list[0].data[5];
       fcur_cmd.data[6] := cmd_list[0].data[6];
       fcur_cmd.data[7] := cmd_list[0].data[7];

       result:= true;
       For i:= 0 to length(cmd_list)-2 do
	begin
	 cmd_list[i].id      := cmd_list[i+1].id;
	 cmd_list[i].command := cmd_list[i+1].command;
	 cmd_list[i].data[0] := cmd_list[i+1].data[0] ;
	 cmd_list[i].data[1] := cmd_list[i+1].data[1] ;
	 cmd_list[i].data[2] := cmd_list[i+1].data[2] ;
	 cmd_list[i].data[3] := cmd_list[i+1].data[3] ;
	 cmd_list[i].data[4] := cmd_list[i+1].data[4] ;
	 cmd_list[i].data[5] := cmd_list[i+1].data[5] ;
	 cmd_list[i].data[6] := cmd_list[i+1].data[6] ;
	 cmd_list[i].data[7] := cmd_list[i+1].data[7] ;
	end;
       setlength(cmd_list,length(cmd_list)-1);
      end;
     finally
      cmd_lock.Release;
     end;
    end;
// ------------------------------------------------------------------------
   Procedure TCOM_RGBU.write_result(res:TRGBU_result);
    var i,b: integer;
    begin // Добавляем результат в очередь результатов
     res_lock.Acquire; { доступ к списку результатов заблокирован}
     try
      i:=length(res_list);
      setlength(res_list,i+1);
      res_list[i].id := res.id;
      for b:=0 to 7 do res_list[i].resb[b] := res.resb[b];
     finally
      res_lock.Release; // конец критической секции
     end;
    end;
// ------------------------------------------------------------------------
   Procedure TCOM_RGBU.Flush_RX;
    begin
     purgeComm(deviceHandle,PURGE_RXCLEAR);
    end;
// ------------------------------------------------------------------------
   Function  TCOM_RGBU.COM_read_byte(var dt:byte):TRGBU_COM_result;
    var rdbytes: DWord;
    begin
     result := cr_unknown;
     If ReadFile(deviceHandle, dt, 1, rdbytes, nil) then
      begin
       If rdbytes = 1 then result := cr_sucess  // Все пучком
		      else result := cr_timeout;
      end
       else
	begin
//	 GetLastError
	 result := cr_linkfail;
	end;
    end;
// ------------------------------------------------------------------------
   Function  TCOM_RGBU.COM_send_byte(dt:byte):TRGBU_COM_result ;
    var wrbytes: DWord;
    begin
     If WriteFile(deviceHandle, dt, 1, wrbytes, nil) then
      begin
       If wrbytes = 1 then result := cr_sucess
		      else result := cr_linkfail;
      end
       else result := cr_linkfail;
    end;
// ------------------------------------------------------------------------
   procedure TCOM_RGBU.Open;
   // Открывает соединение
    begin
     fPortNum := Pnum;
     fCOMSpeed := speed;
     fmax_repeat := 10;
     If fstat <> com_notopened then exit; // Уже открыт, ничего не делать
     fopened   :=true;
     cmd_load_ev.SetEvent;  // Пускаем событие - цикл ожидания в доп.потоке прекращается!
    end;
// ------------------------------------------------------------------------
   procedure TCOM_RGBU.Close;
   // Закрывает соединение и очищает очереди
    begin
     fopened:=false;
     flush_cmd;
     flush_results;
    end;
// ------------------------------------------------------------------------
   procedure TCOM_RGBU.add_command(cmd:TRGBU_cmd);
   // Добавляет команду в очередь
    var i:integer;
    begin
    cmd_lock.Acquire; { доступ к списку команд заблокирован }
     try
      {создать в конце массива cmd_list элемент и скопировать туда все поля cmd}
      i:= length(cmd_list);
      setlength(cmd_list, i+1);
      cmd_list[i].id := cmd.id;
      cmd_list[i].command := cmd.command;
      cmd_list[i].data[0] := cmd.data[0];
      cmd_list[i].data[1] := cmd.data[1];
      cmd_list[i].data[2] := cmd.data[2];
      cmd_list[i].data[3] := cmd.data[3];
      cmd_list[i].data[4] := cmd.data[4];
      cmd_list[i].data[5] := cmd.data[5];
      cmd_list[i].data[6] := cmd.data[6];
      cmd_list[i].data[7] := cmd.data[7];
     finally
      cmd_load_ev.SetEvent;  // Пускаем событие - цикл ожидания в основном потоке прекращается!
      cmd_lock.Release;      // конец критической секции
     end;
    end;
// ------------------------------------------------------------------------
   Procedure TCOM_RGBU.add_command_test;
   var cmd:TRGBU_cmd;
    begin
     cmd.id := 0;
     cmd.command := cmd_test;
     add_command(cmd);
    end;
// ------------------------------------------------------------------------
   Procedure TCOM_RGBU.add_command_RGBU(adr,cmd,r,g,b,u:byte);
   var cmdr :TRGBU_cmd;
    begin
     cmdr.id := 1;
     cmdr.command := cmd_loadvalue;
     cmdr.data[0] := adr; cmdr.data[1] := cmd;
     cmdr.data[2] := r;   cmdr.data[3] := g;
     cmdr.data[4] := b;   cmdr.data[5] := u;
     add_command(cmdr);
    end;
// ------------------------------------------------------------------------
   Procedure TCOM_RGBU.add_command_readADC(id,ch:byte);
   var cmd:TRGBU_cmd;
    begin
     cmd.id := id;
     cmd.command := cmd_readadc;
     cmd.data[0] := ch;
     add_command(cmd);
    end;
// ------------------------------------------------------------------------
   Procedure TCOM_RGBU.add_command_pause(ms:byte);
   var cmd:TRGBU_cmd;
    begin
     cmd.id := 0;
     cmd.command := cmd_pause;
     cmd.data[0] := ms;
     add_command(cmd);
    end;
// ------------------------------------------------------------------------
   procedure TCOM_RGBU.flush_cmd;
   // очищает очередь команд
    begin
     cmd_lock.Acquire; { доступ к списку команд заблокирован }
     try
     setlength(cmd_list,0);
     finally
      cmd_lock.Release; // конец критической секции
     end;
    end;
   procedure TCOM_RGBU.flush_results;
   // очищает очередь результатов
    begin
     res_lock.Acquire; { доступ к списку результатов заблокирован}
     try
     setlength(res_list,0);
     finally
      res_lock.Release; // конец критической секции
     end;
     // конец критической секции
    end;
// ------------------------------------------------------------------------
   function  TCOM_RGBU.get_results(var res:TRGBU_result):boolean;
   // Возвращает очередной результат выполнения команды, если команда предполагает наличие результата
   var i:integer;
    begin
     res_lock.Acquire; { доступ к списку результатов заблокирован}
     try
     If length(res_list) > 0 then
      begin
       result := true;
       res.id      := res_list[0].id;
       res.valid   := res_list[0].valid;
       res.resw[0] := res_list[0].resw[0];
       res.resw[1] := res_list[0].resw[1];
       res.resw[2] := res_list[0].resw[2];
       res.resw[3] := res_list[0].resw[3];
       For i := 0 to length(res_list)-2 do
	begin
	 res_list[i].id      := res_list[i+1].id;
	 res_list[i].valid   := res_list[i+1].valid;
	 res_list[i].resw[0] := res_list[i+1].resw[0];
	 res_list[i].resw[1] := res_list[i+1].resw[1];
	 res_list[i].resw[2] := res_list[i+1].resw[2];
	 res_list[i].resw[3] := res_list[i+1].resw[3];
	end;
	setlength(res_list,length(res_list)-1);
      end else result := false; // больше результатов нет
     finally
      res_lock.Release; // конец критической секции
     end;
    end;











// ------------------------------------------------------------------------

   function TCOM_RGBU.frun_pause;
   var st: TRGBU_linkstate;
    begin
     st:= fstat;
     fstat := com_Executing;
     FLUSH_RX;
     sleep(fcur_cmd.data[0]);
     result := cr_sucess;
     fstat := st;
    end;

// ------------------------------------------------------------------------

   function TCOM_RGBU.frun_testcmd;   // обработка команды из fcur_cmd в fcur_res.
   var st: TRGBU_linkstate;
       re: TRGBU_COM_result;
       b : byte;
    begin
     st:= fstat;
     // 0. очистить очередь приема
     FLUSH_RX;
     // 1. Передаем команду "TEST";
     fstat := com_Executing;
     If COM_send_byte(HLCMD_test) = cr_linkfail then
      begin
       result:= cr_linkfail; fstat := st; exit;
      end;
     // 2. ждем ответа
     fstat := com_WaitReply;
     re := COM_read_byte(b);
     case re of
      cr_timeout : begin result:= cr_timeout; fstat := st; exit; end;
      cr_linkfail,
      cr_unknown : begin result:= cr_linkfail; fstat := st; exit; end;
     end;
      case b of
       HLCMD_SUCCESS: result := cr_sucess;
       HLCMD_FAILED : result := cr_errcmd;
      else            result := cr_unknown;
      end;
      fstat := st;
    end;
// ------------------------------------------------------------------------
   function TCOM_RGBU.frun_loadvalue; // обработка команды из fcur_cmd в fcur_res.
   var st: TRGBU_linkstate;
       re: TRGBU_COM_result;
       b : byte;
    begin
     st:= fstat;
     // 0. очистить очередь приема
     FLUSH_RX;
     // 1. Передаем команду "вывод канала RGBU";
     fstat := com_Executing;
     If COM_send_byte(HLCMD_load) = cr_linkfail then
      begin
       result:= cr_linkfail; fstat := st; exit;
      end;
     // 2. ждем предложения к вводу
     fstat := com_WaitReply;
     re := COM_read_byte(b);
     case re of
      cr_timeout : begin result:= cr_timeout;  fstat := st; exit; end;
      cr_linkfail,
      cr_unknown : begin result:= cr_linkfail; fstat := st; exit; end;
     end;
      case b of
       HLCMD_INPUT: result := cr_sucess;
       HLCMD_FAILED : begin result := cr_errcmd;  fstat := st; exit end;
      else            begin result := cr_unknown; fstat := st; exit end;
      end;
     // 3. выводим fcur_cmd.data[0..5]
     fstat := com_Executing;
     // Адрес устройства
     If COM_send_byte(fcur_cmd.data[0]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // Команда устройству - "Установить яркость"
     If COM_send_byte(fcur_cmd.data[1]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // R-канал
     If COM_send_byte(fcur_cmd.data[2]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // G-канал
     If COM_send_byte(fcur_cmd.data[3]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // B-канал
     If COM_send_byte(fcur_cmd.data[4]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // U-канал
     If COM_send_byte(fcur_cmd.data[5]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;

     // 4. ждем ответ
     fstat := com_WaitReply;
     re := COM_read_byte(b);
     case re of
      cr_timeout : begin result:= cr_timeout;  fstat := st; exit; end;
      cr_linkfail,
      cr_unknown : begin result:= cr_linkfail; fstat := st; exit; end;
     end;
      case b of
       HLCMD_SUCCESS: result := cr_sucess;
       HLCMD_FAILED : result := cr_errcmd;
      else            result := cr_unknown;
      end;

     fstat := st;
    end;
// ------------------------------------------------------------------------
   function TCOM_RGBU.frun_readadc;   // обработка команды из fcur_cmd в fcur_res.
   var st: TRGBU_linkstate;
       re: TRGBU_COM_result;
       b : byte;
    begin
     st:= fstat;
     // 0. очистить очередь приема
     FLUSH_RX;
     // 1. Передаем команду "чтение АЦП";
     fstat := com_Executing;
     If COM_send_byte(HLCMD_ADC) = cr_linkfail then
      begin
       result:= cr_linkfail; fstat := st; exit;
      end;
     // 2. ждем предложения к вводу
     fstat := com_WaitReply;
     re := COM_read_byte(b);
     case re of
      cr_timeout : begin result:= cr_timeout;  fstat := st; exit; end;
      cr_linkfail,
      cr_unknown : begin result:= cr_linkfail; fstat := st; exit; end;
     end;
      case b of
       HLCMD_INPUT: result := cr_sucess;
       HLCMD_FAILED : begin result := cr_errcmd;  fstat := st; exit end;
      else            begin result := cr_unknown; fstat := st; exit end;
      end;
     // 3. передаем номер канала   fcur_cmd.data[0];
     fstat := com_Executing;
     // Номер канала
     If COM_send_byte(fcur_cmd.data[0]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // 4. ждем 2 байта ответа.    fcur_res.resw[0];
     fstat := com_WaitReply;
     re := COM_read_byte(b);
     case re of
      cr_timeout : begin result:= cr_timeout;  fstat := st; exit; end;
      cr_linkfail,
      cr_unknown : begin result:= cr_linkfail; fstat := st; exit; end;
     end;
     fcur_res.resb[0] := b;
     
     re := COM_read_byte(b);
     case re of
      cr_timeout : begin result:= cr_timeout;  fstat := st; exit; end;
      cr_linkfail,
      cr_unknown : begin result:= cr_linkfail; fstat := st; exit; end;
     end;
     fcur_res.resb[1] := b;


     fcur_res.id := fcur_cmd.id;
     fcur_res.valid   := true; // результат засчитать

     result:= cr_sucess; fstat := st;
    end;
// =================================================================
//               Конец определения объекта потока                  |
// =================================================================

initialization
MODULE := TCOM_RGBU.Create(true);
MODULE.Priority := tpLower;
MODULE.FreeOnTerminate := false;
MODULE.Resume;

finalization
If not MODULE.Terminated then MODULE.Terminate;
MODULE.Free;

// SecondThread := TMyThread.Create(false); - запускает поток на выполнение немедленно

// ИЛИ:
//SecondThread :=  TMyThread.Create(True); { create but don't run }
//SecondThread.Priority := tpLower; { set the priority lower than normal }
//SecondThread.Resume; { now run the thread }


//Достаточно объявить и создать глобальную переменную CriticalSection: TCriticalSection (если вы используете класс VCL) в модуле, который виден (т.е. присутствует в uses) всем потокам.
//И каждое действие с файлом заключать в
//CriticalSection.Enter
//try
////действия с файлом
//finally
//  CriticalSection.Leave;
//end;
//



//LockXY:  TCriticalSection
//LockXY.Acquire; { lock out other threads }
//try
//  Y := sin(X);
//finally
//  LockXY.Release;
//end;



//Один из них должен иметь возможность "повесить" второй. Ничего сложного. Ивенты помогут. CreateEvent или TEvent из модуля syncobjs. Создать на WinAPI событие -
//
//hEvent:=CreateEvent(nil,true,true,nil);
//(создали событие без имени с правами по умолчанию, управляемое SetEvent и ResetEvent, начальное состояние - стоит). В "главном" потоке (который вы считаете главным, а не поток, отвечающий за пользовательский интерфейс) Вы в местах, где можете сделать "паузу" ставите код
//
//WaitForSingleObject(hEvent,INFINITE);
//(разумеется, hEvent должен быть глобальной переменной (очень плохо), свойством или полем главной формы (тоже не очень хорошо), или передаваться потоку через конструктор (если создается поток средствами VCL), или через указатель или одно из полей структуры, на которую указывает указатель, передаваемый в поток (если поток создается средствами WinAPI)). Соответственно, где угодно Вы можете "заморозить" поток, выполнив ResetEvent(hEvent) и разморозить, вызвав SetEvent(hEvent) По завершению работы (в том числе и всех потоков) надо обязательно вызвать
//
//CloseHandle(hEvent)









//Создавать окно только для получения сообщений не имеет смысла (хотя учитывая предысторию чекнутого соседа, вполне допустимо :) Посылать сообщения потоку можно используя PostThreadMessage ну а внутри потока организуете обработку сообщений точно также как и для окна. Хотя и это не нужно.
//
//Можно использовать объект синхронизации, Event. Для начала определимся что вам нужно: вам нужно, чтобы пока один поток пишит общие данные, другие потоки их не могли читать.
//Cоздаёте событие
//
//Event := CreateEvent(nil, False, True, nil);
//Первый параметр False говорит о том, что событие сбрасывается автоматически, второй параметр True говорит о том, что после создания событие установлено.
//Каждый поток для обмена данными должен делать следующее:
//
//begin
//  // Ждем, пока будет установлен Event, и сразуже сбрасываем его (автоматически)
//  Windows.WaitForSingleObject(Event, INFINITE);
//  try
//    ...
//    // Записываем или читаем данные не боясь, что другой поток их испортит
//    ...
//  finally
//    // Устанавливаем Event
//    SetEvent(Event);
//  end;
//end;










{procedure TForm1.Button1Click(Sender: TObject);
begin
deviceHandle:=CreateFile(PChar('\\.\COM2'), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
в случае ошибки возвращает INVALID_HANDLE_VALUE.
 особого пояснения требует dwFlagsAndAttributes. Работа с портом может быть
 организована в синхронном (nonoverlapped) или асинхронном (overlapped) режимах
 обработки, что и задается этим флагом. При синхронном режиме (когда параметр
 dwFlagsAndAttributes = 0) только один поток приложения может либо читать, либо
 писать в порт.
end;

function read_write_str(devicehandle: THandle; command: Pointer; commandlenght: DWord): string;
var
  inputReportBuffer: array of Byte;
  inputReportBuffer_element: Byte;
  rest: string;
  n: integer;
  success: boolean;
  unManagedBuffer: Pointer;
  numberOfBytesRead: Cardinal;
  numberOfBytesWritten: Cardinal;
begin
  GetMem(unManagedBuffer, sizeOf(inputReportBuffer));
  numberOfBytesRead := 0;
  numberOfBytesWritten := 0;

  success := WriteFile(devicehandle, command^, commandlenght, numberOfBytesWritten, nil);
  Sleep(50);

  SetLength(inputReportBuffer, 1);
  ReadFile(devicehandle, PChar(inputReportBuffer)^, 1, numberOfBytesRead, nil);
  while numberOfBytesRead > 0 do
  begin
    rest := rest + Chr(inputReportBuffer[0]);
    ReadFile(devicehandle, PChar(inputReportBuffer)^, 1, numberOfBytesRead, nil);
  end;
  result:=rest;
end;

procedure RSSI;
var
  StrCSQ2: string;
  StrCSQ: String;
begin
  StrCSQ2:=(read_write_str(devicehandle, PChar('AT+CSQ'+Char($0D)), 9));
  form1.Caption:='Naycu-'+StrCSQ2;
  if StrCSQ<>StrCSQ2 then
  begin
    StrCSQ:=StrCSQ2;
    form1.Memo1.Lines.Add(StrCSQ);
  end;
end;}


end.
