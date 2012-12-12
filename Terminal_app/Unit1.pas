unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ALed, ExtCtrls, Spin, Gauges, ComCtrls;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Button2: TButton;
    Timer1: TTimer;
    SpinAddr: TSpinEdit;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
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
    Gauge1: TGauge;
    Gauge2: TGauge;
    Gauge4: TGauge;
    Gauge3: TGauge;
    Gauge6: TGauge;
    Gauge5: TGauge;
    Lerrcnt: TLabel;
    Lretrycnt: TLabel;
    SpinR: TScrollBar;
    SpinG: TScrollBar;
    SpinB: TScrollBar;
    SpinU: TScrollBar;
    Button3: TButton;
    Label13: TLabel;
    SpinAddrNew: TSpinEdit;
    TrackBar1: TTrackBar;
    Label14: TLabel;
    ComboR: TComboBox;
    ComboG: TComboBox;
    ComboB: TComboBox;
    ComboU: TComboBox;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Bevel5: TBevel;
    Bevel6: TBevel;
    Bevel7: TBevel;
    Bevel8: TBevel;
    Bevel9: TBevel;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure SpinAddrNewChange(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  ADCVal1, ADCVal2, ADCVal3, ADCVal4, ADCVal5, ADCVal6:integer;
implementation
uses COM2RGBU_wrap;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
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
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var r : TRGBU_result;
    Vr,Vg,Vb,Vu : byte;
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
    100: begin Gauge1.Progress := r.resw[0]; ADCVal1 := r.resw[0]; end;
    101: begin Gauge2.Progress := r.resw[0]; ADCVal2 := r.resw[0]; end;
    102: begin Gauge3.Progress := r.resw[0]; ADCVal3 := r.resw[0]; end;
    103: begin Gauge4.Progress := r.resw[0]; ADCVal4 := r.resw[0]; end;
    104: begin Gauge5.Progress := r.resw[0]; ADCVal5 := r.resw[0]; end;
    105: begin Gauge6.Progress := r.resw[0]; ADCVal6 := r.resw[0]; end;
    -1 : begin
          If r.resb[7] = $FF then memo1.Lines.Add('Команда 0x'+IntToHex(r.resb[7],2)+' - не распознана в очереди.') else
           if r.resb[6] = $FF then memo1.Lines.Add('Команда 0x'+IntToHex(r.resb[7],2)+' - неизвестная ошибка при выполнении команды.') else
            if r.resb[5] = $FF then memo1.Lines.Add('Команда 0x'+IntToHex(r.resb[7],2)+' - Тайм-аут при выполнении команды. Длина очереди: '+inttostr(r.resb[2])) else
             if r.resb[4] = $FF then memo1.Lines.Add('Команда 0x'+IntToHex(r.resb[7],2)+' - Потеря связи при выполнении команды. Длина очереди: '+inttostr(r.resb[2])) else
              memo1.Lines.Add('Рез.ИД: '+inttostr(r.id)+' Data: '+
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

 If module.COM_stat = com_Ready then
  begin
// Источник для канала Red
   Case ComboR.ItemIndex of
   0: Vr := 255-SpinR.Position;
   1: begin Vr := random(255-SpinR.Position); SpinR.Position := 255 - Vr end;
   2: begin Vr := (ADCVal1 div 4) mod 256; SpinR.Position := 255 - Vr end;
   3: begin Vr := (ADCVal2 div 4) mod 256; SpinR.Position := 255 - Vr end;
   4: begin Vr := (ADCVal3 div 4) mod 256; SpinR.Position := 255 - Vr end;
   5: begin Vr := (ADCVal4 div 4) mod 256; SpinR.Position := 255 - Vr end;
   6: begin Vr := (ADCVal5 div 4) mod 256; SpinR.Position := 255 - Vr end;
   7: begin Vr := (ADCVal6 div 4) mod 256; SpinR.Position := 255 - Vr end
   else begin Vr := 255-SpinR.Position end
   end;
// Источник для канала Green
   Case ComboG.ItemIndex of
   0: Vg := 255-SpinG.Position;
   1: begin Vg := random(255-SpinG.Position); SpinG.Position := 255 - Vg end;
   2: begin Vg := (ADCVal1 div 4) mod 256; SpinG.Position := 255 - Vg end;
   3: begin Vg := (ADCVal2 div 4) mod 256; SpinG.Position := 255 - Vg end;
   4: begin Vg := (ADCVal3 div 4) mod 256; SpinG.Position := 255 - Vg end;
   5: begin Vg := (ADCVal4 div 4) mod 256; SpinG.Position := 255 - Vg end;
   6: begin Vg := (ADCVal5 div 4) mod 256; SpinG.Position := 255 - Vg end;
   7: begin Vg := (ADCVal6 div 4) mod 256; SpinG.Position := 255 - Vg end
   else Vg := 255-SpinG.Position;
   end;
// Источник для канала Blue
   Case ComboB.ItemIndex of
   0: Vb := 255-SpinB.Position;
   1: begin Vb := random(255-SpinB.Position); SpinB.Position := 255 - Vb end;
   2: begin Vb := (ADCVal1 div 4) mod 256; SpinB.Position := 255 - Vb end;
   3: begin Vb := (ADCVal2 div 4) mod 256; SpinB.Position := 255 - Vb end;
   4: begin Vb := (ADCVal3 div 4) mod 256; SpinB.Position := 255 - Vb end;
   5: begin Vb := (ADCVal4 div 4) mod 256; SpinB.Position := 255 - Vb end;
   6: begin Vb := (ADCVal5 div 4) mod 256; SpinB.Position := 255 - Vb end;
   7: begin Vb := (ADCVal6 div 4) mod 256; SpinB.Position := 255 - Vb end
   else Vb := 255-SpinB.Position;
   end;

// Источник для канала Ultra
   Case ComboU.ItemIndex of
   0: Vu := 255-SpinU.Position;
   1: begin Vu := random(255-SpinU.Position); SpinU.Position := 255 - Vu end;
   2: begin Vu := (ADCVal1 div 4) mod 256; SpinU.Position := 255 - Vu end;
   3: begin Vu := (ADCVal2 div 4) mod 256; SpinU.Position := 255 - Vu end;
   4: begin Vu := (ADCVal3 div 4) mod 256; SpinU.Position := 255 - Vu end;
   5: begin Vu := (ADCVal4 div 4) mod 256; SpinU.Position := 255 - Vu end;
   6: begin Vu := (ADCVal5 div 4) mod 256; SpinU.Position := 255 - Vu end;
   7: begin Vu := (ADCVal6 div 4) mod 256; SpinU.Position := 255 - Vu end
   else Vu := 255-SpinU.Position;
   end;

   Module.add_command_RGBU(spinAddr.Value,$21,Vr,Vg,Vb,Vu);
   Module.add_command_readADC(100,0);
   Module.add_command_readADC(101,1);
   Module.add_command_readADC(102,2);
   Module.add_command_readADC(103,3);
   Module.add_command_readADC(104,4);
   Module.add_command_readADC(105,5);
  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
Var new_a,old : byte;
begin
 New_a := SpinAddrNew.value;
 old   := SpinAddr.value;
 If (New_a <> old) then
  if Application.MessageBox(Pchar('Сменить адрес 0x'+inttohex(old,2)+' на новый 0x'+inttohex(New_a,2)),'Смена адреса модуля.', MB_YESNO) = IDYES then
   begin
    Module.add_command_pause(100);
    Module.add_command_RGBU(old,$5A,New_a,0,0,0);
    Module.add_command_pause(100);
    Module.add_command_RGBU(old,$5A,New_a,0,0,0);
    Module.add_command_pause(100);
    Module.add_command_RGBU(old,$5A,New_a,0,0,0);
    Module.add_command_pause(100);
    Module.add_command_RGBU(old,$5A,New_a,0,0,0);
    Module.add_command_pause(100);
   end;
end;

procedure TForm1.SpinAddrNewChange(Sender: TObject);
begin
 try
 Button3.Enabled := not (SpinAddrNew.Value = SpinAddr.Value);
 except
 end;
end;

procedure TForm1.TrackBar1Change(Sender: TObject);
begin
 Timer1.Enabled := false; Timer1.Interval := TrackBar1.Position; Timer1.Enabled := true;
 Label14.Caption := 'Интервал обновления ='+inttostr(TrackBar1.Position)+'мс';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 Label14.Caption := 'Интервал обновления ='+inttostr(TrackBar1.Position)+'мс';
end;

end.
