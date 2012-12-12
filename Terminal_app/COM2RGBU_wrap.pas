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
   id      : integer; // ��� ����������
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
   Function  Read_cmd:boolean; // ������ ��������� ������� � fcur_cmd � ������� �� �������. ���� ������� - ���������� true
   Procedure write_result(res:TRGBU_result);
   Procedure Flush_RX;
   Function  COM_read_byte(var dt:byte):TRGBU_COM_result;
   Function  COM_send_byte(    dt:byte):TRGBU_COM_result;
   procedure add_command(cmd:TRGBU_cmd); // ��������� ������� � �������
   function frun_testcmd  :TRGBU_COM_result;   // ��������� ������ �� fcur_cmd � fcur_res.
   function frun_loadvalue:TRGBU_COM_result;
   function frun_readadc  :TRGBU_COM_result;
   function frun_pause    :TRGBU_COM_result;

  protected
   Procedure Execute; override;
  public
   STATE        : longint; // !!!! �������
   COM_rdy      : boolean; // ���������� ������ � ������ ������, false - ����������� ������� ������.
   COM_error    : integer; // ���������� ������ ����������� � �����
   COM_retry    : integer; // ���������� �������� ������������ � �����������

   procedure Open(Pnum: integer; speed:TBaudRate);  // ��������� ����������
   procedure Close;			    // ��������� ���������� � ������� �������
   procedure flush_cmd;         // ������� ������� ������ � �����������
   procedure flush_results;
   function  get_results(var res:TRGBU_result):boolean; // ���������� ��������� ��������� ���������� �������, ���� ������� ������������ ������� ����������
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
     fcur_cmd.executed:= true; // ������ ������� ������� �����������

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
	 sleep(20); // ����� ����� ��������...
	end;

       If (fopened = true) and (fstat = com_notopened) then
	begin  // ���� ������ ���� ������ �� ��� �� ������ - ������� ����.
	 deviceHandle:=CreateFile(PChar('\\.\COM'+IntToStr(fPortNum)), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
	 If deviceHandle = INVALID_HANDLE_VALUE then fstat := com_porterror
      else
       begin // ���� ������ �������, ���� ��������� �����.
	GetCommState(deviceHandle, Dcb);
	Dcb.BaudRate := DWORD(fCOMSpeed);
	Dcb.Parity := NOPARITY;
	Dcb.ByteSize := 8;
	Dcb.StopBits := ONESTOPBIT;
	SetCommState(deviceHandle, Dcb);
	// ������� ��������
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
	begin // ���� ������ ���� ������ �� ��� ������ - ������� ����.
	 FileClose(deviceHandle);
	 deviceHandle := INVALID_HANDLE_VALUE;
	 fstat := com_notopened;
	 fprotostat := prt_notrespond;
	 COM_rdy   := false;
	end;

       If (fstat = com_ready) and (fprotostat = prt_notrespond) then
	begin
	 inc(COM_retry);
	 //�������� �������� ����� - ���� ���� �����, �������� ������.
	 FLUSH_RX;
	  // 1. �������� ������� "TEST";
	 If COM_send_byte(HLCMD_test) = cr_linkfail then fstat := com_porterror
	 else
	  begin
	   // 2. ���� ������
	   fstat := com_WaitReply;
	   re := COM_read_byte(b);
	   case re of // ��������� ������
	    cr_sucess  :{����� ����         }
	       begin
		If b = HLCMD_SUCCESS then fprotostat := prt_active
				     else begin fprotostat := prt_notrespond; sleep(10);end;
		fstat := com_ready;     
	       end;
	    cr_timeout :{�� �������� �������} begin fprotostat := prt_notrespond; sleep(10); fstat := com_ready end;
			{�� ���� � �������  }
	    cr_linkfail,{������ ������ � ����, ������ ����� ���� ����� �� ����������}
	    cr_unknown : begin fprotostat := prt_notrespond; fstat := com_porterror end;
	   end;
	  end;
	 If fprotostat = prt_active then COM_rdy := true;
	end;

	If (fstat = com_ready) and  (fprotostat = prt_active)
	    // ���� ���� �������� � ���������� ��������, ��...
	   then
	 If length(cmd_list)>0 then
	 begin  // ���� ���� ������� � �������...
	  COM_rdy := false;
	  // ��������� ��������� ������� �� ������� ��������� �� � ������� ��������
	  while Read_cmd and (not Terminated)do
	   begin
	    // ��������� ������� ��������� � fcur_cmd
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
			end; // ������� �� ����������, �� � �������� ����� ������� �� �������
	     cr_unknown:begin
			 fcur_cmd.executed := true;
			 fcur_res.valid    := true;
			 fcur_res.id := -1;
			 fcur_res.resb[1] := ord(fcur_cmd.command);
			 fcur_res.resb[6] := $FF;
			end; // ���������� ������, ������� ����� ������� �� �������
	     cr_timeout:begin
			 fprotostat := prt_notrespond;
			 fcur_cmd.executed := false;
			 fcur_res.valid    := true;
			 fcur_res.id := -1;
			 fcur_res.resb[1] := ord(fcur_cmd.command);
			 fcur_res.resb[5] := $FF;
			 fcur_res.resb[2] := length(cmd_list);
			 write_result(fcur_res);
			 break; // �������� ���� � ������������ �����
			end; // �������, ������� ���������
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
			 break; // �������� ���� � ������������ �����������
			end; // ���� ����, ������������ � ��������� �������
	    end;

	    If fcur_res.valid then write_result(fcur_res);

	  // ���� ��������� ������ ��� ������ �� ����� - �������������
	  // ��������� fstat = com_porterror � ������� �� �������� �����(continue)
	  // ���� ���������� �� �������� �������
	  // ������������� fprotostat = prt_notrespond � ������� �� �������� �����(continue)
	   end;


      //CancelIO(deviceHandle); // ��������� ��������� ����������� ��������
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
   Function  TCOM_RGBU.Read_cmd:boolean; // ������ ��������� ������� � fcur_cmd � ������� �� �������. ���� ������� - ���������� true
    var i: integer;
    begin
     // ���� ������� �� ��������� ��-�� ����, ����� �� ���������! ���� ����� 10 ����� ������ - ����������.
     If (not fcur_cmd.executed) AND (fcur_cmd.rpt < fmax_repeat) then begin result := true; exit end;
     result := false;
     cmd_lock.Acquire; { ������ � ������ ������ ������������ }
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
    begin // ��������� ��������� � ������� �����������
     res_lock.Acquire; { ������ � ������ ����������� ������������}
     try
      i:=length(res_list);
      setlength(res_list,i+1);
      res_list[i].id := res.id;
      for b:=0 to 7 do res_list[i].resb[b] := res.resb[b];
     finally
      res_lock.Release; // ����� ����������� ������
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
       If rdbytes = 1 then result := cr_sucess  // ��� ������
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
   // ��������� ����������
    begin
     fPortNum := Pnum;
     fCOMSpeed := speed;
     fmax_repeat := 10;
     If fstat <> com_notopened then exit; // ��� ������, ������ �� ������
     fopened   :=true;
     cmd_load_ev.SetEvent;  // ������� ������� - ���� �������� � ���.������ ������������!
    end;
// ------------------------------------------------------------------------
   procedure TCOM_RGBU.Close;
   // ��������� ���������� � ������� �������
    begin
     fopened:=false;
     flush_cmd;
     flush_results;
    end;
// ------------------------------------------------------------------------
   procedure TCOM_RGBU.add_command(cmd:TRGBU_cmd);
   // ��������� ������� � �������
    var i:integer;
    begin
    cmd_lock.Acquire; { ������ � ������ ������ ������������ }
     try
      {������� � ����� ������� cmd_list ������� � ����������� ���� ��� ���� cmd}
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
      cmd_load_ev.SetEvent;  // ������� ������� - ���� �������� � �������� ������ ������������!
      cmd_lock.Release;      // ����� ����������� ������
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
   // ������� ������� ������
    begin
     cmd_lock.Acquire; { ������ � ������ ������ ������������ }
     try
     setlength(cmd_list,0);
     finally
      cmd_lock.Release; // ����� ����������� ������
     end;
    end;
   procedure TCOM_RGBU.flush_results;
   // ������� ������� �����������
    begin
     res_lock.Acquire; { ������ � ������ ����������� ������������}
     try
     setlength(res_list,0);
     finally
      res_lock.Release; // ����� ����������� ������
     end;
     // ����� ����������� ������
    end;
// ------------------------------------------------------------------------
   function  TCOM_RGBU.get_results(var res:TRGBU_result):boolean;
   // ���������� ��������� ��������� ���������� �������, ���� ������� ������������ ������� ����������
   var i:integer;
    begin
     res_lock.Acquire; { ������ � ������ ����������� ������������}
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
      end else result := false; // ������ ����������� ���
     finally
      res_lock.Release; // ����� ����������� ������
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

   function TCOM_RGBU.frun_testcmd;   // ��������� ������� �� fcur_cmd � fcur_res.
   var st: TRGBU_linkstate;
       re: TRGBU_COM_result;
       b : byte;
    begin
     st:= fstat;
     // 0. �������� ������� ������
     FLUSH_RX;
     // 1. �������� ������� "TEST";
     fstat := com_Executing;
     If COM_send_byte(HLCMD_test) = cr_linkfail then
      begin
       result:= cr_linkfail; fstat := st; exit;
      end;
     // 2. ���� ������
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
   function TCOM_RGBU.frun_loadvalue; // ��������� ������� �� fcur_cmd � fcur_res.
   var st: TRGBU_linkstate;
       re: TRGBU_COM_result;
       b : byte;
    begin
     st:= fstat;
     // 0. �������� ������� ������
     FLUSH_RX;
     // 1. �������� ������� "����� ������ RGBU";
     fstat := com_Executing;
     If COM_send_byte(HLCMD_load) = cr_linkfail then
      begin
       result:= cr_linkfail; fstat := st; exit;
      end;
     // 2. ���� ����������� � �����
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
     // 3. ������� fcur_cmd.data[0..5]
     fstat := com_Executing;
     // ����� ����������
     If COM_send_byte(fcur_cmd.data[0]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // ������� ���������� - "���������� �������"
     If COM_send_byte(fcur_cmd.data[1]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // R-�����
     If COM_send_byte(fcur_cmd.data[2]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // G-�����
     If COM_send_byte(fcur_cmd.data[3]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // B-�����
     If COM_send_byte(fcur_cmd.data[4]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // U-�����
     If COM_send_byte(fcur_cmd.data[5]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;

     // 4. ���� �����
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
   function TCOM_RGBU.frun_readadc;   // ��������� ������� �� fcur_cmd � fcur_res.
   var st: TRGBU_linkstate;
       re: TRGBU_COM_result;
       b : byte;
    begin
     st:= fstat;
     // 0. �������� ������� ������
     FLUSH_RX;
     // 1. �������� ������� "������ ���";
     fstat := com_Executing;
     If COM_send_byte(HLCMD_ADC) = cr_linkfail then
      begin
       result:= cr_linkfail; fstat := st; exit;
      end;
     // 2. ���� ����������� � �����
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
     // 3. �������� ����� ������   fcur_cmd.data[0];
     fstat := com_Executing;
     // ����� ������
     If COM_send_byte(fcur_cmd.data[0]) = cr_linkfail then begin result:= cr_linkfail; fstat := st; exit; end;
     // 4. ���� 2 ����� ������.    fcur_res.resw[0];
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
     fcur_res.valid   := true; // ��������� ���������

     result:= cr_sucess; fstat := st;
    end;
// =================================================================
//               ����� ����������� ������� ������                  |
// =================================================================

initialization
MODULE := TCOM_RGBU.Create(true);
MODULE.Priority := tpLower;
MODULE.FreeOnTerminate := false;
MODULE.Resume;

finalization
If not MODULE.Terminated then MODULE.Terminate;
MODULE.Free;

// SecondThread := TMyThread.Create(false); - ��������� ����� �� ���������� ����������

// ���:
//SecondThread :=  TMyThread.Create(True); { create but don't run }
//SecondThread.Priority := tpLower; { set the priority lower than normal }
//SecondThread.Resume; { now run the thread }


//���������� �������� � ������� ���������� ���������� CriticalSection: TCriticalSection (���� �� ����������� ����� VCL) � ������, ������� ����� (�.�. ������������ � uses) ���� �������.
//� ������ �������� � ������ ��������� �
//CriticalSection.Enter
//try
////�������� � ������
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



//���� �� ��� ������ ����� ����������� "��������" ������. ������ ��������. ������ �������. CreateEvent ��� TEvent �� ������ syncobjs. ������� �� WinAPI ������� -
//
//hEvent:=CreateEvent(nil,true,true,nil);
//(������� ������� ��� ����� � ������� �� ���������, ����������� SetEvent � ResetEvent, ��������� ��������� - �����). � "�������" ������ (������� �� �������� �������, � �� �����, ���������� �� ���������������� ���������) �� � ������, ��� ������ ������� "�����" ������� ���
//
//WaitForSingleObject(hEvent,INFINITE);
//(����������, hEvent ������ ���� ���������� ���������� (����� �����), ��������� ��� ����� ������� ����� (���� �� ����� ������), ��� ������������ ������ ����� ����������� (���� ��������� ����� ���������� VCL), ��� ����� ��������� ��� ���� �� ����� ���������, �� ������� ��������� ���������, ������������ � ����� (���� ����� ��������� ���������� WinAPI)). ��������������, ��� ������ �� ������ "����������" �����, �������� ResetEvent(hEvent) � �����������, ������ SetEvent(hEvent) �� ���������� ������ (� ��� ����� � ���� �������) ���� ����������� �������
//
//CloseHandle(hEvent)









//��������� ���� ������ ��� ��������� ��������� �� ����� ������ (���� �������� ����������� ��������� ������, ������ ��������� :) �������� ��������� ������ ����� ��������� PostThreadMessage �� � ������ ������ ����������� ��������� ��������� ����� ����� ��� � ��� ����. ���� � ��� �� �����.
//
//����� ������������ ������ �������������, Event. ��� ������ ����������� ��� ��� �����: ��� �����, ����� ���� ���� ����� ����� ����� ������, ������ ������ �� �� ����� ������.
//C������ �������
//
//Event := CreateEvent(nil, False, True, nil);
//������ �������� False ������� � ���, ��� ������� ������������ �������������, ������ �������� True ������� � ���, ��� ����� �������� ������� �����������.
//������ ����� ��� ������ ������� ������ ������ ���������:
//
//begin
//  // ����, ���� ����� ���������� Event, � ������� ���������� ��� (�������������)
//  Windows.WaitForSingleObject(Event, INFINITE);
//  try
//    ...
//    // ���������� ��� ������ ������ �� �����, ��� ������ ����� �� ��������
//    ...
//  finally
//    // ������������� Event
//    SetEvent(Event);
//  end;
//end;










{procedure TForm1.Button1Click(Sender: TObject);
begin
deviceHandle:=CreateFile(PChar('\\.\COM2'), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
� ������ ������ ���������� INVALID_HANDLE_VALUE.
 ������� ��������� ������� dwFlagsAndAttributes. ������ � ������ ����� ����
 ������������ � ���������� (nonoverlapped) ��� ����������� (overlapped) �������
 ���������, ��� � �������� ���� ������. ��� ���������� ������ (����� ��������
 dwFlagsAndAttributes = 0) ������ ���� ����� ���������� ����� ���� ������, ����
 ������ � ����.
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
