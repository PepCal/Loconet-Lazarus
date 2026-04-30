unit UnitAutomatismos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ControlMaqueta, ClientLocoNet, AutomatismosMaqueta, ControlLoco,
  fpjson, jsonparser;

type
  TContextoRegla = (crDesconocido, crNuevaCondicion, crAndCondicion, crComando);

  { TFormAutomatismos }

  TFormAutomatismos = class(TForm)
    BBorrarEventos: TButton;
    MemoLog: TMemo;
    procedure BBorrarEventosClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FMotor: TMotorAutomatismos;
    FControl: TControlMaqueta;
    FClient: TClientLocoNet;
    FAuxControlLoco: TControlLoco;

    procedure Log(const S: string);
    procedure SetControl(AControl: TControlMaqueta);

    function GetJSONFileName: string;
    function BloqueVisualJSONATexto(AObj: TJSONObject): string;
    function ReglaVisualJSONATexto(AObj: TJSONObject): string;
    procedure CargarGruposJSON(const FileName: string);

    procedure MotorLog(Sender: TObject; const Msg: string);
    procedure MotorEjecutarLocoVel(Sender: TObject; DCC, Velocidad: Integer);
    procedure MotorEjecutarLocoDir(Sender: TObject; DCC, Direccion: Integer);
    procedure MotorEjecutarFuncion(Sender: TObject; DCC, FuncNum: Integer; State: Boolean);
  public
    property Control: TControlMaqueta read FControl write SetControl;

    // Compatibilidad: el mapa ya no debe insertar en este form. Estas llamadas
    // se redirigen siempre al editor visual.
    procedure InsertarTextoEnReglas(const S: string);
    procedure InsertarCondicionDesdeMapa(const S: string);
    procedure InsertarEjecucionDesdeMapa(const S: string);

    procedure ActivarGrupoExterno(const Nombre: string);
    procedure DesactivarGrupoExterno(const Nombre: string);

    procedure RecargarDesdeVisualJSON;
    procedure PrepararModoEjecucion;
    procedure PararEjecucion;
    function GetContextoCursorRegla: TContextoRegla;
  end;

var
  FormAutomatismos: TFormAutomatismos;

implementation

{$R *.lfm}

uses
  unitautomatizacionvisual;

const
  DIR_REGLAS = 'reglas';
  FILE_REGLAS = 'reglas_visual.json';

{ TFormAutomatismos }

procedure TFormAutomatismos.Log(const S: string);
begin
  if Assigned(MemoLog) then
    MemoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + S);
end;

function TFormAutomatismos.GetJSONFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName) + DIR_REGLAS) + FILE_REGLAS;
end;

function TFormAutomatismos.GetContextoCursorRegla: TContextoRegla;
begin
  // Ya no hay editor de texto: el mapa debe ofrecer siempre insertar como
  // condición o como ejecución en la regla visual activa.
  Result := crNuevaCondicion;
end;

procedure TFormAutomatismos.InsertarCondicionDesdeMapa(const S: string);
begin
  if Trim(S) = '' then Exit;
  if not Assigned(FormAutomatizacionVisual) then
    FormAutomatizacionVisual := TFormAutomatizacionVisual.Create(Application);
  FormAutomatizacionVisual.InsertarCondicionMapa(S);
  FormAutomatizacionVisual.Show;
  FormAutomatizacionVisual.BringToFront;
end;

procedure TFormAutomatismos.InsertarEjecucionDesdeMapa(const S: string);
begin
  if Trim(S) = '' then Exit;
  if not Assigned(FormAutomatizacionVisual) then
    FormAutomatizacionVisual := TFormAutomatizacionVisual.Create(Application);
  FormAutomatizacionVisual.InsertarAccionMapa(S);
  FormAutomatizacionVisual.Show;
  FormAutomatizacionVisual.BringToFront;
end;

procedure TFormAutomatismos.InsertarTextoEnReglas(const S: string);
begin
  if Trim(S) = '' then Exit;
  if not Assigned(FormAutomatizacionVisual) then
    FormAutomatizacionVisual := TFormAutomatizacionVisual.Create(Application);
  FormAutomatizacionVisual.InsertarTextoMapaAuto(S);
  FormAutomatizacionVisual.Show;
  FormAutomatizacionVisual.BringToFront;
end;

function TFormAutomatismos.BloqueVisualJSONATexto(AObj: TJSONObject): string;
var
  Tipo, Texto, Grupo, EstadoTxt: string;
  Direccion, DCC, Velocidad, FuncNum: Integer;
  Estado: Boolean;
begin
  Result := '';
  if AObj = nil then Exit;

  Texto := Trim(AObj.Get('texto', ''));
  if Texto <> '' then
  begin
    Result := Texto;
    Exit;
  end;

  Tipo := Trim(AObj.Get('tipo', ''));
  Direccion := AObj.Get('direccion', AObj.Get('addr', 0));
  DCC := AObj.Get('dcc', 0);
  Velocidad := AObj.Get('velocidad', AObj.Get('valor', 0));
  FuncNum := AObj.Get('funcion', AObj.Get('funcnum', 0));
  Estado := AObj.Get('estado', True);
  Grupo := Trim(AObj.Get('grupo', ''));

  if Estado then EstadoTxt := 'ON' else EstadoTxt := 'OFF';

  if SameText(Tipo, 'Sensor') then
    Result := Format('Sensor(%d,%s)', [Direccion, EstadoTxt])
  else if SameText(Tipo, 'Switch') or SameText(Tipo, 'Desvio') then
    Result := Format('Switch(%d,%s)', [Direccion, EstadoTxt])
  else if SameText(Tipo, 'RailCom') then
  begin
    if Estado then EstadoTxt := 'PRESENTE' else EstadoTxt := 'AUSENTE';
    Result := Format('RailCom(%d,%d,%s)', [Direccion, DCC, EstadoTxt]);
  end
  else if SameText(Tipo, 'RailComEstado') then
  begin
    if Estado then EstadoTxt := 'PRESENTE' else EstadoTxt := 'AUSENTE';
    Result := Format('RailComEstado(%d,%s)', [Direccion, EstadoTxt]);
  end
  else if SameText(Tipo, 'RailComValido') or SameText(Tipo, 'RailComLocoValido') then
    Result := Format('RailComLocoValido(%d)', [Direccion])
  else if SameText(Tipo, 'RailComDir') then
    Result := Format('RailComDir(%d,%d)', [Direccion, DCC])
  else if SameText(Tipo, 'AlActivarGrupo') then
    Result := 'AlActivarGrupo'
  else if SameText(Tipo, 'AlDesactivarGrupo') then
    Result := 'AlDesactivarGrupo'
  else if SameText(Tipo, 'Locomotora') or SameText(Tipo, 'LocoVel') then
    Result := Format('LocoVel(%d,%d)', [DCC, Velocidad])
  else if SameText(Tipo, 'LocoDir') then
    Result := Format('LocoDir(%d,%d)', [DCC, Velocidad])
  else if SameText(Tipo, 'Funcion') then
    Result := Format('Funcion(%d,%d,%s)', [DCC, FuncNum, EstadoTxt])
  else if SameText(Tipo, 'Delay') then
    Result := Format('Delay(%d)', [Velocidad])
  else if SameText(Tipo, 'ActivarGrupo') then
  begin
    if Grupo <> '' then Result := Format('ActivarGrupo(%s)', [Grupo]);
  end
  else if SameText(Tipo, 'DesactivarGrupo') then
  begin
    if Grupo <> '' then Result := Format('DesactivarGrupo(%s)', [Grupo]);
  end;
end;

function TFormAutomatismos.ReglaVisualJSONATexto(AObj: TJSONObject): string;
var
  Arr: TJSONArray;
  i: Integer;
  SCond, SAcc, S: string;
begin
  Result := '';
  if AObj = nil then Exit;

  SCond := '';
  if (AObj.Find('condiciones') <> nil) and (AObj.Find('condiciones').JSONType = jtArray) then
  begin
    Arr := AObj.Arrays['condiciones'];
    for i := 0 to Arr.Count - 1 do
    begin
      if Arr.Items[i].JSONType = jtObject then
        S := BloqueVisualJSONATexto(TJSONObject(Arr.Items[i]))
      else
        S := Trim(Arr.Items[i].AsString);
      if S = '' then Continue;
      if SCond <> '' then SCond := SCond + ' and ';
      SCond := SCond + S;
    end;
  end;

  SAcc := '';
  if (AObj.Find('acciones') <> nil) and (AObj.Find('acciones').JSONType = jtArray) then
  begin
    Arr := AObj.Arrays['acciones'];
    for i := 0 to Arr.Count - 1 do
    begin
      if Arr.Items[i].JSONType = jtObject then
        S := BloqueVisualJSONATexto(TJSONObject(Arr.Items[i]))
      else
        S := Trim(Arr.Items[i].AsString);
      if S = '' then Continue;
      if SAcc <> '' then SAcc := SAcc + ', ';
      SAcc := SAcc + S;
    end;
  end;

  if (SCond = '') and (SAcc = '') then
    Result := Trim(AObj.Get('texto', ''))
  else
  begin
    if SAcc = '' then Exit;
    if SCond = '' then SCond := 'AlActivarGrupo';
    Result := 'Si ' + SCond + ' entonces ' + SAcc;
  end;
end;

procedure TFormAutomatismos.CargarGruposJSON(const FileName: string);
var
  FS: TFileStream;
  Parser: TJSONParser;
  Data: TJSONData;
  RootObj, GrupoObj, ReglaObj: TJSONObject;
  GruposArr, ReglasArr: TJSONArray;
  SL: TStringList;
  i, j: Integer;
  Nombre, LineaRegla: string;
  Activo: Boolean;
begin
  if not Assigned(FMotor) then Exit;

  FMotor.Clear;

  if not FileExists(FileName) then
  begin
    Log('No existe fichero de reglas: ' + FileName);
    Exit;
  end;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    Parser := TJSONParser.Create(FS, []);
    try
      Data := Parser.Parse;
      try
        if Data.JSONType = jtObject then
        begin
          RootObj := TJSONObject(Data);
          if (RootObj.Find('grupos') = nil) or (RootObj.Find('grupos').JSONType <> jtArray) then
            Exit;
          GruposArr := RootObj.Arrays['grupos'];
        end
        else if Data.JSONType = jtArray then
          GruposArr := TJSONArray(Data)
        else
          Exit;

        for i := 0 to GruposArr.Count - 1 do
        begin
          if GruposArr.Items[i].JSONType <> jtObject then Continue;
          GrupoObj := TJSONObject(GruposArr.Items[i]);

          Nombre := Trim(GrupoObj.Get('nombre', ''));
          Activo := GrupoObj.Get('activo', False);
          if Nombre = '' then Nombre := 'Grupo ' + IntToStr(i + 1);

          SL := TStringList.Create;
          try
            if (GrupoObj.Find('reglas') <> nil) and (GrupoObj.Find('reglas').JSONType = jtArray) then
            begin
              ReglasArr := GrupoObj.Arrays['reglas'];
              for j := 0 to ReglasArr.Count - 1 do
              begin
                if ReglasArr.Items[j].JSONType = jtObject then
                begin
                  ReglaObj := TJSONObject(ReglasArr.Items[j]);
                  LineaRegla := ReglaVisualJSONATexto(ReglaObj);
                end
                else
                  LineaRegla := Trim(ReglasArr.Items[j].AsString);

                if LineaRegla <> '' then
                  SL.Add(LineaRegla);
              end;
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

  Log('Reglas cargadas desde: ' + FileName);
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
    Log('INIT: ClientLocoNet OK')
  else
    Log('INIT: ClientLocoNet = NIL');
end;

procedure TFormAutomatismos.FormCreate(Sender: TObject);
begin
  FMotor := TMotorAutomatismos.Create(Self);
  FMotor.OnLog := @MotorLog;
  FMotor.OnEjecutarLocoVel := @MotorEjecutarLocoVel;
  FMotor.OnEjecutarLocoDir := @MotorEjecutarLocoDir;
  FMotor.OnEjecutarFuncion := @MotorEjecutarFuncion;

  FAuxControlLoco := TControlLoco.Create(Self);
  FAuxControlLoco.Client := FClient;

  if Assigned(FControl) then
    FMotor.Control := FControl;

  PrepararModoEjecucion;
  CargarGruposJSON(GetJSONFileName);
end;

procedure TFormAutomatismos.FormDestroy(Sender: TObject);
begin
end;

procedure TFormAutomatismos.PrepararModoEjecucion;
begin
  Caption := 'Ejecución de automatismos';

  if Assigned(MemoLog) then
  begin
    MemoLog.Align := alClient;
    MemoLog.ReadOnly := True;
    MemoLog.ScrollBars := ssVertical;
    MemoLog.WordWrap := False;
  end;

  if Assigned(BBorrarEventos) then
  begin
    BBorrarEventos.Caption := 'Borrar log';
    BBorrarEventos.Align := alBottom;
  end;
end;

procedure TFormAutomatismos.RecargarDesdeVisualJSON;
begin
  CargarGruposJSON(GetJSONFileName);
end;

procedure TFormAutomatismos.PararEjecucion;
begin
  if Assigned(FMotor) then
  begin
    FMotor.Control := nil;
    FMotor.Clear;
  end;
  Log('Procesamiento parado');
end;

procedure TFormAutomatismos.ActivarGrupoExterno(const Nombre: string);
begin
  if Assigned(FMotor) then
    FMotor.ActivarGrupo(Nombre);
end;

procedure TFormAutomatismos.DesactivarGrupoExterno(const Nombre: string);
begin
  if Assigned(FMotor) then
    FMotor.DesactivarGrupo(Nombre);
end;

procedure TFormAutomatismos.MotorLog(Sender: TObject; const Msg: string);
begin
  Log(Msg);
end;

procedure TFormAutomatismos.MotorEjecutarLocoVel(Sender: TObject; DCC, Velocidad: Integer);
begin
  Log(Format('LOCO VEL DCC=%d V=%d', [DCC, Velocidad]));
  if not Assigned(FClient) then
  begin
    Log('ERROR: ClientLocoNet no asignado.');
    Exit;
  end;
  FClient.SetLocoSpeedByDCC(DCC, Velocidad);
end;

procedure TFormAutomatismos.MotorEjecutarLocoDir(Sender: TObject; DCC, Direccion: Integer);
begin
  Log(Format('LOCO DIR DCC=%d DIR=%d', [DCC, Direccion]));
  if not Assigned(FClient) then
  begin
    Log('ERROR: ClientLocoNet no asignado.');
    Exit;
  end;
  FClient.SetLocoDirByDCC(DCC, Direccion);
end;

procedure TFormAutomatismos.MotorEjecutarFuncion(Sender: TObject; DCC, FuncNum: Integer; State: Boolean);
begin
  Log(Format('FUNCION DCC=%d F=%d STATE=%s', [DCC, FuncNum, BoolToStr(State, True)]));

  if not Assigned(FAuxControlLoco) then
  begin
    Log('ERROR: ControlLoco auxiliar no asignado.');
    Exit;
  end;

  if not Assigned(FClient) then
  begin
    Log('ERROR: ClientLocoNet no asignado para funciones.');
    Exit;
  end;

  FAuxControlLoco.Client := FClient;
  FAuxControlLoco.DCC := DCC;
  FAuxControlLoco.SetFunction(FuncNum, State);
end;

procedure TFormAutomatismos.BBorrarEventosClick(Sender: TObject);
begin
  if Assigned(MemoLog) then
    MemoLog.Clear;
end;

end.
