unit Pattern_Unit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Gauges, StdCtrls, Spin, ExtCtrls;

type
  TForm1 = class(TForm)
    Items_count: TLabeledEdit;
    Button1: TButton;
    Step_count: TLabeledEdit;
    Channel_num: TSpinEdit;
    Label1: TLabel;
    Select_random: TRadioButton;
    SubChan_num: TSpinEdit;
    Label2: TLabel;
    Select_garmonic: TRadioButton;
    St_phase_from: TLabeledEdit;
    St_phase_to: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Period_from: TLabeledEdit;
    Label5: TLabel;
    Period_to: TEdit;
    Label6: TLabel;
    Offset_from: TLabeledEdit;
    Label7: TLabel;
    Offset_to: TEdit;
    Mirror: TCheckBox;
    Gain_from: TLabeledEdit;
    Label9: TLabel;
    Gain_to: TEdit;
    progress: TGauge;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

Procedure WriteLine(var f: textfile; line: array of byte; channels, subchannels:integer);
var a,b : integer;
 begin
  For a:=0 to length(line)-1 do
   begin
    write(f,inttostr(line[a]):3);
    if a <> (length(line)-1) then
     If (a mod subchannels) = (subchannels - 1) then write(f, ';') else  write(f, ',');
   end;
  writeln(f);
 end;

Procedure generate_random(var GenFile: textfile;channels,subchannels,counts,step: integer);
var final_line: array of byte;
    last_line : array of byte; // ѕоследнее значение дл€ интерпол€ции
    new_line  : array of byte; //  онечное значение дл€ интерпол€ции
    ch_count  : integer;
    a,b,z, phase : integer;
 Begin
// —делать так чтобы дл€ каждого канала генерировалось соотношение цветов и обща€ €ркость с измен€емой степенью максимальной €ркости(по экспоненте?).
  form1.progress.Progress:= 0;
  ch_count := channels * subchannels;
  If ch_count <=0 then begin form1.progress.Progress:= 100; Exit end;

//  —оздаем массивы
  SetLength(final_line, ch_count);
  SetLength(last_line, ch_count);
  SetLength(new_line, ch_count);
// обнулить начальный массив
  For a:= 0 to ch_count-1 do new_line[a] := random(256);

  For z := 0 to counts-1 do
   begin
    phase := z mod step;
    If  phase = 0 then
      For a:= 0 to ch_count-1 do
       begin
        last_line[a] := new_line[a];
         new_line[a] := random(256); // —читаем следующую точку...
       end;
    For a:= 0 to ch_count-1 do final_line[a] := last_line[a] + trunc(phase*(new_line[a]-last_line[a]) / step );
    WriteLine(GenFile,final_line,channels,subchannels);
    form1.progress.progress := (100*(z+1)) div counts;
   end;
 end;


procedure TForm1.Button1Click(Sender: TObject);
Var f: textfile;
    channels,
    subchannels,
    counts,
    step : integer;
begin
 channels   := Channel_num.Value;
 subchannels:= SubChan_num.Value;
 counts     := strtoint(Items_count.Text);
 step       := strtoint(Step_count.Text);


 assignfile(f,'pattern_gen.txt');
 rewrite(f);

 If Select_random.Checked then generate_random(f,Channels,subchannels,counts,step);

 closefile(f);
end;

end.
