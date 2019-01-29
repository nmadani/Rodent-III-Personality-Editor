unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.UITypes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtDlgs, Vcl.ExtCtrls, Vcl.ComCtrls, System.Actions, Vcl.ActnList, Vcl.ToolWin, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.PlatformDefaultStyleActnCtrls, Vcl.StdActns, System.ImageList, Vcl.ImgList,
  FileBackup,
  RodentOptions,
  OptionDisplay, Vcl.Menus;

type
  TfrmRodentIII = class(TForm)
    scrbxOptions: TScrollBox;
    StatusBar1: TStatusBar;
    memHeader: TMemo;
    pnlTop: TPanel;
    ActionToolBar1: TActionToolBar;
    ActionManager1: TActionManager;
    actSave: TAction;
    actFileOpen: TFileOpen;
    ImageList1: TImageList;
		actFileSaveAs: TFileSaveAs;
    memGuideline: TMemo;
    pumMissingOptions: TPopupMenu;
    pumRemoveOption: TPopupMenu;
    pmiRemoveOption: TMenuItem;
    actRemoveOption: TAction;
    mnuMainMenu: TMainMenu;
    mnuFile: TMenuItem;
    mnuOpen: TMenuItem;
    mnuSave: TMenuItem;
    mnuSaveAs: TMenuItem;
    mnuActions: TMenuItem;
    mnuRemoveAllOptions: TMenuItem;
    actAddAllOptions: TAction;
    mnuAddAllOptions: TMenuItem;
    actRemoveAllOptions: TAction;
    actNewFile: TAction;
    mnuNewFile: TMenuItem;
    pnlComments: TPanel;
    pgcComments: TPageControl;
    tshGuideline: TTabSheet;
    tshComment: TTabSheet;
    memComment: TMemo;
    actLicense: TAction;
    mnuLicense: TMenuItem;
    procedure actAddAllOptionsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
		procedure actSaveExecute(Sender: TObject);
    procedure actFileOpenAccept(Sender: TObject);
		procedure actFileSaveAsAccept(Sender: TObject);
    procedure actLicenseExecute(Sender: TObject);
    procedure actNewFileExecute(Sender: TObject);
    procedure actRemoveAllOptionsExecute(Sender: TObject);
    procedure actRemoveOptionExecute(Sender: TObject);
    procedure scrbxOptionsResize(Sender: TObject);
    procedure ClearOptionDisplay;
  private
    fColCount: Integer;
    fMinOptionDisaplyWidth: Integer;
    fRodentOptions: IRodentOptions;
    fMissingOptions: IRodentOptions;
    fOpenFileName: string;
    procedure OptionChanged(Sender: TObject);
    procedure DisplayGuideline(Sender: TObject);
    procedure AddMissingOption(Sender: TObject);
		procedure OpenFile(const aFileName: string);
    procedure SetMissingOptionsMenu;
    procedure SetOpenFileName(const Value: string);
    procedure SetNewFile;
	public
    property OpenFileName: string read fOpenFileName write SetOpenFileName;
  end;

var
  frmRodentIII: TfrmRodentIII;

implementation

{$R *.dfm}

uses Guidelines, LicenseUnit;

procedure TfrmRodentIII.actAddAllOptionsExecute(Sender: TObject);
var
  i: Integer;
  OD: TOptionDisplay;
begin
  for i := 0 to fMissingOptions.Count - 1 do
  begin
    OD := TOptionDisplay.Create(scrbxOptions, fMissingOptions[i], gGuidelines.GetMaxOptionWidth(Canvas));
    OD.OnChange := OptionChanged;
    OD.OnGuideline := DisplayGuideline;
    OD.RemoveMenu := pumRemoveOption;
    if fMinOptionDisaplyWidth = 0 then
      fMinOptionDisaplyWidth := OD.MinDisplayWidth;
  end;
  scrbxOptionsResize(nil);
  fRodentOptions := TRodentOptions.Create(fRodentOptions.Header, scrbxOptions);
  SetMissingOptionsMenu;
end;

procedure TfrmRodentIII.FormCreate(Sender: TObject);
begin
  SetNewFile;
end;

procedure TfrmRodentIII.actSaveExecute(Sender: TObject);
var
  Backup: TFileBackup;
  ix: Integer;
begin
	if fOpenFileName.IsEmpty then
	begin
		if actFileSaveAs.Dialog.Execute(Handle) = True then
		begin
      fRodentOptions.Header := memHeader.Text;
			if fRodentOptions.Save(actFileSaveAs.Dialog.FileName) then
			  OpenFileName := actFileSaveAs.Dialog.FileName;
			Exit;
		end
		else
			Exit;
	end;
	Backup := TFileBackup.Create(fOpenFileName);
	try
		if Backup.Success then
		begin
      fRodentOptions.Header := memHeader.Text;
      if memGuideline.Text <> '' then
      begin
        if fRodentOptions.MatchStringToOption(memGuideline.Lines[0], ix) then
          fRodentOptions.Comments[ix] := memComment.Text;
      end;
			fRodentOptions.Save(fOpenFileName);
		end;
  finally
		Backup.Free;
  end;
end;

procedure TfrmRodentIII.AddMissingOption(Sender: TObject);
var
  mi: TMenuItem;
  OD: TOptionDisplay;
  i: Integer;
begin
  if Sender is TMenuItem then
  begin
    mi := Sender as TMenuItem;
    for i := 0 to fMissingOptions.Count - 1 do
    begin
      if fMissingOptions.Options[i] = mi.Caption.Replace('&','') then
      begin
        OD := TOptionDisplay.Create(scrbxOptions, fMissingOptions.Options[i],
                                                  fMissingOptions.Values[i],
                                                  gGuidelines.GetMaxOptionWidth(Canvas));
        OD.OnChange := OptionChanged;
        OD.OnGuideline := DisplayGuideline;
        OD.RemoveMenu := pumRemoveOption;
        if fMinOptionDisaplyWidth = 0 then
          fMinOptionDisaplyWidth := OD.MinDisplayWidth;
        scrbxOptionsResize(nil);
        fRodentOptions := TRodentOptions.Create(fRodentOptions.Header, scrbxOptions);
        Break;
      end;
    end;
  end;
  SetMissingOptionsMenu;
end;

procedure TfrmRodentIII.ClearOptionDisplay;
var
  i: Integer;
begin
  for i := scrbxOptions.ControlCount - 1 downto 0 do
  begin
    scrbxOptions.RemoveControl(scrbxOptions.Controls[i]);
  end;
  memHeader.Text := '';
  memGuideline.Text := '';
  memComment.Text := '';
end;

procedure TfrmRodentIII.DisplayGuideline(Sender: TObject);
var
  index: Integer;
  i: Integer;
  OD: TOptionDisplay;
begin
  if Sender is TOptionDisplay then
  begin
    // Save any existing comment
    if memGuideline.Text <> '' then
    begin
      if fRodentOptions.MatchStringToOption(memGuideline.Lines[0], index) then
      begin
        fRodentOptions.Comments[index] := memComment.Text;
        // remove highlight
        for i := 0 to scrbxOptions.ControlCount - 1 do
        begin
          if scrbxOptions.Controls[i] is TOptionDisplay then
          begin
            OD := scrbxOptions.Controls[i] as TOptionDisplay;
            if OD.Option = fRodentOptions.Options[index] then
            begin
              OD.HighLightOff;
              Break;
            end;
          end;
        end;
      end;
    end;
    memGuideline.Text := (Sender as TOptionDisplay).Option + sLineBreak +
                               (Sender as TOptionDisplay).Guideline;
    if fRodentOptions.MatchStringToOption((Sender as TOptionDisplay).Option, index) then
      memComment.Text := fRodentOptions.Comments[index];
  end;
end;

procedure TfrmRodentIII.OpenFile(const aFileName: string);
var
  MaxWidth: Integer;
  i: Integer;
  OptionDisplay: TOptionDisplay;
begin
	if FileExists(aFileName) then
  begin
		OpenFileName := aFileName;
		ClearOptionDisplay;
		fRodentOptions := TRodentOptions.Create(fOpenFileName);
    SetMissingOptionsMenu;
		memHeader.Lines.Text := fRodentOptions.Header;
		MaxWidth := gGuidelines.GetMaxOptionWidth(Canvas);
		for i := 0 to fRodentOptions.Count - 1 do
		begin
			OptionDisplay := TOptionDisplay.Create(scrbxOptions, fRodentOptions[i], MaxWidth);
			OptionDisplay.OnChange := OptionChanged;
      OptionDisplay.RemoveMenu := pumRemoveOption;
			OptionDisplay.OnGuideline := DisplayGuideline;
			if i = 0 then
				fMinOptionDisaplyWidth := OptionDisplay.MinDisplayWidth;
		end;
		scrbxOptionsResize(nil);
	end;
end;

procedure TfrmRodentIII.SetMissingOptionsMenu;
var
  i: Integer;
  mi: TMenuItem;
begin
  fMissingOptions := TRodentOptions.Create(fRodentOptions);
  pumMissingOptions.Items.Clear;
  for i := 0 to fMissingOptions.Count - 1 do
  begin
    mi := TMenuItem.Create(pumMissingOptions);
    mi.Caption := fMissingOptions.Options[i];
    mi.OnClick := AddMissingOption;
    pumMissingOptions.Items.Add(mi);
  end;
end;

procedure TfrmRodentIII.OptionChanged(Sender: TObject);
var
  i: Integer;
  od: TOptionDisplay;
begin
  if Sender is TOptionDisplay then
  begin
    od := (Sender as TOptionDisplay);
    for i := 0 to fRodentOptions.Count - 1 do
    begin
      if fRodentOptions.Options[i] = od.Option then
        fRodentOptions.Values[i] := od.Value;
    end;
	end;
end;

procedure TfrmRodentIII.actFileOpenAccept(Sender: TObject);
begin
	OpenFile(actFileOpen.Dialog.FileName);
end;

procedure TfrmRodentIII.actFileSaveAsAccept(Sender: TObject);
begin
	if fRodentOptions.Save(actFileSaveAs.Dialog.FileName) then
    OpenFileName := actFileSaveAs.Dialog.FileName;
end;

procedure TfrmRodentIII.actLicenseExecute(Sender: TObject);
begin
  LicenseUnit.frmLicense.ShowModal;
end;

procedure TfrmRodentIII.actNewFileExecute(Sender: TObject);
begin
  if fOpenFileName <> '' then
  begin
     if MessageDlg('Save ' + ExtractFileName(fOpenFileName) + '?',
                    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
        actSaveExecute(nil);
  end;
  SetNewFile;
end;

procedure TfrmRodentIII.actRemoveAllOptionsExecute(Sender: TObject);
begin
  ClearOptionDisplay;
  fRodentOptions := TRodentOptions.Create(memHeader.Text, scrbxOptions);
  SetMissingOptionsMenu;
end;

procedure TfrmRodentIII.actRemoveOptionExecute(Sender: TObject);
var
  i: Integer;
  Control: TControl;
  MousePos: TPoint;
begin
  if Sender is TAction then
  begin
    for i := 0 to scrbxOptions.ControlCount - 1 do
    begin
      MousePos := scrbxOptions.ScreenToClient(Mouse.CursorPos);
      Control := scrbxOptions.ControlAtPos(MousePos, True, True, True);
      while Assigned(Control) and ((Control is TOptionDisplay) = False) do
      begin
        Control := Control.Parent;
      end;
      if Control is TOptionDisplay then
      begin
        scrbxOptions.RemoveControl(Control);
        scrbxOptionsResize(nil);
        fRodentOptions := TRodentOptions.Create(fRodentOptions.Header, scrbxOptions);
        Break;
      end;
    end;
    SetMissingOptionsMenu;
  end;
end;

procedure TfrmRodentIII.scrbxOptionsResize(Sender: TObject);
var
  i: Integer;
  OptDispN: Integer;
begin
  OptDispN := 0;
  for i := 0 to scrbxOptions.ControlCount - 1 do
  begin
    fColCount := scrbxOptions.Width div fMinOptionDisaplyWidth;
    if fColCount = 0 then
      fColCount := 1;
    if scrbxOptions.Controls[i] is TOptionDisplay then
    begin
      scrbxOptions.Controls[i].Top := scrbxOptions.Controls[i].Height * (OptDispN div fColCount);
      scrbxOptions.Controls[i].Width := scrbxOptions.Width div fColCount;
      scrbxOptions.Controls[i].Left := scrbxOptions.Controls[i].Width * ((fColCount + OptDispN) mod fColCount);
      Inc(OptDispN);
    end;
  end;
end;

procedure TfrmRodentIII.SetOpenFileName(const Value: string);
begin
  fOpenFileName := Value;
  Caption := Value;
end;

procedure TfrmRodentIII.SetNewFile;
begin
  memHeader.Text := '';
  ClearOptionDisplay;
  fRodentOptions := TRodentOptions.Create(memHeader.Text, scrbxOptions);
  SetMissingOptionsMenu;
  OpenFileName := '';
  Caption := 'New personality file';
end;

end.
