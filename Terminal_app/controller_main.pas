unit controller_main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ALed, ExtCtrls, Spin, Gauges, ComCtrls, Digit;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    Timer1: TTimer;
    hhALed1: ThhALed;
    hhALed2: ThhALed;
    hhALed3: ThhALed;
    hhALed4: ThhALed;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    hhALed5: ThhALed;
    Label10: TLabel;
    Label11: TLabel;
    hhALed6: ThhALed;
    Label12: TLabel;
    COMst: TLabel;
    COMsel: TComboBox;
    Lerrcnt: TLabel;
    Lretrycnt: TLabel;
    TrackBar1: TTrackBar;
    Label14: TLabel;
    PaintBox1: TPaintBox;
    digit1: Tdigit;
    digit2: Tdigit;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Label3: TLabel;
    hhALed7: ThhALed;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Edit2Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const addrs : array[0..8] of byte = (1,2,3,4,5,6,7,8,16);   

var
  Form1: TForm1;
  ADCVal1, ADCVal2, ADCVal3, ADCVal4, ADCVal5, ADCVal6:integer;

implementation
uses COM2RGBU_wrap;

//Type data_source = object
//      private
//       f_file : file;
//
//      public
//       count  : integer;
//       values : integer;
//       Procedure Create(FileName: string);
//       Procedure Reset;
//       Procedure NextData;
//      published
//     end;

var last_Plen : byte;
    cntr      : integer;
    last      : longint;
    r_last    : longint;
    F: textfile;
    FFileOpen : boolean;
    time1, time2 : Tdatetime;
{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
 assignfile(F,'pattern.txt');
 reset(f); digit1.Value :=0; digit2.Value :=0;
 FFileOpen := True;
 If COMsel.ItemIndex >=0 then
  begin
   Module.Open(COMsel.ItemIndex+1,br57600);
   COMsel.Enabled := false;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
 Module.Close;
 COMsel.Enabled := true;
 FFileOpen := false;
 closefile(f);
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var r : TRGBU_result;
    Vr,Vg,Vb,Vu : byte;
    st:string;
    mst: string;
    vst:string;
    adr, posi: integer;

begin
// r_last:= module.STATE;
// memo1.Lines.add(inttostr(r_last-last));
// last:=r_last;
 If module.com_rdy        then hhaled1.Value := true else hhaled1.Value := false;
 If module.COM_error <> 0 then hhaled2.Value := true else hhaled2.Value := false;
 If module.COM_retry <> 0 then hhaled3.Value := true else hhaled3.Value := false;
 Lerrcnt.Caption   := inttostr(module.COM_error);
 Lretrycnt.Caption := inttostr(module.COM_retry);

 case module.COM_stat of
   com_notopened: begin hhaled4.Value := false;                               COMst.Caption := 'not opened' end;
   com_porterror: begin hhaled4.Value := true; hhaled4.trueColor := clred;    COMst.Caption := 'ERROR' end;
   com_ready    : begin hhaled4.Value := true; hhaled4.trueColor := clLime;   COMst.Caption := 'Ready' end;
   com_Executing: begin hhaled4.Value := true; hhaled4.trueColor := clblue;   COMst.Caption := 'Transmit'  end;
   com_waitreply: begin hhaled4.Value := true; hhaled4.trueColor := clYellow; COMst.Caption := 'Receive wait' end;
 end;
 case module.Protocol_stat of
  prt_active    : begin hhaled5.Value := true;  hhaled5.trueColor := cllime;end;
  prt_notrespond: begin hhaled5.Value := false; hhaled5.trueColor := clred; end;
 end;
 If module.Opened then hhaled6.Value := true else hhaled6.Value := false;

 While Module.get_results(r) do
  begin
   case r.id of
    100: begin ADCVal1 := r.resw[0]; end;
    101: begin ADCVal2 := r.resw[0]; end;
    102: begin ADCVal3 := r.resw[0]; end;
    103: begin ADCVal4 := r.resw[0]; end;
    104: begin ADCVal5 := r.resw[0]; end;
    105: begin ADCVal6 := r.resw[0]; end;
    -1 : begin
          If r.resb[7] = $FF then memo1.Lines.Add(timetostr(now)+'Команда 0x'+IntToHex(r.resb[7],2)+' - не распознана в очереди.') else
           if r.resb[6] = $FF then memo1.Lines.Add(timetostr(now)+'Команда 0x'+IntToHex(r.resb[7],2)+' - неизвестная ошибка при выполнении команды.') else
            if r.resb[5] = $FF then memo1.Lines.Add(timetostr(now)+'Команда 0x'+IntToHex(r.resb[7],2)+' - Тайм-аут при выполнении команды. Длина очереди: '+inttostr(r.resb[2])) else
             if r.resb[4] = $FF then memo1.Lines.Add(timetostr(now)+'Команда 0x'+IntToHex(r.resb[7],2)+' - Потеря связи при выполнении команды. Длина очереди: '+inttostr(r.resb[2])) else
              memo1.Lines.Add(timetostr(now)+'Рез.ИД: '+inttostr(r.id)+' Data: '+
                     IntToHex(r.resw[0],4) + ' ' + IntToHex(r.resw[1],4)+ ' '+
                     IntToHex(r.resw[2],4) + ' ' + IntToHex(r.resw[3],4));
         end
    else
    memo1.Lines.Add('Рез.ИД:'+inttostr(r.id)+' Data: '+
     IntToHex(r.resw[0],4) + ' ' + IntToHex(r.resw[1],4)+ ' '+
     IntToHex(r.resw[2],4) + ' ' + IntToHex(r.resw[3],4));
   end;

  end;

   module.COM_error := 0;
   module.COM_retry := 0;


 hhAled7.Value := ((frac(now) < frac(time1) ) or (frac(now) > frac(time2))); // время в рабочем диапазоне
// memo1.Lines.add(timetostr(now)+'  '+timetostr(time1)+'  '+timetostr(time2));

 If (module.COM_stat = com_Ready) and (module.Protocol_stat = prt_active) and hhAled7.Value then
  begin
   If FFileOpen then
   If not EOF(f) then
     begin
      readln(f,st);
      digit1.Value := digit1.Value + 1;
      If digit2.Value < digit1.Value then digit2.Value := digit1.Value;
     end
    else
     begin
      closefile(f);
      sleep(100);
      reset(f);
      digit1.Value := 0;
     end;

// Разберем строку по частям... одна строка - один набор состояний для всех светодиодов.
// <R1>,<G1>,<B1>,<U1>; <R2>,<G2>,<B2>,<U2>; ....  <Rn>,<Gn>,<Bn>,<Un>
   adr := 0;
   If (length(st) > 2) and (copy(st,1,1) <> ';') then
   repeat  // Цикл по модулям
    posi := pos(';',st); If posi = 0 then posi := length(st);
    mst := trim(copy(st,1,posi-1)); st:= trim(copy(st,posi+1,length(st)));
    // Считываем макс.4 значения
     // R
     posi := pos(',',mst); If posi = 0 then posi := length(mst);
     vst := trim(copy(mst,1,posi-1)); mst := trim(copy(mst,posi+1,length(mst)));
     Vr := strtointdef(vst,0);
     // G
     posi := pos(',',mst); If posi = 0 then posi := length(mst);
     vst := trim(copy(mst,1,posi-1)); mst := trim(copy(mst,posi+1,length(mst)));
     Vg := strtointdef(vst,0);
     // B
     posi := pos(',',mst); If posi = 0 then posi := length(mst);
     vst := trim(copy(mst,1,posi-1)); mst := trim(copy(mst,posi+1,length(mst)));
     Vb := strtointdef(vst,0);
     // U
     posi := pos(',',mst); If posi = 0 then posi := length(mst);
     vst := trim(copy(mst,1,posi-1)); mst := trim(copy(mst,posi+1,length(mst)));
     Vu := strtointdef(vst,0);

     If (adr >=0) and (adr <= length(addrs)) then Module.add_command_RGBU(addrs[adr],$21,Vr,Vg,Vb,Vu);
     inc(adr);

   until (length(st) < 1) or (adr >= length(addrs));

//   1 раз в сек?
//   Module.add_command_readADC(100,0);
//   Module.add_command_readADC(101,1);
//   Module.add_command_readADC(102,2);
//   Module.add_command_readADC(103,3);
//   Module.add_command_readADC(104,4);
//   Module.add_command_readADC(105,5);
  end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
 Timer1.Enabled:= false;
 Timer1.Interval := TrackBar1.Position;
 Timer1.Enabled:= true;
 Label14.Caption := 'Интервал: '+inttostr(TrackBar1.Position);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 time1 := strtotime(Edit1.text);
 time2 := strtotime(Edit2.text);
 If paramstr(1) = 'start' then Button1Click(Sender);
end;

procedure TForm1.Edit1Change(Sender: TObject);
begin
 time1 := strtotime(Edit1.text);
end;

procedure TForm1.Edit2Change(Sender: TObject);
begin
 time2 := strtotime(Edit2.text);
end;

end.
