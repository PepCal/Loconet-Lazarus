// === UNIDAD ORGANIZADA Y DOCUMENTADA ===
// Se mantiene funcionalidad original. Comentarios añadidos.

unit unitControlLocomotora;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  Buttons, ExtCtrls, Spin, ControlLoco, ControlMaqueta, ClientLocoNet;

type

  { TForm2 }

  TForm2 = class(TForm)
    ASELocoA: TSpinEdit;
    ASELocoB: TSpinEdit;
    ASELocoC: TSpinEdit;
    CBF0: TCheckBox;
    CBF1: TCheckBox;
    CBF2: TCheckBox;
    CBF3: TCheckBox;
    CBF4: TCheckBox;
    CBF5: TCheckBox;
    CBF6: TCheckBox;
    CBF7: TCheckBox;
    CBF8: TCheckBox;
    ControlLoco1: TControlLoco;
    Label1: TLabel;
    LabelVelocidad: TLabel;
    PAbajo: TPanel;
    PArriba: TPanel;
    PBotonesDireccion: TPanel;
    PControl: TPanel;
    PFunciones: TPanel;
    Panel1: TPanel;
    Panel2: TPanel;
    RBLocoA: TRadioButton;
    RBLocoB: TRadioButton;
    RBLocoC: TRadioButton;
    SBAbajo: TSpeedButton;
    SBArriba: TSpeedButton;
    SBParar: TSpeedButton;
    TrackBarSpeed: TTrackBar;
    procedure CBF0Click(Sender: TObject);
    procedure ControlLoco1Change(Sender: TObject; Speed: Integer; Dir: Integer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure RBLocoABCChange(Sender: TObject);
    procedure SBAbajoClick(Sender: TObject);
    procedure SBArribaClick(Sender: TObject);
    procedure SBPararClick(Sender: TObject);
    procedure TrackBarSpeedChange(Sender: TObject);
    procedure TrackBarSpeedMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FUpdatingUI: Boolean;

    procedure ControlLoco1FunctionChange(Sender: TObject; FuncNo: Integer; State: Boolean);
    procedure ControlLoco1FunctionsChange(Sender: TObject; Funcs: Word);
    procedure HabilitarFunciones(Habilitar: Boolean);
    procedure ResetFunciones;
    function GetCheckFuncion(FuncNo: Integer): TCheckBox;
    procedure EnviarFuncionDesdeCheck(CB: TCheckBox; FuncNo: Integer);
    function GetDCCSeleccionada: Integer;
    procedure RefrescarFuncionesDesdeCliente;
    procedure PintarDireccion(Dir: Integer);
  public
  end;

var
  Form2: TForm2;

implementation

{$R *.lfm}

{ TForm2 }

function TForm2.GetCheckFuncion(FuncNo: Integer): TCheckBox;
begin
  case FuncNo of
    0: Result := CBF0;
    1: Result := CBF1;
    2: Result := CBF2;
    3: Result := CBF3;
    4: Result := CBF4;
    5: Result := CBF5;
    6: Result := CBF6;
    7: Result := CBF7;
    8: Result := CBF8;
  else
    Result := nil;
  end;
end;

function TForm2.GetDCCSeleccionada: Integer;
begin
  Result := 0;

  if RBLocoA.Checked then
    Result := ASELocoA.Value
  else if RBLocoB.Checked then
    Result := ASELocoB.Value
  else if RBLocoC.Checked then
    Result := ASELocoC.Value;
end;

procedure TForm2.HabilitarFunciones(Habilitar: Boolean);
var
  i: Integer;
  CB: TCheckBox;
begin
  if Assigned(PFunciones) then
    PFunciones.Enabled := Habilitar;

  for i := 0 to 8 do
  begin
    CB := GetCheckFuncion(i);
    if Assigned(CB) then
      CB.Enabled := Habilitar;
  end;
end;

procedure TForm2.ResetFunciones;
var
  i: Integer;
  CB: TCheckBox;
begin
  FUpdatingUI := True;
  try
    for i := 0 to 8 do
    begin
      CB := GetCheckFuncion(i);
      if Assigned(CB) then
        CB.Checked := False;
    end;
  finally
    FUpdatingUI := False;
  end;
end;

procedure TForm2.RefrescarFuncionesDesdeCliente;
var
  Funcs: Word;
  DCC: Integer;
begin
  if not Assigned(ControlLoco1) then Exit;
  if not Assigned(ControlLoco1.Client) then Exit;

  DCC := ControlLoco1.DCC;
  if DCC = 0 then Exit;

  // Pedir refresco al cliente
  ControlLoco1.Client.RequestLocoSlotByDCC(DCC);

  // Pintar lo que ya haya en caché
  Funcs := ControlLoco1.Client.GetLocoFunctionsByDCC(DCC);
  ControlLoco1FunctionsChange(Self, Funcs);
end;

procedure TForm2.EnviarFuncionDesdeCheck(CB: TCheckBox; FuncNo: Integer);
begin
  if FUpdatingUI then Exit;
  if not Assigned(CB) then Exit;
  if ControlLoco1.DCC = 0 then Exit;

  ControlLoco1.SetFunction(FuncNo, CB.Checked);
end;

procedure TForm2.CBF0Click(Sender: TObject);
begin
  if Sender = CBF0 then EnviarFuncionDesdeCheck(CBF0, 0)
  else if Sender = CBF1 then EnviarFuncionDesdeCheck(CBF1, 1)
  else if Sender = CBF2 then EnviarFuncionDesdeCheck(CBF2, 2)
  else if Sender = CBF3 then EnviarFuncionDesdeCheck(CBF3, 3)
  else if Sender = CBF4 then EnviarFuncionDesdeCheck(CBF4, 4)
  else if Sender = CBF5 then EnviarFuncionDesdeCheck(CBF5, 5)
  else if Sender = CBF6 then EnviarFuncionDesdeCheck(CBF6, 6)
  else if Sender = CBF7 then EnviarFuncionDesdeCheck(CBF7, 7)
  else if Sender = CBF8 then EnviarFuncionDesdeCheck(CBF8, 8);
end;

procedure TForm2.ControlLoco1FunctionChange(Sender: TObject; FuncNo: Integer; State: Boolean);
var
  CB: TCheckBox;
begin
  CB := GetCheckFuncion(FuncNo);
  if not Assigned(CB) then Exit;

  FUpdatingUI := True;
  try
    CB.Checked := State;
  finally
    FUpdatingUI := False;
  end;
end;

procedure TForm2.ControlLoco1FunctionsChange(Sender: TObject; Funcs: Word);
var
  i: Integer;
  CB: TCheckBox;
begin
  FUpdatingUI := True;
  try
    for i := 0 to 8 do
    begin
      CB := GetCheckFuncion(i);
      if Assigned(CB) then
        CB.Checked := (Funcs and (Word(1) shl i)) <> 0;
    end;
  finally
    FUpdatingUI := False;
  end;
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  ControlLoco1.OnChange := @ControlLoco1Change;
  ControlLoco1.OnFunctionChange := @ControlLoco1FunctionChange;
  ControlLoco1.OnFunctionsChange := @ControlLoco1FunctionsChange;

  FormStyle := fsStayOnTop;
  TrackBarSpeed.Min := 0;
  TrackBarSpeed.Max := 127;
  TrackBarSpeed.Position := 0;
  LabelVelocidad.Caption := '0';

  PControl.Enabled := False;
  HabilitarFunciones(False);
  ResetFunciones;
end;

procedure TForm2.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
  Form2 := nil;
end;

procedure TForm2.PintarDireccion(Dir: Integer);
begin
  PArriba.ParentColor := False;
  PAbajo.ParentColor := False;

  if Dir = 1 then
  begin
    PArriba.Color := clLime;
    PAbajo.Color := clBtnFace;
  end
  else
  begin
    PArriba.Color := clBtnFace;
    PAbajo.Color := clLime;
  end;

  PArriba.Repaint;
  PAbajo.Repaint;
  PBotonesDireccion.Repaint;
end;

procedure TForm2.ControlLoco1Change(Sender: TObject; Speed: Integer; Dir: Integer);
begin
  FUpdatingUI := True;
  try
    if TrackBarSpeed.Position <> Speed then
      TrackBarSpeed.Position := Speed;

    LabelVelocidad.Caption := IntToStr(Speed);
    PintarDireccion(Dir);
  finally
    FUpdatingUI := False;
  end;
end;

procedure TForm2.RBLocoABCChange(Sender: TObject);
var
  ValorSeleccionado: Integer;
begin
  ValorSeleccionado := GetDCCSeleccionada;

  PControl.Enabled := False;
  HabilitarFunciones(False);
  ResetFunciones;

  if ValorSeleccionado <> 0 then
  begin
    // Forzar cambio limpio de locomotora
    ControlLoco1.DCC := 0;
    ControlLoco1.DCC := ValorSeleccionado;

    Caption := 'Control DCC: ' + IntToStr(ValorSeleccionado);

    PControl.Enabled := True;
    HabilitarFunciones(True);

    RefrescarFuncionesDesdeCliente;
  end
  else
    Caption := 'Control locomotora';
end;

procedure TForm2.SBAbajoClick(Sender: TObject);
begin
  if FUpdatingUI then Exit;
  if ControlLoco1.DCC = 0 then Exit;
  ControlLoco1.Backward;
end;

procedure TForm2.SBArribaClick(Sender: TObject);
begin
  if FUpdatingUI then Exit;
  if ControlLoco1.DCC = 0 then Exit;
  ControlLoco1.Forward;
end;

procedure TForm2.SBPararClick(Sender: TObject);
begin
  if FUpdatingUI then Exit;
  if ControlLoco1.DCC = 0 then Exit;
  ControlLoco1.Stop;
end;

procedure TForm2.TrackBarSpeedChange(Sender: TObject);
begin
  if FUpdatingUI then Exit;
  LabelVelocidad.Caption := IntToStr(TrackBarSpeed.Position);
end;

procedure TForm2.TrackBarSpeedMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FUpdatingUI then Exit;
  if ControlLoco1.DCC = 0 then Exit;
  ControlLoco1.Speed := TrackBarSpeed.Position;
end;

end.
