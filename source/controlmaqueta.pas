unit ControlMaqueta;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, ClientLocoNet, MaquetaModel, fgl;

type
  { Lista de zonas de la maqueta }
  TZonasList = specialize TFPGObjectList<TZonaMaqueta>;

type
  {
    Comando pendiente de desvío.

    Se utiliza como elemento de la cola interna para espaciar en el tiempo
    el envío de órdenes de conmutación al sistema LocoNet.
  }
  TPendingSwitchCmd = class
  public
    Addr: Integer;
    State: Boolean;
  end;

  { Lista de comandos pendientes de desvío }
  TPendingSwitchCmdList = specialize TFPGObjectList<TPendingSwitchCmd>;

  { Eventos expuestos por el componente }
  TOnMaquetaSensor = procedure(Sender: TObject; Addr: Integer; State: Boolean) of object;
  TOnMaquetaSwitch = procedure(Sender: TObject; Addr: Integer; State: Boolean) of object;
  TOnMaquetaRailCom = procedure(Sender: TObject; Sensor: Integer; DCC: Integer; Present: Boolean) of object;

type
  TControlMaqueta = class;

  {
    Listener interno que recibe eventos del cliente LocoNet y los redirige
    al componente propietario.
  }
  TControlMaquetaListener = class(TLocoNetListener)
  private
    FOwner: TControlMaqueta;
  public
    constructor Create(AOwner: TControlMaqueta);

    procedure LN_Sensor(Addr: Integer; State: Boolean); override;
    procedure LN_Switch(Addr: Integer; State: Boolean); override;
    procedure LN_RailCom(Sensor: Integer; DCC: Integer; Present: Boolean); override;
  end;

  {
    Componente de control de maqueta.

    Responsabilidades principales:
    - Asociarse a un cliente TClientLocoNet.
    - Mantener una colección de zonas de maqueta.
    - Actualizar el modelo en función de los eventos recibidos de LocoNet.
    - Exponer eventos de alto nivel para sensores, desvíos y RailCom.
    - Gestionar una cola temporizada de órdenes de desvío para evitar envíos
      demasiado seguidos.
  }
  TControlMaqueta = class(TComponent)
  private
    FLocoNet: TClientLocoNet;
    FListener: TControlMaquetaListener;
    FZonas: TZonasList;

    FOnSensor: TOnMaquetaSensor;
    FOnSwitch: TOnMaquetaSwitch;
    FOnRailCom: TOnMaquetaRailCom;

    FPendingSwitches: TPendingSwitchCmdList;
    FSwitchTimer: TTimer;
    FSwitchDelayMs: Integer;
    FProcessingSwitchQueue: Boolean;

    procedure SetLocoNet(AValue: TClientLocoNet);
    procedure SetSwitchDelayMs(AValue: Integer);

    procedure LocoNetSensor(Sender: TObject; Addr: Integer; State: Boolean);
    procedure LocoNetSwitch(Sender: TObject; Addr: Integer; State: Boolean);
    procedure LocoNetRailCom(Sender: TObject; Sensor: Integer; DCC: Integer; Present: Boolean);

    procedure SwitchTimerTick(Sender: TObject);
    procedure EnqueueSwitch(Addr: Integer; State: Boolean);
    procedure ProcessNextSwitchCommand;
    procedure ClearPendingSwitches;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AddZona(const Nombre: string): TZonaMaqueta;
    procedure SetSwitch(Addr: Integer; State: Boolean);

    property Zonas: TZonasList read FZonas;

  published
    property LocoNet: TClientLocoNet read FLocoNet write SetLocoNet;
    property SwitchDelayMs: Integer read FSwitchDelayMs write SetSwitchDelayMs default 100;

    property OnSensor: TOnMaquetaSensor read FOnSensor write FOnSensor;
    property OnSwitch: TOnMaquetaSwitch read FOnSwitch write FOnSwitch;
    property OnRailCom: TOnMaquetaRailCom read FOnRailCom write FOnRailCom;
  end;

procedure Register;

implementation

uses
  LResources;

procedure Register;
begin
  RegisterComponents('LocoNet', [TControlMaqueta]);
end;

{ TControlMaquetaListener }

constructor TControlMaquetaListener.Create(AOwner: TControlMaqueta);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TControlMaquetaListener.LN_Sensor(Addr: Integer; State: Boolean);
begin
  if Assigned(FOwner) then
    FOwner.LocoNetSensor(FOwner, Addr, State);
end;

procedure TControlMaquetaListener.LN_Switch(Addr: Integer; State: Boolean);
begin
  if Assigned(FOwner) then
    FOwner.LocoNetSwitch(FOwner, Addr, State);
end;

procedure TControlMaquetaListener.LN_RailCom(Sensor: Integer; DCC: Integer; Present: Boolean);
begin
  if Assigned(FOwner) then
    FOwner.LocoNetRailCom(FOwner, Sensor, DCC, Present);
end;

{ TControlMaqueta }

constructor TControlMaqueta.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FLocoNet := nil;
  FZonas := TZonasList.Create(True);
  FListener := TControlMaquetaListener.Create(Self);

  FPendingSwitches := TPendingSwitchCmdList.Create(True);
  FProcessingSwitchQueue := False;

  FSwitchDelayMs := 100;

  FSwitchTimer := TTimer.Create(Self);
  FSwitchTimer.Enabled := False;
  FSwitchTimer.Interval := FSwitchDelayMs;
  FSwitchTimer.OnTimer := @SwitchTimerTick;
end;

destructor TControlMaqueta.Destroy;
begin
  if Assigned(FLocoNet) then
    FLocoNet.RemoveListener(FListener);

  if Assigned(FSwitchTimer) then
    FSwitchTimer.Enabled := False;

  ClearPendingSwitches;

  FPendingSwitches.Free;
  FSwitchTimer.Free;
  FListener.Free;
  FZonas.Free;

  inherited Destroy;
end;

function TControlMaqueta.AddZona(const Nombre: string): TZonaMaqueta;
begin
  Result := TZonaMaqueta.Create;
  Result.Nombre := Nombre;
  FZonas.Add(Result);
end;

procedure TControlMaqueta.SetLocoNet(AValue: TClientLocoNet);
begin
  if FLocoNet = AValue then
    Exit;

  if Assigned(FLocoNet) then
    FLocoNet.RemoveListener(FListener);

  FLocoNet := AValue;

  if Assigned(FLocoNet) then
    FLocoNet.AddListener(FListener);
end;

procedure TControlMaqueta.SetSwitchDelayMs(AValue: Integer);
begin
  if AValue < 10 then
    AValue := 10;

  FSwitchDelayMs := AValue;

  if Assigned(FSwitchTimer) then
    FSwitchTimer.Interval := FSwitchDelayMs;
end;

procedure TControlMaqueta.ClearPendingSwitches;
begin
  if Assigned(FPendingSwitches) then
    FPendingSwitches.Clear;
end;

procedure TControlMaqueta.EnqueueSwitch(Addr: Integer; State: Boolean);
var
  Cmd: TPendingSwitchCmd;
  LastCmd: TPendingSwitchCmd;
begin
  {
    Evita duplicar consecutivamente el mismo comando en cola.
    No elimina duplicados no contiguos; únicamente evita repeticiones
    inmediatas del último comando pendiente.
  }
  if Assigned(FPendingSwitches) and (FPendingSwitches.Count > 0) then
  begin
    LastCmd := FPendingSwitches[FPendingSwitches.Count - 1];
    if Assigned(LastCmd) and (LastCmd.Addr = Addr) and (LastCmd.State = State) then
      Exit;
  end;

  Cmd := TPendingSwitchCmd.Create;
  Cmd.Addr := Addr;
  Cmd.State := State;
  FPendingSwitches.Add(Cmd);

  if Assigned(FSwitchTimer) and (not FSwitchTimer.Enabled) then
    FSwitchTimer.Enabled := True;
end;

procedure TControlMaqueta.ProcessNextSwitchCommand;
var
  Cmd: TPendingSwitchCmd;
begin
  if FProcessingSwitchQueue then
    Exit;
  if not Assigned(FLocoNet) then
    Exit;
  if not Assigned(FPendingSwitches) then
    Exit;
  if FPendingSwitches.Count = 0 then
    Exit;

  FProcessingSwitchQueue := True;
  try
    Cmd := FPendingSwitches[0];
    FLocoNet.SetSwitch(Cmd.Addr, Cmd.State);
    FPendingSwitches.Delete(0);
  finally
    FProcessingSwitchQueue := False;
  end;

  if Assigned(FSwitchTimer) then
    FSwitchTimer.Enabled := FPendingSwitches.Count > 0;
end;

procedure TControlMaqueta.SwitchTimerTick(Sender: TObject);
begin
  ProcessNextSwitchCommand;
end;

procedure TControlMaqueta.LocoNetSensor(Sender: TObject; Addr: Integer; State: Boolean);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  {
    Busca el elemento por dirección dentro de cada zona y actualiza el estado
    únicamente si corresponde a un sensor.
  }
  for Z in FZonas do
  begin
    E := Z.FindByAddr(Addr);
    if Assigned(E) and (E.Tipo = etSensor) then
      E.EstadoBool := State;
  end;

  if Assigned(FOnSensor) then
    FOnSensor(Self, Addr, State);
end;

procedure TControlMaqueta.LocoNetSwitch(Sender: TObject; Addr: Integer; State: Boolean);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  {
    Busca el elemento por dirección dentro de cada zona y actualiza el estado
    únicamente si corresponde a un desvío.
  }
  for Z in FZonas do
  begin
    E := Z.FindByAddr(Addr);
    if Assigned(E) and (E.Tipo = etSwitch) then
      E.EstadoBool := State;
  end;

  if Assigned(FOnSwitch) then
    FOnSwitch(Self, Addr, State);
end;

procedure TControlMaqueta.LocoNetRailCom(Sender: TObject; Sensor: Integer; DCC: Integer; Present: Boolean);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  {
    Para elementos de tipo etRail:
    - si Present = True, EstadoInt almacena la DCC detectada;
    - si Present = False, EstadoInt vuelve a 0.
  }
  for Z in FZonas do
  begin
    E := Z.FindByAddr(Sensor);
    if Assigned(E) and (E.Tipo = etRail) then
    begin
      if Present then
        E.EstadoInt := DCC
      else
        E.EstadoInt := 0;
    end;
  end;

  if Assigned(FOnRailCom) then
    FOnRailCom(Self, Sensor, DCC, Present);
end;

procedure TControlMaqueta.SetSwitch(Addr: Integer; State: Boolean);
begin
  if not Assigned(FLocoNet) then
    Exit;

  EnqueueSwitch(Addr, State);
end;

initialization
  {$I controlmaqueta.lrs}

end.
