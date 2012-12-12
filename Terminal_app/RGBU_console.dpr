program RGBU_console;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  COM2RGBU_wrap in 'COM2RGBU_wrap.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
