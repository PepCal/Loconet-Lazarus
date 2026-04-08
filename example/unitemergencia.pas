unit unitEmergencia;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LCLType, LCLIntf,
  Types, ClientLocoNet;

type

  { TFormEmergencia }
  {
    Formulario flotante de parada de emergencia.

    Características:
    - Botón circular siempre visible (top-most).
    - Permite activar/desactivar la alimentación de vía (Track Power).
    - Arrastrable con botón derecho.
    - Cierre mediante doble clic.

    Interacción:
    - Click izquierdo: alterna estado TrackPower.
    - Click derecho + arrastre: reposiciona el control.
  }

  TFormEmergencia = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDblClick(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormPaint(Sender: TObject);

  private
    { === Estado interno === }
    FClient: TClientLocoNet;     // Cliente LocoNet asociado
    FTrackPowerOn: Boolean;      // Estado actual de alimentación de vía

    { === Drag & Drop ventana === }
    FDragging: Boolean;
    FDragOffsetX: Integer;
    FDragOffsetY: Integer;

    { === Métodos internos === }

    // Aplica forma circular a la ventana
    procedure AplicarRegionCircular;

    // Setter controlado de TrackPower
    procedure SetTrackPowerOn(AValue: Boolean);

    // Dibuja texto centrado horizontalmente
    procedure DibujarTextoCentrado(const S: string; Y: Integer);

  public
    property Client: TClientLocoNet read FClient write FClient;
    property TrackPowerOn: Boolean read FTrackPowerOn write SetTrackPowerOn;
  end;

var
  FormEmergencia: TFormEmergencia;

implementation

uses
  Windows;

{$R *.lfm}

{ ============================================================================ }
{ === Métodos internos ======================================================== }
{ ============================================================================ }

procedure TFormEmergencia.SetTrackPowerOn(AValue: Boolean);
begin
  if FTrackPowerOn = AValue then Exit;

  FTrackPowerOn := AValue;
  Invalidate; // fuerza redibujado
end;

procedure TFormEmergencia.AplicarRegionCircular;
var
  R: HRGN;
begin
  // Define una región elíptica que recorta la ventana
  R := CreateEllipticRgn(0, 0, Width, Height);
  SetWindowRgn(Handle, R, True);
end;

procedure TFormEmergencia.DibujarTextoCentrado(const S: string; Y: Integer);
var
  W: Integer;
begin
  W := Canvas.TextWidth(S);
  Canvas.TextOut((ClientWidth - W) div 2, Y, S);
end;

{ ============================================================================ }
{ === Ciclo de vida =========================================================== }
{ ============================================================================ }

procedure TFormEmergencia.FormCreate(Sender: TObject);
begin
  BorderStyle := bsNone;
  FormStyle := fsStayOnTop;
  Position := poDesigned;

  Width := 70;
  Height := 70;

  Color := clBtnFace;

  FTrackPowerOn := True;
  FDragging := False;

  AplicarRegionCircular;
end;

{ ============================================================================ }
{ === Renderizado ============================================================= }
{ ============================================================================ }

procedure TFormEmergencia.FormPaint(Sender: TObject);
begin
  // Color según estado
  if FTrackPowerOn then
    Canvas.Brush.Color := clRed
  else
    Canvas.Brush.Color := clMaroon;

  // Contorno
  Canvas.Pen.Color := clBlack;
  Canvas.Pen.Width := 3;
  Canvas.Ellipse(1, 1, Width - 1, Height - 1);

  // Texto
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Color := clWhite;
  Canvas.Font.Size := 14;
  Canvas.Font.Style := [fsBold];

  DibujarTextoCentrado('STOP', 15);
  DibujarTextoCentrado('VÍAS', 30);

  Canvas.Brush.Style := bsSolid;
end;

{ ============================================================================ }
{ === Interacción ============================================================= }
{ ============================================================================ }

procedure TFormEmergencia.FormMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
  begin
    FDragging := True;
    FDragOffsetX := X;
    FDragOffsetY := Y;
  end;
end;

procedure TFormEmergencia.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  P: TPoint;
begin
  if FDragging then
  begin
    P := Mouse.CursorPos;
    Left := P.X - FDragOffsetX;
    Top := P.Y - FDragOffsetY;
  end;
end;

procedure TFormEmergencia.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  // Fin arrastre
  if Button = mbRight then
  begin
    FDragging := False;
    Exit;
  end;

  // Toggle TrackPower
  if Button = mbLeft then
  begin
    if Assigned(FClient) then
    begin
      FTrackPowerOn := not FTrackPowerOn;
      FClient.TrackPower := FTrackPowerOn;
      Invalidate;
    end;
  end;
end;

procedure TFormEmergencia.FormDblClick(Sender: TObject);
begin
  Close;
end;

end.
