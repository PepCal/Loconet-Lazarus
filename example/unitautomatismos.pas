// === UNIDAD ORGANIZADA Y DOCUMENTADA ===
// Funcionalidad original preservada. Comentarios añadidos para mantenimiento.

unit UnitAutomatismos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Menus,
  ControlMaqueta, ClientLocoNet, AutomatismosMaqueta, ControlLoco, fpjson, jsonparser;

type

  TContextoRegla = (crDesconocido, crNuevaCondicion, crAndCondicion, crComando);

  { TFormAutomatismos }

  TFormAutomatismos = class(TForm)
    BtnActivar: TButton;
    BtnDesactivar: TButton;
    BtnGuardar: TButton;
    BtnNuevo: TButton;
    BtnBorrar: TButton;
    BBorrarEventos: TButton;
    ChkActivo: TCheckBox;
    EdNombreGrupo: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    LbGrupos: TListBox;
    MemoLog: TMemo;
    MemoReglas: TMemo;
    procedure BBorrarEventosClick(Sender: TObject);
    procedure BtnActivarClick(Sender: TObject);
    procedure BtnBorrarClick(Sender: TObject);
    procedure BtnDesactivarClick(Sender: TObject);
    procedure BtnGuardarClick(Sender: TObject);
    procedure BtnNuevoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure LbGruposClick(Sender: TObject);
    procedure ActivarGrupoExterno(const Nombre: string);
    procedure DesactivarGrupoExterno(const Nombre: string);
  private
    FMotor: TMotorAutomatismos;
    FControl: TControlMaqueta;
    FClient: TClientLocoNet;
    FPopupReglas: TPopupMenu;
    FAuxControlLoco: TControlLoco;

    procedure MotorEjecutarFuncion(Sender: TObject; DCC, FuncNum: Integer; State: Boolean);

    procedure CrearMenuContextualReglas;
    procedure InsertarEnMemoReglas(const S: string);
    procedure MenuInsertarClick(Sender: TObject);

    procedure MotorLog(Sender: TObject; const Msg: string);
    procedure MotorEjecutarLocoVel(Sender: TObject; DCC, Velocidad: Integer);
    procedure MotorEjecutarLocoDir(Sender: TObject; DCC, Direccion: Integer);

    procedure RefrescarListaGrupos;
    procedure CargarGrupoEnEditor(const Nombre: string);
    procedure SetControl(AControl: TControlMaqueta);

    procedure GuardarGruposJSON(const FileName: string);
    procedure CargarGruposJSON(const FileName: string);
    function GetJSONFileName: string;

  public
    property Control: TControlMaqueta read FControl write SetControl;
    procedure InsertarTextoEnReglas(const S: string);
    function GetContextoCursorRegla: TContextoRegla;
  end;

var
  FormAutomatismos: TFormAutomatismos;

implementation

{$R *.lfm}

function TFormAutomatismos.GetContextoCursorRegla: TContextoRegla;
var
  P: Integer;
  LineStart, LineEnd: Integer;
  LineText, LeftText: string;
  i: Integer;
begin
  Result := crDesconocido;

  if not Assigned(MemoReglas) then Exit;

  P := MemoReglas.SelStart + 1; // string index base 1

  if P < 1 then
    P := 1;

  LineStart := P;
  while (LineStart > 1) and (MemoReglas.Text[LineStart - 1] <> #10) and
        (MemoReglas.Text[LineStart - 1] <> #13) do
    Dec(LineStart);

  LineEnd := P;
  while (LineEnd <= Length(MemoReglas.Text)) and
        (MemoReglas.Text[LineEnd] <> #10) and
        (MemoReglas.Text[LineEnd] <> #13) do
    Inc(LineEnd);

  LineText := Copy(MemoReglas.Text, LineStart, LineEnd - LineStart);
  LeftText := Copy(MemoReglas.Text, LineStart, P - LineStart);

  LineText := Trim(LineText);

  if LineText = '' then
  begin
    Result := crNuevaCondicion;
    Exit;
  end;

  if Pos('entonces', LowerCase(LineText)) = 0 then
  begin
    if Pos('si ', LowerCase(TrimLeft(LineText))) = 1 then
      Result := crAndCondicion
    else
      Result := crNuevaCondicion;
    Exit;
  end;

  i := Pos('entonces', LowerCase(LineText));

  if i > 0 then
  begin
    if Pos('entonces', LowerCase(LeftText)) > 0 then
      Result := crComando
    else
      Result := crAndCondicion;
    Exit;
  end;

  Result := crDesconocido;
end;

procedure TFormAutomatismos.InsertarTextoEnReglas(const S: string);
var
  TextoAInsertar: string;
  P: Integer;
  LineStart: Integer;
  LeftText: string;
  PosEntonces: Integer;
  TextoTrasEntonces: string;
begin
  if not Assigned(MemoReglas) then Exit;

  TextoAInsertar := S;

  // Si estamos insertando en la zona de comandos,
  // añadir coma automáticamente cuando ya exista un comando previo
  if GetContextoCursorRegla = crComando then
  begin
    P := MemoReglas.SelStart + 1; // string index base 1

    if P < 1 then
      P := 1;

    LineStart := P;
    while (LineStart > 1) and
          (MemoReglas.Text[LineStart - 1] <> #10) and
          (MemoReglas.Text[LineStart - 1] <> #13) do
      Dec(LineStart);

    LeftText := Copy(MemoReglas.Text, LineStart, P - LineStart);

    PosEntonces := Pos('entonces', LowerCase(LeftText));
    if PosEntonces > 0 then
    begin
      TextoTrasEntonces := Trim(Copy(LeftText, PosEntonces + Length('entonces'), MaxInt));

      // Solo poner coma si ya hay algo escrito después de "entonces"
      if TextoTrasEntonces <> '' then
        TextoAInsertar := ', ' + TextoAInsertar;
    end;
  end;

  Show;
  BringToFront;
  MemoReglas.SetFocus;
  MemoReglas.SelText := TextoAInsertar;
end;

procedure TFormAutomatismos.MotorEjecutarFuncion(Sender: TObject; DCC, FuncNum: Integer; State: Boolean);
begin
  MemoLog.Lines.Add(
    FormatDateTime('hh:nn:ss', Now) + '  ' +
    Format('FUNCION DCC=%d F=%d STATE=%s', [DCC, FuncNum, BoolToStr(State, True)])
  );

  if not Assigned(FAuxControlLoco) then
  begin
    MemoLog.Lines.Add('  ERROR: ControlLoco auxiliar no asignado.');
    Exit;
  end;

  if not Assigned(FClient) then
  begin
    MemoLog.Lines.Add('  ERROR: ClientLocoNet no asignado para funciones.');
    Exit;
  end;

  FAuxControlLoco.Client := FClient;
  FAuxControlLoco.DCC := DCC;

  MemoLog.Lines.Add(
    FormatDateTime('hh:nn:ss', Now) + '  ' +
    Format('Llamando a SetFunction DCC=%d F=%d STATE=%s',
      [DCC, FuncNum, BoolToStr(State, True)])
  );

  FAuxControlLoco.SetFunction(FuncNum, State);

  MemoLog.Lines.Add(
    FormatDateTime('hh:nn:ss', Now) + '  ' +
    'SetFunction ejecutado'
  );
end;

procedure TFormAutomatismos.InsertarEnMemoReglas(const S: string);
begin
  InsertarTextoEnReglas(S);
end;

procedure TFormAutomatismos.MenuInsertarClick(Sender: TObject);
var
  MI: TMenuItem;
begin
  if not (Sender is TMenuItem) then Exit;
  MI := TMenuItem(Sender);
  InsertarTextoEnReglas(MI.Hint);
end;

procedure TFormAutomatismos.CrearMenuContextualReglas;

  function AddItem(AParent: TMenuItem; const ACaption, AInsert: string): TMenuItem;
  begin
    Result := TMenuItem.Create(FPopupReglas);
    Result.Caption := ACaption;
    Result.Hint := AInsert;
    Result.OnClick := @MenuInsertarClick;
    AParent.Add(Result);
  end;

var
  RootCond, RootCmd, RootEjemplos: TMenuItem;
  RootAnd, RootRailComCond, RootRailComCmd: TMenuItem;
  RootRapidoCond, RootRapidoCmd: TMenuItem;
  Sep: TMenuItem;
begin
  FPopupReglas := TPopupMenu.Create(Self);

  { =========================
    CONDICIONES
    ========================= }
  RootCond := TMenuItem.Create(FPopupReglas);
  RootCond.Caption := 'Insertar condición';
  FPopupReglas.Items.Add(RootCond);

  AddItem(RootCond, 'Si Sensor(Addr,ON) entonces ', 'Si Sensor(Addr,ON) entonces ');
  AddItem(RootCond, 'Si Sensor(Addr,OFF) entonces ', 'Si Sensor(Addr,OFF) entonces ');
  AddItem(RootCond, 'Si Switch(Addr,ON) entonces ', 'Si Switch(Addr,ON) entonces ');
  AddItem(RootCond, 'Si Switch(Addr,OFF) entonces ', 'Si Switch(Addr,OFF) entonces ');

  AddItem(RootCond, 'Si RailCom(Sensor,Dcc,PRESENTE) entonces ', 'Si RailCom(Sensor,Dcc,PRESENTE) entonces ');
  AddItem(RootCond, 'Si RailCom(Sensor,Dcc,AUSENTE) entonces ', 'Si RailCom(Sensor,Dcc,AUSENTE) entonces ');
  AddItem(RootCond, 'Si RailComEstado(Sensor,PRESENTE) entonces ', 'Si RailComEstado(Sensor,PRESENTE) entonces ');
  AddItem(RootCond, 'Si RailComEstado(Sensor,AUSENTE) entonces ', 'Si RailComEstado(Sensor,AUSENTE) entonces ');

  AddItem(RootCond, 'Si SensorDireccion(Sensor,Dcc,DirL(0/1)) entonces ', 'Si SensorDireccion(Sensor,Dcc,DirL(0/1)) entonces ');
  AddItem(RootCond, 'Si RailComDireccion(Sensor,Dcc,PRESENTE,DirL(0/1)) entonces ', 'Si RailComDireccion(Sensor,Dcc,PRESENTE,DirL(0/1)) entonces ');
  AddItem(RootCond, 'Si RailComDireccion(Sensor,Dcc,AUSENTE,DirL(0/1)) entonces ', 'Si RailComDireccion(Sensor,Dcc,AUSENTE,DirL(0/1)) entonces ');

  AddItem(RootCond, 'Si RailComLocoValido(Sensor) entonces ', 'Si RailComLocoValido(Sensor) entonces ');
  AddItem(RootCond, 'Si RailComDir(Sensor,DirL(0/1)) entonces ', 'Si RailComDir(Sensor,DirL(0/1)) entonces ');

  AddItem(RootCond, 'Si AlActivarGrupo entonces ', 'Si AlActivarGrupo entonces ');
  AddItem(RootCond, 'Si AlDesactivarGrupo entonces ', 'Si AlDesactivarGrupo entonces ');

  { =========================
    PLANTILLAS RÁPIDAS CONDICIÓN
    ========================= }
  RootRapidoCond := TMenuItem.Create(FPopupReglas);
  RootRapidoCond.Caption := 'Insertar plantilla rápida condición';
  FPopupReglas.Items.Add(RootRapidoCond);

  AddItem(RootRapidoCond, 'RailComLocoValido(Sensor)', 'RailComLocoValido(Sensor)');
  AddItem(RootRapidoCond, 'RailComDir(Sensor,0)', 'RailComDir(Sensor,0)');
  AddItem(RootRapidoCond, 'RailComDir(Sensor,1)', 'RailComDir(Sensor,1)');
  AddItem(RootRapidoCond, 'RailCom(Sensor,Dcc,PRESENTE)', 'RailCom(Sensor,Dcc,PRESENTE)');
  AddItem(RootRapidoCond, 'RailCom(Sensor,Dcc,AUSENTE)', 'RailCom(Sensor,Dcc,AUSENTE)');
  AddItem(RootRapidoCond, 'RailComEstado(Sensor,PRESENTE)', 'RailComEstado(Sensor,PRESENTE)');
  AddItem(RootRapidoCond, 'RailComEstado(Sensor,AUSENTE)', 'RailComEstado(Sensor,AUSENTE)');

  { =========================
    AND
    ========================= }
  RootAnd := TMenuItem.Create(FPopupReglas);
  RootAnd.Caption := 'Añadir condición con AND';
  FPopupReglas.Items.Add(RootAnd);

  AddItem(RootAnd, 'and Sensor(Addr,ON)', ' and Sensor(Addr,ON)');
  AddItem(RootAnd, 'and Sensor(Addr,OFF)', ' and Sensor(Addr,OFF)');
  AddItem(RootAnd, 'and Switch(Addr,ON)', ' and Switch(Addr,ON)');
  AddItem(RootAnd, 'and Switch(Addr,OFF)', ' and Switch(Addr,OFF)');

  RootRailComCond := TMenuItem.Create(FPopupReglas);
  RootRailComCond.Caption := 'AND RailCom';
  RootAnd.Add(RootRailComCond);

  AddItem(RootRailComCond, 'and RailCom(Sensor,Dcc,PRESENTE)', ' and RailCom(Sensor,Dcc,PRESENTE)');
  AddItem(RootRailComCond, 'and RailCom(Sensor,Dcc,AUSENTE)', ' and RailCom(Sensor,Dcc,AUSENTE)');
  AddItem(RootRailComCond, 'and RailComEstado(Sensor,PRESENTE)', ' and RailComEstado(Sensor,PRESENTE)');
  AddItem(RootRailComCond, 'and RailComEstado(Sensor,AUSENTE)', ' and RailComEstado(Sensor,AUSENTE)');
  AddItem(RootRailComCond, 'and RailComDireccion(Sensor,Dcc,PRESENTE,DirL(0/1))', ' and RailComDireccion(Sensor,Dcc,PRESENTE,DirL(0/1))');
  AddItem(RootRailComCond, 'and RailComDireccion(Sensor,Dcc,AUSENTE,DirL(0/1))', ' and RailComDireccion(Sensor,Dcc,AUSENTE,DirL(0/1))');
  AddItem(RootRailComCond, 'and RailComLocoValido(Sensor)', ' and RailComLocoValido(Sensor)');
  AddItem(RootRailComCond, 'and RailComDir(Sensor,DirL(0/1))', ' and RailComDir(Sensor,DirL(0/1))');

  { =========================
    COMANDOS
    ========================= }
  RootCmd := TMenuItem.Create(FPopupReglas);
  RootCmd.Caption := 'Insertar comando';
  FPopupReglas.Items.Add(RootCmd);

  AddItem(RootCmd, 'Switch(Addr,ON)', 'Switch(Addr,ON)');
  AddItem(RootCmd, 'Switch(Addr,OFF)', 'Switch(Addr,OFF)');

  AddItem(RootCmd, 'LocoVel(Dcc,Vel)', 'LocoVel(Dcc,Vel)');
  AddItem(RootCmd, 'LocoDir(Dcc,DirL(0/1))', 'LocoDir(Dcc,DirL(0/1))');
  AddItem(RootCmd, 'Funcion(Dcc,NFun,ON)', 'Funcion(Dcc,NFun,ON)');
  AddItem(RootCmd, 'Funcion(Dcc,NFun,OFF)', 'Funcion(Dcc,NFun,OFF)');

  RootRailComCmd := TMenuItem.Create(FPopupReglas);
  RootRailComCmd.Caption := 'Comandos con RailCom';
  RootCmd.Add(RootRailComCmd);

  AddItem(RootRailComCmd, 'LocoVel(RailComLoco(Sensor),Vel)', 'LocoVel(RailComLoco(Sensor),Vel)');
  AddItem(RootRailComCmd, 'LocoDir(RailComLoco(Sensor),DirL(0/1))', 'LocoDir(RailComLoco(Sensor),DirL(0/1))');
  AddItem(RootRailComCmd, 'Funcion(RailComLoco(Sensor),NFun,ON)', 'Funcion(RailComLoco(Sensor),NFun,ON)');
  AddItem(RootRailComCmd, 'Funcion(RailComLoco(Sensor),NFun,OFF)', 'Funcion(RailComLoco(Sensor),NFun,OFF)');

  AddItem(RootCmd, 'ActivarGrupo(NombreGrupo)', 'ActivarGrupo(GrupoA)');
  AddItem(RootCmd, 'DesactivarGrupo(NombreGrupo)', 'DesactivarGrupo(GrupoA)');
  AddItem(RootCmd, 'Delay(ms)', 'Delay(ms)');

  { =========================
    PLANTILLAS RÁPIDAS COMANDO
    ========================= }
  RootRapidoCmd := TMenuItem.Create(FPopupReglas);
  RootRapidoCmd.Caption := 'Insertar plantilla rápida comando';
  FPopupReglas.Items.Add(RootRapidoCmd);

  AddItem(RootRapidoCmd, 'RailComLoco(Sensor)', 'RailComLoco(Sensor)');
  AddItem(RootRapidoCmd, 'LocoVel(RailComLoco(Sensor),Vel)', 'LocoVel(RailComLoco(Sensor),Vel)');
  AddItem(RootRapidoCmd, 'LocoDir(RailComLoco(Sensor),0)', 'LocoDir(RailComLoco(Sensor),0)');
  AddItem(RootRapidoCmd, 'LocoDir(RailComLoco(Sensor),1)', 'LocoDir(RailComLoco(Sensor),1)');
  AddItem(RootRapidoCmd, 'Funcion(RailComLoco(Sensor),0,ON)', 'Funcion(RailComLoco(Sensor),0,ON)');
  AddItem(RootRapidoCmd, 'Funcion(RailComLoco(Sensor),0,OFF)', 'Funcion(RailComLoco(Sensor),0,OFF)');

  Sep := TMenuItem.Create(FPopupReglas);
  Sep.Caption := '-';
  FPopupReglas.Items.Add(Sep);

  { =========================
    EJEMPLOS
    ========================= }
  RootEjemplos := TMenuItem.Create(FPopupReglas);
  RootEjemplos.Caption := 'Insertar ejemplo';
  FPopupReglas.Items.Add(RootEjemplos);

  AddItem(RootEjemplos,
    'Ruta al activar grupo',
    'Si AlActivarGrupo entonces Switch(174,ON), Delay(250), Switch(175,OFF), Delay(250), Switch(176,ON)' + LineEnding);

  AddItem(RootEjemplos,
    'RailCom + velocidad locomotora concreta',
    'Si RailCom(7,1,PRESENTE) and RailComDir(7,0) entonces LocoVel(1,15)' + LineEnding);

  AddItem(RootEjemplos,
    'RailCom + velocidad cualquier locomotora',
    'Si Sensor(19,ON) and RailComLocoValido(7) and RailComDir(7,0) entonces LocoVel(RailComLoco(7),15)' + LineEnding);

  AddItem(RootEjemplos,
    'Parada en sensor usando RailCom',
    'Si Sensor(21,ON) and RailComLocoValido(7) and RailComDir(7,0) entonces LocoVel(RailComLoco(7),0)' + LineEnding);

  AddItem(RootEjemplos,
    'RailComEstado presente',
    'Si RailComEstado(7,PRESENTE) entonces Switch(174,ON)' + LineEnding);

  AddItem(RootEjemplos,
    'RailComEstado ausente',
    'Si RailComEstado(7,AUSENTE) entonces Switch(174,OFF)' + LineEnding);

  AddItem(RootEjemplos,
    'Sensor + delay',
    'Si Sensor(21,ON) entonces Switch(174,ON), Delay(1000), Switch(175,OFF)' + LineEnding);

  AddItem(RootEjemplos,
    'Encender función de la locomotora detectada',
    'Si Sensor(30,ON) and RailComLocoValido(8) entonces Funcion(RailComLoco(8),0,ON)' + LineEnding);

  MemoReglas.PopupMenu := FPopupReglas;
end;

procedure TFormAutomatismos.ActivarGrupoExterno(const Nombre: string);
begin
  if not Assigned(FMotor) then Exit;
  FMotor.ActivarGrupo(Nombre);
  GuardarGruposJSON(GetJSONFileName);
  RefrescarListaGrupos;

  if SameText(Trim(EdNombreGrupo.Text), Nombre) then
    CargarGrupoEnEditor(Nombre);
end;

procedure TFormAutomatismos.DesactivarGrupoExterno(const Nombre: string);
begin
  if not Assigned(FMotor) then Exit;
  FMotor.DesactivarGrupo(Nombre);
  GuardarGruposJSON(GetJSONFileName);
  RefrescarListaGrupos;

  if SameText(Trim(EdNombreGrupo.Text), Nombre) then
    CargarGrupoEnEditor(Nombre);
end;

function TFormAutomatismos.GetJSONFileName: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'automatismos.json';
end;

procedure TFormAutomatismos.GuardarGruposJSON(const FileName: string);
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  ReglasArr: TJSONArray;
  G: TGrupoAutomatismo;
  R: TReglaAutomatismo;
  SL: TStringList;
begin
  if not Assigned(FMotor) then Exit;

  Arr := TJSONArray.Create;
  try
    for G in FMotor.Grupos do
    begin
      Obj := TJSONObject.Create;
      Obj.Add('nombre', G.Nombre);
      Obj.Add('activo', G.Activo);

      ReglasArr := TJSONArray.Create;
      for R in G.Reglas do
        ReglasArr.Add(R.TextoOriginal);

      Obj.Add('reglas', ReglasArr);
      Arr.Add(Obj);
    end;

    SL := TStringList.Create;
    try
      SL.Text := Arr.FormatJSON([], 2);
      SL.SaveToFile(FileName);
    finally
      SL.Free;
    end;
  finally
    Arr.Free;
  end;
end;

procedure TFormAutomatismos.CargarGruposJSON(const FileName: string);
var
  FS: TFileStream;
  Parser: TJSONParser;
  Data: TJSONData;
  Arr: TJSONArray;
  Obj: TJSONObject;
  ReglasArr: TJSONArray;
  SL: TStringList;
  i, j: Integer;
  Nombre: string;
  Activo: Boolean;
begin
  if not Assigned(FMotor) then Exit;
  if not FileExists(FileName) then Exit;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Parser := TJSONParser.Create(FS, []);
    try
      Data := Parser.Parse;
      try
        if Data.JSONType <> jtArray then Exit;

        Arr := TJSONArray(Data);

        FMotor.Clear;

        for i := 0 to Arr.Count - 1 do
        begin
          if Arr.Items[i].JSONType <> jtObject then
            Continue;

          Obj := TJSONObject(Arr.Items[i]);

          Nombre := Obj.Get('nombre', '');
          Activo := Obj.Get('activo', False);

          if Nombre = '' then
            Continue;

          SL := TStringList.Create;
          try
            if Obj.Find('reglas') <> nil then
            begin
              ReglasArr := Obj.Arrays['reglas'];
              for j := 0 to ReglasArr.Count - 1 do
                SL.Add(ReglasArr.Strings[j]);
            end;

            FMotor.CargarGrupoDesdeTexto(Nombre, Activo, SL);
          finally
            SL.Free;
          end;
        end;
      finally
        Data.Free;
      end;
    finally
      Parser.Free;
    end;
  finally
    FS.Free;
  end;

  RefrescarListaGrupos;
end;

procedure TFormAutomatismos.SetControl(AControl: TControlMaqueta);
begin
  FControl := AControl;

  if Assigned(FControl) then
    FClient := FControl.LocoNet
  else
    FClient := nil;

  if Assigned(FMotor) then
    FMotor.Control := FControl;

  if Assigned(FAuxControlLoco) then
     FAuxControlLoco.Client := FClient;

  if Assigned(FClient) then
    MemoLog.Lines.Add('INIT: ClientLocoNet OK')
  else
    MemoLog.Lines.Add('INIT: ClientLocoNet = NIL');
end;

// Métodos del form

procedure TFormAutomatismos.FormCreate(Sender: TObject);
begin
  FMotor := TMotorAutomatismos.Create(Self);
  FMotor.OnLog := @MotorLog;
  FMotor.OnEjecutarLocoVel := @MotorEjecutarLocoVel;
  FMotor.OnEjecutarLocoDir := @MotorEjecutarLocoDir;
  FAuxControlLoco := TControlLoco.Create(Self);
  FAuxControlLoco.Client := FClient;
  FMotor.OnEjecutarFuncion := @MotorEjecutarFuncion;

  if Assigned(FControl) then
    FMotor.Control := FControl;

  CargarGruposJSON(GetJSONFileName);
  CrearMenuContextualReglas;

  RefrescarListaGrupos;
end;

procedure TFormAutomatismos.FormDestroy(Sender: TObject);
begin
end;

procedure TFormAutomatismos.MotorEjecutarLocoVel(Sender: TObject; DCC, Velocidad: Integer);
begin
  MemoLog.Lines.Add(
    FormatDateTime('hh:nn:ss', Now) + '  ' +
    Format('LOCO VEL DCC=%d V=%d', [DCC, Velocidad])
  );

  if not Assigned(FClient) then
  begin
    MemoLog.Lines.Add('  ERROR: ClientLocoNet no asignado.');
    Exit;
  end;

  FClient.SetLocoSpeedByDCC(DCC, Velocidad);
end;

procedure TFormAutomatismos.MotorEjecutarLocoDir(Sender: TObject; DCC, Direccion: Integer);
begin
  MemoLog.Lines.Add(
    FormatDateTime('hh:nn:ss', Now) + '  ' +
    Format('LOCO DIR DCC=%d DIR=%d', [DCC, Direccion])
  );

  if not Assigned(FClient) then
  begin
    MemoLog.Lines.Add('  ERROR: ClientLocoNet no asignado.');
    Exit;
  end;

  FClient.SetLocoDirByDCC(DCC, Direccion);
end;

procedure TFormAutomatismos.BtnNuevoClick(Sender: TObject);
begin
  EdNombreGrupo.Clear;
  ChkActivo.Checked := False;
  MemoReglas.Clear;
  MemoReglas.Lines.Add('Si Sensor(1,ON) entonces Switch(174,OFF)');
end;

procedure TFormAutomatismos.BtnGuardarClick(Sender: TObject);
var
  Nombre: string;
begin
  Nombre := Trim(EdNombreGrupo.Text);
  if Nombre = '' then
  begin
    ShowMessage('Indica un nombre de grupo.');
    Exit;
  end;

  if not Assigned(FMotor) then Exit;

  try
    FMotor.CargarGrupoDesdeTexto(Nombre, ChkActivo.Checked, MemoReglas.Lines);
    GuardarGruposJSON(GetJSONFileName);
    RefrescarListaGrupos;
    MotorLog(Self, 'Grupo guardado: ' + Nombre);
  except
    on E: Exception do
      ShowMessage('Error al guardar grupo: ' + E.Message);
  end;
end;

procedure TFormAutomatismos.BtnActivarClick(Sender: TObject);
var
  Nombre: string;
begin
  Nombre := Trim(EdNombreGrupo.Text);
  if Nombre = '' then Exit;

  if not Assigned(FMotor) then Exit;

  FMotor.ActivarGrupo(Nombre);
  ChkActivo.Checked := True;
  GuardarGruposJSON(GetJSONFileName);
  RefrescarListaGrupos;
end;

procedure TFormAutomatismos.BBorrarEventosClick(Sender: TObject);
begin
  MemoLog.Clear;
end;

procedure TFormAutomatismos.BtnBorrarClick(Sender: TObject);
var
  Nombre: string;
begin
  Nombre := Trim(EdNombreGrupo.Text);
  if Nombre = '' then
  begin
    ShowMessage('No hay ningún grupo seleccionado.');
    Exit;
  end;

  if not Assigned(FMotor) then Exit;

  if MessageDlg('Borrar grupo',
                '¿Deseas borrar el grupo "' + Nombre + '"?',
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  if FMotor.BorrarGrupo(Nombre) then
  begin
    GuardarGruposJSON(GetJSONFileName);

    EdNombreGrupo.Clear;
    ChkActivo.Checked := False;
    MemoReglas.Clear;

    RefrescarListaGrupos;
  end
  else
    ShowMessage('No se encontró el grupo.');
end;

procedure TFormAutomatismos.BtnDesactivarClick(Sender: TObject);
var
  Nombre: string;
begin
  Nombre := Trim(EdNombreGrupo.Text);
  if Nombre = '' then Exit;

  if not Assigned(FMotor) then Exit;

  FMotor.DesactivarGrupo(Nombre);
  ChkActivo.Checked := False;
  GuardarGruposJSON(GetJSONFileName);
  RefrescarListaGrupos;
end;

procedure TFormAutomatismos.LbGruposClick(Sender: TObject);
begin
  CargarGrupoEnEditor('');
end;

// Metodos del motor

procedure TFormAutomatismos.MotorLog(Sender: TObject; const Msg: string);
var
  NombreActual: string;
begin
  NombreActual := Trim(EdNombreGrupo.Text);

  MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + Msg);

  if (Pos('Activado grupo:', Msg) = 1) or
     (Pos('Desactivado grupo:', Msg) = 1) then
  begin
    RefrescarListaGrupos;
    if NombreActual <> '' then
      CargarGrupoEnEditor(NombreActual);
    GuardarGruposJSON(GetJSONFileName);
  end;
end;

// Grupos

function CompareGruposPorNombre(const Item1, Item2: TGrupoAutomatismo): Integer;
begin
  Result := CompareText(Item1.Nombre, Item2.Nombre);
end;

procedure TFormAutomatismos.RefrescarListaGrupos;
var
  i, SelIndex: Integer;
  G: TGrupoAutomatismo;
  NombreSel: string;
begin
  NombreSel := Trim(EdNombreGrupo.Text);
  SelIndex := -1;

  if Assigned(FMotor) then
    FMotor.Grupos.Sort(@CompareGruposPorNombre);

  LbGrupos.Items.BeginUpdate;
  try
    LbGrupos.Clear;

    if not Assigned(FMotor) then Exit;

    for i := 0 to FMotor.Grupos.Count - 1 do
    begin
      G := FMotor.Grupos[i];

      if G.Activo then
        LbGrupos.Items.Add('[ON] ' + G.Nombre)
      else
        LbGrupos.Items.Add('[OFF] ' + G.Nombre);

      if SameText(G.Nombre, NombreSel) then
        SelIndex := i;
    end;

    if SelIndex >= 0 then
      LbGrupos.ItemIndex := SelIndex;
  finally
    LbGrupos.Items.EndUpdate;
  end;
end;

procedure TFormAutomatismos.CargarGrupoEnEditor(const Nombre: string);
var
  G: TGrupoAutomatismo;
  R: TReglaAutomatismo;
  i: Integer;
begin
  MemoReglas.Clear;
  EdNombreGrupo.Clear;
  ChkActivo.Checked := False;

  if not Assigned(FMotor) then Exit;

  G := nil;

  if Trim(Nombre) <> '' then
  begin
    for i := 0 to FMotor.Grupos.Count - 1 do
      if SameText(FMotor.Grupos[i].Nombre, Nombre) then
      begin
        G := FMotor.Grupos[i];
        Break;
      end;
  end
  else if LbGrupos.ItemIndex >= 0 then
  begin
    if LbGrupos.ItemIndex < FMotor.Grupos.Count then
      G := FMotor.Grupos[LbGrupos.ItemIndex];
  end;

  if not Assigned(G) then Exit;

  EdNombreGrupo.Text := G.Nombre;
  ChkActivo.Checked := G.Activo;

  for R in G.Reglas do
    MemoReglas.Lines.Add(R.TextoOriginal);
end;

end.
