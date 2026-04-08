// === UNIDAD ORGANIZADA Y DOCUMENTADA ===
// Motor de automatismos de maqueta. Funcionalidad intacta.

unit AutomatismosMaqueta;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, ClientLocoNet, ControlMaqueta;

const
  MAX_AUT_ADDR = 10239;

type
  TTipoCondicion = (
    tcNone,
    tcSensor,
    tcSwitch,
    tcRailCom,
    tcRailComEstado,
    tcSensorDireccion,
    tcRailComDireccion,
    tcRailComLocoValido,
    tcRailComDirActual,
    tcAlActivarGrupo,
    tcAlDesactivarGrupo
  );

  TTipoComando = (
    cmdNone,
    cmdSwitch,
    cmdLocoVel,
    cmdLocoDir,
    cmdFuncion,
    cmdActivarGrupo,
    cmdDesactivarGrupo,
    cmdDelay
  );

  TDCCSource = (
    dsFixed,
    dsRailComSensor
  );

  TRailComInfo = record
    Loco: Integer;          // última locomotora detectada en ese railcom
    Dir: Integer;           // última dirección conocida de esa locomotora
    HayLoco: Boolean;
    HayDir: Boolean;

    CurrentDCC: Integer;    // estado actual reportado por el railcom
    CurrentPresent: Boolean;
    HasCurrent: Boolean;
  end;

  TCondicionRegla = class
  public
    Tipo: TTipoCondicion;
    Addr: Integer;       // Sensor o Switch
    EstadoBool: Boolean; // ON/OFF
    Sensor: Integer;     // RailCom o SensorDireccion
    DCC: Integer;        // RailCom / SensorDireccion / RailComDireccion
    Present: Boolean;    // RailCom PRESENTE/AUSENTE
    Dir: Integer;        // Dirección 0/1
    constructor Create;
  end;

  TComandoRegla = class
  public
    Tipo: TTipoComando;
    Addr: Integer;
    EstadoBool: Boolean;

    DCCSource: TDCCSource;
    DCC: Integer;          // si DCCSource = dsFixed
    DCCSensor: Integer;    // si DCCSource = dsRailComSensor

    Velocidad: Integer;
    Direccion: Integer;
    FuncNum: Integer;
    FuncState: Boolean;
    Grupo: string;
    DelayMs: Integer;
    constructor Create;
  end;

  TListaCondiciones = specialize TFPGObjectList<TCondicionRegla>;
  TListaComandos = specialize TFPGObjectList<TComandoRegla>;

  TReglaAutomatismo = class
  public
    Condiciones: TListaCondiciones;
    Comandos: TListaComandos;
    TextoOriginal: string;
    EnEjecucion: Boolean;
    UltimoResultado: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

  TListaReglas = specialize TFPGObjectList<TReglaAutomatismo>;

  TGrupoAutomatismo = class
  public
    Nombre: string;
    Activo: Boolean;
    Reglas: TListaReglas;
    constructor Create;
    destructor Destroy; override;
  end;

  TMotorAutomatismos = class;  // forward declaration

  TMotorLocoListener = class(TLocoNetListener)
  private
    FOwner: TMotorAutomatismos;
  public
    constructor Create(AOwner: TMotorAutomatismos);
    procedure LN_LocoDir(Slot: Integer; Addr: Integer; Dir: Integer); override;
    procedure LN_Loco(Slot: Integer; Addr: Integer; Speed: Integer; Dir: Integer); override;
  end;

  TListaGrupos = specialize TFPGObjectList<TGrupoAutomatismo>;

  TOnEjecutarLocoVel = procedure(Sender: TObject; DCC, Velocidad: Integer) of object;
  TOnEjecutarLocoDir = procedure(Sender: TObject; DCC, Direccion: Integer) of object;
  TOnLogAutomatismo = procedure(Sender: TObject; const Msg: string) of object;
  TOnEjecutarFuncion = procedure(Sender: TObject; DCC, FuncNum: Integer; State: Boolean) of object;

  TMotorAutomatismos = class(TComponent)
  private
    FControl: TControlMaqueta;
    FGrupos: TListaGrupos;

    FOnEjecutarLocoVel: TOnEjecutarLocoVel;
    FOnEjecutarLocoDir: TOnEjecutarLocoDir;
    FOnLog: TOnLogAutomatismo;
    FOnEjecutarFuncion: TOnEjecutarFuncion;

    FOldOnSensor: TOnMaquetaSensor;
    FOldOnSwitch: TOnMaquetaSwitch;
    FOldOnRailCom: TOnMaquetaRailCom;

    FEvaluando: Boolean;

    FDirRequestPending: array[0..MAX_AUT_ADDR] of Boolean;
    FLocoDirKnown: array[0..MAX_AUT_ADDR] of Boolean;
    FLocoDir: array[0..MAX_AUT_ADDR] of Integer;

    FSensorKnown: array[0..MAX_AUT_ADDR] of Boolean;
    FSensorState: array[0..MAX_AUT_ADDR] of Boolean;

    FSwitchKnown: array[0..MAX_AUT_ADDR] of Boolean;
    FSwitchState: array[0..MAX_AUT_ADDR] of Boolean;

    FRailComInfo: array[0..MAX_AUT_ADDR] of TRailComInfo;

    FLocoListener: TMotorLocoListener;

    procedure RequestDireccionSiNecesaria(DCC: Integer);
    procedure LocoNetDireccion(Addr: Integer; Dir: Integer);
    procedure SetControl(AValue: TControlMaqueta);

    procedure HookSensor(Sender: TObject; Addr: Integer; State: Boolean);
    procedure HookSwitch(Sender: TObject; Addr: Integer; State: Boolean);
    procedure HookRailCom(Sender: TObject; Sensor: Integer; DCC: Integer; Present: Boolean);

    procedure Log(const S: string);

    function ParseBoolONOFF(const S: string; out Value: Boolean): Boolean;
    function ParseBoolPresencia(const S: string; out Value: Boolean): Boolean;
    function StripQuotes(const S: string): string;

    function SplitTopLevel(const S: string; Delim: Char): TStringList;
    function SplitConditionsAND(const S: string): TStringList;

    function ParseCondicion(const S: string; C: TCondicionRegla): Boolean;
    function ParseComando(const S: string; Cmd: TComandoRegla): Boolean;
    function ParseDCCArgument(const S: string; out Source: TDCCSource; out DCC, Sensor: Integer): Boolean;

    function FindGrupo(const Nombre: string): TGrupoAutomatismo;
    procedure EjecutarComando(Cmd: TComandoRegla);
    procedure EjecutarSecuencia(Regla: TReglaAutomatismo; Comandos: TListaComandos; Index: Integer = 0);

    procedure EjecutarReglasAlActivarGrupo(G: TGrupoAutomatismo);
    procedure EjecutarReglasAlDesactivarGrupo(G: TGrupoAutomatismo);

    procedure EvaluarReglas;
    function EvaluarRegla(R: TReglaAutomatismo): Boolean;
    function EvaluarCondicion(C: TCondicionRegla): Boolean;

    function ResolveDCC(Cmd: TComandoRegla; out DCC: Integer): Boolean;
    function SensorEnRango(Addr: Integer): Boolean;
    function DCCEnRango(DCC: Integer): Boolean;

    procedure ActualizarRailComInfo(Sensor: Integer; DCC: Integer; Present: Boolean);
    function GetRailComInfo(Addr: Integer): TRailComInfo;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AddGrupo(const Nombre: string; Activo: Boolean = False): TGrupoAutomatismo;
    function CargarGrupoDesdeTexto(const Nombre: string; Activo: Boolean; Lineas: TStrings): TGrupoAutomatismo;
    procedure Clear;

    procedure ActivarGrupo(const Nombre: string);
    procedure DesactivarGrupo(const Nombre: string);
    function GrupoActivo(const Nombre: string): Boolean;
    function BorrarGrupo(const Nombre: string): Boolean;

    property Grupos: TListaGrupos read FGrupos;
    property RailComInfo[Addr: Integer]: TRailComInfo read GetRailComInfo;

  published
    property Control: TControlMaqueta read FControl write SetControl;
    property OnEjecutarLocoVel: TOnEjecutarLocoVel read FOnEjecutarLocoVel write FOnEjecutarLocoVel;
    property OnEjecutarLocoDir: TOnEjecutarLocoDir read FOnEjecutarLocoDir write FOnEjecutarLocoDir;
    property OnLog: TOnLogAutomatismo read FOnLog write FOnLog;
    property OnEjecutarFuncion: TOnEjecutarFuncion read FOnEjecutarFuncion write FOnEjecutarFuncion;
  end;

  TDelayThread = class(TThread)
  private
    FMotor: TMotorAutomatismos;
    FComandos: TListaComandos;
    FRegla: TReglaAutomatismo;
    FIndex: Integer;
    FDelayMs: Integer;
  protected
    procedure Execute; override;
    procedure DoContinue;
  public
    constructor Create(AMotor: TMotorAutomatismos; ARegla: TReglaAutomatismo;
      AComandos: TListaComandos; AIndex, ADelayMs: Integer);
  end;

implementation

constructor TMotorLocoListener.Create(AOwner: TMotorAutomatismos);
begin
  inherited Create;
  FOwner := AOwner;
end;

procedure TMotorLocoListener.LN_LocoDir(Slot: Integer; Addr: Integer; Dir: Integer);
begin
  if Assigned(FOwner) then
    FOwner.LocoNetDireccion(Addr, Dir);
end;

procedure TMotorLocoListener.LN_Loco(Slot: Integer; Addr: Integer; Speed: Integer; Dir: Integer);
begin
  if Assigned(FOwner) then
    FOwner.LocoNetDireccion(Addr, Dir);
end;

function TrimUpper(const S: string): string;
begin
  Result := UpperCase(Trim(S));
end;

function StartsTextI(const Prefix, S: string): Boolean;
begin
  Result := CompareText(Copy(Trim(S), 1, Length(Prefix)), Prefix) = 0;
end;

function ExtractInsideParentheses(const S: string): string;
var
  p1, p2: Integer;
begin
  Result := '';
  p1 := Pos('(', S);
  p2 := Length(S);
  while (p2 > 0) and (S[p2] <> ')') do
        Dec(p2);
  if (p1 > 0) and (p2 > p1) then
    Result := Copy(S, p1 + 1, p2 - p1 - 1);
end;

{ TCondicionRegla }

constructor TCondicionRegla.Create;
begin
  Tipo := tcNone;
  Addr := 0;
  EstadoBool := False;
  Sensor := 0;
  DCC := 0;
  Present := False;
  Dir := 0;
end;

{ TComandoRegla }

constructor TComandoRegla.Create;
begin
  Tipo := cmdNone;
  Addr := 0;
  EstadoBool := False;
  DCCSource := dsFixed;
  DCC := 0;
  DCCSensor := -1;
  Velocidad := 0;
  Direccion := 0;
  FuncNum := 0;
  FuncState := False;
  Grupo := '';
  DelayMs := 0;
end;

{ TReglaAutomatismo }

constructor TReglaAutomatismo.Create;
begin
  Condiciones := TListaCondiciones.Create(True);
  Comandos := TListaComandos.Create(True);
  EnEjecucion := False;
  UltimoResultado := False;
end;

destructor TReglaAutomatismo.Destroy;
begin
  Comandos.Free;
  Condiciones.Free;
  inherited Destroy;
end;

{ TGrupoAutomatismo }

constructor TGrupoAutomatismo.Create;
begin
  Reglas := TListaReglas.Create(True);
  Activo := False;
end;

destructor TGrupoAutomatismo.Destroy;
begin
  Reglas.Free;
  inherited Destroy;
end;

{ TDelayThread }

constructor TDelayThread.Create(AMotor: TMotorAutomatismos; ARegla: TReglaAutomatismo;
  AComandos: TListaComandos; AIndex, ADelayMs: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FMotor := AMotor;
  FRegla := ARegla;
  FComandos := AComandos;
  FIndex := AIndex;
  FDelayMs := ADelayMs;
end;

procedure TDelayThread.Execute;
begin
  Sleep(FDelayMs);
  Synchronize(@DoContinue);
end;

procedure TDelayThread.DoContinue;
begin
  if Assigned(FMotor) then
    FMotor.EjecutarSecuencia(FRegla, FComandos, FIndex);
end;

{ TMotorAutomatismos }

function TMotorAutomatismos.GetRailComInfo(Addr: Integer): TRailComInfo;
begin
  FillChar(Result, SizeOf(Result), 0);

  if SensorEnRango(Addr) then
    Result := FRailComInfo[Addr];
end;

function TMotorAutomatismos.SensorEnRango(Addr: Integer): Boolean;
begin
  Result := (Addr >= 0) and (Addr <= MAX_AUT_ADDR);
end;

function TMotorAutomatismos.DCCEnRango(DCC: Integer): Boolean;
begin
  Result := (DCC >= 0) and (DCC <= MAX_AUT_ADDR);
end;

procedure TMotorAutomatismos.RequestDireccionSiNecesaria(DCC: Integer);
begin
  if not DCCEnRango(DCC) then Exit;
  if FLocoDirKnown[DCC] then Exit;
  if FDirRequestPending[DCC] then Exit;

  if Assigned(FControl) and Assigned(FControl.LocoNet) then
  begin
    FDirRequestPending[DCC] := True;
    Log(Format('Solicitando dirección para DCC=%d', [DCC]));
    FControl.LocoNet.RequestLocoSlotByDCC(DCC);
  end;
end;

procedure TMotorAutomatismos.LocoNetDireccion(Addr: Integer; Dir: Integer);
var
  i: Integer;
begin
  if not DCCEnRango(Addr) then Exit;

  FLocoDir[Addr] := Dir;
  FLocoDirKnown[Addr] := True;
  FDirRequestPending[Addr] := False;

  Log(Format('Evento Dirección: DCC=%d DIR=%d', [Addr, Dir]));

  for i := 0 to MAX_AUT_ADDR do
  begin
    if FRailComInfo[i].HayLoco and (FRailComInfo[i].Loco = Addr) then
    begin
      FRailComInfo[i].Dir := Dir;
      FRailComInfo[i].HayDir := True;
    end;
  end;

  EvaluarReglas;
end;

procedure TMotorAutomatismos.SetControl(AValue: TControlMaqueta);
begin
  if FControl = AValue then Exit;

  if Assigned(FControl) then
  begin
    if Assigned(FControl.LocoNet) and Assigned(FLocoListener) then
      FControl.LocoNet.RemoveListener(FLocoListener);

    FControl.OnSensor := FOldOnSensor;
    FControl.OnSwitch := FOldOnSwitch;
    FControl.OnRailCom := FOldOnRailCom;
  end;

  FControl := AValue;

  if Assigned(FControl) then
  begin
    FOldOnSensor := FControl.OnSensor;
    FOldOnSwitch := FControl.OnSwitch;
    FOldOnRailCom := FControl.OnRailCom;

    FControl.OnSensor := @HookSensor;
    FControl.OnSwitch := @HookSwitch;
    FControl.OnRailCom := @HookRailCom;

    if Assigned(FControl.LocoNet) and Assigned(FLocoListener) then
      FControl.LocoNet.AddListener(FLocoListener);
  end;
end;

procedure TMotorAutomatismos.Log(const S: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, S);
end;

constructor TMotorAutomatismos.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FGrupos := TListaGrupos.Create(True);
  FControl := nil;
  FOldOnSensor := nil;
  FOldOnSwitch := nil;
  FOldOnRailCom := nil;
  FEvaluando := False;

  FillChar(FDirRequestPending, SizeOf(FDirRequestPending), 0);
  FillChar(FLocoDirKnown, SizeOf(FLocoDirKnown), 0);
  FillChar(FLocoDir, SizeOf(FLocoDir), 0);

  FillChar(FSensorKnown, SizeOf(FSensorKnown), 0);
  FillChar(FSensorState, SizeOf(FSensorState), 0);

  FillChar(FSwitchKnown, SizeOf(FSwitchKnown), 0);
  FillChar(FSwitchState, SizeOf(FSwitchState), 0);

  FillChar(FRailComInfo, SizeOf(FRailComInfo), 0);

  FLocoListener := TMotorLocoListener.Create(Self);
end;

destructor TMotorAutomatismos.Destroy;
begin
  if Assigned(FControl) and Assigned(FControl.LocoNet) and Assigned(FLocoListener) then
    FControl.LocoNet.RemoveListener(FLocoListener);

  if Assigned(FControl) then
  begin
    FControl.OnSensor := FOldOnSensor;
    FControl.OnSwitch := FOldOnSwitch;
    FControl.OnRailCom := FOldOnRailCom;
  end;

  FLocoListener.Free;
  FGrupos.Free;
  inherited Destroy;
end;

function TMotorAutomatismos.SplitTopLevel(const S: string; Delim: Char): TStringList;
var
  i, Nivel: Integer;
  Parte: string;
begin
  Result := TStringList.Create;
  Nivel := 0;
  Parte := '';

  for i := 1 to Length(S) do
  begin
    case S[i] of
      '(':
        begin
          Inc(Nivel);
          Parte := Parte + S[i];
        end;
      ')':
        begin
          if Nivel > 0 then
            Dec(Nivel);
          Parte := Parte + S[i];
        end;
    else
      begin
        if (S[i] = Delim) and (Nivel = 0) then
        begin
          Result.Add(Trim(Parte));
          Parte := '';
        end
        else
          Parte := Parte + S[i];
      end;
    end;
  end;

  if Trim(Parte) <> '' then
    Result.Add(Trim(Parte));
end;

function TMotorAutomatismos.SplitConditionsAND(const S: string): TStringList;
var
  i, Nivel, StartPos: Integer;
  SLow: string;
  Parte: string;
begin
  Result := TStringList.Create;
  Nivel := 0;
  StartPos := 1;
  SLow := LowerCase(S);

  i := 1;
  while i <= Length(S) do
  begin
    if S[i] = '(' then
      Inc(Nivel)
    else if S[i] = ')' then
    begin
      if Nivel > 0 then
        Dec(Nivel);
    end;

    if (Nivel = 0) and (i <= Length(S) - 4) and (Copy(SLow, i, 5) = ' and ') then
    begin
      Parte := Trim(Copy(S, StartPos, i - StartPos));
      if Parte <> '' then
        Result.Add(Parte);
      StartPos := i + 5;
      Inc(i, 5);
      Continue;
    end;

    Inc(i);
  end;

  Parte := Trim(Copy(S, StartPos, MaxInt));
  if Parte <> '' then
    Result.Add(Parte);
end;

function TMotorAutomatismos.ParseBoolONOFF(const S: string; out Value: Boolean): Boolean;
var
  T: string;
begin
  T := TrimUpper(S);
  Result := True;
  if T = 'ON' then
    Value := True
  else if T = 'OFF' then
    Value := False
  else
    Result := False;
end;

function TMotorAutomatismos.ParseBoolPresencia(const S: string; out Value: Boolean): Boolean;
var
  T: string;
begin
  T := TrimUpper(S);
  Result := True;
  if (T = 'PRESENTE') or (T = 'ON') then
    Value := True
  else if (T = 'AUSENTE') or (T = 'OFF') then
    Value := False
  else
    Result := False;
end;

function TMotorAutomatismos.StripQuotes(const S: string): string;
var
  T: string;
begin
  T := Trim(S);
  if (Length(T) >= 2) and
     (((T[1] = '''') and (T[Length(T)] = '''')) or
      ((T[1] = '"') and (T[Length(T)] = '"'))) then
    Result := Copy(T, 2, Length(T) - 2)
  else
    Result := T;
end;

function TMotorAutomatismos.ParseCondicion(const S: string; C: TCondicionRegla): Boolean;
var
  Args: TStringList;
  Txt: string;
  B: Boolean;
begin
  Result := False;
  Txt := Trim(S);

  if SameText(Txt, 'AlActivarGrupo') then
  begin
    C.Tipo := tcAlActivarGrupo;
    Result := True;
    Exit;
  end
  else if SameText(Txt, 'AlDesactivarGrupo') then
  begin
    C.Tipo := tcAlDesactivarGrupo;
    Result := True;
    Exit;
  end
  else if StartsTextI('RailComLocoValido(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 1 then Exit;
      C.Tipo := tcRailComLocoValido;
      C.Sensor := StrToIntDef(Trim(Args[0]), -1);
      Result := SensorEnRango(C.Sensor);
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('RailComDir(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 2 then Exit;
      C.Tipo := tcRailComDirActual;
      C.Sensor := StrToIntDef(Trim(Args[0]), -1);
      C.Dir := StrToIntDef(Trim(Args[1]), -1);
      Result := SensorEnRango(C.Sensor) and ((C.Dir = 0) or (C.Dir = 1));
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('SensorDireccion(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 3 then Exit;
      C.Tipo := tcSensorDireccion;
      C.Sensor := StrToIntDef(Trim(Args[0]), -1);
      C.DCC := StrToIntDef(Trim(Args[1]), -1);
      C.Dir := StrToIntDef(Trim(Args[2]), -1);

      if (not SensorEnRango(C.Sensor)) or (not DCCEnRango(C.DCC)) or
         ((C.Dir <> 0) and (C.Dir <> 1)) then Exit;

      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('RailComDireccion(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 4 then Exit;
      C.Tipo := tcRailComDireccion;
      C.Sensor := StrToIntDef(Trim(Args[0]), -1);
      C.DCC := StrToIntDef(Trim(Args[1]), -1);

      if not ParseBoolPresencia(Args[2], B) then Exit;
      C.Present := B;

      C.Dir := StrToIntDef(Trim(Args[3]), -1);

      if (not SensorEnRango(C.Sensor)) or (not DCCEnRango(C.DCC)) or
         ((C.Dir <> 0) and (C.Dir <> 1)) then Exit;

      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('RailComEstado(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 2 then Exit;
      C.Tipo := tcRailComEstado;
      C.Sensor := StrToIntDef(Trim(Args[0]), -1);
      if not SensorEnRango(C.Sensor) then Exit;
      if not ParseBoolPresencia(Args[1], B) then Exit;
      C.Present := B;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('Sensor(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 2 then Exit;
      C.Tipo := tcSensor;
      C.Addr := StrToIntDef(Trim(Args[0]), -1);
      if not SensorEnRango(C.Addr) then Exit;
      if not ParseBoolONOFF(Args[1], B) then Exit;
      C.EstadoBool := B;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('Switch(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 2 then Exit;
      C.Tipo := tcSwitch;
      C.Addr := StrToIntDef(Trim(Args[0]), -1);
      if not SensorEnRango(C.Addr) then Exit;
      if not ParseBoolONOFF(Args[1], B) then Exit;
      C.EstadoBool := B;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('RailCom(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 3 then Exit;
      C.Tipo := tcRailCom;
      C.Sensor := StrToIntDef(Trim(Args[0]), -1);
      C.DCC := StrToIntDef(Trim(Args[1]), -1);
      if (not SensorEnRango(C.Sensor)) or (not DCCEnRango(C.DCC)) then Exit;
      if not ParseBoolPresencia(Args[2], B) then Exit;
      C.Present := B;
      Result := True;
    finally
      Args.Free;
    end;
  end;
end;

function TMotorAutomatismos.ParseDCCArgument(const S: string; out Source: TDCCSource;
  out DCC, Sensor: Integer): Boolean;
var
  Txt: string;
  Args: TStringList;
begin
  Result := False;
  Source := dsFixed;
  DCC := -1;
  Sensor := -1;
  Txt := Trim(S);

  if StartsTextI('RailComLoco(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 1 then Exit;
      Sensor := StrToIntDef(Trim(Args[0]), -1);
      if not SensorEnRango(Sensor) then Exit;
      Source := dsRailComSensor;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else
  begin
    DCC := StrToIntDef(Txt, -1);
    if not DCCEnRango(DCC) then Exit;
    Source := dsFixed;
    Result := True;
  end;
end;

function TMotorAutomatismos.ParseComando(const S: string; Cmd: TComandoRegla): Boolean;
var
  Args: TStringList;
  Txt: string;
  B: Boolean;
  DCCValue, Sensor: Integer;
  Source: TDCCSource;
begin
  Result := False;
  Txt := Trim(S);

  if StartsTextI('Switch(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 2 then Exit;
      Cmd.Tipo := cmdSwitch;
      Cmd.Addr := StrToIntDef(Trim(Args[0]), -1);
      if not SensorEnRango(Cmd.Addr) then Exit;
      if not ParseBoolONOFF(Args[1], B) then Exit;
      Cmd.EstadoBool := B;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('LocoVel(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 2 then Exit;
      if not ParseDCCArgument(Args[0], Source, DCCValue, Sensor) then Exit;

      Cmd.Tipo := cmdLocoVel;
      Cmd.DCCSource := Source;
      Cmd.DCC := DCCValue;
      Cmd.DCCSensor := Sensor;
      Cmd.Velocidad := StrToIntDef(Trim(Args[1]), -1);

      if Cmd.Velocidad < 0 then Exit;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('LocoDir(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 2 then Exit;
      if not ParseDCCArgument(Args[0], Source, DCCValue, Sensor) then Exit;

      Cmd.Tipo := cmdLocoDir;
      Cmd.DCCSource := Source;
      Cmd.DCC := DCCValue;
      Cmd.DCCSensor := Sensor;
      Cmd.Direccion := StrToIntDef(Trim(Args[1]), -1);

      if (Cmd.Direccion <> 0) and (Cmd.Direccion <> 1) then Exit;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('Funcion(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 3 then Exit;
      if not ParseDCCArgument(Args[0], Source, DCCValue, Sensor) then Exit;
      if not ParseBoolONOFF(Args[2], B) then Exit;

      Cmd.Tipo := cmdFuncion;
      Cmd.DCCSource := Source;
      Cmd.DCC := DCCValue;
      Cmd.DCCSensor := Sensor;
      Cmd.FuncNum := StrToIntDef(Trim(Args[1]), -1);
      Cmd.FuncState := B;

      if Cmd.FuncNum < 0 then Exit;
      Result := True;
    finally
      Args.Free;
    end;
  end
  else if StartsTextI('ActivarGrupo(', Txt) then
  begin
    Cmd.Tipo := cmdActivarGrupo;
    Cmd.Grupo := StripQuotes(ExtractInsideParentheses(Txt));
    Result := Cmd.Grupo <> '';
  end
  else if StartsTextI('DesactivarGrupo(', Txt) then
  begin
    Cmd.Tipo := cmdDesactivarGrupo;
    Cmd.Grupo := StripQuotes(ExtractInsideParentheses(Txt));
    Result := Cmd.Grupo <> '';
  end
  else if StartsTextI('Delay(', Txt) then
  begin
    Args := SplitTopLevel(ExtractInsideParentheses(Txt), ',');
    try
      if Args.Count <> 1 then Exit;
      Cmd.Tipo := cmdDelay;
      Cmd.DelayMs := StrToIntDef(Trim(Args[0]), -1);
      if Cmd.DelayMs < 0 then Exit;
      Result := True;
    finally
      Args.Free;
    end;
  end;
end;

function TMotorAutomatismos.FindGrupo(const Nombre: string): TGrupoAutomatismo;
var
  G: TGrupoAutomatismo;
begin
  Result := nil;
  for G in FGrupos do
    if SameText(G.Nombre, Nombre) then
      Exit(G);
end;

function TMotorAutomatismos.AddGrupo(const Nombre: string; Activo: Boolean): TGrupoAutomatismo;
begin
  Result := FindGrupo(Nombre);
  if Assigned(Result) then Exit;

  Result := TGrupoAutomatismo.Create;
  Result.Nombre := Nombre;
  Result.Activo := Activo;
  FGrupos.Add(Result);
end;

function TMotorAutomatismos.CargarGrupoDesdeTexto(const Nombre: string; Activo: Boolean;
  Lineas: TStrings): TGrupoAutomatismo;
var
  i, p: Integer;
  L, ParteCond, ParteCmds: string;
  R: TReglaAutomatismo;
  SLCond, SLCmd: TStringList;
  Cnd: TCondicionRegla;
  Cmd: TComandoRegla;
begin
  Result := AddGrupo(Nombre, Activo);
  Result.Reglas.Clear;
  Result.Activo := Activo;

  for i := 0 to Lineas.Count - 1 do
  begin
    L := Trim(Lineas[i]);
    if L = '' then Continue;
    if (L[1] = ';') or (L[1] = '#') then Continue;

    p := Pos(' entonces ', LowerCase(L));
    if p = 0 then
      raise Exception.CreateFmt('Línea %d sin "entonces": %s', [i + 1, L]);

    if Copy(LowerCase(L), 1, 3) <> 'si ' then
      raise Exception.CreateFmt('Línea %d debe comenzar por "Si ": %s', [i + 1, L]);

    ParteCond := Trim(Copy(L, 4, p - 4));
    ParteCmds := Trim(Copy(L, p + Length(' entonces '), MaxInt));

    R := TReglaAutomatismo.Create;
    try
      R.TextoOriginal := L;

      SLCond := SplitConditionsAND(ParteCond);
      try
        if SLCond.Count = 0 then
          raise Exception.CreateFmt('No hay condiciones en línea %d', [i + 1]);

        for p := 0 to SLCond.Count - 1 do
        begin
          Cnd := TCondicionRegla.Create;
          if not ParseCondicion(SLCond[p], Cnd) then
          begin
            Cnd.Free;
            raise Exception.CreateFmt('Condición inválida en línea %d: %s', [i + 1, SLCond[p]]);
          end;
          R.Condiciones.Add(Cnd);
        end;
      finally
        SLCond.Free;
      end;

      SLCmd := SplitTopLevel(ParteCmds, ',');
      try
        if SLCmd.Count = 0 then
          raise Exception.CreateFmt('No hay comandos en línea %d', [i + 1]);

        for p := 0 to SLCmd.Count - 1 do
        begin
          Cmd := TComandoRegla.Create;
          if not ParseComando(SLCmd[p], Cmd) then
          begin
            Cmd.Free;
            raise Exception.CreateFmt('Comando inválido en línea %d: %s', [i + 1, SLCmd[p]]);
          end;
          R.Comandos.Add(Cmd);
        end;
      finally
        SLCmd.Free;
      end;

      Result.Reglas.Add(R);
    except
      R.Free;
      raise;
    end;
  end;
end;

procedure TMotorAutomatismos.Clear;
begin
  FGrupos.Clear;
end;

procedure TMotorAutomatismos.ActivarGrupo(const Nombre: string);
var
  G: TGrupoAutomatismo;
begin
  G := FindGrupo(Nombre);
  if Assigned(G) then
  begin
    if not G.Activo then
    begin
      G.Activo := True;
      Log('Activado grupo: ' + G.Nombre);
      EjecutarReglasAlActivarGrupo(G);
      EvaluarReglas;
    end;
  end
  else
    Log('No existe el grupo a activar: ' + Nombre);
end;

procedure TMotorAutomatismos.DesactivarGrupo(const Nombre: string);
var
  G: TGrupoAutomatismo;
begin
  G := FindGrupo(Nombre);
  if Assigned(G) then
  begin
    if G.Activo then
    begin
      G.Activo := False;
      Log('Desactivado grupo: ' + G.Nombre);
      EjecutarReglasAlDesactivarGrupo(G);
    end;
  end
  else
    Log('No existe el grupo a desactivar: ' + Nombre);
end;

function TMotorAutomatismos.GrupoActivo(const Nombre: string): Boolean;
var
  G: TGrupoAutomatismo;
begin
  G := FindGrupo(Nombre);
  Result := Assigned(G) and G.Activo;
end;

function TMotorAutomatismos.BorrarGrupo(const Nombre: string): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := FGrupos.Count - 1 downto 0 do
  begin
    if SameText(FGrupos[i].Nombre, Nombre) then
    begin
      Log('Borrado grupo: ' + FGrupos[i].Nombre);
      FGrupos.Delete(i);
      Result := True;
      Exit;
    end;
  end;
end;

procedure TMotorAutomatismos.EjecutarReglasAlActivarGrupo(G: TGrupoAutomatismo);
var
  R: TReglaAutomatismo;
  C: TCondicionRegla;
  TieneCondActivar: Boolean;
begin
  if not Assigned(G) then Exit;

  for R in G.Reglas do
  begin
    TieneCondActivar := False;
    for C in R.Condiciones do
      if C.Tipo = tcAlActivarGrupo then
      begin
        TieneCondActivar := True;
        Break;
      end;

    if TieneCondActivar and (not R.EnEjecucion) then
    begin
      Log('Regla cumplida [' + G.Nombre + ']: ' + R.TextoOriginal);
      R.EnEjecucion := True;
      EjecutarSecuencia(R, R.Comandos, 0);
    end;
  end;
end;

procedure TMotorAutomatismos.EjecutarReglasAlDesactivarGrupo(G: TGrupoAutomatismo);
var
  R: TReglaAutomatismo;
  C: TCondicionRegla;
  TieneCondDesactivar: Boolean;
begin
  if not Assigned(G) then Exit;

  for R in G.Reglas do
  begin
    TieneCondDesactivar := False;
    for C in R.Condiciones do
      if C.Tipo = tcAlDesactivarGrupo then
      begin
        TieneCondDesactivar := True;
        Break;
      end;

    if TieneCondDesactivar and (not R.EnEjecucion) then
    begin
      Log('Regla cumplida [' + G.Nombre + ']: ' + R.TextoOriginal);
      R.EnEjecucion := True;
      EjecutarSecuencia(R, R.Comandos, 0);
    end;
  end;
end;

procedure TMotorAutomatismos.EjecutarSecuencia(Regla: TReglaAutomatismo;
  Comandos: TListaComandos; Index: Integer);
var
  Cmd: TComandoRegla;
  Th: TDelayThread;
begin
  if not Assigned(Regla) then Exit;

  if not Assigned(Comandos) then
  begin
    Regla.EnEjecucion := False;
    Exit;
  end;

  if Index >= Comandos.Count then
  begin
    Regla.EnEjecucion := False;
    Exit;
  end;

  Cmd := Comandos[Index];

  case Cmd.Tipo of
    cmdDelay:
      begin
        Log(Format('DELAY %d ms', [Cmd.DelayMs]));
        Th := TDelayThread.Create(Self, Regla, Comandos, Index + 1, Cmd.DelayMs);
        Th.Start;
      end;
  else
    begin
      EjecutarComando(Cmd);
      EjecutarSecuencia(Regla, Comandos, Index + 1);
    end;
  end;
end;

function TMotorAutomatismos.ResolveDCC(Cmd: TComandoRegla; out DCC: Integer): Boolean;
begin
  Result := False;
  DCC := -1;

  case Cmd.DCCSource of
    dsFixed:
      begin
        if not DCCEnRango(Cmd.DCC) then Exit;
        DCC := Cmd.DCC;
        Result := True;
      end;

    dsRailComSensor:
      begin
        if not SensorEnRango(Cmd.DCCSensor) then Exit;
        if FRailComInfo[Cmd.DCCSensor].HayLoco and (FRailComInfo[Cmd.DCCSensor].Loco > 0) then
        begin
          DCC := FRailComInfo[Cmd.DCCSensor].Loco;
          Result := True;
        end;
      end;
  end;
end;

procedure TMotorAutomatismos.EjecutarComando(Cmd: TComandoRegla);
var
  DCCResuelto: Integer;
begin
  case Cmd.Tipo of
    cmdSwitch:
      begin
        if Assigned(FControl) then
        begin
          Log(Format('SWITCH %d -> %s', [Cmd.Addr, BoolToStr(Cmd.EstadoBool, True)]));
          FControl.SetSwitch(Cmd.Addr, Cmd.EstadoBool);
        end;
      end;

    cmdLocoVel:
      begin
        if not ResolveDCC(Cmd, DCCResuelto) then
        begin
          Log('LOCO VEL cancelado: no se pudo resolver DCC');
          Exit;
        end;

        Log(Format('LOCO VEL DCC=%d V=%d', [DCCResuelto, Cmd.Velocidad]));
        if Assigned(FOnEjecutarLocoVel) then
          FOnEjecutarLocoVel(Self, DCCResuelto, Cmd.Velocidad);
      end;

    cmdLocoDir:
      begin
        if not ResolveDCC(Cmd, DCCResuelto) then
        begin
          Log('LOCO DIR cancelado: no se pudo resolver DCC');
          Exit;
        end;

        Log(Format('LOCO DIR DCC=%d DIR=%d', [DCCResuelto, Cmd.Direccion]));
        if Assigned(FOnEjecutarLocoDir) then
          FOnEjecutarLocoDir(Self, DCCResuelto, Cmd.Direccion);
      end;

    cmdFuncion:
      begin
        if not ResolveDCC(Cmd, DCCResuelto) then
        begin
          Log('FUNCION cancelada: no se pudo resolver DCC');
          Exit;
        end;

        Log(Format('FUNCION DCC=%d F=%d STATE=%s',
          [DCCResuelto, Cmd.FuncNum, BoolToStr(Cmd.FuncState, True)]));
        if Assigned(FOnEjecutarFuncion) then
          FOnEjecutarFuncion(Self, DCCResuelto, Cmd.FuncNum, Cmd.FuncState);
      end;

    cmdActivarGrupo:
      ActivarGrupo(Cmd.Grupo);

    cmdDesactivarGrupo:
      DesactivarGrupo(Cmd.Grupo);

    cmdDelay:
      ; // no hace nada aquí
  end;
end;

function TMotorAutomatismos.EvaluarCondicion(C: TCondicionRegla): Boolean;
begin
  Result := False;

  case C.Tipo of
    tcSensor:
      Result := SensorEnRango(C.Addr) and
                FSensorKnown[C.Addr] and
                (FSensorState[C.Addr] = C.EstadoBool);

    tcSwitch:
      Result := SensorEnRango(C.Addr) and
                FSwitchKnown[C.Addr] and
                (FSwitchState[C.Addr] = C.EstadoBool);

    tcRailCom:
      Result := SensorEnRango(C.Sensor) and
                FRailComInfo[C.Sensor].HasCurrent and
                (FRailComInfo[C.Sensor].CurrentDCC = C.DCC) and
                (FRailComInfo[C.Sensor].CurrentPresent = C.Present);

    tcRailComEstado:
      Result := SensorEnRango(C.Sensor) and
                FRailComInfo[C.Sensor].HasCurrent and
                (FRailComInfo[C.Sensor].CurrentPresent = C.Present);

    tcSensorDireccion:
      Result := SensorEnRango(C.Sensor) and
                FSensorKnown[C.Sensor] and
                FSensorState[C.Sensor] and
                DCCEnRango(C.DCC) and
                FLocoDirKnown[C.DCC] and
                (FLocoDir[C.DCC] = C.Dir);

    tcRailComDireccion:
      Result := SensorEnRango(C.Sensor) and
                FRailComInfo[C.Sensor].HasCurrent and
                (FRailComInfo[C.Sensor].CurrentDCC = C.DCC) and
                (FRailComInfo[C.Sensor].CurrentPresent = C.Present) and
                FRailComInfo[C.Sensor].HayDir and
                (FRailComInfo[C.Sensor].Dir = C.Dir);

    tcRailComLocoValido:
      Result := SensorEnRango(C.Sensor) and
                FRailComInfo[C.Sensor].HayLoco and
                (FRailComInfo[C.Sensor].Loco > 0);

    tcRailComDirActual:
      Result := SensorEnRango(C.Sensor) and
                FRailComInfo[C.Sensor].HayDir and
                (FRailComInfo[C.Sensor].Dir = C.Dir);

    tcAlActivarGrupo,
    tcAlDesactivarGrupo:
      Result := False;
  end;
end;

function TMotorAutomatismos.EvaluarRegla(R: TReglaAutomatismo): Boolean;
var
  C: TCondicionRegla;
begin
  Result := True;

  if not Assigned(R) then
  begin
    Result := False;
    Exit;
  end;

  if R.Condiciones.Count = 0 then
  begin
    Result := False;
    Exit;
  end;

  for C in R.Condiciones do
  begin
    if (C.Tipo = tcAlActivarGrupo) or (C.Tipo = tcAlDesactivarGrupo) then
    begin
      Result := False;
      Exit;
    end;

    if not EvaluarCondicion(C) then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

procedure TMotorAutomatismos.EvaluarReglas;
var
  G: TGrupoAutomatismo;
  R: TReglaAutomatismo;
  Cumple: Boolean;
begin
  if FEvaluando then Exit;
  FEvaluando := True;
  try
    for G in FGrupos do
    begin
      if not G.Activo then Continue;

      for R in G.Reglas do
      begin
        Cumple := EvaluarRegla(R);

        if Cumple and (not R.UltimoResultado) and (not R.EnEjecucion) then
        begin
          Log('Regla cumplida [' + G.Nombre + ']: ' + R.TextoOriginal);
          R.EnEjecucion := True;
          EjecutarSecuencia(R, R.Comandos, 0);
        end;

        R.UltimoResultado := Cumple;
      end;
    end;
  finally
    FEvaluando := False;
  end;
end;

procedure TMotorAutomatismos.ActualizarRailComInfo(Sensor: Integer; DCC: Integer; Present: Boolean);
begin
  if not SensorEnRango(Sensor) then Exit;

  FRailComInfo[Sensor].HasCurrent := True;
  FRailComInfo[Sensor].CurrentDCC := DCC;
  FRailComInfo[Sensor].CurrentPresent := Present;

  if Present and DCCEnRango(DCC) and (DCC > 0) then
  begin
    FRailComInfo[Sensor].Loco := DCC;
    FRailComInfo[Sensor].HayLoco := True;

    if FLocoDirKnown[DCC] then
    begin
      FRailComInfo[Sensor].Dir := FLocoDir[DCC];
      FRailComInfo[Sensor].HayDir := True;
    end
    else
      RequestDireccionSiNecesaria(DCC);
  end;
end;

procedure TMotorAutomatismos.HookSensor(Sender: TObject; Addr: Integer; State: Boolean);
begin
  if Assigned(FOldOnSensor) then
    FOldOnSensor(Sender, Addr, State);

  if SensorEnRango(Addr) then
  begin
    FSensorKnown[Addr] := True;
    FSensorState[Addr] := State;
  end;

  EvaluarReglas;
end;

procedure TMotorAutomatismos.HookSwitch(Sender: TObject; Addr: Integer; State: Boolean);
begin
  if Assigned(FOldOnSwitch) then
    FOldOnSwitch(Sender, Addr, State);

  if SensorEnRango(Addr) then
  begin
    FSwitchKnown[Addr] := True;
    FSwitchState[Addr] := State;
  end;

  EvaluarReglas;
end;

procedure TMotorAutomatismos.HookRailCom(Sender: TObject; Sensor: Integer; DCC: Integer; Present: Boolean);
begin
  if Assigned(FOldOnRailCom) then
    FOldOnRailCom(Sender, Sensor, DCC, Present);

  Log(Format('HookRailCom -> Sensor=%d DCC=%d Present=%s',
    [Sensor, DCC, BoolToStr(Present, True)]));

  ActualizarRailComInfo(Sensor, DCC, Present);
  EvaluarReglas;
end;

end.
