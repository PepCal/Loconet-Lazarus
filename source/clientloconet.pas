unit ClientLocoNet;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sockets;

const
  MAX_SLOTS = 128;

  { Bits del campo DIRF (opcode A1) }
  LN_DIRF_DIR = $20;
  LN_DIRF_F0  = $10;
  LN_DIRF_F4  = $08;
  LN_DIRF_F3  = $04;
  LN_DIRF_F2  = $02;
  LN_DIRF_F1  = $01;

  { Bits del campo SND (opcode A2) }
  LN_SND_F5 = $01;
  LN_SND_F6 = $02;
  LN_SND_F7 = $04;
  LN_SND_F8 = $08;

type
  {
    Estado cacheado de un slot LocoNet.

    - Valid indica si el slot contiene datos válidos ya resueltos.
    - Addr almacena la dirección DCC asociada al slot.
    - Speed y Dir representan el último estado conocido.
    - Funcs contiene F0..F8 en los bits 0..8.
  }
  TSlot = record
    Valid: Boolean;
    Addr: Integer;
    Speed: Integer;
    Dir: Integer;
    Funcs: Word;
  end;

  {
    Estructura de operaciones pendientes para locomotoras cuya relación
    DCC -> slot todavía no se conoce en el momento de emitir la orden.

    Cuando llega posteriormente un E7 con la resolución del slot, se aplican
    los cambios pendientes almacenados aquí.
  }
  TPendingLoco = record
    Active: Boolean;
    Addr: Integer;

    HasSpeed: Boolean;
    Speed: Integer;

    HasDir: Boolean;
    Dir: Integer;

    HasFuncs: Boolean;
    FuncMask: Word;    // Máscara de funciones a modificar
    FuncValues: Word;  // Valores objetivo para dichas funciones
  end;

type
  {
    Clase base para receptores externos de eventos LocoNet.

    Permite subscribirse al componente sin depender exclusivamente de eventos
    publicados. Todas las llamadas son virtuales para poder sobreescribir
    únicamente las necesarias.
  }
  TLocoNetListener = class
  public
    procedure LN_Sensor(Addr: Integer; State: Boolean); virtual;
    procedure LN_Switch(Addr: Integer; State: Boolean); virtual;
    procedure LN_RailCom(Sensor: Integer; DCC: Integer; Present: Boolean); virtual;
    procedure LN_LocoSpeed(Slot: Integer; Addr: Integer; Speed: Integer); virtual;
    procedure LN_LocoDir(Slot: Integer; Addr: Integer; Dir: Integer); virtual;
    procedure LN_Loco(Slot: Integer; Addr: Integer; Speed: Integer; Dir: Integer); virtual;
    procedure LN_LocoFunc(Slot: Integer; Addr: Integer; FuncNo: Integer; State: Boolean); virtual;
    procedure LN_LocoFuncs(Slot: Integer; Addr: Integer; Funcs: Word); virtual;
  end;

  {
    Hilo de recepción del cliente TCP.

    Se encarga de leer líneas procedentes del servidor LocoNet/TCP y de
    sincronizar su procesado con el hilo principal mediante Synchronize.
  }
  TLocoNetThread = class(TThread)
  private
    FOwner: TObject;
    FText: string;
    FLine: string;
    procedure DoReceive;
    procedure DoLine;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TObject);
  end;

  { Tipos de eventos expuestos por el componente }
  TOnReceive   = procedure(Sender: TObject; const Text: string) of object;
  TOnSensor    = procedure(Sender: TObject; Addr: Integer; State: Boolean) of object;
  TOnSwitch    = procedure(Sender: TObject; Addr: Integer; State: Boolean) of object;
  TOnSlot      = procedure(Sender: TObject; Slot: Integer; Loco: Integer; Speed: Integer; Dir: Integer) of object;
  TOnLocoSpeed = procedure(Sender: TObject; Slot: Integer; Addr: Integer; Speed: Integer) of object;
  TOnLocoDir   = procedure(Sender: TObject; Slot: Integer; Addr: Integer; Dir: Integer) of object;
  TOnLoco      = procedure(Sender: TObject; Slot: Integer; Addr: Integer; Speed: Integer; Dir: Integer) of object;
  TOnRailCom   = procedure(Sender: TObject; Sensor: Integer; DCC: Integer; Present: Boolean) of object;
  TOnLocoFunc  = procedure(Sender: TObject; Slot: Integer; Addr: Integer; FuncNo: Integer; State: Boolean) of object;
  TOnLocoFuncs = procedure(Sender: TObject; Slot: Integer; Addr: Integer; Funcs: Word) of object;

  {
    Cliente LocoNet/TCP para Lazarus.

    Funcionalidad principal:
    - Conexión/desconexión con servidor LocoNet/TCP.
    - Envío de órdenes de desvíos, locomotoras y corriente de vía.
    - Decodificación de mensajes RECEIVE del servidor.
    - Cache interno de slots LocoNet y funciones F0..F8.
    - Resolución diferida DCC -> slot mediante peticiones BF/E7.
    - Notificación por eventos y por listeners.
  }
  TClientLocoNet = class(TComponent)
  private
    FSocket: LongInt;
    FHost: string;
    FPort: Integer;
    FOnReceive: TOnReceive;
    FOnSensor: TOnSensor;
    FOnSwitch: TOnSwitch;
    FOnSlot: TOnSlot;
    FOnLocoSpeed: TOnLocoSpeed;
    FOnLocoDir: TOnLocoDir;
    FOnLoco: TOnLoco;
    FOnRailCom: TOnRailCom;
    FOnLocoFunc: TOnLocoFunc;
    FOnLocoFuncs: TOnLocoFuncs;
    FThread: TLocoNetThread;
    FBuffer: string;
    FSlots: array[0..MAX_SLOTS - 1] of TSlot;
    FPending: array[0..MAX_SLOTS - 1] of TPendingLoco;
    FTrackPower: Boolean;
    FListeners: TList;

    procedure SetHost(AValue: string);
    procedure SetPort(AValue: Integer);
    procedure SetTrackPowerProp(AValue: Boolean);

    procedure ParseLine(const line: string);

    procedure SendBytes(const Data: array of Byte);
    function CalcChecksum(const Data: array of Byte): Byte;

    procedure RequestSlotData(Slot: Integer);
    procedure RequestLocoSlot(DCC: Integer);

    procedure AddPendingLoco(DCC, Speed, Dir: Integer);
    procedure AddPendingFunc(DCC, FuncNo: Integer; State: Boolean);

    procedure SetLocoSpeed(Slot: Integer; Speed: Integer);
    procedure SetLocoDir(Slot: Integer; Dir: Integer);
    procedure SetLocoFunction(Slot: Integer; FuncNo: Integer; State: Boolean);

    function FuncBit(FuncNo: Integer): Word;
    function BuildDIRF(Slot: Integer): Byte;
    function BuildSND(Slot: Integer): Byte;
    procedure NotifyFunctionChanges(Slot, Addr: Integer; OldFuncs, NewFuncs: Word);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Connect;
    procedure Disconnect;

    procedure SendText(const AText: string);

    procedure SetSwitch(Address: Integer; State: Boolean);
    procedure SetLocoSpeedByDCC(DCC: Integer; Speed: Integer);
    procedure SetLocoDirByDCC(DCC: Integer; Dir: Integer);
    procedure SetLocoFunctionByDCC(DCC: Integer; FuncNo: Integer; State: Boolean);
    procedure SetTrackPower(State: Boolean);

    procedure AddListener(L: TLocoNetListener);
    procedure RemoveListener(L: TLocoNetListener);
    procedure RequestLocoSlotByDCC(DCC: Integer);

    function GetLocoFunctionsBySlot(Slot: Integer): Word;
    function GetLocoFunctionsByDCC(DCC: Integer): Word;

  published
    property Host: string read FHost write SetHost;
    property Port: Integer read FPort write SetPort default 1234;

    property TrackPower: Boolean read FTrackPower write SetTrackPowerProp;

    property OnReceive: TOnReceive read FOnReceive write FOnReceive;
    property OnSensor: TOnSensor read FOnSensor write FOnSensor;
    property OnSwitch: TOnSwitch read FOnSwitch write FOnSwitch;
    property OnSlot: TOnSlot read FOnSlot write FOnSlot;
    property OnLocoSpeed: TOnLocoSpeed read FOnLocoSpeed write FOnLocoSpeed;
    property OnLocoDir: TOnLocoDir read FOnLocoDir write FOnLocoDir;
    property OnLoco: TOnLoco read FOnLoco write FOnLoco;
    property OnRailCom: TOnRailCom read FOnRailCom write FOnRailCom;
    property OnLocoFunc: TOnLocoFunc read FOnLocoFunc write FOnLocoFunc;
    property OnLocoFuncs: TOnLocoFuncs read FOnLocoFuncs write FOnLocoFuncs;
  end;

procedure Register;

implementation

uses
  LResources;

{ TLocoNetListener }

procedure TLocoNetListener.LN_Sensor(Addr: Integer; State: Boolean);
begin
end;

procedure TLocoNetListener.LN_Switch(Addr: Integer; State: Boolean);
begin
end;

procedure TLocoNetListener.LN_RailCom(Sensor: Integer; DCC: Integer; Present: Boolean);
begin
end;

procedure TLocoNetListener.LN_Loco(Slot: Integer; Addr: Integer; Speed: Integer; Dir: Integer);
begin
end;

procedure TLocoNetListener.LN_LocoSpeed(Slot: Integer; Addr: Integer; Speed: Integer);
begin
end;

procedure TLocoNetListener.LN_LocoDir(Slot: Integer; Addr: Integer; Dir: Integer);
begin
end;

procedure TLocoNetListener.LN_LocoFunc(Slot: Integer; Addr: Integer; FuncNo: Integer; State: Boolean);
begin
end;

procedure TLocoNetListener.LN_LocoFuncs(Slot: Integer; Addr: Integer; Funcs: Word);
begin
end;

{ Registro del componente }

procedure Register;
begin
  RegisterComponents('LocoNet', [TClientLocoNet]);
end;

{ TLocoNetThread }

constructor TLocoNetThread.Create(AOwner: TObject);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FOwner := AOwner;
end;

procedure TLocoNetThread.DoLine;
var
  client: TClientLocoNet;
begin
  client := TClientLocoNet(FOwner);

  client.ParseLine(FLine);

  if Assigned(client.FOnReceive) then
    client.FOnReceive(client, FLine);
end;

procedure TLocoNetThread.DoReceive;
var
  client: TClientLocoNet;
begin
  client := TClientLocoNet(FOwner);

  if Assigned(client.FOnReceive) then
    client.FOnReceive(client, FText);
end;

procedure TLocoNetThread.Execute;
var
  buffer: array[0..255] of Char;
  len: Integer;
  s, line: string;
  client: TClientLocoNet;
begin
  client := TClientLocoNet(FOwner);

  while not Terminated do
  begin
    if client.FSocket <= 0 then
    begin
      Sleep(10);
      Continue;
    end;

    len := fprecv(client.FSocket, @buffer, SizeOf(buffer), 0);

    if Terminated then
      Break;

    { Conexión cerrada por el extremo remoto }
    if len = 0 then
      Break;

    { Error de socket: se reintenta tras una breve pausa }
    if len < 0 then
    begin
      Sleep(10);
      Continue;
    end;

    SetString(s, buffer, len);
    client.FBuffer := client.FBuffer + s;

    while Pos(#10, client.FBuffer) > 0 do
    begin
      line := Copy(client.FBuffer, 1, Pos(#10, client.FBuffer) - 1);
      Delete(client.FBuffer, 1, Pos(#10, client.FBuffer));

      line := StringReplace(line, #13, '', [rfReplaceAll]);

      if line <> '' then
      begin
        FLine := line;
        TThread.Synchronize(nil, @DoLine);

        if Terminated then
          Break;
      end;
    end;
  end;
end;

{ TClientLocoNet }

constructor TClientLocoNet.Create(AOwner: TComponent);
var
  i: Integer;
begin
  inherited Create(AOwner);

  FPort := 1234;
  FListeners := TList.Create;

  for i := 0 to MAX_SLOTS - 1 do
  begin
    FSlots[i].Valid := False;
    FSlots[i].Addr  := 0;
    FSlots[i].Speed := 0;
    FSlots[i].Dir   := 0;
    FSlots[i].Funcs := 0;
  end;

  for i := 0 to MAX_SLOTS - 1 do
  begin
    FPending[i].Active := False;
    FPending[i].HasSpeed := False;
    FPending[i].HasDir := False;
    FPending[i].HasFuncs := False;
    FPending[i].FuncMask := 0;
    FPending[i].FuncValues := 0;
  end;
end;

destructor TClientLocoNet.Destroy;
begin
  if FSocket > 0 then
  begin
    CloseSocket(FSocket);
    FSocket := -1;
  end;

  FListeners.Free;

  inherited Destroy;
end;

procedure TClientLocoNet.Connect;
var
  addr: TInetSockAddr;
begin
  if FSocket > 0 then
    Exit; // Ya conectado

  FSocket := fpsocket(AF_INET, SOCK_STREAM, 0);
  if FSocket < 0 then
    raise Exception.Create('Error creando socket');

  FillChar(addr, SizeOf(addr), 0);
  addr.sin_family := AF_INET;
  addr.sin_port := htons(FPort);
  addr.sin_addr := StrToNetAddr(FHost);

  if fpconnect(FSocket, @addr, SizeOf(addr)) <> 0 then
    raise Exception.Create('Error conectando');

  FThread := TLocoNetThread.Create(Self);
end;

procedure TClientLocoNet.Disconnect;
begin
  if FSocket > 0 then
  begin
    CloseSocket(FSocket);
    FSocket := -1;
  end;

  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;
    FThread := nil;
  end;
end;

procedure TClientLocoNet.SetHost(AValue: string);
begin
  if FHost = AValue then
    Exit;
  FHost := AValue;
end;

procedure TClientLocoNet.SetPort(AValue: Integer);
begin
  if FPort = AValue then
    Exit;
  FPort := AValue;
end;

procedure TClientLocoNet.SendText(const AText: string);
var
  s: string;
begin
  if FSocket <= 0 then
    Exit;

  s := AText + #13#10;
  fpsend(FSocket, PChar(s), Length(s), 0);
end;

procedure TClientLocoNet.SendBytes(const Data: array of Byte);
var
  i: Integer;
  s: string;
begin
  s := 'SEND ';
  for i := 0 to High(Data) do
    s := s + IntToHex(Data[i], 2) + ' ';

  SendText(Trim(s));
end;

function TClientLocoNet.CalcChecksum(const Data: array of Byte): Byte;
var
  i: Integer;
  xorv: Byte;
begin
  xorv := 0;
  for i := 0 to High(Data) - 1 do
    xorv := xorv xor Data[i];
  Result := xorv xor $FF;
end;

function TClientLocoNet.FuncBit(FuncNo: Integer): Word;
begin
  if (FuncNo < 0) or (FuncNo > 8) then
    Exit(0);
  Result := Word(1) shl FuncNo;
end;

function TClientLocoNet.BuildDIRF(Slot: Integer): Byte;
var
  f: Word;
begin
  Result := 0;

  if (Slot < 0) or (Slot >= MAX_SLOTS) then
    Exit;

  f := FSlots[Slot].Funcs;

  if FSlots[Slot].Dir = 1 then
    Result := Result or LN_DIRF_DIR;

  if (f and FuncBit(0)) <> 0 then Result := Result or LN_DIRF_F0;
  if (f and FuncBit(1)) <> 0 then Result := Result or LN_DIRF_F1;
  if (f and FuncBit(2)) <> 0 then Result := Result or LN_DIRF_F2;
  if (f and FuncBit(3)) <> 0 then Result := Result or LN_DIRF_F3;
  if (f and FuncBit(4)) <> 0 then Result := Result or LN_DIRF_F4;
end;

function TClientLocoNet.BuildSND(Slot: Integer): Byte;
var
  f: Word;
begin
  Result := 0;

  if (Slot < 0) or (Slot >= MAX_SLOTS) then
    Exit;

  f := FSlots[Slot].Funcs;

  if (f and FuncBit(5)) <> 0 then Result := Result or LN_SND_F5;
  if (f and FuncBit(6)) <> 0 then Result := Result or LN_SND_F6;
  if (f and FuncBit(7)) <> 0 then Result := Result or LN_SND_F7;
  if (f and FuncBit(8)) <> 0 then Result := Result or LN_SND_F8;
end;

procedure TClientLocoNet.NotifyFunctionChanges(Slot, Addr: Integer; OldFuncs, NewFuncs: Word);
var
  i, j: Integer;
  oldState, newState: Boolean;
begin
  if OldFuncs = NewFuncs then
    Exit;

  if Assigned(FOnLocoFuncs) then
    FOnLocoFuncs(Self, Slot, Addr, NewFuncs);

  for j := 0 to FListeners.Count - 1 do
    if TObject(FListeners[j]) is TLocoNetListener then
      TLocoNetListener(FListeners[j]).LN_LocoFuncs(Slot, Addr, NewFuncs);

  for i := 0 to 8 do
  begin
    oldState := (OldFuncs and FuncBit(i)) <> 0;
    newState := (NewFuncs and FuncBit(i)) <> 0;

    if oldState <> newState then
    begin
      if Assigned(FOnLocoFunc) then
        FOnLocoFunc(Self, Slot, Addr, i, newState);

      for j := 0 to FListeners.Count - 1 do
        if TObject(FListeners[j]) is TLocoNetListener then
          TLocoNetListener(FListeners[j]).LN_LocoFunc(Slot, Addr, i, newState);
    end;
  end;
end;

procedure TClientLocoNet.RequestSlotData(Slot: Integer);
var
  data: array[0..2] of Byte;
begin
  data[0] := $BB;
  data[1] := Slot and $7F;
  data[2] := CalcChecksum(data);

  SendBytes(data);
end;

procedure TClientLocoNet.RequestLocoSlot(DCC: Integer);
var
  data: array[0..3] of Byte;
begin
  data[0] := $BF;
  data[1] := (DCC shr 7) and $7F;
  data[2] := DCC and $7F;
  data[3] := CalcChecksum(data);

  SendBytes(data);
end;

procedure TClientLocoNet.ParseLine(const line: string);
var
  dataStr: string;
  parts: TStringArray;
  bytes: array of Byte;
  i, j: Integer;
  addr: Integer;
  slot, speed, dir: Integer;
  dcc: Integer;
  adrLow, adrHigh, dirf, snd: Integer;
  present: Integer;
  state: Boolean;
  oldFuncs, newFuncs: Word;
begin
  if Pos('RECEIVE ', line) <> 1 then
    Exit;

  dataStr := Copy(line, 9, Length(line));

  parts := dataStr.Split(' ');
  SetLength(bytes, Length(parts));

  for i := 0 to High(parts) do
    bytes[i] := StrToInt('$' + parts[i]);

  if Length(bytes) = 0 then
    Exit;

  case bytes[0] of
    $82:
      FTrackPower := False;

    $83:
      FTrackPower := True;

    { Mensaje de sensor }
    $B2:
    begin
      if Length(bytes) >= 3 then
      begin
        addr := ((bytes[1] and $7F) shl 1) or ((bytes[2] and $20) shr 5);
        state := (bytes[2] and $10) <> 0;

        if Assigned(FOnSensor) then
          FOnSensor(Self, addr, state);

        for j := 0 to FListeners.Count - 1 do
          if TObject(FListeners[j]) is TLocoNetListener then
            TLocoNetListener(FListeners[j]).LN_Sensor(addr, state);
      end;
    end;

    { Mensaje RailCom }
    $D0:
    begin
      if Length(bytes) < 6 then
        Exit;

      addr := (bytes[2] and $7F) + ((bytes[1] and $1F) shl 7) + 1;
      if (bytes[1] and $20) <> 0 then
        present := 1
      else
        present := 0;
      dcc := bytes[4] and $7F;

      if Assigned(FOnRailCom) then
        FOnRailCom(Self, addr, dcc, present = 1);

      for j := 0 to FListeners.Count - 1 do
        if TObject(FListeners[j]) is TLocoNetListener then
          TLocoNetListener(FListeners[j]).LN_RailCom(addr, dcc, present = 1);
    end;

    { Mensaje de desvío }
    $B0:
    begin
      if Length(bytes) < 4 then
        Exit;

      addr := bytes[1] + ((bytes[2] and $0F) shl 7) + 1;
      state := (bytes[2] and $20) = 0;

      if Assigned(FOnSwitch) then
        FOnSwitch(Self, addr, state);

      for j := 0 to FListeners.Count - 1 do
        if TObject(FListeners[j]) is TLocoNetListener then
          TLocoNetListener(FListeners[j]).LN_Switch(addr, state);
    end;

    { Respuesta de datos completos de slot }
    $E7:
    begin
      if Length(bytes) < 11 then
        Exit;

      slot    := bytes[2];
      adrLow  := bytes[4];
      speed   := bytes[5];
      dirf    := bytes[6];
      adrHigh := bytes[9];
      snd     := bytes[10];

      if adrHigh = 0 then
        dcc := adrLow
      else
        dcc := ((adrHigh and $7F) shl 7) or (adrLow and $7F);

      dir := Ord((dirf and LN_DIRF_DIR) <> 0);

      if speed <= 1 then
        speed := 0;

      if (slot < MAX_SLOTS) and (dcc > 0) then
      begin
        oldFuncs := FSlots[slot].Funcs;

        FSlots[slot].Valid := True;
        FSlots[slot].Addr  := dcc;
        FSlots[slot].Speed := speed;
        FSlots[slot].Dir   := dir;
        FSlots[slot].Funcs := 0;

        if (dirf and LN_DIRF_F0) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(0);
        if (dirf and LN_DIRF_F1) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(1);
        if (dirf and LN_DIRF_F2) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(2);
        if (dirf and LN_DIRF_F3) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(3);
        if (dirf and LN_DIRF_F4) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(4);

        if (snd and LN_SND_F5) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(5);
        if (snd and LN_SND_F6) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(6);
        if (snd and LN_SND_F7) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(7);
        if (snd and LN_SND_F8) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(8);

        { Aplicar órdenes pendientes para esta locomotora una vez resuelto el slot }
        for i := 0 to MAX_SLOTS - 1 do
        begin
          if FPending[i].Active and (FPending[i].Addr = dcc) then
          begin
            if FPending[i].HasSpeed then
              SetLocoSpeed(slot, FPending[i].Speed);

            if FPending[i].HasDir then
              SetLocoDir(slot, FPending[i].Dir);

            if FPending[i].HasFuncs then
            begin
              for j := 0 to 8 do
                if (FPending[i].FuncMask and FuncBit(j)) <> 0 then
                  SetLocoFunction(slot, j, (FPending[i].FuncValues and FuncBit(j)) <> 0);
            end;

            FPending[i].Active := False;
            Break;
          end;
        end;

        if Assigned(FOnLocoSpeed) then
          FOnLocoSpeed(Self, slot, dcc, speed);

        if Assigned(FOnLocoDir) then
          FOnLocoDir(Self, slot, dcc, dir);

        for j := 0 to FListeners.Count - 1 do
          if TObject(FListeners[j]) is TLocoNetListener then
          begin
            TLocoNetListener(FListeners[j]).LN_LocoSpeed(slot, dcc, speed);
            TLocoNetListener(FListeners[j]).LN_LocoDir(slot, dcc, dir);
          end;

        newFuncs := FSlots[slot].Funcs;
        NotifyFunctionChanges(slot, dcc, oldFuncs, newFuncs);

        if Assigned(FOnLoco) then
          FOnLoco(Self, slot, dcc, speed, dir);

        for j := 0 to FListeners.Count - 1 do
          if TObject(FListeners[j]) is TLocoNetListener then
            TLocoNetListener(FListeners[j]).LN_Loco(slot, dcc, speed, dir);
      end;
    end;

    { Cambio de velocidad }
    $A0:
    begin
      if Length(bytes) >= 3 then
      begin
        slot  := bytes[1];
        speed := bytes[2] and $7F;

        if slot < MAX_SLOTS then
        begin
          if not FSlots[slot].Valid then
          begin
            RequestSlotData(slot);
            Exit;
          end;

          FSlots[slot].Speed := speed;
          dcc := FSlots[slot].Addr;

          if Assigned(FOnLocoSpeed) then
            FOnLocoSpeed(Self, slot, dcc, speed);

          for j := 0 to FListeners.Count - 1 do
            if TObject(FListeners[j]) is TLocoNetListener then
              TLocoNetListener(FListeners[j]).LN_LocoSpeed(slot, dcc, speed);
        end;
      end;
    end;

    { Cambio de dirección y funciones F0..F4 }
    $A1:
    begin
      if Length(bytes) >= 3 then
      begin
        slot := bytes[1];
        dirf := bytes[2];

        if slot < MAX_SLOTS then
        begin
          if not FSlots[slot].Valid then
          begin
            RequestSlotData(slot);
            Exit;
          end;

          dcc := FSlots[slot].Addr;
          oldFuncs := FSlots[slot].Funcs;
          dir := FSlots[slot].Dir;

          FSlots[slot].Dir := Ord((dirf and LN_DIRF_DIR) <> 0);

          if (dirf and LN_DIRF_F0) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(0)
                                       else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(0);
          if (dirf and LN_DIRF_F1) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(1)
                                       else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(1);
          if (dirf and LN_DIRF_F2) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(2)
                                       else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(2);
          if (dirf and LN_DIRF_F3) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(3)
                                       else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(3);
          if (dirf and LN_DIRF_F4) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(4)
                                       else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(4);

          {
            Notificar siempre el estado de direcci�n recibido desde la central.

            Motivo: SetLocoDir actualiza FSlots[slot].Dir antes de enviar el
            paquete $A1 para poder construir DIRF. Cuando vuelve el eco de la
            central, la comparaci�n contra la cach� puede indicar falsamente
            que no hay cambio y entonces no se actualiza el TControlLoco
            visible. La velocidad no ten�a este problema porque $A0 notificaba
            siempre.
          }
          if Assigned(FOnLocoDir) then
            FOnLocoDir(Self, slot, dcc, FSlots[slot].Dir);

          for j := 0 to FListeners.Count - 1 do
            if TObject(FListeners[j]) is TLocoNetListener then
              TLocoNetListener(FListeners[j]).LN_LocoDir(slot, dcc, FSlots[slot].Dir);

          newFuncs := FSlots[slot].Funcs;
          NotifyFunctionChanges(slot, dcc, oldFuncs, newFuncs);
        end;
      end;
    end;

    { Cambio de funciones F5..F8 }
    $A2:
    begin
      if Length(bytes) >= 3 then
      begin
        slot := bytes[1];
        snd  := bytes[2];

        if slot < MAX_SLOTS then
        begin
          if not FSlots[slot].Valid then
          begin
            RequestSlotData(slot);
            Exit;
          end;

          dcc := FSlots[slot].Addr;
          oldFuncs := FSlots[slot].Funcs;

          if (snd and LN_SND_F5) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(5)
                                     else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(5);
          if (snd and LN_SND_F6) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(6)
                                     else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(6);
          if (snd and LN_SND_F7) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(7)
                                     else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(7);
          if (snd and LN_SND_F8) <> 0 then FSlots[slot].Funcs := FSlots[slot].Funcs or FuncBit(8)
                                     else FSlots[slot].Funcs := FSlots[slot].Funcs and not FuncBit(8);

          newFuncs := FSlots[slot].Funcs;
          NotifyFunctionChanges(slot, dcc, oldFuncs, newFuncs);
        end;
      end;
    end;
  end;
end;

procedure TClientLocoNet.AddListener(L: TLocoNetListener);
begin
  if (L <> nil) and (FListeners.IndexOf(L) < 0) then
    FListeners.Add(L);
end;

procedure TClientLocoNet.RemoveListener(L: TLocoNetListener);
begin
  if L <> nil then
    FListeners.Remove(L);
end;

procedure TClientLocoNet.RequestLocoSlotByDCC(DCC: Integer);
begin
  RequestLocoSlot(DCC);
end;

procedure TClientLocoNet.SetSwitch(Address: Integer; State: Boolean);
var
  data: array[0..3] of Byte;
  addr0: Integer;
begin
  addr0 := Address - 1;

  data[0] := $B0;
  data[1] := addr0 and $7F;
  data[2] := (addr0 shr 7) and $0F;

  if State then
    data[2] := data[2] or $10
  else
    data[2] := data[2] or $30;

  data[3] := CalcChecksum(data);
  SendBytes(data);

  { Segundo envío para completar la secuencia de conmutación }
  data[2] := data[2] and not $10;
  data[3] := CalcChecksum(data);
  SendBytes(data);
end;

procedure TClientLocoNet.SetLocoSpeed(Slot: Integer; Speed: Integer);
var
  data: array[0..3] of Byte;
begin
  if (Slot < 0) or (Slot >= MAX_SLOTS) then
    Exit;

  FSlots[Slot].Speed := Speed;

  data[0] := $A0;
  data[1] := Slot and $7F;

  if Speed <= 0 then
    data[2] := 0
  else
    data[2] := Speed and $7F;

  data[3] := CalcChecksum(data);

  SendBytes(data);
end;

procedure TClientLocoNet.SetLocoDir(Slot: Integer; Dir: Integer);
var
  data: array[0..3] of Byte;
begin
  if (Slot < 0) or (Slot >= MAX_SLOTS) then
    Exit;

  FSlots[Slot].Dir := Ord(Dir <> 0);

  data[0] := $A1;
  data[1] := Slot and $7F;
  data[2] := BuildDIRF(Slot);
  data[3] := CalcChecksum(data);

  SendBytes(data);
end;

procedure TClientLocoNet.SetLocoFunction(Slot: Integer; FuncNo: Integer; State: Boolean);
var
  data: array[0..3] of Byte;
  bit: Word;
  oldFuncs, newFuncs: Word;
  dcc: Integer;
begin
  if (Slot < 0) or (Slot >= MAX_SLOTS) then
    Exit;
  if (FuncNo < 0) or (FuncNo > 8) then
    Exit;

  bit := FuncBit(FuncNo);
  oldFuncs := FSlots[Slot].Funcs;
  dcc := FSlots[Slot].Addr;

  if State then
    FSlots[Slot].Funcs := FSlots[Slot].Funcs or bit
  else
    FSlots[Slot].Funcs := FSlots[Slot].Funcs and not bit;

  newFuncs := FSlots[Slot].Funcs;

  NotifyFunctionChanges(Slot, dcc, oldFuncs, newFuncs);

  if FuncNo <= 4 then
  begin
    data[0] := $A1;
    data[1] := Slot and $7F;
    data[2] := BuildDIRF(Slot);
    data[3] := CalcChecksum(data);
    SendBytes(data);
  end
  else
  begin
    data[0] := $A2;
    data[1] := Slot and $7F;
    data[2] := BuildSND(Slot);
    data[3] := CalcChecksum(data);
    SendBytes(data);
  end;
end;

procedure TClientLocoNet.AddPendingLoco(DCC: Integer; Speed: Integer; Dir: Integer);
var
  i: Integer;
begin
  { Si ya existe una entrada pendiente para esta DCC, se actualiza }
  for i := 0 to MAX_SLOTS - 1 do
  begin
    if FPending[i].Active and (FPending[i].Addr = DCC) then
    begin
      if Speed <> -1 then
      begin
        FPending[i].HasSpeed := True;
        FPending[i].Speed := Speed;
      end;

      if Dir <> -1 then
      begin
        FPending[i].HasDir := True;
        FPending[i].Dir := Dir;
      end;

      Exit;
    end;
  end;

  { Si no existe, se crea una nueva entrada pendiente }
  for i := 0 to MAX_SLOTS - 1 do
  begin
    if not FPending[i].Active then
    begin
      FPending[i].Active := True;
      FPending[i].Addr := DCC;

      FPending[i].HasSpeed := (Speed <> -1);
      FPending[i].Speed := Speed;

      FPending[i].HasDir := (Dir <> -1);
      FPending[i].Dir := Dir;

      FPending[i].HasFuncs := False;
      FPending[i].FuncMask := 0;
      FPending[i].FuncValues := 0;
      Exit;
    end;
  end;
end;

procedure TClientLocoNet.AddPendingFunc(DCC, FuncNo: Integer; State: Boolean);
var
  i: Integer;
  bit: Word;
begin
  if (FuncNo < 0) or (FuncNo > 8) then
    Exit;

  bit := FuncBit(FuncNo);

  { Actualizar entrada existente si la hay }
  for i := 0 to MAX_SLOTS - 1 do
  begin
    if FPending[i].Active and (FPending[i].Addr = DCC) then
    begin
      FPending[i].HasFuncs := True;
      FPending[i].FuncMask := FPending[i].FuncMask or bit;

      if State then
        FPending[i].FuncValues := FPending[i].FuncValues or bit
      else
        FPending[i].FuncValues := FPending[i].FuncValues and not bit;

      Exit;
    end;
  end;

  { Crear una nueva entrada pendiente }
  for i := 0 to MAX_SLOTS - 1 do
  begin
    if not FPending[i].Active then
    begin
      FPending[i].Active := True;
      FPending[i].Addr := DCC;

      FPending[i].HasSpeed := False;
      FPending[i].Speed := 0;

      FPending[i].HasDir := False;
      FPending[i].Dir := 0;

      FPending[i].HasFuncs := True;
      FPending[i].FuncMask := bit;

      if State then
        FPending[i].FuncValues := bit
      else
        FPending[i].FuncValues := 0;

      Exit;
    end;
  end;
end;

procedure TClientLocoNet.SetLocoSpeedByDCC(DCC: Integer; Speed: Integer);
var
  i: Integer;
begin
  for i := 0 to MAX_SLOTS - 1 do
  begin
    if FSlots[i].Valid and (FSlots[i].Addr = DCC) then
    begin
      SetLocoSpeed(i, Speed);
      Exit;
    end;
  end;

  RequestLocoSlot(DCC);
  AddPendingLoco(DCC, Speed, -1);
end;

procedure TClientLocoNet.SetLocoDirByDCC(DCC: Integer; Dir: Integer);
var
  i: Integer;
begin
  for i := 0 to MAX_SLOTS - 1 do
  begin
    if FSlots[i].Valid and (FSlots[i].Addr = DCC) then
    begin
      SetLocoDir(i, Dir);
      Exit;
    end;
  end;

  RequestLocoSlot(DCC);
  AddPendingLoco(DCC, -1, Dir);
end;

procedure TClientLocoNet.SetLocoFunctionByDCC(DCC: Integer; FuncNo: Integer; State: Boolean);
var
  i: Integer;
begin
  for i := 0 to MAX_SLOTS - 1 do
  begin
    if FSlots[i].Valid and (FSlots[i].Addr = DCC) then
    begin
      SetLocoFunction(i, FuncNo, State);
      Exit;
    end;
  end;

  RequestLocoSlot(DCC);
  AddPendingFunc(DCC, FuncNo, State);
end;

procedure TClientLocoNet.SetTrackPower(State: Boolean);
var
  data: array[0..1] of Byte;
begin
  if State then
    data[0] := $83
  else
    data[0] := $82;

  data[1] := CalcChecksum(data);
  SendBytes(data);
end;

procedure TClientLocoNet.SetTrackPowerProp(AValue: Boolean);
begin
  if FTrackPower = AValue then
    Exit;

  FTrackPower := AValue;
  SetTrackPower(FTrackPower);
end;

function TClientLocoNet.GetLocoFunctionsBySlot(Slot: Integer): Word;
begin
  if (Slot < 0) or (Slot >= MAX_SLOTS) then
    Result := 0
  else
    Result := FSlots[Slot].Funcs;
end;

function TClientLocoNet.GetLocoFunctionsByDCC(DCC: Integer): Word;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to MAX_SLOTS - 1 do
    if FSlots[i].Valid and (FSlots[i].Addr = DCC) then
      Exit(FSlots[i].Funcs);
end;

initialization
  {$I clientloconet.lrs}

end.
