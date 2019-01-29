unit OptionDisplay;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtDlgs, Vcl.ExtCtrls,
  RodentOptions, Vcl.Menus;

type
  TOptionDisplay = class(TPanel)
  private
    fOption: TLabel;
    fValue: TEdit;
    fIncrease: TButton;
    fDecrease: TButton;
    fCallback: TNotifyEvent;
    fOnGuideline: TNotifyEvent;
    fGuideline: string;
    procedure DisplayGuideline(Sender: TObject);
    function GetOption: string;
    function GetValue: string;
    procedure SetOption(const Value: string);
    procedure SetValue(const Value: string);
    procedure IncValue(Sender: TObject);
    procedure DecValue(Sender: TObject);
    procedure NotifyChange(Sender: TObject);
    function GetValueButtonWidth: Integer;
    function GetMinDisplayWidth: Integer;
    function GetRemoveMenu: TPopupMenu;
    procedure SetRemoveMenu(const Value: TPopupMenu);
    procedure SetUp(const aOption, aValue: string; LabelWidth: Integer);
  public
    constructor Create(const aParent: TWinControl; const aOption: ROption; LabelWidth: Integer);
        reintroduce; overload;
    constructor Create(const aParent: TWinControl; const aOption, aValue: string; LabelWidth: Integer);
        reintroduce; overload;
    procedure HighLightOn;
    procedure HighLightOff;
    property Option: string read GetOption write SetOption;
    property Value: string read GetValue write SetValue;
    property OnChange: TNotifyEvent read fCallback write fCallback;
    property OnGuideline: TNotifyEvent read fOnGuideline write fOnGuideline;
    property MinDisplayWidth: Integer read GetMinDisplayWidth;
    property Guideline: string read fGuideline;
    property RemoveMenu: TPopupMenu read GetRemoveMenu write SetRemoveMenu;
  end;

implementation

uses Guidelines;

resourcestring
  cStrValueField = '000000';
  cStrIncDecCaption = '   -   ';

const
  cSmallMargin = 10;
  cLargeMargin = 15;
  cButtonMargin = 2;

{ TOptionDisplay }

constructor TOptionDisplay.Create(const aParent: TWinControl; const aOption: ROption; LabelWidth:
    Integer);
begin
  inherited Create(aParent);
  Parent := aParent;
  SetUp(aOption.Option, aOption.Value, LabelWidth);
end;

constructor TOptionDisplay.Create(const aParent: TWinControl; const aOption, aValue: string;
  LabelWidth: Integer);
begin
  inherited Create(aParent);
  Parent := aParent;
  SetUp(aOption, aValue, LabelWidth);
end;

procedure TOptionDisplay.DecValue(Sender: TObject);
var
  IntVal: Integer;
begin
  if TryStrToInt(fValue.Text, IntVal) then
  begin
    Dec(IntVal);
    fValue.Text := IntVal.ToString;
  end;
  DisplayGuideline(Sender);
end;

procedure TOptionDisplay.DisplayGuideline(Sender: TObject);
begin
  HighLightOn;
  if Assigned(fOnGuideline) then
    fOnGuideline(Self);
end;

function TOptionDisplay.GetMinDisplayWidth: Integer;
begin
  Result := fOption.Width + GetValueButtonWidth + 3 * cLargeMargin;
end;

function TOptionDisplay.GetOption: string;
begin
  Result := fOption.Caption;
end;

function TOptionDisplay.GetRemoveMenu: TPopupMenu;
begin
  Result := fValue.PopupMenu;
end;

function TOptionDisplay.GetValue: string;
begin
  Result := fValue.Text;
end;

procedure TOptionDisplay.IncValue(Sender: TObject);
var
  IntVal: Integer;
begin
  if TryStrToInt(fValue.Text, IntVal) then
  begin
    Inc(IntVal);
    fValue.Text := IntVal.ToString;
  end;
  DisplayGuideline(Sender);
end;

function TOptionDisplay.GetValueButtonWidth: Integer;
begin
  Result := Canvas.TextWidth(cStrValueField) + 2 * Canvas.TextWidth(cStrIncDecCaption) +
            2 *cSmallMargin;
end;

procedure TOptionDisplay.HighLightOff;
begin
  BevelKind := bkNone;
  BevelInner := bvNone;
  BevelWidth := 1;
end;

procedure TOptionDisplay.HighLightOn;
begin
  BevelKind := bkTile;
  BevelInner := bvLowered;
  BevelWidth := 2;
end;

procedure TOptionDisplay.NotifyChange(Sender: TObject);
begin
  if Assigned(fCallback) then
    fCallback(Self);
end;

procedure TOptionDisplay.SetOption(const Value: string);
begin
  fOption.Caption := Value;
end;

procedure TOptionDisplay.SetRemoveMenu(const Value: TPopupMenu);
begin
  fValue.PopupMenu := Value;
  fOption.PopupMenu := Value;
  if Assigned(fIncrease) then
    fIncrease.PopupMenu := Value;
  if Assigned(fDecrease) then
    fDecrease.PopupMenu := Value;
end;

procedure TOptionDisplay.SetUp(const aOption, aValue: string; LabelWidth: Integer);
var
  IntVal: Integer;
  lValue: string;
begin
  fGuideline := gGuidelines.Guideline[aOption];
  OnClick := DisplayGuideline;

  // Handle missing defauls
  if aValue.IsEmpty then
  begin
    if aOption.Contains('BookFile') then
      lValue := ''
    else
      lValue := '0';
  end
  else
    lValue := aValue;

  fOption := TLabel.Create(Self);
  fOption.Parent := Self;
  fOption.AutoSize := False;
  fOption.Width := LabelWidth;
  fOption.Left := cLargeMargin;
  fOption.Caption := aOption;
  fOption.Font := Font;
  fOption.OnClick := DisplayGuideline;

  Height := fOption.Height + 2 * cSmallMargin;
  fOption.Top := (Height - Canvas.TextHeight(aOption)) div 2;

  if TryStrToInt(lValue, IntVal) then
  begin
    fDecrease := TButton.Create(Self);
    fDecrease.Parent := Self;
    fDecrease.Caption := '-';
    fDecrease.Width := Canvas.TextWidth(cStrIncDecCaption) + cButtonMargin;
    fDecrease.Top := Height - (cSmallMargin + fDecrease.Height);
    fDecrease.Left := fOption.Left + fOption.Width + cLargeMargin;
    fDecrease.OnClick := DecValue;
    fDecrease.Font := Font;

    fValue := TEdit.Create(Self);
    fValue.Parent := Self;
    fValue.Top := Height - (cSmallMargin + fValue.Height);
    fValue.Left := fDecrease.Left + fDecrease.Width + cSmallMargin;
    fValue.Width := Canvas.TextWidth(cStrValueField);
    fValue.Text := lValue;
    fValue.Font := Font;
    fValue.OnChange := NotifyChange;
    fValue.OnClick := DisplayGuideline;

    fIncrease := TButton.Create(Self);
    fIncrease.Parent := Self;
    fIncrease.Caption := '+';
    fIncrease.Width := Canvas.TextWidth(cStrIncDecCaption) + cButtonMargin;
    fIncrease.Top := Height - (cSmallMargin + fIncrease.Height);
    fIncrease.Left := fValue.Left + fValue.Width + cSmallMargin;
    fIncrease.OnClick := IncValue;
    fIncrease.Font := Font;
  end
  else
  begin
    fValue := TEdit.Create(Self);
    fValue.Parent := Self;
    fValue.Top := Height - (cSmallMargin + fValue.Height);
    fValue.Left := fOption.Left + fOption.Width + cLargeMargin;
    fValue.Text := lValue;
    fValue.Font := Font;
    fValue.Width := GetValueButtonWidth;
    fValue.OnChange := NotifyChange;
    fValue.OnClick := DisplayGuideline;
  end;
end;

procedure TOptionDisplay.SetValue(const Value: string);
begin
  fValue.Text := Value;
end;

end.
