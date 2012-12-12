program RGBU_controller;

uses
  Forms,
  controller_main in 'controller_main.pas' {Form1},
  COM2RGBU_wrap in 'COM2RGBU_wrap.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
