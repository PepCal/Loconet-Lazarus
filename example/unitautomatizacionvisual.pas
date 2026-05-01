unit unitautomatizacionvisual;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls, Dialogs,
  fpjson, jsonparser, StrUtils;

type
  TTipoBloqueVisual = (
    tbvSensor,
    tbvSwitch,
    tbvRailCom,
    tbvRailComValido,
    tbvRailComDir,
    tbvAlActivarGrupo,
    tbvAlDesactivarGrupo,
    tbvLocomotora,
    tbvDelay,
    tbvActivarGrupo,
    tbvDesactivarGrupo
  );

  TUsoBloqueVisual = (
    ubvCondicion,
    ubvAccion
  );

  TBloqueVisual = class
  public
    Tipo: TTipoBloqueVisual;
    Uso: TUsoBloqueVisual;
    Direccion: Integer;
    Estado: Boolean;
    DCC: Integer;
    Velocidad: Integer;
    Grupo: string;
    Descripcion: string;

    constructor Create(ATipo: TTipoBloqueVisual; AUso: TUsoBloqueVisual);
    function TextoVisible: string;
    function TextoRegla: string;
    function ToJSON: TJSONObject;
    procedure FromJSON(AObj: TJSONObject);
  end;

  TReglaVisual = class
  public
    Nombre: string;
    Condiciones: TList;
    Acciones: TList;

    constructor Create;
    destructor Destroy; override;
    function TextoRegla: string;
    function ToJSON: TJSONObject;
    procedure FromJSON(AObj: TJSONObject);
  end;

  TGrupoVisual = class
  public
    Nombre: string;
    Activo: Boolean;
    Reglas: TList;

    constructor Create;
    destructor Destroy; override;
    function ToJSON: TJSONObject;
    procedure FromJSON(AObj: TJSONObject);
  end;

  { TFormAutomatizacionVisual }

  TFormAutomatizacionVisual = class(TForm)
  private
    FControl: TObject;

    PanelPrincipal: TPanel;
    PanelPaleta: TPanel;
    PanelTrabajo: TPanel;
    PanelPropiedades: TPanel;
    SplitPaleta: TSplitter;
    SplitPropiedades: TSplitter;

    ScrollCondicion: TScrollBox;
    ScrollAccion: TScrollBox;
    ScrollGrupos: TScrollBox;
    ScrollCondicionesRegla: TScrollBox;
    ScrollAccionesRegla: TScrollBox;

    LblTituloPaletaCond: TLabel;
    LblTituloPaletaAcc: TLabel;
    LblGrupos: TLabel;
    LblCondiciones: TLabel;
    LblAcciones: TLabel;
    LblPropiedades: TLabel;

    BtnNuevoGrupo: TButton;
    BtnNuevaRegla: TButton;
    BtnGuardarJSON: TButton;
    BtnCargarJSON: TButton;
    BtnGenerarTexto: TButton;

    LblNombre: TLabel;
    EdNombre: TEdit;
    LblDescripcion: TLabel;
    EdDescripcion: TEdit;
    LblDireccion: TLabel;
    EdDireccion: TEdit;
    ChkEstado: TCheckBox;
    LblDCC: TLabel;
    EdDCC: TEdit;
    LblVelocidad: TLabel;
    EdVelocidad: TEdit;
    LblGrupo: TLabel;
    EdGrupo: TEdit;

    DlgGuardar: TSaveDialog;
    DlgAbrir: TOpenDialog;

    Grupos: TList;
    GrupoSeleccionado: TGrupoVisual;
    ReglaSeleccionada: TReglaVisual;
    BloqueSeleccionado: TBloqueVisual;
    FCargandoPropiedades: Boolean;
    FProcesandoReglas: Boolean;
    FModificado: Boolean;

    function RutaDirectorioReglas: string;
    function RutaFicheroReglas: string;
    procedure MarcarModificado;
    procedure GuardarJSONEnFichero(const AFichero: string);
    function CargarJSONDeFichero(const AFichero: string): Boolean;
    function ConfirmarGuardarSiModificado: Boolean;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);

    procedure CrearInterfaz;
    procedure CrearPaleta;
    procedure CrearBotonPaleta(AParent: TWinControl; const ATexto: string;
      ATipo: TTipoBloqueVisual; AUso: TUsoBloqueVisual; ATop: Integer;
      AColor: TColor);
    procedure CrearDatosIniciales;
    function EdicionReglasPermitida(AAvisar: Boolean = True): Boolean;
    procedure ActualizarEstadoEdicion;

    procedure BtnPaletaClick(Sender: TObject);
    procedure BtnNuevoGrupoClick(Sender: TObject);
    procedure BtnNuevaReglaClick(Sender: TObject);
    procedure BtnGuardarJSONClick(Sender: TObject);
    procedure BtnCargarJSONClick(Sender: TObject);
    procedure BtnGenerarTextoClick(Sender: TObject);

    procedure PintarTodo;
    procedure PintarGrupos;
    procedure PintarRegla;
    procedure PintarBloque(AParent: TWinControl; ABloque: TBloqueVisual;
      ALeft, ATop: Integer);

    procedure GrupoCardClick(Sender: TObject);
    procedure GrupoActivarClick(Sender: TObject);
    procedure GrupoEditarClick(Sender: TObject);
    procedure GrupoBorrarClick(Sender: TObject);
    procedure ReglaCardClick(Sender: TObject);
    procedure ReglaEditarClick(Sender: TObject);
    procedure ReglaBorrarClick(Sender: TObject);
    procedure BloqueCardClick(Sender: TObject);
    procedure BloqueEditarDescripcionClick(Sender: TObject);
    procedure BloqueBorrarClick(Sender: TObject);

    procedure MostrarPropiedadesBloque(ABloque: TBloqueVisual);
    procedure LimpiarPropiedades;
    procedure PropiedadChange(Sender: TObject);
    procedure AplicarPropiedades;

    function BuscarRutaIcono(const AFichero: string): string;
    function IconoParaBloque(ATipo: TTipoBloqueVisual; AUso: TUsoBloqueVisual): string;
    function CrearTarjeta(AParent: TWinControl; ALeft, ATop, AWidth, AHeight: Integer;
      AColor: TColor; const ACaption: string; const AIcono: string = ''): TPanel;

    procedure LimpiarModelo;
    function ModeloToJSON: TJSONObject;
    procedure ModeloFromJSON(AObj: TJSONObject);
    function GenerarTextoReglas: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure InsertarElementoMapaEnRegla(ATipo: TTipoBloqueVisual;
      AUso: TUsoBloqueVisual; ADireccion: Integer);
    procedure InsertarTextoMapaEnRegla(const ATexto: string; AUso: TUsoBloqueVisual);
    procedure InsertarCondicionMapa(const ATexto: string);
    procedure InsertarAccionMapa(const ATexto: string);
    procedure InsertarTextoMapaAuto(const ATexto: string);
    procedure InsertarCondicionDesdeMenuMapa(const ATexto: string);
    procedure InsertarEjecucionDesdeMenuMapa(const ATexto: string);

    property Control: TObject read FControl write FControl;
  end;

var
  FormAutomatizacionVisual: TFormAutomatizacionVisual;

implementation

uses
  UnitAutomatismos, ControlMaqueta;

{$R *.lfm}

const
  DIR_REGLAS = 'reglas';
  FILE_REGLAS = 'reglas_visual.json';

  COLOR_CONDICION = $00C8D7FF; // salmón claro
  COLOR_ACCION    = $00D8F0D8; // verde claro
  COLOR_GRUPO     = $00F0F0F0;
  COLOR_REGLA     = $00E8E8E8;
  COLOR_SELECCION = $00FFFFCC;

  // Medidas fijas de la zona central de reglas.
  // No se anclan a la derecha para que las tarjetas no se redimensionen
  // y no se oculten los botones de editar/borrar.
  // Tarjetas de regla compactas: ancho fijo para que siempre se vean
  // los botones de editar y borrar dentro del área visible.
  ANCHO_SCROLL_REGLA = 380;
  ANCHO_TARJETA_BLOQUE = 340;

function TipoBloqueToStr(ATipo: TTipoBloqueVisual): string;
begin
  case ATipo of
    tbvSensor: Result := 'Sensor';
    tbvSwitch: Result := 'Switch';
    tbvRailCom: Result := 'RailCom';
    tbvRailComValido: Result := 'RailComValido';
    tbvRailComDir: Result := 'RailComDir';
    tbvAlActivarGrupo: Result := 'AlActivarGrupo';
    tbvAlDesactivarGrupo: Result := 'AlDesactivarGrupo';
    tbvLocomotora: Result := 'Locomotora';
    tbvDelay: Result := 'Delay';
    tbvActivarGrupo: Result := 'ActivarGrupo';
    tbvDesactivarGrupo: Result := 'DesactivarGrupo';
  else
    Result := 'Sensor';
  end;
end;

function StrToTipoBloque(const S: string): TTipoBloqueVisual;
begin
  if SameText(S, 'Sensor') then Result := tbvSensor
  else if SameText(S, 'Switch') then Result := tbvSwitch
  else if SameText(S, 'RailCom') then Result := tbvRailCom
  else if SameText(S, 'RailComValido') then Result := tbvRailComValido
  else if SameText(S, 'RailComDir') then Result := tbvRailComDir
  else if SameText(S, 'AlActivarGrupo') then Result := tbvAlActivarGrupo
  else if SameText(S, 'AlDesactivarGrupo') then Result := tbvAlDesactivarGrupo
  else if SameText(S, 'Locomotora') then Result := tbvLocomotora
  else if SameText(S, 'Delay') then Result := tbvDelay
  else if SameText(S, 'ActivarGrupo') then Result := tbvActivarGrupo
  else if SameText(S, 'DesactivarGrupo') then Result := tbvDesactivarGrupo
  else Result := tbvSensor;
end;

function UsoBloqueToStr(AUso: TUsoBloqueVisual): string;
begin
  if AUso = ubvCondicion then Result := 'Condicion'
  else Result := 'Accion';
end;

function StrToUsoBloque(const S: string): TUsoBloqueVisual;
begin
  if SameText(S, 'Condicion') then Result := ubvCondicion
  else Result := ubvAccion;
end;

{ TBloqueVisual }

constructor TBloqueVisual.Create(ATipo: TTipoBloqueVisual; AUso: TUsoBloqueVisual);
begin
  inherited Create;
  Tipo := ATipo;
  Uso := AUso;
  Direccion := 0;
  Estado := True;
  DCC := 0;
  Velocidad := 0;
  Grupo := '';
  Descripcion := '';
end;

function TBloqueVisual.TextoVisible: string;
begin
  case Tipo of
    tbvSensor:
      if Estado then Result := Format('Sensor %d ON', [Direccion])
      else Result := Format('Sensor %d OFF', [Direccion]);

    tbvSwitch:
      if Estado then Result := Format('Switch %d ON', [Direccion])
      else Result := Format('Switch %d OFF', [Direccion]);

    tbvRailCom:
      if Estado then Result := Format('RailCom %d DCC %d PRESENTE', [Direccion, DCC])
      else Result := Format('RailCom %d DCC %d AUSENTE', [Direccion, DCC]);

    tbvRailComValido:
      Result := Format('RailCom válido %d', [Direccion]);

    tbvRailComDir:
      Result := Format('RailCom dir %d = %d', [Direccion, DCC]);

    tbvAlActivarGrupo:
      Result := 'Al activar grupo';

    tbvAlDesactivarGrupo:
      Result := 'Al desactivar grupo';

    tbvLocomotora:
      Result := Format('Loco DCC %d vel %d', [DCC, Velocidad]);

    tbvDelay:
      Result := Format('Delay %d ms', [Velocidad]);

    tbvActivarGrupo:
      Result := 'Activar grupo ' + Grupo;

    tbvDesactivarGrupo:
      Result := 'Desactivar grupo ' + Grupo;

  else
    Result := 'Bloque';
  end;

end;

function TBloqueVisual.TextoRegla: string;
var
  SEstado: string;
begin
  if Estado then
    SEstado := 'ON'
  else
    SEstado := 'OFF';

  case Tipo of
    tbvSensor:
      Result := Format('Sensor(%d,%s)', [Direccion, SEstado]);

    tbvSwitch:
      Result := Format('Switch(%d,%s)', [Direccion, SEstado]);

    tbvRailCom:
      begin
        if Estado then SEstado := 'PRESENTE' else SEstado := 'AUSENTE';
        Result := Format('RailCom(%d,%d,%s)', [Direccion, DCC, SEstado]);
      end;

    tbvRailComValido:
      Result := Format('RailComLocoValido(%d)', [Direccion]);

    tbvRailComDir:
      Result := Format('RailComDir(%d,%d)', [Direccion, DCC]);

    tbvAlActivarGrupo:
      Result := 'AlActivarGrupo';

    tbvAlDesactivarGrupo:
      Result := 'AlDesactivarGrupo';

    tbvLocomotora:
      Result := Format('LocoVel(%d,%d)', [DCC, Velocidad]);

    tbvDelay:
      Result := Format('Delay(%d)', [Velocidad]);

    tbvActivarGrupo:
      Result := Format('ActivarGrupo(%s)', [Grupo]);

    tbvDesactivarGrupo:
      Result := Format('DesactivarGrupo(%s)', [Grupo]);

  else
    Result := '';
  end;
end;

function TBloqueVisual.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('tipo', TipoBloqueToStr(Tipo));
  Result.Add('uso', UsoBloqueToStr(Uso));
  Result.Add('direccion', Direccion);
  Result.Add('estado', Estado);
  Result.Add('dcc', DCC);
  Result.Add('velocidad', Velocidad);
  Result.Add('grupo', Grupo);
  Result.Add('descripcion', Descripcion);
end;

procedure TBloqueVisual.FromJSON(AObj: TJSONObject);
begin
  Tipo := StrToTipoBloque(AObj.Get('tipo', 'Sensor'));
  Uso := StrToUsoBloque(AObj.Get('uso', 'Condicion'));
  Direccion := AObj.Get('direccion', 0);
  Estado := AObj.Get('estado', True);
  DCC := AObj.Get('dcc', 0);
  Velocidad := AObj.Get('velocidad', 0);
  Grupo := AObj.Get('grupo', '');
  Descripcion := AObj.Get('descripcion', AObj.Get('nombreVisible', ''));
end;

{ TReglaVisual }

constructor TReglaVisual.Create;
begin
  inherited Create;
  Nombre := 'Nueva regla';
  Condiciones := TList.Create;
  Acciones := TList.Create;
end;

destructor TReglaVisual.Destroy;
var
  i: Integer;
begin
  for i := 0 to Condiciones.Count - 1 do TObject(Condiciones[i]).Free;
  for i := 0 to Acciones.Count - 1 do TObject(Acciones[i]).Free;
  Condiciones.Free;
  Acciones.Free;
  inherited Destroy;
end;

function TReglaVisual.TextoRegla: string;
var
  i: Integer;
  SCond, SAcc: string;
begin
  Result := '';

  if Acciones.Count = 0 then
    Exit;

  SCond := '';
  for i := 0 to Condiciones.Count - 1 do
  begin
    if TBloqueVisual(Condiciones[i]).TextoRegla = '' then Continue;
    if SCond <> '' then SCond := SCond + ' and ';
    SCond := SCond + TBloqueVisual(Condiciones[i]).TextoRegla;
  end;

  SAcc := '';
  for i := 0 to Acciones.Count - 1 do
  begin
    if TBloqueVisual(Acciones[i]).TextoRegla = '' then Continue;
    if SAcc <> '' then SAcc := SAcc + ', ';
    SAcc := SAcc + TBloqueVisual(Acciones[i]).TextoRegla;
  end;

  if SAcc = '' then
    Exit;

  if SCond = '' then
    Result := 'Si AlActivarGrupo entonces ' + SAcc
  else
    Result := 'Si ' + SCond + ' entonces ' + SAcc;
end;

function TReglaVisual.ToJSON: TJSONObject;
var
  ArrCond, ArrAcc: TJSONArray;
  i: Integer;
begin
  Result := TJSONObject.Create;
  Result.Add('nombre', Nombre);

  ArrCond := TJSONArray.Create;
  for i := 0 to Condiciones.Count - 1 do
    ArrCond.Add(TBloqueVisual(Condiciones[i]).ToJSON);
  Result.Add('condiciones', ArrCond);

  ArrAcc := TJSONArray.Create;
  for i := 0 to Acciones.Count - 1 do
    ArrAcc.Add(TBloqueVisual(Acciones[i]).ToJSON);
  Result.Add('acciones', ArrAcc);
end;

procedure TReglaVisual.FromJSON(AObj: TJSONObject);
var
  Arr: TJSONArray;
  i: Integer;
  B: TBloqueVisual;
begin
  Nombre := AObj.Get('nombre', 'Regla');

  Arr := AObj.Arrays['condiciones'];
  if Arr <> nil then
    for i := 0 to Arr.Count - 1 do
    begin
      B := TBloqueVisual.Create(tbvSensor, ubvCondicion);
      B.FromJSON(Arr.Objects[i]);
      Condiciones.Add(B);
    end;

  Arr := AObj.Arrays['acciones'];
  if Arr <> nil then
    for i := 0 to Arr.Count - 1 do
    begin
      B := TBloqueVisual.Create(tbvSwitch, ubvAccion);
      B.FromJSON(Arr.Objects[i]);
      Acciones.Add(B);
    end;
end;

{ TGrupoVisual }

constructor TGrupoVisual.Create;
begin
  inherited Create;
  Nombre := 'Nuevo grupo';
  Activo := True;
  Reglas := TList.Create;
end;

destructor TGrupoVisual.Destroy;
var
  i: Integer;
begin
  for i := 0 to Reglas.Count - 1 do TObject(Reglas[i]).Free;
  Reglas.Free;
  inherited Destroy;
end;

function TGrupoVisual.ToJSON: TJSONObject;
var
  Arr: TJSONArray;
  i: Integer;
begin
  Result := TJSONObject.Create;
  Result.Add('nombre', Nombre);
  Result.Add('activo', Activo);

  Arr := TJSONArray.Create;
  for i := 0 to Reglas.Count - 1 do
    Arr.Add(TReglaVisual(Reglas[i]).ToJSON);
  Result.Add('reglas', Arr);
end;

procedure TGrupoVisual.FromJSON(AObj: TJSONObject);
var
  Arr: TJSONArray;
  i: Integer;
  R: TReglaVisual;
begin
  Nombre := AObj.Get('nombre', 'Grupo');
  Activo := AObj.Get('activo', True);

  Arr := AObj.Arrays['reglas'];
  if Arr <> nil then
    for i := 0 to Arr.Count - 1 do
    begin
      R := TReglaVisual.Create;
      R.FromJSON(Arr.Objects[i]);
      Reglas.Add(R);
    end;
end;

{ TFormAutomatizacionVisual }

constructor TFormAutomatizacionVisual.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Caption := 'Automatización visual';
  Width := 1200;
  Height := 760;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;
  BorderIcons := [biSystemMenu, biMinimize, biMaximize];
  Constraints.MinWidth := 980;
  Constraints.MinHeight := 640;

  Grupos := TList.Create;
  FProcesandoReglas := False;
  FModificado := False;
  OnCloseQuery := @FormCloseQuery;
  CrearInterfaz;

  if FileExists(RutaFicheroReglas) then
    CargarJSONDeFichero(RutaFicheroReglas)
  else
  begin
    CrearDatosIniciales;
    PintarTodo;
    FModificado := False;
  end;

  ActualizarEstadoEdicion;
end;

destructor TFormAutomatizacionVisual.Destroy;
begin
  LimpiarModelo;
  Grupos.Free;
  inherited Destroy;
end;

function TFormAutomatizacionVisual.RutaDirectorioReglas: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + DIR_REGLAS;
end;

function TFormAutomatizacionVisual.RutaFicheroReglas: string;
begin
  Result := IncludeTrailingPathDelimiter(RutaDirectorioReglas) + FILE_REGLAS;
end;

procedure TFormAutomatizacionVisual.MarcarModificado;
begin
  if not FCargandoPropiedades then
    FModificado := True;
end;

procedure TFormAutomatizacionVisual.GuardarJSONEnFichero(const AFichero: string);
var
  Obj: TJSONObject;
  SL: TStringList;
begin
  ForceDirectories(ExtractFileDir(AFichero));

  Obj := ModeloToJSON;
  SL := TStringList.Create;
  try
    SL.Text := Obj.FormatJSON([], 2);
    SL.SaveToFile(AFichero);
    FModificado := False;
  finally
    SL.Free;
    Obj.Free;
  end;
end;

function TFormAutomatizacionVisual.CargarJSONDeFichero(const AFichero: string): Boolean;
var
  SL: TStringList;
  Data: TJSONData;
begin
  Result := False;
  if not FileExists(AFichero) then
  begin
    ShowMessage('No existe el fichero de reglas: ' + AFichero);
    Exit;
  end;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFichero);
    Data := GetJSON(SL.Text);
    try
      if Data.JSONType = jtObject then
      begin
        ModeloFromJSON(TJSONObject(Data));
        PintarTodo;
        FModificado := False;
        Result := True;
      end;
    finally
      Data.Free;
    end;
  finally
    SL.Free;
  end;
end;

function TFormAutomatizacionVisual.ConfirmarGuardarSiModificado: Boolean;
var
  R: Integer;
begin
  Result := True;
  if not FModificado then Exit;

  R := MessageDlg('Guardar reglas',
    'Se han modificado las reglas. ¿Quieres guardar los cambios?',
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);

  case R of
    mrYes:
      GuardarJSONEnFichero(RutaFicheroReglas);
    mrNo:
      ;
  else
    Result := False;
  end;
end;

procedure TFormAutomatizacionVisual.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmarGuardarSiModificado;
end;

procedure TFormAutomatizacionVisual.CrearInterfaz;
begin
  DlgGuardar := TSaveDialog.Create(Self);
  DlgGuardar.Filter := 'JSON (*.json)|*.json|Todos los archivos|*.*';
  DlgGuardar.DefaultExt := 'json';
  DlgGuardar.InitialDir := RutaDirectorioReglas;
  DlgGuardar.FileName := FILE_REGLAS;

  DlgAbrir := TOpenDialog.Create(Self);
  DlgAbrir.Filter := 'JSON (*.json)|*.json|Todos los archivos|*.*';
  DlgAbrir.InitialDir := RutaDirectorioReglas;
  DlgAbrir.FileName := FILE_REGLAS;

  PanelPrincipal := TPanel.Create(Self);
  PanelPrincipal.Parent := Self;
  PanelPrincipal.Align := alClient;
  PanelPrincipal.BevelOuter := bvNone;

  PanelPaleta := TPanel.Create(Self);
  PanelPaleta.Parent := PanelPrincipal;
  PanelPaleta.Align := alLeft;
  PanelPaleta.Width := 260;
  PanelPaleta.Caption := '';

  SplitPaleta := TSplitter.Create(Self);
  SplitPaleta.Parent := PanelPrincipal;
  SplitPaleta.Align := alLeft;
  SplitPaleta.Width := 6;

  PanelPropiedades := TPanel.Create(Self);
  PanelPropiedades.Parent := PanelPrincipal;
  PanelPropiedades.Align := alRight;
  PanelPropiedades.Width := 250;
  PanelPropiedades.Constraints.MinWidth := 250;
  PanelPropiedades.Constraints.MaxWidth := 250;
  PanelPropiedades.Caption := '';

  // El panel de propiedades queda fijo. Se mantiene el campo por compatibilidad,
  // pero el splitter no es visible ni operativo.
  SplitPropiedades := TSplitter.Create(Self);
  SplitPropiedades.Parent := PanelPrincipal;
  SplitPropiedades.Align := alRight;
  SplitPropiedades.Width := 0;
  SplitPropiedades.Visible := False;
  SplitPropiedades.Enabled := False;

  PanelTrabajo := TPanel.Create(Self);
  PanelTrabajo.Parent := PanelPrincipal;
  PanelTrabajo.Align := alClient;
  PanelTrabajo.Caption := '';

  CrearPaleta;

  LblGrupos := TLabel.Create(Self);
  LblGrupos.Parent := PanelTrabajo;
  LblGrupos.Caption := 'GRUPOS Y REGLAS';
  LblGrupos.Left := 10;
  LblGrupos.Top := 8;
  LblGrupos.Font.Style := [fsBold];

  BtnNuevoGrupo := TButton.Create(Self);
  BtnNuevoGrupo.Parent := PanelTrabajo;
  BtnNuevoGrupo.Caption := 'Nuevo grupo';
  BtnNuevoGrupo.Left := 10;
  BtnNuevoGrupo.Top := 30;
  BtnNuevoGrupo.Width := 100;
  BtnNuevoGrupo.OnClick := @BtnNuevoGrupoClick;

  BtnNuevaRegla := TButton.Create(Self);
  BtnNuevaRegla.Parent := PanelTrabajo;
  BtnNuevaRegla.Caption := 'Nueva regla';
  BtnNuevaRegla.Left := 115;
  BtnNuevaRegla.Top := 30;
  BtnNuevaRegla.Width := 100;
  BtnNuevaRegla.OnClick := @BtnNuevaReglaClick;

  BtnGuardarJSON := TButton.Create(Self);
  BtnGuardarJSON.Parent := PanelTrabajo;
  BtnGuardarJSON.Caption := 'Guardar JSON';
  BtnGuardarJSON.Left := 225;
  BtnGuardarJSON.Top := 30;
  BtnGuardarJSON.Width := 105;
  BtnGuardarJSON.OnClick := @BtnGuardarJSONClick;

  BtnCargarJSON := TButton.Create(Self);
  BtnCargarJSON.Parent := PanelTrabajo;
  BtnCargarJSON.Caption := 'Cargar JSON';
  BtnCargarJSON.Left := 335;
  BtnCargarJSON.Top := 30;
  BtnCargarJSON.Width := 100;
  BtnCargarJSON.OnClick := @BtnCargarJSONClick;

  BtnGenerarTexto := TButton.Create(Self);
  BtnGenerarTexto.Parent := PanelTrabajo;
  BtnGenerarTexto.Caption := 'Ejecutar';
  BtnGenerarTexto.Left := 440;
  BtnGenerarTexto.Top := 30;
  BtnGenerarTexto.Width := 105;
  BtnGenerarTexto.OnClick := @BtnGenerarTextoClick;

  ScrollGrupos := TScrollBox.Create(Self);
  ScrollGrupos.Parent := PanelTrabajo;
  ScrollGrupos.Left := 10;
  ScrollGrupos.Top := 65;
  ScrollGrupos.Width := 300;
  ScrollGrupos.Height := 610;
  ScrollGrupos.Anchors := [akLeft, akTop, akBottom];

  LblCondiciones := TLabel.Create(Self);
  LblCondiciones.Parent := PanelTrabajo;
  LblCondiciones.Caption := 'CONDICIONES DE LA REGLA';
  LblCondiciones.Left := 325;
  LblCondiciones.Top := 70;
  LblCondiciones.Font.Style := [fsBold];

  ScrollCondicionesRegla := TScrollBox.Create(Self);
  ScrollCondicionesRegla.Parent := PanelTrabajo;
  ScrollCondicionesRegla.Left := 325;
  ScrollCondicionesRegla.Top := 95;
  ScrollCondicionesRegla.Width := ANCHO_SCROLL_REGLA;
  ScrollCondicionesRegla.Height := 250;
  ScrollCondicionesRegla.Anchors := [akLeft, akTop];

  LblAcciones := TLabel.Create(Self);
  LblAcciones.Parent := PanelTrabajo;
  LblAcciones.Caption := 'EJECUCIÓN DE LA REGLA';
  LblAcciones.Left := 325;
  LblAcciones.Top := 360;
  LblAcciones.Font.Style := [fsBold];

  ScrollAccionesRegla := TScrollBox.Create(Self);
  ScrollAccionesRegla.Parent := PanelTrabajo;
  ScrollAccionesRegla.Left := 325;
  ScrollAccionesRegla.Top := 385;
  ScrollAccionesRegla.Width := ANCHO_SCROLL_REGLA;
  ScrollAccionesRegla.Height := 290;
  ScrollAccionesRegla.Anchors := [akLeft, akTop];

  LblPropiedades := TLabel.Create(Self);
  LblPropiedades.Parent := PanelPropiedades;
  LblPropiedades.Caption := 'PROPIEDADES';
  LblPropiedades.Left := 10;
  LblPropiedades.Top := 10;
  LblPropiedades.Font.Style := [fsBold];

  LblNombre := TLabel.Create(Self);
  LblNombre.Parent := PanelPropiedades;
  LblNombre.Caption := 'Bloque';
  LblNombre.Left := 10;
  LblNombre.Top := 45;

  EdNombre := TEdit.Create(Self);
  EdNombre.Parent := PanelPropiedades;
  EdNombre.Left := 10;
  EdNombre.Top := 65;
  EdNombre.Width := 230;
  EdNombre.Enabled := False;

  LblDescripcion := TLabel.Create(Self);
  LblDescripcion.Parent := PanelPropiedades;
  LblDescripcion.Caption := 'Descripción';
  LblDescripcion.Left := 10;
  LblDescripcion.Top := 105;

  EdDescripcion := TEdit.Create(Self);
  EdDescripcion.Parent := PanelPropiedades;
  EdDescripcion.Left := 10;
  EdDescripcion.Top := 125;
  EdDescripcion.Width := 230;
  EdDescripcion.Font.Style := [fsBold];
  EdDescripcion.Font.Color := $004A4A4A;
  EdDescripcion.OnChange := @PropiedadChange;

  LblDireccion := TLabel.Create(Self);
  LblDireccion.Parent := PanelPropiedades;
  LblDireccion.Caption := 'Dirección / sensor';
  LblDireccion.Left := 10;
  LblDireccion.Top := 165;

  EdDireccion := TEdit.Create(Self);
  EdDireccion.Parent := PanelPropiedades;
  EdDireccion.Left := 10;
  EdDireccion.Top := 185;
  EdDireccion.Width := 230;
  EdDireccion.OnChange := @PropiedadChange;

  ChkEstado := TCheckBox.Create(Self);
  ChkEstado.Parent := PanelPropiedades;
  ChkEstado.Caption := 'Estado ON / PRESENTE';
  ChkEstado.Left := 10;
  ChkEstado.Top := 220;
  ChkEstado.OnChange := @PropiedadChange;

  LblDCC := TLabel.Create(Self);
  LblDCC.Parent := PanelPropiedades;
  LblDCC.Caption := 'DCC / dirección';
  LblDCC.Left := 10;
  LblDCC.Top := 255;

  EdDCC := TEdit.Create(Self);
  EdDCC.Parent := PanelPropiedades;
  EdDCC.Left := 10;
  EdDCC.Top := 275;
  EdDCC.Width := 230;
  EdDCC.OnChange := @PropiedadChange;

  LblVelocidad := TLabel.Create(Self);
  LblVelocidad.Parent := PanelPropiedades;
  LblVelocidad.Caption := 'Velocidad / delay ms';
  LblVelocidad.Left := 10;
  LblVelocidad.Top := 310;

  EdVelocidad := TEdit.Create(Self);
  EdVelocidad.Parent := PanelPropiedades;
  EdVelocidad.Left := 10;
  EdVelocidad.Top := 330;
  EdVelocidad.Width := 230;
  EdVelocidad.OnChange := @PropiedadChange;

  LblGrupo := TLabel.Create(Self);
  LblGrupo.Parent := PanelPropiedades;
  LblGrupo.Caption := 'Grupo';
  LblGrupo.Left := 10;
  LblGrupo.Top := 365;

  EdGrupo := TEdit.Create(Self);
  EdGrupo.Parent := PanelPropiedades;
  EdGrupo.Left := 10;
  EdGrupo.Top := 385;
  EdGrupo.Width := 230;
  EdGrupo.OnChange := @PropiedadChange;

  LimpiarPropiedades;
end;

procedure TFormAutomatizacionVisual.CrearPaleta;
var
  y: Integer;
begin
  LblTituloPaletaCond := TLabel.Create(Self);
  LblTituloPaletaCond.Parent := PanelPaleta;
  LblTituloPaletaCond.Caption := 'CONDICIÓN';
  LblTituloPaletaCond.Left := 10;
  LblTituloPaletaCond.Top := 10;
  LblTituloPaletaCond.Font.Style := [fsBold];

  ScrollCondicion := TScrollBox.Create(Self);
  ScrollCondicion.Parent := PanelPaleta;
  ScrollCondicion.Left := 10;
  ScrollCondicion.Top := 35;
  ScrollCondicion.Width := 235;
  ScrollCondicion.Height := 340;
  ScrollCondicion.Anchors := [akLeft, akTop, akRight];

  y := 8;
  CrearBotonPaleta(ScrollCondicion, 'Sensor', tbvSensor, ubvCondicion, y, COLOR_CONDICION); Inc(y, 45);
  CrearBotonPaleta(ScrollCondicion, 'Switch', tbvSwitch, ubvCondicion, y, COLOR_CONDICION); Inc(y, 45);
  CrearBotonPaleta(ScrollCondicion, 'RailCom', tbvRailCom, ubvCondicion, y, COLOR_CONDICION); Inc(y, 45);
  CrearBotonPaleta(ScrollCondicion, 'RailCom válido', tbvRailComValido, ubvCondicion, y, COLOR_CONDICION); Inc(y, 45);
  CrearBotonPaleta(ScrollCondicion, 'RailCom dirección', tbvRailComDir, ubvCondicion, y, COLOR_CONDICION); Inc(y, 45);
  CrearBotonPaleta(ScrollCondicion, 'Al activar grupo', tbvAlActivarGrupo, ubvCondicion, y, COLOR_CONDICION); Inc(y, 45);
  CrearBotonPaleta(ScrollCondicion, 'Al desactivar grupo', tbvAlDesactivarGrupo, ubvCondicion, y, COLOR_CONDICION);

  LblTituloPaletaAcc := TLabel.Create(Self);
  LblTituloPaletaAcc.Parent := PanelPaleta;
  LblTituloPaletaAcc.Caption := 'EJECUCIÓN';
  LblTituloPaletaAcc.Left := 10;
  LblTituloPaletaAcc.Top := 390;
  LblTituloPaletaAcc.Font.Style := [fsBold];

  ScrollAccion := TScrollBox.Create(Self);
  ScrollAccion.Parent := PanelPaleta;
  ScrollAccion.Left := 10;
  ScrollAccion.Top := 415;
  ScrollAccion.Width := 235;
  ScrollAccion.Height := 260;
  ScrollAccion.Anchors := [akLeft, akTop, akRight, akBottom];

  y := 8;
  CrearBotonPaleta(ScrollAccion, 'Switch', tbvSwitch, ubvAccion, y, COLOR_ACCION); Inc(y, 45);
  CrearBotonPaleta(ScrollAccion, 'Locomotora', tbvLocomotora, ubvAccion, y, COLOR_ACCION); Inc(y, 45);
  CrearBotonPaleta(ScrollAccion, 'Delay', tbvDelay, ubvAccion, y, COLOR_ACCION); Inc(y, 45);
  CrearBotonPaleta(ScrollAccion, 'Activar grupo', tbvActivarGrupo, ubvAccion, y, COLOR_ACCION); Inc(y, 45);
  CrearBotonPaleta(ScrollAccion, 'Desactivar grupo', tbvDesactivarGrupo, ubvAccion, y, COLOR_ACCION);
end;

procedure TFormAutomatizacionVisual.CrearBotonPaleta(AParent: TWinControl;
  const ATexto: string; ATipo: TTipoBloqueVisual; AUso: TUsoBloqueVisual;
  ATop: Integer; AColor: TColor);
var
  P: TPanel;
begin
  P := CrearTarjeta(AParent, 8, ATop, 200, 36, AColor, ATexto, IconoParaBloque(ATipo, AUso));
  P.Tag := Ord(ATipo) * 10 + Ord(AUso);
  P.OnClick := @BtnPaletaClick;
end;

procedure TFormAutomatizacionVisual.CrearDatosIniciales;
var
  G: TGrupoVisual;
  R: TReglaVisual;
begin
  G := TGrupoVisual.Create;
  G.Nombre := 'Grupo 1';
  Grupos.Add(G);

  R := TReglaVisual.Create;
  R.Nombre := 'Regla 1';
  G.Reglas.Add(R);

  GrupoSeleccionado := G;
  ReglaSeleccionada := R;
end;


function TFormAutomatizacionVisual.EdicionReglasPermitida(AAvisar: Boolean): Boolean;
begin
  Result := not FProcesandoReglas;

  if (not Result) and AAvisar then
    MessageDlg('Edición bloqueada',
      'El motor de automatismos está en ejecución. Pare el motor antes de modificar reglas o grupos.',
      mtWarning, [mbOK], 0);
end;

procedure TFormAutomatizacionVisual.ActualizarEstadoEdicion;
var
  Editable: Boolean;
begin
  Editable := EdicionReglasPermitida(False);

  BtnNuevoGrupo.Enabled := Editable;
  BtnNuevaRegla.Enabled := Editable;
  BtnGuardarJSON.Enabled := Editable;
  BtnCargarJSON.Enabled := Editable;

  ScrollCondicion.Enabled := Editable;
  ScrollAccion.Enabled := Editable;

  EdDescripcion.Enabled := Editable;
  EdDireccion.Enabled := Editable;
  ChkEstado.Enabled := Editable;
  EdDCC.Enabled := Editable;
  EdVelocidad.Enabled := Editable;
  EdGrupo.Enabled := Editable;
end;

procedure TFormAutomatizacionVisual.BtnPaletaClick(Sender: TObject);
var
  P: TPanel;
  Tipo: TTipoBloqueVisual;
  Uso: TUsoBloqueVisual;
  B: TBloqueVisual;
begin
  if not EdicionReglasPermitida(True) then Exit;
  if ReglaSeleccionada = nil then
  begin
    ShowMessage('Seleccione o cree una regla antes de insertar bloques.');
    Exit;
  end;

  P := TPanel(Sender);
  Tipo := TTipoBloqueVisual(P.Tag div 10);
  Uso := TUsoBloqueVisual(P.Tag mod 10);

  B := TBloqueVisual.Create(Tipo, Uso);

  if Uso = ubvCondicion then
    ReglaSeleccionada.Condiciones.Add(B)
  else
    ReglaSeleccionada.Acciones.Add(B);

  BloqueSeleccionado := B;
  MarcarModificado;
  PintarRegla;
  MostrarPropiedadesBloque(B);
end;

procedure TFormAutomatizacionVisual.BtnNuevoGrupoClick(Sender: TObject);
var
  G: TGrupoVisual;
begin
  if not EdicionReglasPermitida(True) then Exit;
  G := TGrupoVisual.Create;
  G.Nombre := 'Grupo ' + IntToStr(Grupos.Count + 1);
  Grupos.Add(G);
  GrupoSeleccionado := G;
  ReglaSeleccionada := nil;
  BloqueSeleccionado := nil;
  MarcarModificado;
  PintarTodo;
end;

procedure TFormAutomatizacionVisual.BtnNuevaReglaClick(Sender: TObject);
var
  R: TReglaVisual;
begin
  if not EdicionReglasPermitida(True) then Exit;
  if GrupoSeleccionado = nil then
  begin
    ShowMessage('Seleccione o cree un grupo antes de crear una regla.');
    Exit;
  end;

  R := TReglaVisual.Create;
  R.Nombre := 'Regla ' + IntToStr(GrupoSeleccionado.Reglas.Count + 1);
  GrupoSeleccionado.Reglas.Add(R);
  ReglaSeleccionada := R;
  BloqueSeleccionado := nil;
  MarcarModificado;
  PintarTodo;
end;

procedure TFormAutomatizacionVisual.BtnGuardarJSONClick(Sender: TObject);
begin
  if not EdicionReglasPermitida(True) then Exit;
  ForceDirectories(RutaDirectorioReglas);
  DlgGuardar.InitialDir := RutaDirectorioReglas;
  if DlgGuardar.FileName = '' then
    DlgGuardar.FileName := FILE_REGLAS;

  if not DlgGuardar.Execute then Exit;

  GuardarJSONEnFichero(DlgGuardar.FileName);
end;

procedure TFormAutomatizacionVisual.BtnCargarJSONClick(Sender: TObject);
begin
  if not EdicionReglasPermitida(True) then Exit;
  if not ConfirmarGuardarSiModificado then Exit;

  ForceDirectories(RutaDirectorioReglas);
  DlgAbrir.InitialDir := RutaDirectorioReglas;
  if DlgAbrir.FileName = '' then
    DlgAbrir.FileName := FILE_REGLAS;

  if not DlgAbrir.Execute then Exit;

  CargarJSONDeFichero(DlgAbrir.FileName);
end;

procedure TFormAutomatizacionVisual.BtnGenerarTextoClick(Sender: TObject);
var
  FN: string;
begin
  if not FProcesandoReglas then
  begin
    FN := RutaFicheroReglas;
    GuardarJSONEnFichero(FN);

    if not Assigned(FormAutomatismos) then
      FormAutomatismos := TFormAutomatismos.Create(Application);

    if FControl is TControlMaqueta then
      FormAutomatismos.Control := TControlMaqueta(FControl);

    FormAutomatismos.RecargarDesdeVisualJSON;
    FormAutomatismos.PrepararModoEjecucion;
    FormAutomatismos.Show;
    FormAutomatismos.BringToFront;

    FProcesandoReglas := True;
    BtnGenerarTexto.Caption := 'Parar';
    ActualizarEstadoEdicion;
    PintarTodo;
  end
  else
  begin
    if Assigned(FormAutomatismos) then
      FormAutomatismos.PararEjecucion;

    FProcesandoReglas := False;
    BtnGenerarTexto.Caption := 'Ejecutar';
    ActualizarEstadoEdicion;
    PintarTodo;
  end;
end;

procedure TFormAutomatizacionVisual.PintarTodo;
begin
  PintarGrupos;
  PintarRegla;
end;

procedure TFormAutomatizacionVisual.PintarGrupos;
var
  i, j, y: Integer;
  G: TGrupoVisual;
  R: TReglaVisual;
  P, B: TPanel;
begin
  while ScrollGrupos.ControlCount > 0 do
    ScrollGrupos.Controls[0].Free;

  y := 8;

  for i := 0 to Grupos.Count - 1 do
  begin
    G := TGrupoVisual(Grupos[i]);

    P := CrearTarjeta(ScrollGrupos, 8, y, 250, 52, COLOR_GRUPO, G.Nombre, '');
    if G = GrupoSeleccionado then
      P.Color := COLOR_SELECCION;

    P.Tag := PtrInt(G);
    P.OnClick := @GrupoCardClick;

    // Icono activar/desactivar grupo
    if G.Activo then
      B := CrearTarjeta(P, 142, 20, 32, 26, clWhite, '', 'icono_grupo_on.png')
    else
      B := CrearTarjeta(P, 142, 20, 32, 26, clWhite, '', 'icono_grupo_off.png');
    B.Tag := PtrInt(G);
    B.Hint := 'Activar/desactivar grupo';
    B.ShowHint := True;
    if EdicionReglasPermitida(False) then
      B.OnClick := @GrupoActivarClick
    else
      B.Enabled := False;

    // Icono editar grupo
    B := CrearTarjeta(P, 178, 20, 32, 26, clWhite, '', 'icono_editar.png');
    B.Tag := PtrInt(G);
    if EdicionReglasPermitida(False) then
      B.OnClick := @GrupoEditarClick
    else
      B.Enabled := False;

    // Icono borrar grupo
    B := CrearTarjeta(P, 214, 20, 32, 26, clWhite, '', 'icono_borrar.png');
    B.Tag := PtrInt(G);
    if EdicionReglasPermitida(False) then
      B.OnClick := @GrupoBorrarClick
    else
      B.Enabled := False;

    Inc(y, 58);

    if G = GrupoSeleccionado then
    begin
      for j := 0 to G.Reglas.Count - 1 do
      begin
        R := TReglaVisual(G.Reglas[j]);

        P := CrearTarjeta(ScrollGrupos, 28, y, 230, 48, COLOR_REGLA, R.Nombre, '');
        if R = ReglaSeleccionada then
          P.Color := COLOR_SELECCION;

        P.Tag := PtrInt(R);
        P.OnClick := @ReglaCardClick;

        // Icono editar regla
        B := CrearTarjeta(P, 158, 18, 32, 24, clWhite, '', 'icono_editar.png');
        B.Tag := PtrInt(R);
        if EdicionReglasPermitida(False) then
          B.OnClick := @ReglaEditarClick
        else
          B.Enabled := False;

        // Icono borrar regla
        B := CrearTarjeta(P, 194, 18, 32, 24, clWhite, '', 'icono_borrar.png');
        B.Tag := PtrInt(R);
        if EdicionReglasPermitida(False) then
          B.OnClick := @ReglaBorrarClick
        else
          B.Enabled := False;

        Inc(y, 54);
      end;
    end;

    Inc(y, 8);
  end;
end;

procedure TFormAutomatizacionVisual.PintarRegla;
var
  i, y: Integer;
begin
  while ScrollCondicionesRegla.ControlCount > 0 do
    ScrollCondicionesRegla.Controls[0].Free;
  while ScrollAccionesRegla.ControlCount > 0 do
    ScrollAccionesRegla.Controls[0].Free;

  if ReglaSeleccionada = nil then Exit;

  y := 8;
  for i := 0 to ReglaSeleccionada.Condiciones.Count - 1 do
  begin
    PintarBloque(ScrollCondicionesRegla, TBloqueVisual(ReglaSeleccionada.Condiciones[i]), 8, y);
    Inc(y, 64);
  end;

  y := 8;
  for i := 0 to ReglaSeleccionada.Acciones.Count - 1 do
  begin
    PintarBloque(ScrollAccionesRegla, TBloqueVisual(ReglaSeleccionada.Acciones[i]), 8, y);
    Inc(y, 64);
  end;
end;

procedure TFormAutomatizacionVisual.PintarBloque(AParent: TWinControl;
  ABloque: TBloqueVisual; ALeft, ATop: Integer);
var
  P, BEdit, BBorrar: TPanel;
  LDesc: TLabel;
  C: TColor;
  W: Integer;
begin
  if ABloque.Uso = ubvCondicion then C := COLOR_CONDICION
  else C := COLOR_ACCION;

  if ABloque = BloqueSeleccionado then C := COLOR_SELECCION;

  // Ancho fijo y compacto. No depende del tamaño del formulario ni del
  // ScrollBox, así los botones de edición y borrado siempre quedan visibles.
  W := ANCHO_TARJETA_BLOQUE;
  if W > AParent.ClientWidth - ALeft - 12 then
    W := AParent.ClientWidth - ALeft - 12;
  if W < 300 then W := 300;

  P := CrearTarjeta(AParent, ALeft, ATop, W, 64, C,
    ABloque.TextoVisible, IconoParaBloque(ABloque.Tipo, ABloque.Uso));
  P.Tag := PtrInt(ABloque);
  P.OnClick := @BloqueCardClick;

  if Trim(ABloque.Descripcion) <> '' then
  begin
    LDesc := TLabel.Create(Self);
    LDesc.Parent := P;
    LDesc.Left := 64;
    LDesc.Top := 36;
    // Reservar espacio a la derecha para editar/borrar.
    LDesc.Width := W - 150;
    LDesc.Height := 18;
    LDesc.Caption := ABloque.Descripcion;
    LDesc.Font.Style := [fsBold];
    LDesc.Font.Color := $004A4A4A;
    LDesc.Transparent := True;
    LDesc.Enabled := False;
  end;

  BEdit := CrearTarjeta(P, W - 64, 8, 24, 24, clWhite, '', 'icono_editar.png');
  BEdit.Tag := PtrInt(ABloque);
  if EdicionReglasPermitida(False) then
    BEdit.OnClick := @BloqueEditarDescripcionClick
  else
    BEdit.Enabled := False;
  BEdit.Hint := 'Editar descripción';
  BEdit.ShowHint := True;

  BBorrar := CrearTarjeta(P, W - 34, 8, 24, 24, clWhite, '', 'icono_borrar.png');
  BBorrar.Tag := PtrInt(ABloque);
  if EdicionReglasPermitida(False) then
    BBorrar.OnClick := @BloqueBorrarClick
  else
    BBorrar.Enabled := False;
  BBorrar.Hint := 'Borrar bloque';
  BBorrar.ShowHint := True;
end;

procedure TFormAutomatizacionVisual.GrupoCardClick(Sender: TObject);
begin
  GrupoSeleccionado := TGrupoVisual(TPanel(Sender).Tag);
  ReglaSeleccionada := nil;
  BloqueSeleccionado := nil;
  LimpiarPropiedades;
  PintarTodo;
end;

procedure TFormAutomatizacionVisual.GrupoActivarClick(Sender: TObject);
var
  G: TGrupoVisual;
begin
  if not EdicionReglasPermitida(True) then Exit;
  G := TGrupoVisual(TPanel(Sender).Tag);
  if G = nil then Exit;

  G.Activo := not G.Activo;
  GrupoSeleccionado := G;
  MarcarModificado;
  PintarTodo;
end;

procedure TFormAutomatizacionVisual.GrupoEditarClick(Sender: TObject);
var
  G: TGrupoVisual;
  S: string;
begin
  if not EdicionReglasPermitida(True) then Exit;
  G := TGrupoVisual(TPanel(Sender).Tag);
  S := G.Nombre;
  if InputQuery('Renombrar grupo', 'Nombre:', S) then
  begin
    G.Nombre := S;
    MarcarModificado;
    PintarTodo;
  end;
end;

procedure TFormAutomatizacionVisual.GrupoBorrarClick(Sender: TObject);
var
  G: TGrupoVisual;
  i: Integer;
begin
  if not EdicionReglasPermitida(True) then Exit;
  G := TGrupoVisual(TPanel(Sender).Tag);
  if MessageDlg('Borrar grupo', '¿Borrar el grupo "' + G.Nombre + '"?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  i := Grupos.IndexOf(G);
  if i >= 0 then Grupos.Delete(i);

  if GrupoSeleccionado = G then GrupoSeleccionado := nil;
  ReglaSeleccionada := nil;
  BloqueSeleccionado := nil;
  G.Free;
  MarcarModificado;
  PintarTodo;
end;

procedure TFormAutomatizacionVisual.ReglaCardClick(Sender: TObject);
begin
  ReglaSeleccionada := TReglaVisual(TPanel(Sender).Tag);
  BloqueSeleccionado := nil;
  LimpiarPropiedades;
  PintarTodo;
end;

procedure TFormAutomatizacionVisual.ReglaEditarClick(Sender: TObject);
var
  R: TReglaVisual;
  S: string;
begin
  if not EdicionReglasPermitida(True) then Exit;
  R := TReglaVisual(TPanel(Sender).Tag);
  S := R.Nombre;
  if InputQuery('Renombrar regla', 'Nombre:', S) then
  begin
    R.Nombre := S;
    MarcarModificado;
    PintarTodo;
  end;
end;

procedure TFormAutomatizacionVisual.ReglaBorrarClick(Sender: TObject);
var
  R: TReglaVisual;
  i: Integer;
begin
  if not EdicionReglasPermitida(True) then Exit;
  if GrupoSeleccionado = nil then Exit;

  R := TReglaVisual(TPanel(Sender).Tag);
  if MessageDlg('Borrar regla', '¿Borrar la regla "' + R.Nombre + '"?',
    mtConfirmation, [mbYes, mbNo], 0) <> mrYes then Exit;

  i := GrupoSeleccionado.Reglas.IndexOf(R);
  if i >= 0 then GrupoSeleccionado.Reglas.Delete(i);

  if ReglaSeleccionada = R then ReglaSeleccionada := nil;
  BloqueSeleccionado := nil;
  R.Free;
  MarcarModificado;
  PintarTodo;
end;

procedure TFormAutomatizacionVisual.BloqueCardClick(Sender: TObject);
begin
  BloqueSeleccionado := TBloqueVisual(TPanel(Sender).Tag);
  MostrarPropiedadesBloque(BloqueSeleccionado);
  PintarRegla;
end;

procedure TFormAutomatizacionVisual.BloqueEditarDescripcionClick(Sender: TObject);
var
  B: TBloqueVisual;
  S: string;
begin
  if not EdicionReglasPermitida(True) then Exit;
  B := TBloqueVisual(TPanel(Sender).Tag);
  if B = nil then Exit;

  BloqueSeleccionado := B;
  S := B.Descripcion;
  if InputQuery('Descripción del bloque',
    'Descripción adicional para la tarjeta. El nombre fijo del bloque no se modifica:', S) then
  begin
    B.Descripcion := S;
    MarcarModificado;
    MostrarPropiedadesBloque(B);
    PintarRegla;
  end;
end;

procedure TFormAutomatizacionVisual.BloqueBorrarClick(Sender: TObject);
var
  B: TBloqueVisual;
  i: Integer;
begin
  if not EdicionReglasPermitida(True) then Exit;
  if ReglaSeleccionada = nil then Exit;

  B := TBloqueVisual(TPanel(Sender).Tag);

  i := ReglaSeleccionada.Condiciones.IndexOf(B);
  if i >= 0 then
    ReglaSeleccionada.Condiciones.Delete(i)
  else
  begin
    i := ReglaSeleccionada.Acciones.IndexOf(B);
    if i >= 0 then ReglaSeleccionada.Acciones.Delete(i);
  end;

  if BloqueSeleccionado = B then
    BloqueSeleccionado := nil;

  B.Free;
  MarcarModificado;
  LimpiarPropiedades;
  PintarRegla;
end;

procedure TFormAutomatizacionVisual.MostrarPropiedadesBloque(ABloque: TBloqueVisual);
begin
  FCargandoPropiedades := True;
  try
    LimpiarPropiedades;

    if ABloque = nil then Exit;

    LblNombre.Visible := True;
    EdNombre.Visible := True;
    EdNombre.Text := ABloque.TextoVisible;

    LblDescripcion.Visible := True;
    EdDescripcion.Visible := True;
    EdDescripcion.Text := ABloque.Descripcion;

    case ABloque.Tipo of
      tbvSensor, tbvSwitch, tbvRailCom, tbvRailComValido, tbvRailComDir:
      begin
        LblDireccion.Visible := True;
        EdDireccion.Visible := True;
        EdDireccion.Text := IntToStr(ABloque.Direccion);
      end;
    end;

    case ABloque.Tipo of
      tbvSensor, tbvSwitch, tbvRailCom:
      begin
        ChkEstado.Visible := True;
        ChkEstado.Checked := ABloque.Estado;
      end;
    end;

    case ABloque.Tipo of
      tbvRailCom, tbvRailComDir, tbvLocomotora:
      begin
        LblDCC.Visible := True;
        EdDCC.Visible := True;
        EdDCC.Text := IntToStr(ABloque.DCC);
      end;
    end;

    case ABloque.Tipo of
      tbvLocomotora, tbvDelay:
      begin
        LblVelocidad.Visible := True;
        EdVelocidad.Visible := True;
        EdVelocidad.Text := IntToStr(ABloque.Velocidad);
      end;
    end;

    case ABloque.Tipo of
      tbvActivarGrupo, tbvDesactivarGrupo:
      begin
        LblGrupo.Visible := True;
        EdGrupo.Visible := True;
        EdGrupo.Text := ABloque.Grupo;
      end;
    end;
  finally
    FCargandoPropiedades := False;
  end;
end;

procedure TFormAutomatizacionVisual.LimpiarPropiedades;
begin
  LblNombre.Visible := False;
  EdNombre.Visible := False;

  LblDescripcion.Visible := False;
  EdDescripcion.Visible := False;

  LblDireccion.Visible := False;
  EdDireccion.Visible := False;

  ChkEstado.Visible := False;

  LblDCC.Visible := False;
  EdDCC.Visible := False;

  LblVelocidad.Visible := False;
  EdVelocidad.Visible := False;

  LblGrupo.Visible := False;
  EdGrupo.Visible := False;
end;

procedure TFormAutomatizacionVisual.PropiedadChange(Sender: TObject);
begin
  if FCargandoPropiedades then Exit;
  if not EdicionReglasPermitida(False) then Exit;
  AplicarPropiedades;
end;

procedure TFormAutomatizacionVisual.AplicarPropiedades;
begin
  if BloqueSeleccionado = nil then Exit;

  if EdDireccion.Visible then
    BloqueSeleccionado.Direccion := StrToIntDef(EdDireccion.Text, 0);

  if ChkEstado.Visible then
    BloqueSeleccionado.Estado := ChkEstado.Checked;

  if EdDCC.Visible then
    BloqueSeleccionado.DCC := StrToIntDef(EdDCC.Text, 0);

  if EdVelocidad.Visible then
    BloqueSeleccionado.Velocidad := StrToIntDef(EdVelocidad.Text, 0);

  if EdGrupo.Visible then
    BloqueSeleccionado.Grupo := EdGrupo.Text;

  if EdDescripcion.Visible then
    BloqueSeleccionado.Descripcion := EdDescripcion.Text;

  FCargandoPropiedades := True;
  try
    EdNombre.Text := BloqueSeleccionado.TextoVisible;
  finally
    FCargandoPropiedades := False;
  end;

  MarcarModificado;
  PintarRegla;
end;

function TFormAutomatizacionVisual.BuscarRutaIcono(const AFichero: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
            'iconos' + DirectorySeparator + AFichero;

  if not FileExists(Result) then
    Result := '';
end;

function TFormAutomatizacionVisual.IconoParaBloque(ATipo: TTipoBloqueVisual;
  AUso: TUsoBloqueVisual): string;
begin
  Result := '';

  case ATipo of
    tbvSensor:
      Result := 'icono_sensor.png';

    tbvSwitch:
      if AUso = ubvCondicion then
        Result := 'icono_switch.png'
      else
        Result := 'icono_switch_accion.png';

    tbvRailCom:
      Result := 'icono_railcom.png';

    tbvRailComValido:
      Result := 'icono_railcom_valido.png';

    tbvRailComDir:
      Result := 'icono_railcom_dir.png';

    tbvAlActivarGrupo:
      Result := 'icono_grupo_on.png';

    tbvAlDesactivarGrupo:
      Result := 'icono_grupo_off.png';

    tbvLocomotora:
      Result := 'icono_locomotora.png';

    tbvDelay:
      Result := 'icono_delay.png';

    tbvActivarGrupo:
      Result := 'icono_activar_grupo.png';

    tbvDesactivarGrupo:
      Result := 'icono_desactivar_grupo.png';
  end;
end;

function TFormAutomatizacionVisual.CrearTarjeta(AParent: TWinControl; ALeft,
  ATop, AWidth, AHeight: Integer; AColor: TColor; const ACaption: string;
  const AIcono: string): TPanel;
var
  Img: TImage;
  L: TLabel;
  IconPath: string;
begin
  Result := TPanel.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Color := AColor;
  Result.BevelOuter := bvRaised;
  Result.Caption := '';

  // ICONO GRANDE (protagonista)
  if AIcono <> '' then
  begin
    IconPath := BuscarRutaIcono(AIcono);
    if IconPath <> '' then
    begin
      Img := TImage.Create(Self);
      Img.Parent := Result;
      Img.Left := 4;
      Img.Top := 4;
      Img.Width := AHeight - 8;
      Img.Height := AHeight - 8;
      Img.Stretch := True;
      Img.Proportional := True;
      Img.Center := True;
      Img.Enabled := False;

      try
        Img.Picture.LoadFromFile(IconPath);
      except
        Img.Free;
      end;
    end;
  end;

  // TEXTO secundario (a la derecha)
  L := TLabel.Create(Self);
  L.Parent := Result;
  L.Left := AHeight;
  if AHeight >= 60 then
  begin
    L.Top := 8;
    L.Height := 24;
    L.Layout := tlCenter;
  end
  else
  begin
    L.Top := 0;
    L.Height := AHeight;
    L.Layout := tlCenter;
  end;

  if (AWidth >= 180) and (AHeight >= 40) then
    L.Width := AWidth - AHeight - 72
  else
    L.Width := AWidth - AHeight - 4;
  L.Alignment := taLeftJustify;
  L.WordWrap := True;
  L.Caption := ACaption;
  L.Transparent := True;
  L.Enabled := False;
end;

procedure TFormAutomatizacionVisual.LimpiarModelo;
var
  i: Integer;
begin
  if Grupos = nil then Exit;
  for i := 0 to Grupos.Count - 1 do TObject(Grupos[i]).Free;
  Grupos.Clear;
  GrupoSeleccionado := nil;
  ReglaSeleccionada := nil;
  BloqueSeleccionado := nil;
end;

function TFormAutomatizacionVisual.ModeloToJSON: TJSONObject;
var
  Arr: TJSONArray;
  i: Integer;
begin
  Result := TJSONObject.Create;
  Result.Add('version', 1);

  Arr := TJSONArray.Create;
  for i := 0 to Grupos.Count - 1 do
    Arr.Add(TGrupoVisual(Grupos[i]).ToJSON);

  Result.Add('grupos', Arr);
end;

procedure TFormAutomatizacionVisual.ModeloFromJSON(AObj: TJSONObject);
var
  Arr: TJSONArray;
  i: Integer;
  G: TGrupoVisual;
begin
  LimpiarModelo;

  Arr := AObj.Arrays['grupos'];
  if Arr <> nil then
    for i := 0 to Arr.Count - 1 do
    begin
      G := TGrupoVisual.Create;
      G.FromJSON(Arr.Objects[i]);
      Grupos.Add(G);
    end;

  if Grupos.Count > 0 then
  begin
    GrupoSeleccionado := TGrupoVisual(Grupos[0]);
    if GrupoSeleccionado.Reglas.Count > 0 then
      ReglaSeleccionada := TReglaVisual(GrupoSeleccionado.Reglas[0]);
  end;
end;

function TFormAutomatizacionVisual.GenerarTextoReglas: string;
var
  i, j: Integer;
  G: TGrupoVisual;
  R: TReglaVisual;
  SR, Linea: string;
begin
  Result := '';

  for i := 0 to Grupos.Count - 1 do
  begin
    G := TGrupoVisual(Grupos[i]);
    SR := '';

    for j := 0 to G.Reglas.Count - 1 do
    begin
      R := TReglaVisual(G.Reglas[j]);
      Linea := R.TextoRegla;
      if Linea <> '' then
        SR := SR + Linea + LineEnding;
    end;

    if SR <> '' then
      Result := Result + '[' + G.Nombre + ']' + LineEnding + SR + LineEnding;
  end;

  if Result = '' then
    Result := 'No hay reglas generables.';
end;


function ExtraerEntreParentesisLocal(const S: string): string;
var
  P1, P2: Integer;
begin
  P1 := Pos('(', S);
  P2 := RPos(')', S);
  if (P1 > 0) and (P2 > P1) then
    Result := Copy(S, P1 + 1, P2 - P1 - 1)
  else
    Result := '';
end;

function ParametroLocal(const S: string; AIndex: Integer): string;
var
  i, Nivel, Ini, Num: Integer;
  C: Char;
begin
  Result := '';
  Ini := 1;
  Nivel := 0;
  Num := 0;

  for i := 1 to Length(S) + 1 do
  begin
    if i <= Length(S) then C := S[i] else C := ',';

    if C = '(' then Inc(Nivel)
    else if C = ')' then Dec(Nivel);

    if ((C = ',') and (Nivel = 0)) or (i > Length(S)) then
    begin
      Inc(Num);
      if Num = AIndex then
      begin
        Result := Trim(Copy(S, Ini, i - Ini));
        Exit;
      end;
      Ini := i + 1;
    end;
  end;
end;

function LimpiarTextoMapaLocal(const ATexto: string): string;
var
  S: string;
  P: Integer;
begin
  S := Trim(ATexto);

  if (Length(S) >= 3) and (LowerCase(Copy(S, 1, 3)) = 'si ') then
    Delete(S, 1, 3);

  // Compatibilidad: si queda alguna llamada antigua con formato "and Sensor(...)",
  // en el visual debe entrar como bloque normal.
  if (Length(S) >= 4) and (LowerCase(Copy(S, 1, 4)) = 'and ') then
    Delete(S, 1, 4);

  P := Pos(' entonces', LowerCase(S));
  if P > 0 then
    S := Copy(S, 1, P - 1);

  Result := Trim(S);
end;

procedure TFormAutomatizacionVisual.InsertarTextoMapaEnRegla(const ATexto: string;
  AUso: TUsoBloqueVisual);
var
  S, Params, P1, P2, P3: string;
  B: TBloqueVisual;
  G: TGrupoVisual;
  R: TReglaVisual;
begin
  if not EdicionReglasPermitida(True) then Exit;
  S := LimpiarTextoMapaLocal(ATexto);
  if S = '' then Exit;

  if GrupoSeleccionado = nil then
  begin
    if Grupos.Count = 0 then
    begin
      G := TGrupoVisual.Create;
      G.Nombre := 'Grupo 1';
      Grupos.Add(G);
    end;
    GrupoSeleccionado := TGrupoVisual(Grupos[0]);
  end;

  if ReglaSeleccionada = nil then
  begin
    if GrupoSeleccionado.Reglas.Count = 0 then
    begin
      R := TReglaVisual.Create;
      R.Nombre := 'Regla 1';
      GrupoSeleccionado.Reglas.Add(R);
    end;
    ReglaSeleccionada := TReglaVisual(GrupoSeleccionado.Reglas[0]);
  end;

  Params := ExtraerEntreParentesisLocal(S);
  P1 := ParametroLocal(Params, 1);
  P2 := ParametroLocal(Params, 2);
  P3 := ParametroLocal(Params, 3);

  B := nil;

  if Pos('Sensor(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvSensor, AUso);
    B.Direccion := StrToIntDef(P1, 0);
    B.Estado := SameText(P2, 'ON') or SameText(P2, '1') or SameText(P2, 'TRUE') or SameText(P2, 'PRESENTE');
  end
  else if Pos('Switch(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvSwitch, AUso);
    B.Direccion := StrToIntDef(P1, 0);
    B.Estado := SameText(P2, 'ON') or SameText(P2, '1') or SameText(P2, 'TRUE');
  end
  else if Pos('RailCom(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvRailCom, AUso);
    B.Direccion := StrToIntDef(P1, 0);
    B.DCC := StrToIntDef(P2, 0);
    B.Estado := SameText(P3, 'PRESENTE') or SameText(P3, 'ON') or SameText(P3, '1') or SameText(P3, 'TRUE');
  end
  else if Pos('RailComEstado(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvRailCom, AUso);
    B.Direccion := StrToIntDef(P1, 0);
    B.DCC := 0;
    B.Estado := SameText(P2, 'PRESENTE') or SameText(P2, 'ON') or SameText(P2, '1') or SameText(P2, 'TRUE');
  end
  else if Pos('RailComLocoValido(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvRailComValido, AUso);
    B.Direccion := StrToIntDef(P1, 0);
  end
  else if Pos('RailComDir(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvRailComDir, AUso);
    B.Direccion := StrToIntDef(P1, 0);
    B.DCC := StrToIntDef(P2, 0);
  end
  else if SameText(S, 'AlActivarGrupo') then
    B := TBloqueVisual.Create(tbvAlActivarGrupo, AUso)
  else if SameText(S, 'AlDesactivarGrupo') then
    B := TBloqueVisual.Create(tbvAlDesactivarGrupo, AUso)
  else if Pos('LocoVel(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvLocomotora, AUso);
    B.DCC := StrToIntDef(P1, 0);
    B.Velocidad := StrToIntDef(P2, 0);
  end
  else if Pos('Delay(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvDelay, AUso);
    B.Velocidad := StrToIntDef(P1, 0);
  end
  else if Pos('ActivarGrupo(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvActivarGrupo, AUso);
    B.Grupo := P1;
  end
  else if Pos('DesactivarGrupo(', S) = 1 then
  begin
    B := TBloqueVisual.Create(tbvDesactivarGrupo, AUso);
    B.Grupo := P1;
  end;

  if B = nil then
  begin
    ShowMessage('No se reconoce el bloque para el editor visual: ' + S);
    Exit;
  end;

  if AUso = ubvCondicion then
    ReglaSeleccionada.Condiciones.Add(B)
  else
    ReglaSeleccionada.Acciones.Add(B);

  BloqueSeleccionado := B;
  MarcarModificado;
  PintarTodo;
  MostrarPropiedadesBloque(B);
end;

procedure TFormAutomatizacionVisual.InsertarTextoMapaAuto(const ATexto: string);
var
  S, L, CondPart, AccPart, Item: string;
  P, I: Integer;
  Parts: TStringList;
begin
  if not EdicionReglasPermitida(True) then Exit;
  S := Trim(ATexto);
  if S = '' then Exit;

  if (Length(S) >= 4) and (LowerCase(Copy(S, 1, 4)) = 'and ') then
  begin
    InsertarTextoMapaEnRegla(Trim(Copy(S, 5, MaxInt)), ubvCondicion);
    Show;
    BringToFront;
    Exit;
  end;

  L := LowerCase(S);
  P := Pos(' entonces ', L);

  if (Pos('si ', L) = 1) and (P > 0) then
  begin
    CondPart := Trim(Copy(S, 4, P - 4));
    AccPart := Trim(Copy(S, P + Length(' entonces '), MaxInt));

    // Si viene de menú contextual como "Si X entonces", no se crea regla nueva:
    // se añade X como condición a la regla visual activa.
    if AccPart = '' then
    begin
      while CondPart <> '' do
      begin
        I := Pos(' and ', LowerCase(CondPart));
        if I > 0 then
        begin
          Item := Trim(Copy(CondPart, 1, I - 1));
          Delete(CondPart, 1, I + Length(' and ') - 1);
        end
        else
        begin
          Item := Trim(CondPart);
          CondPart := '';
        end;

        if Item <> '' then
          InsertarTextoMapaEnRegla(Item, ubvCondicion);
      end;

      Show;
      BringToFront;
      Exit;
    end;

    if GrupoSeleccionado = nil then
    begin
      if Grupos.Count = 0 then
      begin
        GrupoSeleccionado := TGrupoVisual.Create;
        GrupoSeleccionado.Nombre := 'Grupo 1';
        Grupos.Add(GrupoSeleccionado);
      end
      else
        GrupoSeleccionado := TGrupoVisual(Grupos[0]);
    end;

    ReglaSeleccionada := TReglaVisual.Create;
    ReglaSeleccionada.Nombre := 'Regla ' + IntToStr(GrupoSeleccionado.Reglas.Count + 1);
    GrupoSeleccionado.Reglas.Add(ReglaSeleccionada);

    while CondPart <> '' do
    begin
      I := Pos(' and ', LowerCase(CondPart));
      if I > 0 then
      begin
        Item := Trim(Copy(CondPart, 1, I - 1));
        Delete(CondPart, 1, I + Length(' and ') - 1);
      end
      else
      begin
        Item := Trim(CondPart);
        CondPart := '';
      end;
      if Item <> '' then
        InsertarTextoMapaEnRegla(Item, ubvCondicion);
    end;

    Parts := TStringList.Create;
    try
      Parts.Delimiter := #1;
      Parts.StrictDelimiter := True;
      Parts.DelimitedText := StringReplace(AccPart, ',', #1, [rfReplaceAll]);
      for I := 0 to Parts.Count - 1 do
      begin
        Item := Trim(Parts[I]);
        if Item <> '' then
          InsertarTextoMapaEnRegla(Item, ubvAccion);
      end;
    finally
      Parts.Free;
    end;

    PintarTodo;
    Show;
    BringToFront;
    Exit;
  end;

  if (Pos('Switch(', S) = 1) or
     (Pos('LocoVel(', S) = 1) or
     (Pos('LocoDir(', S) = 1) or
     (Pos('Funcion(', S) = 1) or
     (Pos('Delay(', S) = 1) or
     (Pos('ActivarGrupo(', S) = 1) or
     (Pos('DesactivarGrupo(', S) = 1) then
    InsertarTextoMapaEnRegla(S, ubvAccion)
  else
    InsertarTextoMapaEnRegla(S, ubvCondicion);

  Show;
  BringToFront;
end;

procedure TFormAutomatizacionVisual.InsertarCondicionDesdeMenuMapa(const ATexto: string);
begin
  InsertarTextoMapaEnRegla(ATexto, ubvCondicion);
end;

procedure TFormAutomatizacionVisual.InsertarEjecucionDesdeMenuMapa(const ATexto: string);
begin
  InsertarTextoMapaEnRegla(ATexto, ubvAccion);
end;

procedure TFormAutomatizacionVisual.InsertarCondicionMapa(const ATexto: string);
begin
  InsertarTextoMapaEnRegla(ATexto, ubvCondicion);
end;

procedure TFormAutomatizacionVisual.InsertarAccionMapa(const ATexto: string);
begin
  InsertarTextoMapaEnRegla(ATexto, ubvAccion);
end;

procedure TFormAutomatizacionVisual.InsertarElementoMapaEnRegla(
  ATipo: TTipoBloqueVisual; AUso: TUsoBloqueVisual; ADireccion: Integer);
var
  B: TBloqueVisual;
begin
  if not EdicionReglasPermitida(True) then Exit;
  if ReglaSeleccionada = nil then
  begin
    ShowMessage('Seleccione o cree una regla antes de insertar bloques desde el mapa.');
    Exit;
  end;

  B := TBloqueVisual.Create(ATipo, AUso);
  B.Direccion := ADireccion;

  if AUso = ubvCondicion then
    ReglaSeleccionada.Condiciones.Add(B)
  else
    ReglaSeleccionada.Acciones.Add(B);

  BloqueSeleccionado := B;
  MarcarModificado;
  PintarRegla;
  MostrarPropiedadesBloque(B);
end;

end.
