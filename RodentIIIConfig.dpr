program RodentIIIConfig;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmRodentIII},
  RodentOptions in 'RodentOptions.pas',
  OptionDisplay in 'OptionDisplay.pas',
  FileBackup in 'FileBackup.pas',
  Guidelines in 'Guidelines.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmRodentIII, frmRodentIII);
  Application.Run;
end.
