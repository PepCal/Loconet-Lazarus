unit ControlLoco;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ClientLocoNet;

type
  { Evento general de cambio de estado de la locomotora }
  TOnLocoChange = procedure(Sender: TObject; Speed: Integer; Dir: Integer) of object;

  { Evento para notificar el cambio de una función individual }
  TOnLocoFunctionChange = procedure(Sender: TObject; FuncNo: Integer; State: Boolean) of object;

  { Evento para notificar el cambio del conjunto de funciones }
  TOnLocoFunctionsChange = procedure(Sender: TObject; Funcs: Word) of object;

type
  TControlLoco = class;

type
  {
    Listener interno que recibe eventos del cliente LocoNet y los filtra
    para la dirección DCC asociada al componente propietario.
  }
  TControlLocoListener = class(TLocoNetListener)
  private
    FOwner: TControlLoco;
  public
    constructor Create(AOwner: TControlLoco);

    procedure LN_LocoSpeed(Slot: Integer; Addr: Integer; Speed: Integer); override;
    procedure LN_LocoDir(Slot: Integer; Addr: Integer; Dir: Integer); override;
    procedure LN_Loco(Slot: Integer; Addr: Integer; Speed: Integer; Dir: Integer); override;

    procedure LN_LocoFunc(Slot: Integer; Addr: Integer; FuncNo: Integer; State: Boolean); override;
    procedure LN_LocoFuncs(Slot: Integer; Addr: Integer; Funcs: Word); override;
  end;

  {
    Componente de control de una locomotora DCC concreta.

    Funcionalidad:
    - Mantiene el estado local de velocidad, dirección y funciones.
    - Envía órdenes al cliente LocoNet asociado.
    - Escucha actualizaciones de red para la DCC configurada.
    - Expone eventos de cambio para integración con formularios y controles.
  }
  TControlLoco = class(TComponent)
  private
    FClient: TClientLocoNet;
    FListener: TControlLocoListener;

    FDCC: Integer;
    FSpeed: Integer;
    FDir: Integer;
    FFuncs: Word;

    FOnChange: TOnLocoChange;
    FOnFunctionChange: TOnLocoFunctionChange;
    FOnFunctionsChange: TOnLocoFunctionsChange;

    {
      Marca interna para evitar realimentación entre cambios locales y cambios
      recibidos desde la red.
    }
    FUpdatingFromNet: Boolean;

    procedure SetClient(AValue: TClientLocoNet);
    procedure SetSpeed(AValue: Integer);
    procedure SetDir(AValue: Integer);
    procedure SetDCC(AValue: Integer);

    procedure DoLocoFromNet(Speed, Dir: Integer);
    procedure DoFunctionFromNet(FuncNo: Integer; State: Boolean);
    procedure DoFunctionsFromNet(Funcs: Word);

    function FuncBit(FuncNo: Integer): Word;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Stop;
    procedure Forward;
    procedure Backward;

    procedure SetFunction(FuncNo: Integer; State: Boolean);
    function GetFunction(FuncNo: Integer): Boolean;
    procedure ClearFunctions;

  published
    property Client: TClientLocoNet read FClient write SetClient;
    property DCC: Integer read FDCC write SetDCC default 0;
    property Speed: Integer read FSpeed write SetSpeed default 0;
    property Direction: Integer read FDir write SetDir default 1;

    property OnChange: TOnLocoChange read FOnChange write FOnChange;
    property OnFunctionChange: TOnLocoFunctionChange read FOnFunctionChange write FOnFunctionChange;
    property OnFunctionsChange: TOnLocoFunctionsChange read FOnFunctionsChange write FOnFunctionsChange;
  end;

procedure Register;

implementation

uses
  LResources;

procedure Register;
begin
  RegisterComponents('LocoNet', [TControlLoco]);
end;

{ TControlLocoListener }

constructor TControlLocoListener.Create(AOwner: TControlLoco);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TControlLocoListener.LN_Loco(Slot: Integer; Addr: Integer; Speed: Integer; Dir: Integer);
begin
  if Assigned(FOwner) and (Addr = FOwner.FDCC) then
    FOwner.DoLocoFromNet(Speed, Dir);
end;

procedure TControlLocoListener.LN_LocoSpeed(Slot: Integer; Addr: Integer; Speed: Integer);
begin
  if Assigned(FOwner) and (Addr = FOwner.FDCC) then
    FOwner.DoLocoFromNet(Speed, FOwner.FDir);
end;

procedure TControlLocoListener.LN_LocoDir(Slot: Integer; Addr: Integer; Dir: Integer);
begin
  if Assigned(FOwner) and (Addr = FOwner.FDCC) then
    FOwner.DoLocoFromNet(FOwner.FSpeed, Dir);
end;

procedure TControlLocoListener.LN_LocoFunc(Slot: Integer; Addr: Integer; FuncNo: Integer; State: Boolean);
begin
  if Assigned(FOwner) and (Addr = FOwner.FDCC) then
    FOwner.DoFunctionFromNet(FuncNo, State);
end;

procedure TControlLocoListener.LN_LocoFuncs(Slot: Integer; Addr: Integer; Funcs: Word);
begin
  if Assigned(FOwner) and (Addr = FOwner.FDCC) then
    FOwner.DoFunctionsFromNet(Funcs);
end;

{ TControlLoco }

constructor TControlLoco.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FDir := 1;
  FFuncs := 0;
  FListener := TControlLocoListener.Create(Self);
end;

destructor TControlLoco.Destroy;
begin
  if Assigned(FClient) then
    FClient.RemoveListener(FListener);

  FListener.Free;

  inherited Destroy;
end;

function TControlLoco.FuncBit(FuncNo: Integer): Word;
begin
  if (FuncNo < 0) or (FuncNo > 15) then
    Exit(0);

  Result := Word(1) shl FuncNo;
end;

procedure TControlLoco.SetClient(AValue: TClientLocoNet);
begin
  if FClient = AValue then
    Exit;

  if Assigned(FClient) then
    FClient.RemoveListener(FListener);

  FClient := AValue;

  if Assigned(FClient) then
    FClient.AddListener(FListener);
end;

procedure TControlLoco.DoLocoFromNet(Speed, Dir: Integer);
begin
  FUpdatingFromNet := True;
  try
    if (FSpeed <> Speed) or (FDir <> Dir) then
    begin
      FSpeed := Speed;
      FDir := Dir;

      if Assigned(FOnChange) then
        FOnChange(Self, FSpeed, FDir);
    end;
  finally
    FUpdatingFromNet := False;
  end;
end;

procedure TControlLoco.DoFunctionFromNet(FuncNo: Integer; State: Boolean);
var
  Bit: Word;
  Changed: Boolean;
begin
  if (FuncNo < 0) or (FuncNo > 8) then
    Exit;

  Bit := FuncBit(FuncNo);
  Changed := False;

  FUpdatingFromNet := True;
  try
    if State then
    begin
      if (FFuncs and Bit) = 0 then
      begin
        FFuncs := FFuncs or Bit;
        Changed := True;
      end;
    end
    else
    begin
      if (FFuncs and Bit) <> 0 then
      begin
        FFuncs := FFuncs and not Bit;
        Changed := True;
      end;
    end;

    if Changed then
    begin
      if Assigned(FOnFunctionChange) then
        FOnFunctionChange(Self, FuncNo, State);

      if Assigned(FOnFunctionsChange) then
        FOnFunctionsChange(Self, FFuncs);
    end;
  finally
    FUpdatingFromNet := False;
  end;
end;

procedure TControlLoco.DoFunctionsFromNet(Funcs: Word);
var
  i: Integer;
  OldFuncs: Word;
begin
  OldFuncs := FFuncs;
  if OldFuncs = Funcs then
    Exit;

  FUpdatingFromNet := True;
  try
    FFuncs := Funcs;

    for i := 0 to 8 do
    begin
      if ((OldFuncs xor FFuncs) and FuncBit(i)) <> 0 then
      begin
        if Assigned(FOnFunctionChange) then
          FOnFunctionChange(Self, i, (FFuncs and FuncBit(i)) <> 0);
      end;
    end;

    if Assigned(FOnFunctionsChange) then
      FOnFunctionsChange(Self, FFuncs);
  finally
    FUpdatingFromNet := False;
  end;
end;

procedure TControlLoco.SetDCC(AValue: Integer);
var
  funcs: Word;
  i: Integer;
begin
  if FDCC = AValue then
    Exit;

  FDCC := AValue;

  if (FDCC = 0) or (FClient = nil) then
    Exit;

  { Solicita al cliente la actualización del slot correspondiente a la DCC.
    La operación es asíncrona y no bloqueante. }
  FClient.RequestLocoSlotByDCC(FDCC);

  { Lee el estado de funciones disponible en caché en ese momento. }
  funcs := FClient.GetLocoFunctionsByDCC(FDCC);

  { Notificación global del estado de funciones }
  if Assigned(FOnFunctionsChange) then
    FOnFunctionsChange(Self, funcs);

  { Notificación individual de funciones F0..F8 }
  for i := 0 to 8 do
    if Assigned(FOnFunctionChange) then
      FOnFunctionChange(Self, i, (funcs and (Word(1) shl i)) <> 0);
end;

procedure TControlLoco.SetSpeed(AValue: Integer);
begin
  FSpeed := AValue;

  if not FUpdatingFromNet then
    if Assigned(FClient) and (FDCC <> 0) then
      FClient.SetLocoSpeedByDCC(FDCC, FSpeed);

  if Assigned(FOnChange) then
    FOnChange(Self, FSpeed, FDir);
end;

procedure TControlLoco.SetDir(AValue: Integer);
begin
  FDir := AValue;

  if not FUpdatingFromNet then
  begin
    if Assigned(FClient) and (FDCC <> 0) then
      FClient.SetLocoDirByDCC(FDCC, FDir);
  end;

  if Assigned(FOnChange) then
    FOnChange(Self, FSpeed, FDir);
end;

procedure TControlLoco.SetFunction(FuncNo: Integer; State: Boolean);
var
  Bit: Word;
begin
  if (FuncNo < 0) or (FuncNo > 8) then
    Exit;
  if FDCC = 0 then
    Exit;

  Bit := FuncBit(FuncNo);

  if State then
    FFuncs := FFuncs or Bit
  else
    FFuncs := FFuncs and not Bit;

  if not FUpdatingFromNet then
  begin
    if Assigned(FClient) then
      FClient.SetLocoFunctionByDCC(FDCC, FuncNo, State);
  end;

  if Assigned(FOnFunctionChange) then
    FOnFunctionChange(Self, FuncNo, State);

  if Assigned(FOnFunctionsChange) then
    FOnFunctionsChange(Self, FFuncs);
end;

function TControlLoco.GetFunction(FuncNo: Integer): Boolean;
begin
  if (FuncNo < 0) or (FuncNo > 8) then
    Exit(False);

  Result := (FFuncs and FuncBit(FuncNo)) <> 0;
end;

procedure TControlLoco.ClearFunctions;
begin
  FFuncs := 0;

  if Assigned(FOnFunctionsChange) then
    FOnFunctionsChange(Self, FFuncs);
end;

procedure TControlLoco.Stop;
begin
  SetSpeed(0);
end;

procedure TControlLoco.Forward;
begin
  SetDir(1);
end;

procedure TControlLoco.Backward;
begin
  SetDir(0);
end;

initialization
  {$I controlloco.lrs}

end.
