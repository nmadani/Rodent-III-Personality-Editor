program RodentIIIConfig;

uses
  Vcl.Forms,
  MainForm in 'MainForm.pas' {frmRodentIII},
  RodentOptions in 'RodentOptions.pas',
  OptionDisplay in 'OptionDisplay.pas',
  FileBackup in 'FileBackup.pas',
  Guidelines in 'Guidelines.pas',
  LicenseUnit in 'LicenseUnit.pas' {frmLicense};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmRodentIII, frmRodentIII);
  Application.CreateForm(TfrmLicense, frmLicense);
  Application.Run;
end.
