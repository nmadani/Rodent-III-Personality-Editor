unit MainForm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtDlgs, Vcl.ExtCtrls, Vcl.ComCtrls, System.Actions, Vcl.ActnList, Vcl.ToolWin, Vcl.ActnMan,
  Vcl.ActnCtrls, Vcl.PlatformDefaultStyleActnCtrls, Vcl.StdActns, System.ImageList, Vcl.ImgList,
  FileBackup,
  RodentOptions,
  OptionDisplay, Vcl.Menus;

type
  TfrmRodentIII = class(TForm)
    scrbxOptions: TScrollBox;
    StatusBar1: TStatusBar;
    memComments: TMemo;
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
    procedure actAddAllOptionsExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
		procedure actSaveExecute(Sender: TObject);
    procedure actFileOpenAccept(Sender: TObject);
		procedure actFileSaveAsAccept(Sender: TObject);
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

uses Guidelines;

procedure TfrmRodentIII.actAddAllOptionsExecute(Sender: TObject);
var
  i: Integer;
  OD: TOptionDisplay;
begin
  for i := 0 to fMissingOptions.Count - 1 do
  begin
    OD := TOptionDisplay.Create(scrbxOptions, fMissingOptions.Options[i], gGuidelines.GetMaxOptionWidth(Canvas));
    OD.OnChange := OptionChanged;
    OD.OnGuideline := DisplayGuideline;
    OD.RemoveMenu := pumRemoveOption;
    if fMinOptionDisaplyWidth = 0 then
      fMinOptionDisaplyWidth := OD.MinDisplayWidth;
  end;
  scrbxOptionsResize(nil);
  fRodentOptions := TRodentOptions.Create(fRodentOptions.Comments, scrbxOptions);
  SetMissingOptionsMenu;
end;

procedure TfrmRodentIII.FormCreate(Sender: TObject);
begin
  SetNewFile;
end;

procedure TfrmRodentIII.actSaveExecute(Sender: TObject);
var
  Backup: TFileBackup;
begin
	if fOpenFileName.IsEmpty then
	begin
		if actFileSaveAs.Dialog.Execute(Handle) = True then
		begin
      fRodentOptions.Comments := memComments.Text;
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
      if fMissingOptions.Options[i].Option = mi.Caption.Replace('&','') then
      begin
        OD := TOptionDisplay.Create(scrbxOptions, fMissingOptions.Options[i].Option,
                                                  fMissingOptions.Options[i].Value,
                                                  gGuidelines.GetMaxOptionWidth(Canvas));
        OD.OnChange := OptionChanged;
        OD.OnGuideline := DisplayGuideline;
        OD.RemoveMenu := pumRemoveOption;
        if fMinOptionDisaplyWidth = 0 then
          fMinOptionDisaplyWidth := OD.MinDisplayWidth;
        scrbxOptionsResize(nil);
        fRodentOptions := TRodentOptions.Create(fRodentOptions.Comments, scrbxOptions);
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
end;

procedure TfrmRodentIII.DisplayGuideline(Sender: TObject);
begin
  if Sender is TOptionDisplay then
    memGuideline.Lines.Text := (Sender as TOptionDisplay).Option + sLineBreak +
                               (Sender as TOptionDisplay).Guideline;
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
		fRodentOptions := TRodentOptions.Create(fOpenFileName);
    SetMissingOptionsMenu;
		memComments.Lines.Text := fRodentOptions.Comments;
		MaxWidth := gGuidelines.GetMaxOptionWidth(Canvas);
		ClearOptionDisplay;
		for i := 0 to fRodentOptions.Count - 1 do
		begin
			OptionDisplay := TOptionDisplay.Create(scrbxOptions, fRodentOptions.Options[i], MaxWidth);
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
    mi.Caption := fMissingOptions.Options[i].Option;
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
      if fRodentOptions.Options[i].Option = od.Option then
        fRodentOptions.Options[i].Value := od.Value;
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
  fRodentOptions := TRodentOptions.Create(memComments.Text, scrbxOptions);
  SetMissingOptionsMenu;
end;

procedure TfrmRodentIII.actRemoveOptionExecute(Sender: TObject);
var
  i: Integer;
  Control: TControl;
  OD: TOptionDisplay;
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
        OD := Control as TOptionDisplay;
        scrbxOptions.RemoveControl(Control);
        scrbxOptionsResize(nil);
        fRodentOptions := TRodentOptions.Create(fRodentOptions.Comments, scrbxOptions);
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
  memComments.Text := '';
  ClearOptionDisplay;
  fRodentOptions := TRodentOptions.Create(memComments.Text, scrbxOptions);
  SetMissingOptionsMenu;
  OpenFileName := '';
  Caption := 'New personality file';
end;

end.
