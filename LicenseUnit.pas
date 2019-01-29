unit LicenseUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmLicense = class(TForm)
    memLicense: TMemo;
    btnOK: TButton;
    procedure btnOKClick(Sender: TObject);
    procedure memLicenseKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmLicense: TfrmLicense;

implementation

{$R *.dfm}

procedure TfrmLicense.btnOKClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmLicense.memLicenseKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
    Close;
end;

end.
