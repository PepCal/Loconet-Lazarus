// === UNIDAD ORGANIZADA Y DOCUMENTADA ===
// NOTA: Se mantiene funcionalidad original. Se añaden comentarios y estructura.

unit unitcontrolmaqueta;

{$mode ObjFPC}{$H+}

interface

uses
    Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
    Buttons, Menus, ControlMaqueta, MaquetaModel, fpjson, jsonparser, fgl, LCLIntf, Math, Types,
    IntfGraphics, FPImage, UnitAutomatismos;

type

{ =========================
  SWITCH VISUAL
  ========================= }

  TSwitchVisual = class
  public
    Nombre: string;
    FileOff: string;
    FileOn: string;

    Img: array[0..1] of TBitmap;

    constructor Create;
    destructor Destroy; override;

    procedure LoadImages;
  end;

  TSwitchVisualList = specialize TFPGObjectList<TSwitchVisual>;

{ =========================
  IMAGE REPOSITORY
  ========================= }

  TImageRepository = class
  private
    FSwitchTypes: TSwitchVisualList;
    FGraficos: TGraficoVisualList;

  public
    Sensor: array[0..1] of TBitmap;
    Rail: array[0..2] of TBitmap;

    constructor Create;
    destructor Destroy; override;

    function AddSwitchType(const Nombre, ImgOff, ImgOn: string): TSwitchVisual;
    function GetSwitchImage(const SubTipo: string; State: Integer): TBitmap;
    function ExistsSwitchType(const Nombre: string): Boolean;
    function SwitchTypeCount: Integer;
    function GetSwitchTypeNames: string;
    function GetSwitchTypeName(Index: Integer): string;
    function FindSwitchType(const Nombre: string): TSwitchVisual;
    function RenameSwitchType(const OldName, NewName: string): Boolean;
    function DeleteSwitchType(const Nombre: string): Boolean;

    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);

    function DeleteGraphicType(const Nombre: string): Boolean;
    function FindGraphicType(const Nombre: string): TGraficoVisual;
    function RenameGraphicType(const OldName, NewName: string): Boolean;
    function AddGraphicType(const Nombre, ImgFile: string): TGraficoVisual;
    function GetGraphicImage(const SubTipo: string): TBitmap;
    function ExistsGraphicType(const Nombre: string): Boolean;
    function GraphicTypeCount: Integer;
    function GetGraphicTypeName(Index: Integer): string;
  end;

{ =========================
  FORM
  ========================= }

  TModoMaqueta = (mmOperacion, mmEdicion, mmInsercion);

  { TForm_ControlMaqueta }

  TForm_ControlMaqueta = class(TForm)
    BColorFondo: TButton;
    BtnAutomatismos: TButton;
    BRefrescaMapa: TButton;
    BCargaRaMapa: TButton;
    ColorDialog1: TColorDialog;
    BCargarMapa: TButton;
    BGuardarMapa: TButton;
    BEdicionMaqueta: TButton;
    CBMapas: TComboBox;
    ControlMaqueta1: TControlMaqueta;
    PaintBox1: TPaintBox;
    Panel2: TPanel;
    PanelBotones: TPanel;
    ScrollBox1: TScrollBox;

    procedure BCargaRaMapaClick(Sender: TObject);
    procedure BRefrescaMapaClick(Sender: TObject);
    procedure CargarMapaInicial;
    procedure CrearMapaVacioInicial;
    procedure BCargarMapaClick(Sender: TObject);
    procedure BColorFondoClick(Sender: TObject);
    procedure BEdicionMaquetaClick(Sender: TObject);
    procedure BGuardarMapaClick(Sender: TObject);
    procedure BtnAutomatismosClick(Sender: TObject);
    procedure ControlMaqueta1RailCom(Sender: TObject; Sensor: Integer;
      DCC: Integer; Present: Boolean);
    procedure ControlMaqueta1Sensor(Sender: TObject; Addr: Integer;
      State: Boolean);
    procedure ControlMaqueta1Switch(Sender: TObject; Addr: Integer;
      State: Boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1Paint(Sender: TObject);
    function ScreenToWorldX(X: Integer): Integer;
    function ScreenToWorldY(Y: Integer): Integer;
    procedure DoZoom(WheelDelta: Integer; MousePos: TPoint);
    procedure ScrollBox1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    function WorldToScreenX(X: Integer): Integer;
    function WorldToScreenY(Y: Integer): Integer;

  private

    ImageRepo: TImageRepository;
    Modo: TModoMaqueta;
    ElementoSeleccionado: TElementoMaqueta;
    OffsetDragX, OffsetDragY: Integer;
    DragActivo: Boolean;
    Zoom: Double;
    ZoomMin, ZoomMax: Double;
    FondoMapa: TColor;
    LAnchoMapa: TLabel;
    LAltoMapa: TLabel;
    EAnchoMapa: TEdit;
    EAltoMapa: TEdit;
    BAplicarMapa: TButton;
    FPopupElementoRegla: TPopupMenu;
    FElementoPopup: TElementoMaqueta;

    TipoInsertar: TElementoTipo;
    SubTipoInsertar: string;
    AddrInsertar: Integer;
    SelectedElements: specialize TFPGObjectList<TElementoMaqueta>;
    MultiSelect: Boolean;

    AreaWidth: Integer;
    AreaHeight: Integer;

    FSelectingRect: Boolean;
    FSelectStartX: Integer;
    FSelectStartY: Integer;
    FSelectCurrentX: Integer;
    FSelectCurrentY: Integer;

    FMapaActualFileName: string;
    FMapaVacioInicial: Boolean;

    BCopiarPanel: TButton;
    BPegarPanel: TButton;
    FClipboardElementos: specialize TFPGObjectList<TElementoMaqueta>;

    // ===== PALETA / PANEL VISUAL =====
    PaletaHost: TPanel;
    ScrollPanelEdicion: TScrollBox;
    PanelTipos: TGroupBox;
    PanelSubtipos: TGroupBox;
    PanelProps: TGroupBox;
    FlowTipos: TFlowPanel;
    FlowSubtipos: TFlowPanel;

    LTipo: TLabel;
    LSubTipo: TLabel;
    LAddr: TLabel;
    LTexto: TLabel;
    LRot: TLabel;
    LFontSize: TLabel;
    EFontSize: TEdit;

    ESubTipo: TEdit;
    EAddr: TEdit;
    ETexto: TEdit;
    ERot: TEdit;

    LGrupoNombre: TLabel;
    EGrupoNombre: TEdit;
    LGrupoAccion: TLabel;
    CbGrupoAccion: TComboBox;

    BNuevoSubtipo: TButton;
    BBorrarSubtipo: TButton;
    BAplicarProps: TButton;
    BRotarPanel: TButton;
    BModoEdicionPanel: TButton;
    BModoInsercionPanel: TButton;
    BBorrarPanel: TButton;
    BSalirPanel: TButton;

    LColorTexto: TLabel;
    PColorTexto: TPanel;
    BColorTexto: TButton;
    BSeleccionarTodo: TButton;

    procedure OnSeleccionarTodoClick(Sender: TObject);

    procedure OnColorTextoClick(Sender: TObject);
    procedure ActualizarPreviewColorTexto;

    procedure CrearPanelEdicion;
    procedure ReconstruirPaletaTipos;
    procedure ReconstruirPaletaSubtipos;
    procedure SincronizarPaletaConElemento(E: TElementoMaqueta);
    procedure ActualizarPanelPropiedades;
    procedure ActualizarTituloPanelPropiedades;
    procedure SeleccionarTipoPaleta(ATipo: TElementoTipo);
    procedure SeleccionarSubTipoPaleta(const ASubTipo: string);
    procedure ActualizarBotonSubtipoSwitch(const OldName, NewName: string);
    procedure SaveSwitchCatalog;
    procedure LoadSwitchCatalog;

    procedure AplicarEstadosSwitchDelMapa;
    procedure LimpiarMapa;
    procedure GuardarMapaActualAutomaticamente;
    procedure MarcarMapaActual(const AFileName: string; AEsMapaVacioInicial: Boolean);
    procedure OnBorrarSubtipoClick(Sender: TObject);
    procedure OnAplicarTamanoMapa(Sender: TObject);
    procedure GuardarMapaEnArchivo(const FileName: string);
    procedure CargarMapaDeArchivo(const FileName: string);
    procedure CargarListaMapas;
    function GetMapsPath: string;
    procedure MenuInsertarEnReglasClick(Sender: TObject);
    procedure CrearMenuContextualElementoRegla(E: TElementoMaqueta);
    function TituloElementoParaMenu(E: TElementoMaqueta): string;
    function GetContextoActualRegla: TContextoRegla;

    procedure OnTipoPaletaClick(Sender: TObject);
    procedure OnSubTipoPaletaClick(Sender: TObject);
    procedure OnNuevoSubtipoClick(Sender: TObject);
    procedure OnAplicarPropsClick(Sender: TObject);
    procedure OnRotarPanelClick(Sender: TObject);
    procedure OnModoEdicionPanelClick(Sender: TObject);
    procedure OnModoInsercionPanelClick(Sender: TObject);
    procedure OnBorrarPanelClick(Sender: TObject);
    procedure OnSalirPanelClick(Sender: TObject);

    function CrearNuevoSubTipoSwitch(var ASubTipo: string): Boolean;
    function CrearNuevoSubTipoGrafico(var ASubTipo: string): Boolean;
    function TipoToStr(ATipo: TElementoTipo): string;
    function StrToTipo(const S: string; out ATipo: TElementoTipo): Boolean;
    function AccionGrupoToStr(A: TAccionGrupo): string;
    function StrToAccionGrupo(const S: string; out A: TAccionGrupo): Boolean;
    function GetTextoControlGrupo(E: TElementoMaqueta): string;
    function SubTipoEnUso(const Nombre: string; ATipo: TElementoTipo): Boolean;
    procedure RenombrarSubTipoEnElementos(const OldName, NewName: string);
    function RenombrarSubTipoSwitch(var ASubTipo: string): Boolean;
    function SeleccionarArchivoImagen(const Titulo: string; var FileName: string): Boolean;
    function ElegirSubTipoGrafico(var ASubTipo: string): Boolean;
    function ElegirTipoElemento(var ATipo: TElementoTipo): Boolean;
    function ElegirSubTipoSwitch(var ASubTipo: string): Boolean;
    function BorrarElemento(E: TElementoMaqueta): Boolean;
    function PedirDatosInsercion: Boolean;
    function EditarArchivosSubTipoSwitch(const ASubTipo: string): Boolean;
    function EditarElemento(E: TElementoMaqueta): Boolean;
    procedure GetMouseRealPos(out RX, RY: Integer);
    procedure InsertarElemento(X, Y: Integer);
    function GetElementoAt(X, Y: Integer): TElementoMaqueta;

    function GetImage(E: TElementoMaqueta): TBitmap;
    function GetTipoCaption(ATipo: TElementoTipo): string;
    function AplicarPropsAElemento(E: TElementoMaqueta): Boolean;
    procedure AplicarPropsAInsercion;
    function ClonarElemento(E: TElementoMaqueta): TElementoMaqueta;
    procedure CopiarSeleccionActual;
    procedure PegarElementosCopiados;
    procedure OnCopiarPanelClick(Sender: TObject);
    procedure OnPegarPanelClick(Sender: TObject);
    procedure DibujarElemento(E: TElementoMaqueta);

    function GetElementoBoundsWorld(E: TElementoMaqueta): TRect;
    function NormalizarRect(const R: TRect): TRect;
    procedure SeleccionarElementosEnRect(const RSel: TRect);

  end;

const
  SCROLL_MARGIN = 20;
  SCROLL_STEP = 10;

var
  Form_ControlMaqueta: TForm_ControlMaqueta;

implementation

{$R *.lfm}

{ =========================
  UTIL
  ========================= }

function Snap(Value: Integer): Integer;
const
  Grid = 10;
begin
  Result := (Value div Grid) * Grid;
end;

function RotateBitmap(const Src: TBitmap; AngleDeg: Double): TBitmap;
var
  SrcImg, DstImg: TLazIntfImage;
  SrcX, SrcY: Integer;
  DstX, DstY: Integer;
  cxS, cyS, cxD, cyD: Double;
  rad, c, s: Double;
  x0, y0: Double;
  MinX, MinY, MaxX, MaxY: Double;
  Corners: array[0..3] of TPoint;
  Pts: array[0..3] of TPointF;
  W, H: Integer;
  Col: TFPColor;
begin
  Result := TBitmap.Create;
  if (Src = nil) or Src.Empty then Exit;

  SrcImg := TLazIntfImage.Create(0, 0);
  DstImg := nil;
  try
    SrcImg.LoadFromBitmap(Src.Handle, Src.MaskHandle);

    rad := DegToRad(AngleDeg);
    c := Cos(rad);
    s := Sin(rad);

    Corners[0] := Point(0, 0);
    Corners[1] := Point(Src.Width - 1, 0);
    Corners[2] := Point(Src.Width - 1, Src.Height - 1);
    Corners[3] := Point(0, Src.Height - 1);

    cxS := (Src.Width - 1) / 2;
    cyS := (Src.Height - 1) / 2;

    for SrcX := 0 to 3 do
    begin
      x0 := Corners[SrcX].X - cxS;
      y0 := Corners[SrcX].Y - cyS;
      Pts[SrcX].X := x0 * c - y0 * s;
      Pts[SrcX].Y := x0 * s + y0 * c;
    end;

    MinX := Pts[0].X; MaxX := Pts[0].X;
    MinY := Pts[0].Y; MaxY := Pts[0].Y;

    for SrcX := 1 to 3 do
    begin
      if Pts[SrcX].X < MinX then MinX := Pts[SrcX].X;
      if Pts[SrcX].X > MaxX then MaxX := Pts[SrcX].X;
      if Pts[SrcX].Y < MinY then MinY := Pts[SrcX].Y;
      if Pts[SrcX].Y > MaxY then MaxY := Pts[SrcX].Y;
    end;

    W := Ceil(MaxX - MinX + 1);
    H := Ceil(MaxY - MinY + 1);

    if W <= 0 then W := 1;
    if H <= 0 then H := 1;

    DstImg := TLazIntfImage.Create(0, 0);
    DstImg.DataDescription := SrcImg.DataDescription;
    DstImg.SetSize(W, H);

    cxD := (W - 1) / 2;
    cyD := (H - 1) / 2;

    for DstY := 0 to H - 1 do
      for DstX := 0 to W - 1 do
      begin
        x0 := DstX - cxD;
        y0 := DstY - cyD;

        SrcX := Round( x0 * c + y0 * s + cxS );
        SrcY := Round(-x0 * s + y0 * c + cyS );

        if (SrcX >= 0) and (SrcX < Src.Width) and
           (SrcY >= 0) and (SrcY < Src.Height) and
           (DstX >= 0) and (DstX < W) and
           (DstY >= 0) and (DstY < H) then
        begin
          Col := SrcImg.Colors[SrcX, SrcY];
          DstImg.Colors[DstX, DstY] := Col;
        end
        else
        begin
          Col.red := 0;
          Col.green := 0;
          Col.blue := 0;
          Col.alpha := 0;
          DstImg.Colors[DstX, DstY] := Col;
        end;
      end;

    Result.LoadFromIntfImage(DstImg);
  finally
    SrcImg.Free;
    DstImg.Free;
  end;
end;

procedure LoadBitmap(Bmp: TBitmap; const FileName: string);
var Pic: TPicture;
begin
  Pic := TPicture.Create;
  try
    Pic.LoadFromFile(FileName);
    Bmp.Assign(Pic.Bitmap);
  finally
    Pic.Free;
  end;
end;

function CreateTextBitmap(ACanvas: TCanvas; const ATxt: string;
  AZoom: Double; ATextColor: TColor; AFontSize: Integer): TBitmap;
const
  MASK_COLOR = clFuchsia;
var
  W, H: Integer;
begin
  Result := TBitmap.Create;

  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Height := Round(AFontSize * AZoom);
  if ACanvas.Font.Height < 6 then
    ACanvas.Font.Height := 6;

  W := ACanvas.TextWidth(ATxt);
  H := ACanvas.TextHeight(ATxt);

  if W < 1 then W := 1;
  if H < 1 then H := 1;

  Result.SetSize(W, H);

  // Fondo temporal con color máscara
  Result.Transparent := False;
  Result.Canvas.Brush.Style := bsSolid;
  Result.Canvas.Brush.Color := MASK_COLOR;
  Result.Canvas.FillRect(0, 0, W, H);

  // Dibujar texto sin antialias para evitar halos/delineado
  Result.Canvas.Font.Assign(ACanvas.Font);
  Result.Canvas.Font.Color := ATextColor;
  Result.Canvas.Font.Style := [fsBold];
  Result.Canvas.Font.Height := ACanvas.Font.Height;
  {$IFDEF LCL}
  Result.Canvas.Font.Quality := fqNonAntialiased;
  {$ENDIF}

  Result.Canvas.Brush.Style := bsClear;
  Result.Canvas.TextOut(0, 0, ATxt);

  // Activar transparencia usando el color de máscara
  Result.TransparentColor := MASK_COLOR;
  Result.Transparent := True;
end;

{ =========================
  GRAFICO VISUAL
  ========================= }

  function TImageRepository.DeleteGraphicType(const Nombre: string): Boolean;
  var
    i: Integer;
  begin
    Result := False;

    for i := 0 to FGraficos.Count - 1 do
      if SameText(FGraficos[i].Nombre, Nombre) then
      begin
        FGraficos.Delete(i);
        Exit(True);
      end;
  end;

function TImageRepository.DeleteSwitchType(const Nombre: string): Boolean;
var
  i: Integer;
begin
  Result := False;

  for i := 0 to FSwitchTypes.Count - 1 do
    if SameText(FSwitchTypes[i].Nombre, Nombre) then
    begin
      FSwitchTypes.Delete(i);
      Exit(True);
    end;
end;



  function TImageRepository.FindGraphicType(const Nombre: string): TGraficoVisual;
  var
    G: TGraficoVisual;
  begin
    Result := nil;
    for G in FGraficos do
      if SameText(G.Nombre, Nombre) then
        Exit(G);
  end;

  function TImageRepository.RenameGraphicType(const OldName, NewName: string): Boolean;
  var
    G: TGraficoVisual;
  begin
    Result := False;

    if Trim(OldName) = '' then Exit(False);
    if Trim(NewName) = '' then Exit(False);

    if SameText(OldName, NewName) then
      Exit(True);

    if ExistsGraphicType(NewName) then
      Exit(False);

    G := FindGraphicType(OldName);
    if not Assigned(G) then Exit(False);

    G.Nombre := Trim(NewName);
    Result := True;
  end;

function TImageRepository.AddGraphicType(const Nombre, ImgFile: string): TGraficoVisual;
begin
  Result := TGraficoVisual.Create;
  Result.Nombre := Nombre;
  Result.FileName := ImgFile;
  Result.LoadImage;
  FGraficos.Add(Result);
end;

function TImageRepository.ExistsGraphicType(const Nombre: string): Boolean;
var
  G: TGraficoVisual;
begin
  Result := False;
  for G in FGraficos do
    if SameText(G.Nombre, Nombre) then
      Exit(True);
end;

function TImageRepository.GraphicTypeCount: Integer;
begin
  Result := FGraficos.Count;
end;

function TImageRepository.GetGraphicTypeName(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FGraficos.Count) then
    Result := FGraficos[Index].Nombre
  else
    Result := '';
end;

function TImageRepository.GetGraphicImage(const SubTipo: string): TBitmap;
var
  G: TGraficoVisual;
begin
  Result := nil;
  for G in FGraficos do
    if SameText(G.Nombre, SubTipo) then
      Exit(G.Img);
end;

{ =========================
  SWITCH VISUAL
  ========================= }

constructor TSwitchVisual.Create;
begin
  Img[0] := TBitmap.Create;
  Img[1] := TBitmap.Create;
end;

destructor TSwitchVisual.Destroy;
begin
  Img[0].Free;
  Img[1].Free;
  inherited;
end;

procedure TSwitchVisual.LoadImages;
begin
  if FileExists(FileOff) then LoadBitmap(Img[0], FileOff);
  if FileExists(FileOn) then LoadBitmap(Img[1], FileOn);
end;

{ =========================
  IMAGE REPO
  ========================= }

function AppBasePath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
end;

function SaveImagePath(const FileName: string): string;
begin
  if Trim(FileName) = '' then
    Exit('');

  Result := ExtractRelativePath(AppBasePath, ExpandFileName(FileName));
end;

function LoadImagePath(const FileName: string): string;
begin
  if Trim(FileName) = '' then
    Exit('');

  if ExtractFileDrive(FileName) <> '' then
    Result := ExpandFileName(FileName)
  else
    Result := ExpandFileName(AppBasePath + FileName);
end;

function GetResPath(const FileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + FileName;
end;

constructor TImageRepository.Create;
begin
  FSwitchTypes := TSwitchVisualList.Create(True);
  FGraficos := TGraficoVisualList.Create(True);

  Sensor[0] := TBitmap.Create;
  Sensor[1] := TBitmap.Create;

  Rail[0] := TBitmap.Create;
  Rail[1] := TBitmap.Create;
  Rail[2] := TBitmap.Create;

  LoadBitmap(Sensor[0], GetResPath('sensor_off.png'));
  LoadBitmap(Sensor[1], GetResPath('sensor_on.png'));

  LoadBitmap(Rail[0], GetResPath('rail_free.png'));
  LoadBitmap(Rail[1], GetResPath('rail_occ.png'));
  LoadBitmap(Rail[2], GetResPath('rail_loco.png'));
end;

destructor TImageRepository.Destroy;
var i: Integer;
begin
  for i := 0 to 1 do Sensor[i].Free;
  for i := 0 to 2 do Rail[i].Free;

  FSwitchTypes.Free;
  FGraficos.Free;
  inherited;
end;

function TImageRepository.RenameSwitchType(const OldName, NewName: string): Boolean;
var
  S: TSwitchVisual;
begin
  Result := False;

  if Trim(OldName) = '' then Exit(False);
  if Trim(NewName) = '' then Exit(False);

  if SameText(OldName, NewName) then
    Exit(True);

  if ExistsSwitchType(NewName) then
    Exit(False);

  S := FindSwitchType(OldName);
  if not Assigned(S) then Exit(False);

  S.Nombre := Trim(NewName);
  Result := True;
end;

function TImageRepository.FindSwitchType(const Nombre: string): TSwitchVisual;
var
  S: TSwitchVisual;
begin
  Result := nil;
  for S in FSwitchTypes do
    if SameText(S.Nombre, Nombre) then
      Exit(S);
end;

function TImageRepository.GetSwitchTypeNames: string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FSwitchTypes.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ', ';
    Result := Result + FSwitchTypes[i].Nombre;
  end;
end;

function TImageRepository.GetSwitchTypeName(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FSwitchTypes.Count) then
    Result := FSwitchTypes[Index].Nombre
  else
    Result := '';
end;

function TImageRepository.SwitchTypeCount: Integer;
begin
  Result := FSwitchTypes.Count;
end;

function TImageRepository.ExistsSwitchType(const Nombre: string): Boolean;
var
  S: TSwitchVisual;
begin
  Result := False;
  for S in FSwitchTypes do
    if SameText(S.Nombre, Nombre) then
      Exit(True);
end;

function TImageRepository.AddSwitchType(const Nombre, ImgOff, ImgOn: string): TSwitchVisual;
begin
  Result := TSwitchVisual.Create;
  Result.Nombre := Nombre;
  Result.FileOff := ImgOff;
  Result.FileOn := ImgOn;
  Result.LoadImages;
  FSwitchTypes.Add(Result);
end;

function TImageRepository.GetSwitchImage(const SubTipo: string; State: Integer): TBitmap;
var
  S: TSwitchVisual;
  Idx: Integer;
begin
  Result := nil;

  if State < 0 then Idx := 0
  else if State > 1 then Idx := 1
  else Idx := State;

  for S in FSwitchTypes do
    if SameText(S.Nombre, SubTipo) then
      Exit(S.Img[Idx]);

  if FSwitchTypes.Count > 0 then
    Result := FSwitchTypes[0].Img[Idx];
end;

procedure TImageRepository.SaveToFile(const FileName: string);
var
  Root: TJSONObject;
  ArrSwitch: TJSONArray;
  ArrGraphic: TJSONArray;
  Obj: TJSONObject;
  S: TSwitchVisual;
  G: TGraficoVisual;
begin
  Root := TJSONObject.Create;
  ArrSwitch := TJSONArray.Create;
  ArrGraphic := TJSONArray.Create;

  for S in FSwitchTypes do
  begin
    if S.Nombre = '' then Continue;
    if S.FileOff = '' then Continue;
    if S.FileOn = '' then Continue;

    Obj := TJSONObject.Create;
    Obj.Add('name', S.Nombre);
    Obj.Add('img_off', SaveImagePath(S.FileOff));
    Obj.Add('img_on', SaveImagePath(S.FileOn));
    ArrSwitch.Add(Obj);
  end;

  for G in FGraficos do
  begin
    if G.Nombre = '' then Continue;
    if G.FileName = '' then Continue;

    Obj := TJSONObject.Create;
    Obj.Add('name', G.Nombre);
    Obj.Add('img', SaveImagePath(G.FileName));
    ArrGraphic.Add(Obj);
  end;

  Root.Add('switch_types', ArrSwitch);
  Root.Add('graphic_types', ArrGraphic);

  with TStringList.Create do
  try
    Text := Root.FormatJSON;
    SaveToFile(FileName);
  finally
    Free;
  end;

  Root.Free;
end;

function SafeGetString(Obj: TJSONObject; const Key: string; const Default: string = ''): string;
begin
  if Obj.IndexOfName(Key) <> -1 then
    Result := Obj.Get(Key, Default)
  else
    Result := Default;
end;

function FileValid(const FileName: string): Boolean;
begin
  Result := (FileName <> '') and FileExists(FileName);
end;

procedure TImageRepository.LoadFromFile(const FileName: string);
var
  Root: TJSONObject;
  Arr: TJSONArray;
  Obj: TJSONObject;
  SL: TStringList;
  i: Integer;
  S: TSwitchVisual;
  G: TGraficoVisual;
  Name, OffFile, OnFile, ImgFile: string;
begin
  if not FileExists(FileName) then Exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    try
      Root := TJSONObject(GetJSON(SL.Text));
    except
      Exit;
    end;
  finally
    SL.Free;
  end;

  try
    if (Root.IndexOfName('switch_types') <> -1) and
       (Root.Find('switch_types') is TJSONArray) then
    begin
      Arr := Root.Arrays['switch_types'];

      for i := 0 to Arr.Count - 1 do
      begin
        if not (Arr.Items[i] is TJSONObject) then Continue;

        Obj := Arr.Objects[i];

        Name := SafeGetString(Obj, 'name');
        OffFile := LoadImagePath(SafeGetString(Obj, 'img_off'));
        OnFile := LoadImagePath(SafeGetString(Obj, 'img_on'));

        if Name = '' then Continue;
        if ExistsSwitchType(Name) then Continue;
        if not FileValid(OffFile) then Continue;
        if not FileValid(OnFile) then Continue;

        S := TSwitchVisual.Create;
        S.Nombre := Name;
        S.FileOff := OffFile;
        S.FileOn := OnFile;
        S.LoadImages;
        FSwitchTypes.Add(S);
      end;
    end;

    if (Root.IndexOfName('graphic_types') <> -1) and
       (Root.Find('graphic_types') is TJSONArray) then
    begin
      Arr := Root.Arrays['graphic_types'];

      for i := 0 to Arr.Count - 1 do
      begin
        if not (Arr.Items[i] is TJSONObject) then Continue;

        Obj := Arr.Objects[i];

        Name := SafeGetString(Obj, 'name');
        ImgFile := LoadImagePath(SafeGetString(Obj, 'img'));

        if Name = '' then Continue;
        if ExistsGraphicType(Name) then Continue;
        if not FileValid(ImgFile) then Continue;

        G := TGraficoVisual.Create;
        G.Nombre := Name;
        G.FileName := ImgFile;
        G.LoadImage;
        FGraficos.Add(G);
      end;
    end;

  finally
    Root.Free;
  end;
end;

{ =========================
  FORM
  ========================= }

function TForm_ControlMaqueta.GetContextoActualRegla: TContextoRegla;
begin
  Result := crDesconocido;

  if Assigned(FormAutomatismos) then
    Result := FormAutomatismos.GetContextoCursorRegla;
end;

function TForm_ControlMaqueta.TituloElementoParaMenu(E: TElementoMaqueta): string;
begin
  Result := '';

  if not Assigned(E) then Exit('');

  case E.Tipo of
    etSensor:
      Result := Format('Sensor %d', [E.Addr]);

    etRail:
      Result := Format('RailCom %d', [E.Addr]);

    etSwitch:
      begin
        if Trim(E.SubTipo) <> '' then
          Result := Format('Switch %d [%s]', [E.Addr, E.SubTipo])
        else
          Result := Format('Switch %d', [E.Addr]);
      end;

  else
    Result := 'Elemento';
  end;
end;

procedure TForm_ControlMaqueta.MenuInsertarEnReglasClick(Sender: TObject);
var
  S: string;
begin
  if not (Sender is TMenuItem) then Exit;

  S := TMenuItem(Sender).Hint;
  if S = '' then Exit;

  if not Assigned(FormAutomatismos) then
    FormAutomatismos := TFormAutomatismos.Create(Application);

  FormAutomatismos.InsertarTextoEnReglas(S);
end;

procedure TForm_ControlMaqueta.CrearMenuContextualElementoRegla(E: TElementoMaqueta);

  function AddItem(AParent: TMenuItem; const ACaption, AInsert: string): TMenuItem;
  begin
    Result := TMenuItem.Create(FPopupElementoRegla);
    Result.Caption := ACaption;
    Result.Hint := AInsert;
    Result.OnClick := @MenuInsertarEnReglasClick;
    AParent.Add(Result);
  end;

var
  Root: TMenuItem;
  Ctx: TContextoRegla;
  Titulo: string;
begin
  if Assigned(FPopupElementoRegla) then
    FreeAndNil(FPopupElementoRegla);

  FPopupElementoRegla := TPopupMenu.Create(Self);
  FElementoPopup := E;

  if not Assigned(E) then Exit;

  Titulo := TituloElementoParaMenu(E);
  Ctx := GetContextoActualRegla;

  Root := TMenuItem.Create(FPopupElementoRegla);
  Root.Caption := Titulo;
  FPopupElementoRegla.Items.Add(Root);

  case E.Tipo of
    etSensor:
      begin
        case Ctx of
          crNuevaCondicion:
            begin
              AddItem(Root,
                Format('Si Sensor(%d,ON) entonces ', [E.Addr]),
                Format('Si Sensor(%d,ON) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si Sensor(%d,OFF) entonces ', [E.Addr]),
                Format('Si Sensor(%d,OFF) entonces ', [E.Addr]));
            end;

          crAndCondicion:
            begin
              AddItem(Root,
                Format('and Sensor(%d,ON)', [E.Addr]),
                Format(' and Sensor(%d,ON)', [E.Addr]));
              AddItem(Root,
                Format('and Sensor(%d,OFF)', [E.Addr]),
                Format(' and Sensor(%d,OFF)', [E.Addr]));
            end;

        else
          begin
            AddItem(Root,
              Format('Si Sensor(%d,ON) entonces ', [E.Addr]),
              Format('Si Sensor(%d,ON) entonces ', [E.Addr]));
            AddItem(Root,
              Format('Si Sensor(%d,OFF) entonces ', [E.Addr]),
              Format('Si Sensor(%d,OFF) entonces ', [E.Addr]));
            AddItem(Root,
              Format('and Sensor(%d,ON)', [E.Addr]),
              Format(' and Sensor(%d,ON)', [E.Addr]));
            AddItem(Root,
              Format('and Sensor(%d,OFF)', [E.Addr]),
              Format(' and Sensor(%d,OFF)', [E.Addr]));
          end;
        end;
      end;

    etRail:
      begin
        case Ctx of
          crNuevaCondicion:
            begin
              AddItem(Root,
                Format('Si RailCom(%d,Dcc,PRESENTE) entonces ', [E.Addr]),
                Format('Si RailCom(%d,Dcc,PRESENTE) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si RailCom(%d,Dcc,AUSENTE) entonces ', [E.Addr]),
                Format('Si RailCom(%d,Dcc,AUSENTE) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si RailComEstado(%d,PRESENTE) entonces ', [E.Addr]),
                Format('Si RailComEstado(%d,PRESENTE) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si RailComEstado(%d,AUSENTE) entonces ', [E.Addr]),
                Format('Si RailComEstado(%d,AUSENTE) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si RailComLocoValido(%d) entonces ', [E.Addr]),
                Format('Si RailComLocoValido(%d) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si RailComDir(%d,0) entonces ', [E.Addr]),
                Format('Si RailComDir(%d,0) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si RailComDir(%d,1) entonces ', [E.Addr]),
                Format('Si RailComDir(%d,1) entonces ', [E.Addr]));
            end;

          crAndCondicion:
            begin
              AddItem(Root,
                Format('and RailComLocoValido(%d)', [E.Addr]),
                Format(' and RailComLocoValido(%d)', [E.Addr]));
              AddItem(Root,
                Format('and RailComDir(%d,0)', [E.Addr]),
                Format(' and RailComDir(%d,0)', [E.Addr]));
              AddItem(Root,
                Format('and RailComDir(%d,1)', [E.Addr]),
                Format(' and RailComDir(%d,1)', [E.Addr]));
              AddItem(Root,
                Format('and RailCom(%d,Dcc,PRESENTE)', [E.Addr]),
                Format(' and RailCom(%d,Dcc,PRESENTE)', [E.Addr]));
              AddItem(Root,
                Format('and RailCom(%d,Dcc,AUSENTE)', [E.Addr]),
                Format(' and RailCom(%d,Dcc,AUSENTE)', [E.Addr]));
              AddItem(Root,
                Format('and RailComEstado(%d,PRESENTE)', [E.Addr]),
                Format(' and RailComEstado(%d,PRESENTE)', [E.Addr]));
              AddItem(Root,
                Format('and RailComEstado(%d,AUSENTE)', [E.Addr]),
                Format(' and RailComEstado(%d,AUSENTE)', [E.Addr]));
            end;

          crComando:
            begin
              AddItem(Root,
                Format('RailComLoco(%d)', [E.Addr]),
                Format('RailComLoco(%d)', [E.Addr]));
              AddItem(Root,
                Format('LocoVel(RailComLoco(%d),Vel)', [E.Addr]),
                Format('LocoVel(RailComLoco(%d),Vel)', [E.Addr]));
              AddItem(Root,
                Format('LocoDir(RailComLoco(%d),0)', [E.Addr]),
                Format('LocoDir(RailComLoco(%d),0)', [E.Addr]));
              AddItem(Root,
                Format('LocoDir(RailComLoco(%d),1)', [E.Addr]),
                Format('LocoDir(RailComLoco(%d),1)', [E.Addr]));
              AddItem(Root,
                Format('Funcion(RailComLoco(%d),0,ON)', [E.Addr]),
                Format('Funcion(RailComLoco(%d),0,ON)', [E.Addr]));
              AddItem(Root,
                Format('Funcion(RailComLoco(%d),0,OFF)', [E.Addr]),
                Format('Funcion(RailComLoco(%d),0,OFF)', [E.Addr]));
            end;

        else
          begin
            AddItem(Root,
              Format('Si RailComLocoValido(%d) entonces ', [E.Addr]),
              Format('Si RailComLocoValido(%d) entonces ', [E.Addr]));
            AddItem(Root,
              Format('Si RailComEstado(%d,PRESENTE) entonces ', [E.Addr]),
              Format('Si RailComEstado(%d,PRESENTE) entonces ', [E.Addr]));
            AddItem(Root,
              Format('Si RailComEstado(%d,AUSENTE) entonces ', [E.Addr]),
              Format('Si RailComEstado(%d,AUSENTE) entonces ', [E.Addr]));
            AddItem(Root,
              Format('and RailComLocoValido(%d)', [E.Addr]),
              Format(' and RailComLocoValido(%d)', [E.Addr]));
            AddItem(Root,
              Format('and RailComEstado(%d,PRESENTE)', [E.Addr]),
              Format(' and RailComEstado(%d,PRESENTE)', [E.Addr]));
            AddItem(Root,
              Format('and RailComEstado(%d,AUSENTE)', [E.Addr]),
              Format(' and RailComEstado(%d,AUSENTE)', [E.Addr]));
            AddItem(Root,
              Format('LocoVel(RailComLoco(%d),Vel)', [E.Addr]),
              Format('LocoVel(RailComLoco(%d),Vel)', [E.Addr]));
          end;
        end;
      end;

    etSwitch:
      begin
        case Ctx of
          crNuevaCondicion:
            begin
              AddItem(Root,
                Format('Si Switch(%d,ON) entonces ', [E.Addr]),
                Format('Si Switch(%d,ON) entonces ', [E.Addr]));
              AddItem(Root,
                Format('Si Switch(%d,OFF) entonces ', [E.Addr]),
                Format('Si Switch(%d,OFF) entonces ', [E.Addr]));
            end;

          crAndCondicion:
            begin
              AddItem(Root,
                Format('and Switch(%d,ON)', [E.Addr]),
                Format(' and Switch(%d,ON)', [E.Addr]));
              AddItem(Root,
                Format('and Switch(%d,OFF)', [E.Addr]),
                Format(' and Switch(%d,OFF)', [E.Addr]));
            end;

          crComando:
            begin
              AddItem(Root,
                Format('Switch(%d,ON)', [E.Addr]),
                Format('Switch(%d,ON)', [E.Addr]));
              AddItem(Root,
                Format('Switch(%d,OFF)', [E.Addr]),
                Format('Switch(%d,OFF)', [E.Addr]));
            end;

        else
          begin
            AddItem(Root,
              Format('Si Switch(%d,ON) entonces ', [E.Addr]),
              Format('Si Switch(%d,ON) entonces ', [E.Addr]));
            AddItem(Root,
              Format('and Switch(%d,ON)', [E.Addr]),
              Format(' and Switch(%d,ON)', [E.Addr]));
            AddItem(Root,
              Format('Switch(%d,ON)', [E.Addr]),
              Format('Switch(%d,ON)', [E.Addr]));
          end;
        end;
      end;
  end;
end;

procedure TForm_ControlMaqueta.ActualizarBotonSubtipoSwitch(const OldName, NewName: string);
var
  i: Integer;
  B: TSpeedButton;
begin
  if not Assigned(FlowSubtipos) then Exit;

  for i := 0 to FlowSubtipos.ControlCount - 1 do
  begin
    if FlowSubtipos.Controls[i] is TSpeedButton then
    begin
      B := TSpeedButton(FlowSubtipos.Controls[i]);
      if SameText(Trim(B.Caption), Trim(OldName)) then
      begin
        B.Caption := Trim(NewName);
        B.Invalidate;
      end;
    end;
  end;

  FlowSubtipos.Invalidate;
  FlowSubtipos.Update;
end;

function TForm_ControlMaqueta.AccionGrupoToStr(A: TAccionGrupo): string;
begin
  case A of
    agActivar: Result := 'Activar';
    agDesactivar: Result := 'Desactivar';
  else
    Result := 'Activar';
  end;
end;

function TForm_ControlMaqueta.StrToAccionGrupo(const S: string; out A: TAccionGrupo): Boolean;
var
  L: string;
begin
  L := Trim(LowerCase(S));
  Result := True;

  if L = 'activar' then
    A := agActivar
  else if L = 'desactivar' then
    A := agDesactivar
  else
    Result := False;
end;

function TForm_ControlMaqueta.GetTextoControlGrupo(E: TElementoMaqueta): string;
begin
  if not Assigned(E) then
    Exit('');

  case E.GrupoAccion of
    agActivar:
      Result := 'Activar ' + E.GrupoNombre;
    agDesactivar:
      Result := 'Desactivar ' + E.GrupoNombre;
  else
    Result := E.GrupoNombre;
  end;
end;

function TForm_ControlMaqueta.GetTipoCaption(ATipo: TElementoTipo): string;
begin
  case ATipo of
    etSensor:       Result := 'Sensor';
    etRail:         Result := 'RailCom';
    etSwitch:       Result := 'Switch';
    etTexto:        Result := 'Texto';
    etGrafico:      Result := 'Gráfico';
    etControlGrupo: Result := 'ControlGrupo';
  else
    Result := 'Desconocido';
  end;
end;

procedure TForm_ControlMaqueta.ActualizarTituloPanelPropiedades;
begin
  if Modo = mmOperacion then
    PanelProps.Caption := 'Modo operación'
  else if Assigned(ElementoSeleccionado) and (Modo = mmEdicion) then
    PanelProps.Caption := 'Editar elemento'
  else if Modo = mmInsercion then
    PanelProps.Caption := 'Insertar elemento'
  else
    PanelProps.Caption := 'Propiedades';
end;

procedure TForm_ControlMaqueta.CrearPanelEdicion;
const
  MARGEN_X = 8;
  W_EDIT = 190;
  W_ADDR = 100;
  W_ROT = 60;
  W_BTN_ROT = 70;
  H_BTN = 28;
  SEP_Y = 8;
var
  YBotones: Integer;
  WBtnCol: Integer;
  XCol2: Integer;

begin
  if Assigned(PaletaHost) then
    FreeAndNil(PaletaHost);

  if Assigned(ScrollPanelEdicion) then
    FreeAndNil(ScrollPanelEdicion);

  Panel2.Caption := '';
  Panel2.BevelOuter := bvNone;

  ScrollPanelEdicion := TScrollBox.Create(Self);
  ScrollPanelEdicion.Parent := Panel2;
  ScrollPanelEdicion.Align := alClient;
  ScrollPanelEdicion.BorderStyle := bsNone;
  ScrollPanelEdicion.VertScrollBar.Visible := True;
  ScrollPanelEdicion.HorzScrollBar.Visible := False;
  ScrollPanelEdicion.VertScrollBar.Tracking := True;

  PaletaHost := TPanel.Create(Self);
  PaletaHost.Parent := ScrollPanelEdicion;
  PaletaHost.Align := alTop;
  PaletaHost.BevelOuter := bvNone;
  PaletaHost.Caption := '';
  PaletaHost.Height := 800;

  PanelTipos := TGroupBox.Create(Self);
  PanelTipos.Parent := PaletaHost;
  PanelTipos.Align := alTop;
  PanelTipos.Caption := 'Tipos';
  PanelTipos.Height := 105;

  FlowTipos := TFlowPanel.Create(Self);
  FlowTipos.Parent := PanelTipos;
  FlowTipos.Align := alClient;
  FlowTipos.AutoWrap := True;
  FlowTipos.BevelOuter := bvNone;
  FlowTipos.BorderSpacing.Around := 4;

  PanelSubtipos := TGroupBox.Create(Self);
  PanelSubtipos.Parent := PaletaHost;
  PanelSubtipos.Align := alTop;
  PanelSubtipos.Caption := 'Subtipos';
  PanelSubtipos.Height := 150;

  FlowSubtipos := TFlowPanel.Create(Self);
  FlowSubtipos.Parent := PanelSubtipos;
  FlowSubtipos.Align := alClient;
  FlowSubtipos.AutoWrap := True;
  FlowSubtipos.BevelOuter := bvNone;
  FlowSubtipos.BorderSpacing.Around := 4;

  BBorrarSubtipo := TButton.Create(Self);
  BBorrarSubtipo.Parent := PanelSubtipos;
  BBorrarSubtipo.Align := alBottom;
  BBorrarSubtipo.Height := H_BTN;
  BBorrarSubtipo.Caption := 'Borrar subtipo';
  BBorrarSubtipo.OnClick := @OnBorrarSubtipoClick;

  BNuevoSubtipo := TButton.Create(Self);
  BNuevoSubtipo.Parent := PanelSubtipos;
  BNuevoSubtipo.Align := alBottom;
  BNuevoSubtipo.Height := H_BTN;
  BNuevoSubtipo.Caption := 'Nuevo subtipo...';
  BNuevoSubtipo.OnClick := @OnNuevoSubtipoClick;

  PanelProps := TGroupBox.Create(Self);
  PanelProps.Parent := PaletaHost;
  PanelProps.Align := alClient;
  PanelProps.Caption := 'Propiedades';

  LTipo := TLabel.Create(Self);
  LTipo.Parent := PanelProps;
  LTipo.Left := MARGEN_X;
  LTipo.Top := 24;
  LTipo.Caption := 'Tipo: -';

  LSubTipo := TLabel.Create(Self);
  LSubTipo.Parent := PanelProps;
  LSubTipo.Left := MARGEN_X;
  LSubTipo.Top := 56;
  LSubTipo.Caption := 'Subtipo:';

  ESubTipo := TEdit.Create(Self);
  ESubTipo.Parent := PanelProps;
  ESubTipo.Left := MARGEN_X;
  ESubTipo.Top := 72;
  ESubTipo.Width := W_EDIT;

  LAddr := TLabel.Create(Self);
  LAddr.Parent := PanelProps;
  LAddr.Left := MARGEN_X;
  LAddr.Top := 104;
  LAddr.Caption := 'Dirección:';

  EAddr := TEdit.Create(Self);
  EAddr.Parent := PanelProps;
  EAddr.Left := MARGEN_X;
  EAddr.Top := 120;
  EAddr.Width := W_ADDR;

  LTexto := TLabel.Create(Self);
  LTexto.Parent := PanelProps;
  LTexto.Left := MARGEN_X;
  LTexto.Top := 152;
  LTexto.Caption := 'Texto:';

  ETexto := TEdit.Create(Self);
  ETexto.Parent := PanelProps;
  ETexto.Left := MARGEN_X;
  ETexto.Top := 168;
  ETexto.Width := W_EDIT;

  LFontSize := TLabel.Create(Self);
  LFontSize.Parent := PanelProps;
  LFontSize.Left := MARGEN_X;
  LFontSize.Top := 296;
  LFontSize.Caption := 'Tamaño texto:';

  EFontSize := TEdit.Create(Self);
  EFontSize.Parent := PanelProps;
  EFontSize.Left := MARGEN_X;
  EFontSize.Top := 312;
  EFontSize.Width := 60;
  EFontSize.Text := '14';

  LGrupoNombre := TLabel.Create(Self);
  LGrupoNombre.Parent := PanelProps;
  LGrupoNombre.Left := MARGEN_X;
  LGrupoNombre.Top := 200;
  LGrupoNombre.Caption := 'Nombre grupo:';

  EGrupoNombre := TEdit.Create(Self);
  EGrupoNombre.Parent := PanelProps;
  EGrupoNombre.Left := MARGEN_X;
  EGrupoNombre.Top := 216;
  EGrupoNombre.Width := W_EDIT;

  LGrupoAccion := TLabel.Create(Self);
  LGrupoAccion.Parent := PanelProps;
  LGrupoAccion.Left := MARGEN_X;
  LGrupoAccion.Top := 248;
  LGrupoAccion.Caption := 'Acción:';

  CbGrupoAccion := TComboBox.Create(Self);
  CbGrupoAccion.Parent := PanelProps;
  CbGrupoAccion.Left := MARGEN_X;
  CbGrupoAccion.Top := 264;
  CbGrupoAccion.Width := W_EDIT;
  CbGrupoAccion.Style := csDropDownList;
  CbGrupoAccion.Items.Add('Activar');
  CbGrupoAccion.Items.Add('Desactivar');
  CbGrupoAccion.ItemIndex := 0;

  LFontSize := TLabel.Create(Self);
  LFontSize.Parent := PanelProps;
  LFontSize.Left := MARGEN_X;
  LFontSize.Top := 296;
  LFontSize.Caption := 'Tamaño texto:';

  EFontSize := TEdit.Create(Self);
  EFontSize.Parent := PanelProps;
  EFontSize.Left := MARGEN_X;
  EFontSize.Top := 312;
  EFontSize.Width := 60;
  EFontSize.Text := '14';

  LColorTexto := TLabel.Create(Self);
  LColorTexto.Parent := PanelProps;
  LColorTexto.Left := MARGEN_X;
  LColorTexto.Top := 344;
  LColorTexto.Caption := 'Color texto:';

  PColorTexto := TPanel.Create(Self);
  PColorTexto.Parent := PanelProps;
  PColorTexto.Left := MARGEN_X;
  PColorTexto.Top := 360;
  PColorTexto.Width := 40;
  PColorTexto.Height := 22;
  PColorTexto.BevelOuter := bvLowered;
  PColorTexto.Color := clWhite;
  PColorTexto.Caption := '';

  BColorTexto := TButton.Create(Self);
  BColorTexto.Parent := PanelProps;
  BColorTexto.Left := PColorTexto.Left + PColorTexto.Width + 8;
  BColorTexto.Top := 358;
  BColorTexto.Width := 70;
  BColorTexto.Height := 26;
  BColorTexto.Caption := 'Color...';
  BColorTexto.OnClick := @OnColorTextoClick;

  LRot := TLabel.Create(Self);
  LRot.Parent := PanelProps;
  LRot.Left := MARGEN_X;
  LRot.Top := 392;
  LRot.Caption := 'Rotación (0..7):';

  ERot := TEdit.Create(Self);
  ERot.Parent := PanelProps;
  ERot.Left := MARGEN_X;
  ERot.Top := 408;
  ERot.Width := W_ROT;
  ERot.Text := '0';

  BRotarPanel := TButton.Create(Self);
  BRotarPanel.Parent := PanelProps;
  BRotarPanel.Left := ERot.Left + ERot.Width + 8;
  BRotarPanel.Top := ERot.Top - 1;
  BRotarPanel.Width := W_BTN_ROT;
  BRotarPanel.Height := ERot.Height + 2;
  BRotarPanel.Caption := 'Rotar';
  BRotarPanel.OnClick := @OnRotarPanelClick;

  BAplicarProps := TButton.Create(Self);
  BAplicarProps.Parent := PanelProps;
  BAplicarProps.Left := MARGEN_X;
  BAplicarProps.Top := ERot.Top + ERot.Height + 16;
  BAplicarProps.Width := W_EDIT;
  BAplicarProps.Height := H_BTN;
  BAplicarProps.Caption := 'Aplicar cambios';
  BAplicarProps.OnClick := @OnAplicarPropsClick;

  // ---- Tamaño del mapa ----
  LAnchoMapa := TLabel.Create(Self);
  LAnchoMapa.Parent := PanelProps;
  LAnchoMapa.Left := MARGEN_X;
  LAnchoMapa.Top := BAplicarProps.Top + H_BTN + 12;
  LAnchoMapa.Caption := 'Ancho mapa:';

  EAnchoMapa := TEdit.Create(Self);
  EAnchoMapa.Parent := PanelProps;
  EAnchoMapa.Left := MARGEN_X;
  EAnchoMapa.Top := LAnchoMapa.Top + 16;
  EAnchoMapa.Width := 70;
  EAnchoMapa.Text := IntToStr(AreaWidth);

  LAltoMapa := TLabel.Create(Self);
  LAltoMapa.Parent := PanelProps;
  LAltoMapa.Left := EAnchoMapa.Left + EAnchoMapa.Width + 20;
  LAltoMapa.Top := LAnchoMapa.Top;
  LAltoMapa.Caption := 'Alto mapa:';

  EAltoMapa := TEdit.Create(Self);
  EAltoMapa.Parent := PanelProps;
  EAltoMapa.Left := LAltoMapa.Left;
  EAltoMapa.Top := EAnchoMapa.Top;
  EAltoMapa.Width := 70;
  EAltoMapa.Text := IntToStr(AreaHeight);

  BAplicarMapa := TButton.Create(Self);
  BAplicarMapa.Parent := PanelProps;
  BAplicarMapa.Left := MARGEN_X;
  BAplicarMapa.Top := EAnchoMapa.Top + EAnchoMapa.Height + 12;
  BAplicarMapa.Width := W_EDIT;
  BAplicarMapa.Height := H_BTN;
  BAplicarMapa.Caption := 'Aplicar tamaño mapa';
  BAplicarMapa.OnClick := @OnAplicarTamanoMapa;

  YBotones := BAplicarMapa.Top + H_BTN + SEP_Y;

  WBtnCol := (W_EDIT - 8) div 2;
  XCol2 := MARGEN_X + WBtnCol + 8;

  BModoEdicionPanel := TButton.Create(Self);
  BModoEdicionPanel.Parent := PanelProps;
  BModoEdicionPanel.Left := MARGEN_X;
  BModoEdicionPanel.Top := YBotones;
  BModoEdicionPanel.Width := WBtnCol;
  BModoEdicionPanel.Height := H_BTN;
  BModoEdicionPanel.Caption := 'Modo edición';
  BModoEdicionPanel.OnClick := @OnModoEdicionPanelClick;

  BModoInsercionPanel := TButton.Create(Self);
  BModoInsercionPanel.Parent := PanelProps;
  BModoInsercionPanel.Left := XCol2;
  BModoInsercionPanel.Top := YBotones;
  BModoInsercionPanel.Width := WBtnCol;
  BModoInsercionPanel.Height := H_BTN;
  BModoInsercionPanel.Caption := 'Modo inserción';
  BModoInsercionPanel.OnClick := @OnModoInsercionPanelClick;

  BBorrarPanel := TButton.Create(Self);
  BBorrarPanel.Parent := PanelProps;
  BBorrarPanel.Left := MARGEN_X;
  BBorrarPanel.Top := YBotones + H_BTN + SEP_Y;
  BBorrarPanel.Width := WBtnCol;
  BBorrarPanel.Height := H_BTN;
  BBorrarPanel.Caption := 'Borrar elemento(s)';
  BBorrarPanel.OnClick := @OnBorrarPanelClick;

  BSeleccionarTodo := TButton.Create(Self);
  BSeleccionarTodo.Parent := PanelProps;
  BSeleccionarTodo.Left := XCol2;
  BSeleccionarTodo.Top := YBotones + H_BTN + SEP_Y;
  BSeleccionarTodo.Width := WBtnCol;
  BSeleccionarTodo.Height := H_BTN;
  BSeleccionarTodo.Caption := 'Selección todo';
  BSeleccionarTodo.OnClick := @OnSeleccionarTodoClick;

  BCopiarPanel := TButton.Create(Self);
  BCopiarPanel.Parent := PanelProps;
  BCopiarPanel.Left := MARGEN_X;
  BCopiarPanel.Top := YBotones + (H_BTN + SEP_Y) * 2;
  BCopiarPanel.Width := WBtnCol;
  BCopiarPanel.Height := H_BTN;
  BCopiarPanel.Caption := 'Copiar selección';
  BCopiarPanel.OnClick := @OnCopiarPanelClick;

  BPegarPanel := TButton.Create(Self);
  BPegarPanel.Parent := PanelProps;
  BPegarPanel.Left := XCol2;
  BPegarPanel.Top := YBotones + (H_BTN + SEP_Y) * 2;
  BPegarPanel.Width := WBtnCol;
  BPegarPanel.Height := H_BTN;
  BPegarPanel.Caption := 'Pegar copiados';
  BPegarPanel.OnClick := @OnPegarPanelClick;

  BSalirPanel := TButton.Create(Self);
  BSalirPanel.Parent := PanelProps;
  BSalirPanel.Left := MARGEN_X;
  BSalirPanel.Top := YBotones + (H_BTN + SEP_Y) * 3;
  BSalirPanel.Width := WBtnCol;
  BSalirPanel.Height := H_BTN;
  BSalirPanel.Caption := 'Salir edición';
  BSalirPanel.OnClick := @OnSalirPanelClick;

  PaletaHost.Height := PanelTipos.Height + PanelSubtipos.Height + 1120;
  Panel2.Visible := False;

  ReconstruirPaletaTipos;
  ReconstruirPaletaSubtipos;
  ActualizarPanelPropiedades;
end;

procedure TForm_ControlMaqueta.OnModoEdicionPanelClick(Sender: TObject);
begin
  Modo := mmEdicion;
  Panel2.Visible := True;
  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.OnModoInsercionPanelClick(Sender: TObject);
begin
  Modo := mmInsercion;
  ElementoSeleccionado := nil;
  Panel2.Visible := True;
  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.OnBorrarPanelClick(Sender: TObject);
var
  i: Integer;
  E: TElementoMaqueta;
  Msg: string;
begin
  // ===== MULTI-SELECCIÓN =====
  if MultiSelect and Assigned(SelectedElements) and (SelectedElements.Count > 0) then
  begin
    Msg := Format('¿Desea borrar los %d elementos seleccionados?', [SelectedElements.Count]);

    if MessageDlg('Borrar elementos', Msg, mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;

    // Borrar todos
    for i := SelectedElements.Count - 1 downto 0 do
    begin
      E := SelectedElements[i];
      BorrarElemento(E);
    end;

    SelectedElements.Clear;
    ElementoSeleccionado := nil;
    MultiSelect := False;
    DragActivo := False;

    ActualizarPanelPropiedades;
    PaintBox1.Invalidate;
    Exit;
  end;

  // ===== SELECCIÓN SIMPLE =====
  if not Assigned(ElementoSeleccionado) then Exit;

  if MessageDlg(
       'Borrar elemento',
       '¿Desea borrar el elemento seleccionado?',
       mtConfirmation,
       [mbYes, mbNo],
       0
     ) <> mrYes then Exit;

  if BorrarElemento(ElementoSeleccionado) then
  begin
    ElementoSeleccionado := nil;

    if Assigned(SelectedElements) then
      SelectedElements.Clear;

    MultiSelect := False;
    DragActivo := False;

    ActualizarPanelPropiedades;
    PaintBox1.Invalidate;
  end;
end;

procedure TForm_ControlMaqueta.OnSalirPanelClick(Sender: TObject);
begin
  Modo := mmOperacion;
  ElementoSeleccionado := nil;
  DragActivo := False;
  Panel2.Visible := False;
  PanelBotones.Visible := True;
  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure ClearWinControls(AParent: TWinControl);
var
  i: Integer;
begin
  for i := AParent.ControlCount - 1 downto 0 do
    AParent.Controls[i].Free;
end;

function TForm_ControlMaqueta.SubTipoEnUso(const Nombre: string; ATipo: TElementoTipo): Boolean;
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  Result := False;

  for Z in ControlMaqueta1.Zonas do
    for E in Z.Elementos do
      if (E.Tipo = ATipo) and SameText(Trim(E.SubTipo), Trim(Nombre)) then
        Exit(True);
end;

procedure TForm_ControlMaqueta.OnBorrarSubtipoClick(Sender: TObject);
begin
  if Trim(SubTipoInsertar) = '' then
  begin
    MessageDlg('No hay subtipo seleccionado.', mtError, [mbOK], 0);
    Exit;
  end;

  case TipoInsertar of
    etSwitch:
      begin
        if SubTipoEnUso(SubTipoInsertar, etSwitch) then
        begin
          MessageDlg(
            'No se puede borrar el subtipo porque hay elementos del mapa que lo están usando.',
            mtError, [mbOK], 0);
          Exit;
        end;

        if MessageDlg(
             'Borrar subtipo',
             '¿Desea borrar el subtipo de switch "' + SubTipoInsertar + '"?',
             mtConfirmation,
             [mbYes, mbNo],
             0
           ) <> mrYes then Exit;

        if not ImageRepo.DeleteSwitchType(SubTipoInsertar) then
        begin
          MessageDlg('No se ha podido borrar el subtipo de switch.', mtError, [mbOK], 0);
          Exit;
        end;

        SaveSwitchCatalog;

        if ImageRepo.SwitchTypeCount > 0 then
          SubTipoInsertar := ImageRepo.GetSwitchTypeName(0)
        else
          SubTipoInsertar := '';

        ReconstruirPaletaSubtipos;
        ActualizarPanelPropiedades;
        PaintBox1.Invalidate;
      end;

    etGrafico:
      begin
        if SubTipoEnUso(SubTipoInsertar, etGrafico) then
        begin
          MessageDlg(
            'No se puede borrar el subtipo porque hay elementos del mapa que lo están usando.',
            mtError, [mbOK], 0);
          Exit;
        end;

        if MessageDlg(
             'Borrar subtipo',
             '¿Desea borrar el subtipo gráfico "' + SubTipoInsertar + '"?',
             mtConfirmation,
             [mbYes, mbNo],
             0
           ) <> mrYes then Exit;

        if not ImageRepo.DeleteGraphicType(SubTipoInsertar) then
        begin
          MessageDlg('No se ha podido borrar el subtipo gráfico.', mtError, [mbOK], 0);
          Exit;
        end;

        SaveSwitchCatalog;

        if ImageRepo.GraphicTypeCount > 0 then
          SubTipoInsertar := ImageRepo.GetGraphicTypeName(0)
        else
          SubTipoInsertar := '';

        ReconstruirPaletaSubtipos;
        ActualizarPanelPropiedades;
        PaintBox1.Invalidate;
      end;
  else
    MessageDlg('El tipo actual no usa subtipos borrables.', mtInformation, [mbOK], 0);
  end;
end;

procedure TForm_ControlMaqueta.ReconstruirPaletaTipos;
var
  B: TSpeedButton;
  T: TElementoTipo;
begin
  ClearWinControls(FlowTipos);

  for T := Low(TElementoTipo) to High(TElementoTipo) do
  begin
    B := TSpeedButton.Create(Self);
    B.Parent := FlowTipos;
    B.Caption := GetTipoCaption(T);
    B.Width := 90;
    B.Height := 28;
    B.Tag := Ord(T);
    B.AllowAllUp := False;
    B.GroupIndex := 1;
    B.Down := Ord(TipoInsertar) = Ord(T);
    B.OnClick := @OnTipoPaletaClick;
  end;
end;

procedure TForm_ControlMaqueta.ReconstruirPaletaSubtipos;
var
  i: Integer;
  B: TSpeedButton;
begin
  ClearWinControls(FlowSubtipos);

  case TipoInsertar of
    etSwitch:
      begin
        PanelSubtipos.Caption := 'Subtipos de switch';
        for i := 0 to ImageRepo.SwitchTypeCount - 1 do
        begin
          B := TSpeedButton.Create(Self);
          B.Parent := FlowSubtipos;
          B.Caption := ImageRepo.GetSwitchTypeName(i);
          B.Width := 110;
          B.Height := 28;
          B.AllowAllUp := False;
          B.GroupIndex := 2;
          B.Down := SameText(SubTipoInsertar, B.Caption);
          B.OnClick := @OnSubTipoPaletaClick;
        end;
        BNuevoSubtipo.Visible := True;
        BBorrarSubtipo.Visible := True;
      end;

    etGrafico:
      begin
        PanelSubtipos.Caption := 'Subtipos gráficos';
        for i := 0 to ImageRepo.GraphicTypeCount - 1 do
        begin
          B := TSpeedButton.Create(Self);
          B.Parent := FlowSubtipos;
          B.Caption := ImageRepo.GetGraphicTypeName(i);
          B.Width := 110;
          B.Height := 28;
          B.AllowAllUp := False;
          B.GroupIndex := 2;
          B.Down := SameText(SubTipoInsertar, B.Caption);
          B.OnClick := @OnSubTipoPaletaClick;
        end;
        BNuevoSubtipo.Visible := True;
        BBorrarSubtipo.Visible := True;
      end;
  else
    PanelSubtipos.Caption := 'Subtipos';
    BNuevoSubtipo.Visible := False;
    BBorrarSubtipo.Visible := False;
  end;
end;

procedure TForm_ControlMaqueta.SincronizarPaletaConElemento(E: TElementoMaqueta);
begin
  if not Assigned(E) then Exit;

  TipoInsertar := E.Tipo;

  case E.Tipo of
    etSwitch, etGrafico:
      SubTipoInsertar := E.SubTipo;
  else
    SubTipoInsertar := '';
  end;

  if E.Tipo in [etSensor, etRail, etSwitch] then
    AddrInsertar := E.Addr
  else
    AddrInsertar := 0;

  ReconstruirPaletaTipos;
  ReconstruirPaletaSubtipos;
end;

procedure TForm_ControlMaqueta.SeleccionarTipoPaleta(ATipo: TElementoTipo);
begin
  TipoInsertar := ATipo;

  case TipoInsertar of
    etSwitch:
      begin
        if ImageRepo.SwitchTypeCount > 0 then
        begin
          if not ImageRepo.ExistsSwitchType(SubTipoInsertar) then
            SubTipoInsertar := ImageRepo.GetSwitchTypeName(0);
        end
        else
          SubTipoInsertar := '';
      end;

    etGrafico:
      begin
        if ImageRepo.GraphicTypeCount > 0 then
        begin
          if not ImageRepo.ExistsGraphicType(SubTipoInsertar) then
            SubTipoInsertar := ImageRepo.GetGraphicTypeName(0);
        end
        else
          SubTipoInsertar := '';
      end;

    etTexto, etControlGrupo:
      begin
        AddrInsertar := 0;
        SubTipoInsertar := '';
      end;

  else
    SubTipoInsertar := '';
  end;

  ReconstruirPaletaTipos;
  ReconstruirPaletaSubtipos;
  ActualizarPanelPropiedades;
end;

procedure TForm_ControlMaqueta.SeleccionarSubTipoPaleta(const ASubTipo: string);
begin
  SubTipoInsertar := ASubTipo;
  ReconstruirPaletaSubtipos;
  ActualizarPanelPropiedades;
end;

procedure TForm_ControlMaqueta.ActualizarPreviewColorTexto;
begin
  if Assigned(PColorTexto) then
    PColorTexto.Color := PColorTexto.Color;
end;

procedure TForm_ControlMaqueta.OnColorTextoClick(Sender: TObject);
var
  D: TColorDialog;
begin
  D := TColorDialog.Create(Self);
  try
    D.Color := PColorTexto.Color;
    if D.Execute then
    begin
      PColorTexto.Color := D.Color;

      if Assigned(ElementoSeleccionado) and (Modo = mmEdicion) and
         (ElementoSeleccionado.Tipo in [etTexto, etControlGrupo]) then
      begin
        ElementoSeleccionado.ColorTexto := D.Color;
        PaintBox1.Invalidate;
      end;
    end;
  finally
    D.Free;
  end;
end;

procedure TForm_ControlMaqueta.OnTipoPaletaClick(Sender: TObject);
begin
  if Sender is TSpeedButton then
  begin
    SeleccionarTipoPaleta(TElementoTipo(TSpeedButton(Sender).Tag));
    Modo := mmInsercion;
    PaintBox1.Invalidate;
  end;
end;

procedure TForm_ControlMaqueta.OnSubTipoPaletaClick(Sender: TObject);
begin
  if Sender is TSpeedButton then
  begin
    SeleccionarSubTipoPaleta(TSpeedButton(Sender).Caption);
    Modo := mmInsercion;
    PaintBox1.Invalidate;
  end;
end;

procedure TForm_ControlMaqueta.OnNuevoSubtipoClick(Sender: TObject);
begin
  case TipoInsertar of
    etSwitch:
      begin
        if CrearNuevoSubTipoSwitch(SubTipoInsertar) then
        begin
          ReconstruirPaletaSubtipos;
          ActualizarPanelPropiedades;
          SaveSwitchCatalog;
        end;
      end;

    etGrafico:
      begin
        if CrearNuevoSubTipoGrafico(SubTipoInsertar) then
        begin
          ReconstruirPaletaSubtipos;
          ActualizarPanelPropiedades;
          SaveSwitchCatalog;
        end;
      end;
  end;
end;

procedure TForm_ControlMaqueta.ActualizarPanelPropiedades;
begin
  ActualizarTituloPanelPropiedades;

  // Tamaño del mapa
  if Assigned(EAnchoMapa) then
    EAnchoMapa.Text := IntToStr(AreaWidth);
  if Assigned(EAltoMapa) then
    EAltoMapa.Text := IntToStr(AreaHeight);

  // ===== SELECCIÓN MÚLTIPLE =====
  if MultiSelect and Assigned(SelectedElements) and (SelectedElements.Count > 1) then
  begin
    LTipo.Caption := 'Selección múltiple (' + IntToStr(SelectedElements.Count) + ')';

    ESubTipo.Text := '';
    EAddr.Text := '';
    ETexto.Text := '';
    ERot.Text := '';
    EGrupoNombre.Text := '';
    CbGrupoAccion.ItemIndex := -1;
    EFontSize.Text := '';
    PColorTexto.Color := clWhite;

    ESubTipo.Enabled := False;
    EAddr.Enabled := False;
    ETexto.Enabled := False;
    ERot.Enabled := False;

    EGrupoNombre.Enabled := False;
    CbGrupoAccion.Enabled := False;
    LGrupoNombre.Enabled := False;
    LGrupoAccion.Enabled := False;

    EFontSize.Enabled := False;
    LFontSize.Enabled := False;

    PColorTexto.Enabled := False;
    BColorTexto.Enabled := False;

    BAplicarProps.Enabled := False;
    BRotarPanel.Enabled := False;

    // Controles de tamaño de mapa: siguen disponibles
    if Assigned(LAnchoMapa) then
      LAnchoMapa.Enabled := Modo <> mmOperacion;
    if Assigned(LAltoMapa) then
      LAltoMapa.Enabled := Modo <> mmOperacion;
    if Assigned(EAnchoMapa) then
      EAnchoMapa.Enabled := Modo <> mmOperacion;
    if Assigned(EAltoMapa) then
      EAltoMapa.Enabled := Modo <> mmOperacion;
    if Assigned(BAplicarMapa) then
      BAplicarMapa.Enabled := Modo <> mmOperacion;

    if Assigned(BModoEdicionPanel) then
      BModoEdicionPanel.Enabled := Modo <> mmEdicion;

    if Assigned(BModoInsercionPanel) then
      BModoInsercionPanel.Enabled := Modo <> mmInsercion;

    // En multiselección sí debe permitir borrar
    if Assigned(BBorrarPanel) then
      BBorrarPanel.Enabled := SelectedElements.Count > 0;

    if Assigned(BSalirPanel) then
      BSalirPanel.Enabled := Modo <> mmOperacion;

    Exit;
  end;

  // ===== SELECCIÓN SIMPLE =====
  if Assigned(ElementoSeleccionado) and (Modo = mmEdicion) then
  begin
    LTipo.Caption := 'Tipo: ' + GetTipoCaption(ElementoSeleccionado.Tipo);
    ESubTipo.Text := ElementoSeleccionado.SubTipo;
    EAddr.Text := IntToStr(ElementoSeleccionado.Addr);
    ETexto.Text := ElementoSeleccionado.Texto;
    ERot.Text := IntToStr(ElementoSeleccionado.Rot);
    EGrupoNombre.Text := ElementoSeleccionado.GrupoNombre;
    CbGrupoAccion.ItemIndex := Ord(ElementoSeleccionado.GrupoAccion);

    if ElementoSeleccionado.Tipo in [etTexto, etControlGrupo] then
    begin
      PColorTexto.Color := ElementoSeleccionado.ColorTexto;
      EFontSize.Text := IntToStr(ElementoSeleccionado.FontSize);
    end
    else
    begin
      PColorTexto.Color := clWhite;
      EFontSize.Text := '14';
    end;

    ESubTipo.Enabled := ElementoSeleccionado.Tipo in [etSwitch, etGrafico];
    EAddr.Enabled := ElementoSeleccionado.Tipo in [etSensor, etRail, etSwitch, etGrafico];
    ETexto.Enabled := ElementoSeleccionado.Tipo = etTexto;
    ERot.Enabled := True;

    EGrupoNombre.Enabled := ElementoSeleccionado.Tipo = etControlGrupo;
    CbGrupoAccion.Enabled := ElementoSeleccionado.Tipo = etControlGrupo;
    LGrupoNombre.Enabled := ElementoSeleccionado.Tipo = etControlGrupo;
    LGrupoAccion.Enabled := ElementoSeleccionado.Tipo = etControlGrupo;

    EFontSize.Enabled := ElementoSeleccionado.Tipo in [etTexto, etControlGrupo];
    LFontSize.Enabled := ElementoSeleccionado.Tipo in [etTexto, etControlGrupo];

    PColorTexto.Enabled := ElementoSeleccionado.Tipo in [etTexto, etControlGrupo];
    BColorTexto.Enabled := ElementoSeleccionado.Tipo in [etTexto, etControlGrupo];

    BAplicarProps.Enabled := True;
    BRotarPanel.Enabled := True;
  end
  else
  begin
    LTipo.Caption := 'Tipo: ' + GetTipoCaption(TipoInsertar);
    ESubTipo.Text := SubTipoInsertar;
    EAddr.Text := IntToStr(AddrInsertar);

    if TipoInsertar = etTexto then
      ETexto.Text := ''
    else
      ETexto.Text := '';

    if TipoInsertar = etControlGrupo then
    begin
      if Trim(EGrupoNombre.Text) = '' then
        EGrupoNombre.Text := '';
      if CbGrupoAccion.ItemIndex < 0 then
        CbGrupoAccion.ItemIndex := 0;
    end
    else
    begin
      EGrupoNombre.Text := '';
      CbGrupoAccion.ItemIndex := 0;
    end;

    if Trim(ERot.Text) = '' then
      ERot.Text := '0';

    if TipoInsertar in [etTexto, etControlGrupo] then
    begin
      PColorTexto.Color := clWhite;

      if Trim(EFontSize.Text) = '' then
        EFontSize.Text := '14';
    end
    else
    begin
      PColorTexto.Color := clWhite;
      EFontSize.Text := '14';
    end;

    ESubTipo.Enabled := TipoInsertar in [etSwitch, etGrafico];
    EAddr.Enabled := TipoInsertar in [etSensor, etRail, etSwitch, etGrafico];
    ETexto.Enabled := TipoInsertar = etTexto;
    ERot.Enabled := True;

    EGrupoNombre.Enabled := TipoInsertar = etControlGrupo;
    CbGrupoAccion.Enabled := TipoInsertar = etControlGrupo;
    LGrupoNombre.Enabled := TipoInsertar = etControlGrupo;
    LGrupoAccion.Enabled := TipoInsertar = etControlGrupo;

    EFontSize.Enabled := TipoInsertar in [etTexto, etControlGrupo];
    LFontSize.Enabled := TipoInsertar in [etTexto, etControlGrupo];

    PColorTexto.Enabled := TipoInsertar in [etTexto, etControlGrupo];
    BColorTexto.Enabled := TipoInsertar in [etTexto, etControlGrupo];

    BAplicarProps.Enabled := True;
    BRotarPanel.Enabled := True;
  end;

  // Controles de tamaño de mapa: siempre habilitados en edición/inserción
  if Assigned(LAnchoMapa) then
    LAnchoMapa.Enabled := Modo <> mmOperacion;
  if Assigned(LAltoMapa) then
    LAltoMapa.Enabled := Modo <> mmOperacion;
  if Assigned(EAnchoMapa) then
    EAnchoMapa.Enabled := Modo <> mmOperacion;
  if Assigned(EAltoMapa) then
    EAltoMapa.Enabled := Modo <> mmOperacion;
  if Assigned(BAplicarMapa) then
    BAplicarMapa.Enabled := Modo <> mmOperacion;

  if Assigned(BModoEdicionPanel) then
    BModoEdicionPanel.Enabled := Modo <> mmEdicion;

  if Assigned(BModoInsercionPanel) then
    BModoInsercionPanel.Enabled := Modo <> mmInsercion;

  if Assigned(BBorrarPanel) then
    BBorrarPanel.Enabled := Assigned(ElementoSeleccionado) or
      (Assigned(SelectedElements) and (SelectedElements.Count > 0));

  if Assigned(BSalirPanel) then
    BSalirPanel.Enabled := Modo <> mmOperacion;
end;

function TForm_ControlMaqueta.AplicarPropsAElemento(E: TElementoMaqueta): Boolean;
var
  VAddr, VRot: Integer;
  STxt: string;
  VSize: Integer;
  OldSubTipo: string;
begin
  Result := False;
  if not Assigned(E) then Exit;

  STxt := Trim(ESubTipo.Text);
  OldSubTipo := Trim(E.SubTipo);

  if not TryStrToInt(Trim(ERot.Text), VRot) then
  begin
    MessageDlg('Rotación no válida.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if (VRot < 0) or (VRot > 7) then
  begin
    MessageDlg('La rotación debe estar entre 0 y 7.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if not TryStrToInt(Trim(EFontSize.Text), VSize) then
    VSize := 14;

  if VSize < 6 then
    VSize := 6
  else if VSize > 100 then
    VSize := 100;

  case E.Tipo of
    etTexto:
      begin
        if Trim(ETexto.Text) = '' then
        begin
          MessageDlg('El texto no puede estar vacío.', mtError, [mbOK], 0);
          Exit(False);
        end;

        E.Texto := Trim(ETexto.Text);
        E.ColorTexto := PColorTexto.Color;
        E.FontSize := VSize;
        E.Addr := 0;
        E.SubTipo := '';
        E.GrupoNombre := '';
        E.GrupoAccion := agActivar;
      end;

    etGrafico:
      begin
        if STxt = '' then
        begin
          MessageDlg('Debe indicar el subtipo gráfico.', mtError, [mbOK], 0);
          Exit(False);
        end;

        if not TryStrToInt(Trim(EAddr.Text), VAddr) then
          VAddr := 0;

        if VAddr < 0 then
          VAddr := 0;

        if not SameText(OldSubTipo, STxt) then
        begin
          if ImageRepo.ExistsGraphicType(OldSubTipo) then
          begin
            if ImageRepo.ExistsGraphicType(STxt) then
            begin
              E.SubTipo := STxt;
            end
            else
            begin
              if not ImageRepo.RenameGraphicType(OldSubTipo, STxt) then
              begin
                MessageDlg('No se ha podido renombrar el subtipo gráfico.', mtError, [mbOK], 0);
                Exit(False);
              end;

              RenombrarSubTipoEnElementos(OldSubTipo, STxt);
              SaveSwitchCatalog;
              E.SubTipo := STxt;
            end;
          end
          else
            E.SubTipo := STxt;
        end
        else
          E.SubTipo := STxt;

        E.Addr := VAddr;
        E.Texto := '';
        E.GrupoNombre := '';
        E.GrupoAccion := agActivar;

        if E.Addr > 0 then
          E.EstadoBool := False
        else
          E.EstadoBool := True;
      end;

        etSensor, etRail, etSwitch:
      begin
        if not TryStrToInt(Trim(EAddr.Text), VAddr) then
        begin
          MessageDlg('Dirección no válida.', mtError, [mbOK], 0);
          Exit(False);
        end;

        E.Addr := VAddr;
        E.Texto := '';
        E.GrupoNombre := '';
        E.GrupoAccion := agActivar;

        if E.Tipo = etSwitch then
        begin
          if STxt = '' then
          begin
            MessageDlg('Debe indicar el subtipo de switch.', mtError, [mbOK], 0);
            Exit(False);
          end;

          E.SubTipo := STxt;
        end
        else
          E.SubTipo := '';
      end;

    etControlGrupo:
      begin
        if Trim(EGrupoNombre.Text) = '' then
        begin
          MessageDlg('Debe indicar el nombre del grupo.', mtError, [mbOK], 0);
          Exit(False);
        end;

        if CbGrupoAccion.ItemIndex < 0 then
        begin
          MessageDlg('Debe indicar la acción del grupo.', mtError, [mbOK], 0);
          Exit(False);
        end;

        E.Addr := 0;
        E.Texto := '';
        E.SubTipo := '';
        E.GrupoNombre := Trim(EGrupoNombre.Text);
        E.GrupoAccion := TAccionGrupo(CbGrupoAccion.ItemIndex);
        E.ColorTexto := PColorTexto.Color;
        E.FontSize := VSize;
      end;
  end;

  E.Rot := VRot;
  Result := True;
end;

procedure TForm_ControlMaqueta.AplicarPropsAInsercion;
var
  VAddr: Integer;
begin
  SubTipoInsertar := Trim(ESubTipo.Text);

  if TipoInsertar in [etSensor, etRail, etSwitch, etGrafico] then
  begin
    if not TryStrToInt(Trim(EAddr.Text), VAddr) then
    begin
      MessageDlg('Dirección no válida.', mtError, [mbOK], 0);
      Exit;
    end;

    if VAddr < 0 then
    begin
      MessageDlg('La dirección no puede ser negativa.', mtError, [mbOK], 0);
      Exit;
    end;

    AddrInsertar := VAddr;
  end
  else
    AddrInsertar := 0;
end;

procedure TForm_ControlMaqueta.OnAplicarPropsClick(Sender: TObject);
var
  OldElemSubTipo: string;
  NewSubTipo: string;
begin
  if Assigned(ElementoSeleccionado) and (Modo = mmEdicion) then
  begin
    // Guardar el subtipo real del elemento antes de cambiarlo
    OldElemSubTipo := Trim(ElementoSeleccionado.SubTipo);

    if AplicarPropsAElemento(ElementoSeleccionado) then
    begin
      NewSubTipo := Trim(ElementoSeleccionado.SubTipo);

      // ---- SWITCH ----
      if (ElementoSeleccionado.Tipo = etSwitch) and
         (OldElemSubTipo <> '') and
         (NewSubTipo <> '') and
         (not SameText(OldElemSubTipo, NewSubTipo)) then
      begin
        // Si el nuevo ya existe, no renombramos catálogo; solo cambiamos el elemento
        if ImageRepo.ExistsSwitchType(OldElemSubTipo) and
           (not ImageRepo.ExistsSwitchType(NewSubTipo)) then
        begin
          if not ImageRepo.RenameSwitchType(OldElemSubTipo, NewSubTipo) then
          begin
            MessageDlg('No se ha podido renombrar el subtipo de switch en el catálogo.',
              mtError, [mbOK], 0);
            Exit;
          end;

          // Actualizar todos los elementos que usaban el subtipo antiguo
          RenombrarSubTipoEnElementos(OldElemSubTipo, NewSubTipo);

          // Guardar en JSON
          SaveSwitchCatalog;
        end;
      end;

      // ---- GRAFICO ----
      if (ElementoSeleccionado.Tipo = etGrafico) and
         (OldElemSubTipo <> '') and
         (NewSubTipo <> '') and
         (not SameText(OldElemSubTipo, NewSubTipo)) then
      begin
        if ImageRepo.ExistsGraphicType(OldElemSubTipo) and
           (not ImageRepo.ExistsGraphicType(NewSubTipo)) then
        begin
          if not ImageRepo.RenameGraphicType(OldElemSubTipo, NewSubTipo) then
          begin
            MessageDlg('No se ha podido renombrar el subtipo gráfico en el catálogo.',
              mtError, [mbOK], 0);
            Exit;
          end;

          RenombrarSubTipoEnElementos(OldElemSubTipo, NewSubTipo);
          SaveSwitchCatalog;
        end;
      end;

      // Resincronizar paleta
      TipoInsertar := ElementoSeleccionado.Tipo;
      SubTipoInsertar := NewSubTipo;

      ReconstruirPaletaTipos;
      ReconstruirPaletaSubtipos;
      ActualizarPanelPropiedades;

      if Assigned(FlowSubtipos) then
      begin
        FlowSubtipos.Realign;
        FlowSubtipos.Invalidate;
        FlowSubtipos.Update;
      end;

      if Assigned(PanelSubtipos) then
      begin
        PanelSubtipos.Invalidate;
        PanelSubtipos.Update;
      end;

      PaintBox1.Invalidate;
    end;
  end
  else
  begin
    AplicarPropsAInsercion;
    ActualizarPanelPropiedades;
  end;
end;

procedure TForm_ControlMaqueta.FormCreate(Sender: TObject);
begin
  AreaWidth := 2000;
  AreaHeight := 1500;

  PaintBox1.Width := AreaWidth;
  PaintBox1.Height := AreaHeight;

  FondoMapa := clBlack;

  Zoom := 1.0;
  ZoomMin := 0.5;
  ZoomMax := 2.0;

  Modo := mmOperacion;

  ImageRepo := TImageRepository.Create;
  LoadSwitchCatalog;

  if ImageRepo.SwitchTypeCount = 0 then
  begin
    ImageRepo.AddSwitchType('desvio', 'sw_desvio_off.png', 'sw_desvio_on.png');
    ImageRepo.AddSwitchType('luz',    'sw_luz_off.png',    'sw_luz_on.png');
    SaveSwitchCatalog;
  end;

  TipoInsertar := etSwitch;
  SubTipoInsertar := '';
  AddrInsertar := 1;

  FMapaActualFileName := '';
  FMapaVacioInicial := True;

  CrearPanelEdicion;
  SeleccionarTipoPaleta(etSwitch);

  SelectedElements := specialize TFPGObjectList<TElementoMaqueta>.Create(False);
  MultiSelect := False;
  FClipboardElementos := specialize TFPGObjectList<TElementoMaqueta>.Create(True);

  FSelectingRect := False;
  FSelectStartX := 0;
  FSelectStartY := 0;
  FSelectCurrentX := 0;
  FSelectCurrentY := 0;

  CargarMapaInicial;
end;

procedure TForm_ControlMaqueta.FormDestroy(Sender: TObject);
var
  FileName: string;
begin
  FileName := ExtractFilePath(Application.ExeName) + 'switch_types.json';

  if Assigned(FPopupElementoRegla) then
    FreeAndNil(FPopupElementoRegla);

  ImageRepo.SaveToFile(FileName);
  ImageRepo.Free;

  FClipboardElementos.Free;
  SelectedElements.Free;
end;

procedure TForm_ControlMaqueta.FormShow(Sender: TObject);
begin
  CargarListaMapas;
end;

function TForm_ControlMaqueta.TipoToStr(ATipo: TElementoTipo): string;
begin
  case ATipo of
    etSensor:       Result := 'sensor';
    etRail:         Result := 'via';
    etSwitch:       Result := 'switch';
    etTexto:        Result := 'texto';
    etGrafico:      Result := 'grafico';
    etControlGrupo: Result := 'controlgrupo';
  else
    Result := 'desconocido';
  end;
end;

function TForm_ControlMaqueta.StrToTipo(const S: string; out ATipo: TElementoTipo): Boolean;
var
  L: string;
begin
  L := Trim(LowerCase(S));
  Result := True;

  if L = 'sensor' then
    ATipo := etSensor
  else if L = 'via' then
    ATipo := etRail
  else if L = 'switch' then
    ATipo := etSwitch
  else if L = 'texto' then
    ATipo := etTexto
  else if L = 'grafico' then
    ATipo := etGrafico
  else if (L = 'controlgrupo') or (L = 'grupo') then
    ATipo := etControlGrupo
  else
    Result := False;
end;

procedure TForm_ControlMaqueta.LimpiarMapa;
begin
  ElementoSeleccionado := nil;
  DragActivo := False;
  FSelectingRect := False;

  if Assigned(SelectedElements) then
    SelectedElements.Clear;

  MultiSelect := False;

  ControlMaqueta1.Zonas.Clear;
end;

procedure TForm_ControlMaqueta.MarcarMapaActual(const AFileName: string;
  AEsMapaVacioInicial: Boolean);
begin
  FMapaActualFileName := Trim(AFileName);
  FMapaVacioInicial := AEsMapaVacioInicial;
end;

procedure TForm_ControlMaqueta.GuardarMapaActualAutomaticamente;
begin
  // El mapa vacío inicial no se guarda automáticamente
  if FMapaVacioInicial then
    Exit;

  // Si el mapa actual no tiene fichero asociado, no hay dónde autoguardar
  if Trim(FMapaActualFileName) = '' then
    Exit;

  GuardarMapaEnArchivo(FMapaActualFileName);
end;

procedure TForm_ControlMaqueta.GuardarMapaEnArchivo(const FileName: string);
var
  Root: TJSONObject;
  ArrZonas: TJSONArray;
  ArrElems: TJSONArray;
  ZonaObj: TJSONObject;
  ElemObj: TJSONObject;
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
  SL: TStringList;
begin
  Root := TJSONObject.Create;
  ArrZonas := TJSONArray.Create;

  try
    Root.Add('area_width', AreaWidth);
    Root.Add('area_height', AreaHeight);
    Root.Add('background_color', Integer(FondoMapa));

    for Z in ControlMaqueta1.Zonas do
    begin
      ZonaObj := TJSONObject.Create;
      ZonaObj.Add('nombre', Z.Nombre);

      ArrElems := TJSONArray.Create;

      for E in Z.Elementos do
      begin
        ElemObj := TJSONObject.Create;
        ElemObj.Add('tipo', TipoToStr(E.Tipo));
        ElemObj.Add('subtipo', E.SubTipo);
        ElemObj.Add('addr', E.Addr);
        ElemObj.Add('x', E.X);
        ElemObj.Add('y', E.Y);
        ElemObj.Add('texto', E.Texto);
        ElemObj.Add('color_texto', Integer(E.ColorTexto));
        ElemObj.Add('grupo_nombre', E.GrupoNombre);
        ElemObj.Add('grupo_accion', AccionGrupoToStr(E.GrupoAccion));
        ElemObj.Add('rot', E.Rot);
        ElemObj.Add('font_size', E.FontSize);

        ElemObj.Add('estado_bool', E.EstadoBool);
        ElemObj.Add('estado_int', E.EstadoInt);

        ArrElems.Add(ElemObj);
      end;

      ZonaObj.Add('elementos', ArrElems);
      ArrZonas.Add(ZonaObj);
    end;

    Root.Add('zonas', ArrZonas);

    SL := TStringList.Create;
    try
      SL.Text := Root.FormatJSON;
      SL.SaveToFile(FileName);
    finally
      SL.Free;
    end;

  finally
    Root.Free;
  end;
end;

procedure TForm_ControlMaqueta.OnSeleccionarTodoClick(Sender: TObject);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  if not Assigned(SelectedElements) then Exit;

  SelectedElements.Clear;

  for Z in ControlMaqueta1.Zonas do
    for E in Z.Elementos do
      SelectedElements.Add(E);

  if SelectedElements.Count > 0 then
    ElementoSeleccionado := SelectedElements[0]
  else
    ElementoSeleccionado := nil;

  MultiSelect := SelectedElements.Count > 1;

  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.SaveSwitchCatalog;
var
  FileName: string;
begin
  FileName := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'switch_types.json';
  ImageRepo.SaveToFile(FileName);
end;

procedure TForm_ControlMaqueta.LoadSwitchCatalog;
var
  FileName: string;
begin
  FileName := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'switch_types.json';
  ImageRepo.LoadFromFile(FileName);
end;

procedure TForm_ControlMaqueta.AplicarEstadosSwitchDelMapa;
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  for Z in ControlMaqueta1.Zonas do
    for E in Z.Elementos do
      if E.Tipo = etSwitch then
        ControlMaqueta1.SetSwitch(E.Addr, E.EstadoBool);
end;

procedure TForm_ControlMaqueta.CargarMapaDeArchivo(const FileName: string);
var
  SL: TStringList;
  Root: TJSONObject;
  ArrZonas: TJSONArray;
  ArrElems: TJSONArray;
  ZonaObj: TJSONObject;
  ElemObj: TJSONObject;
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
  i, j: Integer;
  TipoStr: string;
  ETipo: TElementoTipo;
begin
  if not FileExists(FileName) then Exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(FileName);
    Root := TJSONObject(GetJSON(SL.Text));
  finally
    SL.Free;
  end;

  try
    LimpiarMapa;

    if Root.IndexOfName('area_width') <> -1 then
      AreaWidth := Root.Get('area_width', AreaWidth);

    if Root.IndexOfName('area_height') <> -1 then
      AreaHeight := Root.Get('area_height', AreaHeight);

    if Root.IndexOfName('background_color') <> -1 then
      FondoMapa := TColor(Root.Get('background_color', Integer(clBlack)))
    else
      FondoMapa := clBlack;

    PaintBox1.Width := Round(AreaWidth * Zoom);
    PaintBox1.Height := Round(AreaHeight * Zoom);

    if (Root.IndexOfName('zonas') = -1) or not (Root.Find('zonas') is TJSONArray) then
      Exit;

    ArrZonas := Root.Arrays['zonas'];

    for i := 0 to ArrZonas.Count - 1 do
    begin
      if not (ArrZonas.Items[i] is TJSONObject) then Continue;

      ZonaObj := ArrZonas.Objects[i];
      Z := ControlMaqueta1.AddZona(ZonaObj.Get('nombre', 'Zona'));

      if (ZonaObj.IndexOfName('elementos') = -1) or
         not (ZonaObj.Find('elementos') is TJSONArray) then
        Continue;

      ArrElems := ZonaObj.Arrays['elementos'];

      for j := 0 to ArrElems.Count - 1 do
      begin
        if not (ArrElems.Items[j] is TJSONObject) then Continue;

        ElemObj := ArrElems.Objects[j];
        TipoStr := ElemObj.Get('tipo', '');

        if not StrToTipo(TipoStr, ETipo) then
          Continue;

        E := TElementoMaqueta.Create;
        E.Tipo := ETipo;
        E.SubTipo := ElemObj.Get('subtipo', '');
        E.Addr := ElemObj.Get('addr', 0);
        E.Texto := ElemObj.Get('texto', '');
        E.GrupoNombre := ElemObj.Get('grupo_nombre', '');

        if not StrToAccionGrupo(ElemObj.Get('grupo_accion', 'Activar'), E.GrupoAccion) then
          E.GrupoAccion := agActivar;

        if ElemObj.IndexOfName('color_texto') <> -1 then
          E.ColorTexto := TColor(ElemObj.Get('color_texto', Integer(clWhite)))
        else
          E.ColorTexto := clWhite;

        E.X := ElemObj.Get('x', 0);
        E.Y := ElemObj.Get('y', 0);
        E.Rot := ElemObj.Get('rot', 0) mod 8;

        if ElemObj.IndexOfName('font_size') <> -1 then
          E.FontSize := ElemObj.Get('font_size', 14)
        else
          E.FontSize := 14;

        if ElemObj.IndexOfName('estado_bool') <> -1 then
          E.EstadoBool := ElemObj.Get('estado_bool', False)
        else
          E.EstadoBool := False;

        if ElemObj.IndexOfName('estado_int') <> -1 then
          E.EstadoInt := ElemObj.Get('estado_int', 0)
        else
          E.EstadoInt := 0;

        Z.AddElemento(E);
      end;
    end;

    // Reaplicar físicamente los estados de los switches
    // pasará por la cola temporizada de ControlMaqueta
    AplicarEstadosSwitchDelMapa;

  finally
    Root.Free;
  end;

  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.RenombrarSubTipoEnElementos(const OldName, NewName: string);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  for Z in ControlMaqueta1.Zonas do
    for E in Z.Elementos do
      if SameText(E.SubTipo, OldName) then
        E.SubTipo := NewName;
end;

function TForm_ControlMaqueta.RenombrarSubTipoSwitch(var ASubTipo: string): Boolean;
var
  NombreNuevo: string;
  NombreAntiguo: string;
begin
  Result := False;

  NombreAntiguo := Trim(ASubTipo);
  if NombreAntiguo = '' then Exit(False);

  NombreNuevo := NombreAntiguo;
  if not InputQuery(
    'Renombrar tipo de switch',
    'Nuevo nombre para el tipo "' + NombreAntiguo + '":',
    NombreNuevo
  ) then
    Exit(False);

  NombreNuevo := Trim(NombreNuevo);

  if NombreNuevo = '' then
  begin
    MessageDlg('Debe indicar un nombre.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if SameText(NombreAntiguo, NombreNuevo) then
  begin
    Result := True;
    Exit;
  end;

  if ImageRepo.ExistsSwitchType(NombreNuevo) then
  begin
    MessageDlg('Ya existe un tipo con ese nombre.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if not ImageRepo.RenameSwitchType(NombreAntiguo, NombreNuevo) then
  begin
    MessageDlg('No se ha podido renombrar el tipo.', mtError, [mbOK], 0);
    Exit(False);
  end;

  RenombrarSubTipoEnElementos(NombreAntiguo, NombreNuevo);
  ASubTipo := NombreNuevo;

  Result := True;
end;

function TForm_ControlMaqueta.GetImage(E: TElementoMaqueta): TBitmap;
begin
  case E.Tipo of
    etSensor:       Result := ImageRepo.Sensor[E.GetStateIndex];
    etSwitch:       Result := ImageRepo.GetSwitchImage(E.SubTipo, E.GetStateIndex);
    etRail:         Result := ImageRepo.Rail[E.GetStateIndex];
    etTexto:        Result := nil;
    etGrafico:      Result := ImageRepo.GetGraphicImage(E.SubTipo);
    etControlGrupo: Result := nil;
  else
    Result := nil;
  end;
end;

function TForm_ControlMaqueta.CrearNuevoSubTipoGrafico(var ASubTipo: string): Boolean;
var
  Nombre: string;
  FileImg: string;
begin
  Result := False;

  Nombre := '';
  if not InputQuery('Nuevo tipo gráfico', 'Nombre del nuevo tipo:', Nombre) then Exit(False);

  Nombre := Trim(Nombre);
  if Nombre = '' then
  begin
    MessageDlg('Debe indicar un nombre.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if ImageRepo.ExistsGraphicType(Nombre) then
  begin
    MessageDlg('Ese tipo ya existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  FileImg := '';
  if not SeleccionarArchivoImagen('Seleccionar imagen para "' + Nombre + '"', FileImg) then
    Exit(False);

  if (FileImg = '') or (not FileExists(FileImg)) then
  begin
    MessageDlg('El archivo no existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  ImageRepo.AddGraphicType(Nombre, FileImg);
  SaveSwitchCatalog;
  ASubTipo := Nombre;
  Result := True;
end;

function TForm_ControlMaqueta.ElegirSubTipoGrafico(var ASubTipo: string): Boolean;
var
  Lista: TStringList;
  Sel: string;
  i: Integer;
begin
  Result := False;

  Lista := TStringList.Create;
  try
    Lista.Add('Nuevo...');

    for i := 0 to ImageRepo.GraphicTypeCount - 1 do
      Lista.Add(ImageRepo.GetGraphicTypeName(i));

    Sel := ASubTipo;
    if Sel = '' then
      Sel := Lista[0];

    if not InputQuery(
      'Tipo gráfico',
      'Valores disponibles:' + LineEnding + Lista.Text + LineEnding + 'Escriba el tipo:',
      Sel
    ) then
      Exit(False);

    Sel := Trim(Sel);

    if SameText(Sel, 'Nuevo...') or SameText(Sel, 'Nuevo') then
      Exit(CrearNuevoSubTipoGrafico(ASubTipo));

    if ImageRepo.ExistsGraphicType(Sel) then
    begin
      ASubTipo := Sel;
      Exit(True);
    end;

    MessageDlg('Debe elegir un tipo existente o "Nuevo...".', mtError, [mbOK], 0);
    Exit(False);
  finally
    Lista.Free;
  end;
end;

function TForm_ControlMaqueta.ElegirTipoElemento(var ATipo: TElementoTipo): Boolean;
var
  S: string;
begin
  case ATipo of
    etSensor:       S := 'sensor';
    etRail:         S := 'via';
    etSwitch:       S := 'switch';
    etTexto:        S := 'texto';
    etGrafico:      S := 'grafico';
    etControlGrupo: S := 'controlgrupo';
  else
    S := 'switch';
  end;

  Result := InputQuery(
    'Tipo de elemento',
    'Introduce tipo: sensor, via, switch, texto, grafico o controlgrupo',
    S
  );

  if not Result then Exit(False);

  S := Trim(LowerCase(S));

  if S = 'sensor' then
    ATipo := etSensor
  else if (S = 'via') or (S = 'rail') then
    ATipo := etRail
  else if (S = 'switch') or (S = 'sw') then
    ATipo := etSwitch
  else if (S = 'texto') or (S = 'txt') then
    ATipo := etTexto
  else if (S = 'grafico') or (S = 'img') then
    ATipo := etGrafico
  else if (S = 'controlgrupo') or (S = 'grupo') then
    ATipo := etControlGrupo
  else
  begin
    MessageDlg('Tipo no válido.', mtError, [mbOK], 0);
    Exit(False);
  end;
end;

function TForm_ControlMaqueta.ElegirSubTipoSwitch(var ASubTipo: string): Boolean;
var
  Lista: TStringList;
  Sel: string;
  i: Integer;
begin
  Result := False;

  Lista := TStringList.Create;
  try
    Lista.Add('Nuevo...');

    for i := 0 to ImageRepo.SwitchTypeCount - 1 do
      Lista.Add(ImageRepo.GetSwitchTypeName(i));

    Sel := ASubTipo;
    if Sel = '' then
      Sel := Lista[0];

    if not InputQuery(
      'Subtipo de switch',
      'Escriba uno de estos valores:' + LineEnding + Lista.Text,
      Sel
    ) then
      Exit(False);

    Sel := Trim(Sel);

    if SameText(Sel, 'Nuevo...') or SameText(Sel, 'Nuevo') then
    begin
      if CrearNuevoSubTipoSwitch(ASubTipo) then
        Exit(True)
      else
        Exit(False);
    end;

    if ImageRepo.ExistsSwitchType(Sel) then
    begin
      ASubTipo := Sel;
      Exit(True);
    end;

    MessageDlg('Debe elegir un tipo existente o "Nuevo...".', mtError, [mbOK], 0);
    Exit(False);

  finally
    Lista.Free;
  end;
end;

function TForm_ControlMaqueta.SeleccionarArchivoImagen(
  const Titulo: string; var FileName: string): Boolean;
var
  D: TOpenDialog;
begin
  Result := False;

  D := TOpenDialog.Create(Self);
  try
    D.Title := Titulo;
    D.Filter := 'Imágenes (*.png;*.bmp;*.jpg;*.jpeg)|*.png;*.bmp;*.jpg;*.jpeg|Todos los archivos (*.*)|*.*';
    D.Options := [ofFileMustExist, ofPathMustExist];

    if FileName <> '' then
      D.FileName := FileName;

    if D.Execute then
    begin
      FileName := D.FileName;
      Result := True;
    end;
  finally
    D.Free;
  end;
end;

function TForm_ControlMaqueta.CrearNuevoSubTipoSwitch(var ASubTipo: string): Boolean;
var
  Nombre: string;
  FileOff: string;
  FileOn: string;
begin
  Result := False;

  Nombre := '';
  if not InputQuery('Nuevo tipo de switch', 'Nombre del nuevo tipo:', Nombre) then
    Exit(False);

  Nombre := Trim(Nombre);
  if Nombre = '' then
  begin
    MessageDlg('Debe indicar un nombre.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if ImageRepo.ExistsSwitchType(Nombre) then
  begin
    MessageDlg('Ese tipo ya existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  FileOff := '';
  if not SeleccionarArchivoImagen('Seleccionar imagen OFF para "' + Nombre + '"', FileOff) then
    Exit(False);

  if (FileOff = '') or (not FileExists(FileOff)) then
  begin
    MessageDlg('El archivo OFF no existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  FileOn := '';
  if not SeleccionarArchivoImagen('Seleccionar imagen ON para "' + Nombre + '"', FileOn) then
    Exit(False);

  if (FileOn = '') or (not FileExists(FileOn)) then
  begin
    MessageDlg('El archivo ON no existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  ImageRepo.AddSwitchType(Nombre, FileOff, FileOn);
  SaveSwitchCatalog;
  ASubTipo := Nombre;
  Result := True;
end;

function TForm_ControlMaqueta.BorrarElemento(E: TElementoMaqueta): Boolean;
var
  Z: TZonaMaqueta;
  i: Integer;
begin
  Result := False;
  if not Assigned(E) then Exit;

  for Z in ControlMaqueta1.Zonas do
    for i := 0 to Z.Elementos.Count - 1 do
      if Z.Elementos[i] = E then
      begin
        Z.Elementos.Delete(i);
        Result := True;
        Exit;
      end;
end;

function TForm_ControlMaqueta.ClonarElemento(E: TElementoMaqueta): TElementoMaqueta;
begin
  Result := nil;
  if not Assigned(E) then Exit;

  Result := TElementoMaqueta.Create;
  Result.Tipo := E.Tipo;
  Result.SubTipo := E.SubTipo;
  Result.Addr := E.Addr;
  Result.X := E.X;
  Result.Y := E.Y;
  Result.Texto := E.Texto;
  Result.ColorTexto := E.ColorTexto;
  Result.GrupoNombre := E.GrupoNombre;
  Result.GrupoAccion := E.GrupoAccion;
  Result.Rot := E.Rot;
  Result.FontSize := E.FontSize;
  Result.EstadoBool := E.EstadoBool;
  Result.EstadoInt := E.EstadoInt;
end;

procedure TForm_ControlMaqueta.CopiarSeleccionActual;
var
  i: Integer;
  E: TElementoMaqueta;
begin
  if not Assigned(FClipboardElementos) then Exit;

  FClipboardElementos.Clear;

  if MultiSelect and Assigned(SelectedElements) and (SelectedElements.Count > 0) then
  begin
    for i := 0 to SelectedElements.Count - 1 do
    begin
      E := SelectedElements[i];
      FClipboardElementos.Add(ClonarElemento(E));
    end;
    Exit;
  end;

  if Assigned(ElementoSeleccionado) then
    FClipboardElementos.Add(ClonarElemento(ElementoSeleccionado));
end;

procedure TForm_ControlMaqueta.PegarElementosCopiados;
var
  Z: TZonaMaqueta;
  i: Integer;
  EOrig, ENuevo: TElementoMaqueta;
  MinX, MinY: Integer;
  OffsetX, OffsetY: Integer;
begin
  if not Assigned(FClipboardElementos) then Exit;
  if FClipboardElementos.Count = 0 then Exit;

  if ControlMaqueta1.Zonas.Count = 0 then
    Z := ControlMaqueta1.AddZona('Zona 1')
  else
    Z := ControlMaqueta1.Zonas[0];

  if Assigned(SelectedElements) then
    SelectedElements.Clear;

  MinX := MaxInt;
  MinY := MaxInt;

  for i := 0 to FClipboardElementos.Count - 1 do
  begin
    EOrig := FClipboardElementos[i];
    if EOrig.X < MinX then MinX := EOrig.X;
    if EOrig.Y < MinY then MinY := EOrig.Y;
  end;

  OffsetX := 20;
  OffsetY := 20;

  for i := 0 to FClipboardElementos.Count - 1 do
  begin
    EOrig := FClipboardElementos[i];
    ENuevo := ClonarElemento(EOrig);

    ENuevo.X := Snap((EOrig.X - MinX) + OffsetX);
    ENuevo.Y := Snap((EOrig.Y - MinY) + OffsetY);

    if ENuevo.X < 0 then ENuevo.X := 0;
    if ENuevo.Y < 0 then ENuevo.Y := 0;
    if ENuevo.X > AreaWidth then ENuevo.X := AreaWidth;
    if ENuevo.Y > AreaHeight then ENuevo.Y := AreaHeight;

    Z.AddElemento(ENuevo);

    if Assigned(SelectedElements) then
      SelectedElements.Add(ENuevo);
  end;

  if Assigned(SelectedElements) and (SelectedElements.Count > 0) then
    ElementoSeleccionado := SelectedElements[SelectedElements.Count - 1]
  else
    ElementoSeleccionado := nil;

  MultiSelect := Assigned(SelectedElements) and (SelectedElements.Count > 1);

  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.OnCopiarPanelClick(Sender: TObject);
begin
  CopiarSeleccionActual;

  if Assigned(FClipboardElementos) and (FClipboardElementos.Count > 0) then
    MessageDlg(Format('Se han copiado %d elemento(s).', [FClipboardElementos.Count]),
      mtInformation, [mbOK], 0)
  else
    MessageDlg('No hay elementos seleccionados para copiar.',
      mtInformation, [mbOK], 0);

  ActualizarPanelPropiedades;
end;

procedure TForm_ControlMaqueta.OnPegarPanelClick(Sender: TObject);
begin
  if not Assigned(FClipboardElementos) or (FClipboardElementos.Count = 0) then
  begin
    MessageDlg('No hay elementos copiados.', mtInformation, [mbOK], 0);
    Exit;
  end;

  PegarElementosCopiados;
end;

function TForm_ControlMaqueta.PedirDatosInsercion: Boolean;
var
  S: string;
begin
  Result := False;

  if not ElegirTipoElemento(TipoInsertar) then Exit(False);

  if TipoInsertar = etTexto then
  begin
    S := '';
    if not InputQuery('Texto', 'Introduce el texto:', S) then Exit(False);
    S := Trim(S);
    if S = '' then
    begin
      MessageDlg('El texto no puede estar vacío.', mtError, [mbOK], 0);
      Exit(False);
    end;
    SubTipoInsertar := S;
    AddrInsertar := 0;
    Result := True;
    Exit;
  end;

  if TipoInsertar = etGrafico then
  begin
    AddrInsertar := 0;
    if not ElegirSubTipoGrafico(SubTipoInsertar) then Exit(False);
    Result := True;
    Exit;
  end;

  if TipoInsertar = etControlGrupo then
  begin
    AddrInsertar := 0;
    Result := True;
    Exit;
  end;

  S := IntToStr(AddrInsertar);
  if not InputQuery('Dirección', 'Introduce la dirección:', S) then Exit(False);

  if not TryStrToInt(Trim(S), AddrInsertar) then
  begin
    MessageDlg('Dirección no válida.', mtError, [mbOK], 0);
    Exit(False);
  end;

  SubTipoInsertar := '';

  if TipoInsertar = etSwitch then
    if not ElegirSubTipoSwitch(SubTipoInsertar) then Exit(False);

  Result := True;
end;

function TForm_ControlMaqueta.EditarArchivosSubTipoSwitch(const ASubTipo: string): Boolean;
var
  S: TSwitchVisual;
  Resp: Integer;
  FileOff: string;
  FileOn: string;
begin
  Result := False;

  S := ImageRepo.FindSwitchType(ASubTipo);
  if not Assigned(S) then
  begin
    MessageDlg('No se encuentra el tipo de switch "' + ASubTipo + '".',
      mtError, [mbOK], 0);
    Exit(False);
  end;

  Resp := MessageDlg(
    'Editar imágenes',
    '¿Desea cambiar los archivos OFF/ON del tipo "' + ASubTipo + '"?' + LineEnding +
    'Esto afectará a todos los elementos de ese tipo.',
    mtConfirmation,
    [mbYes, mbNo],
    0
  );

  if Resp <> mrYes then
    Exit(True);

  FileOff := S.FileOff;
  if not SeleccionarArchivoImagen('Seleccionar imagen OFF para "' + ASubTipo + '"', FileOff) then
    Exit(False);

  if (FileOff = '') or (not FileExists(FileOff)) then
  begin
    MessageDlg('El archivo OFF no existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  FileOn := S.FileOn;
  if not SeleccionarArchivoImagen('Seleccionar imagen ON para "' + ASubTipo + '"', FileOn) then
    Exit(False);

  if (FileOn = '') or (not FileExists(FileOn)) then
  begin
    MessageDlg('El archivo ON no existe.', mtError, [mbOK], 0);
    Exit(False);
  end;

  S.FileOff := FileOff;
  S.FileOn := FileOn;
  S.LoadImages;
  SaveSwitchCatalog;

  Result := True;
end;

function TForm_ControlMaqueta.EditarElemento(E: TElementoMaqueta): Boolean;
var
  NuevoTipo: TElementoTipo;
  S: string;
  NuevaAddr: Integer;
  NuevoSubTipo: string;
  NuevoTexto: string;
  NuevaRot: Integer;
  Resp: Integer;
  NuevaAccion: TAccionGrupo;
begin
  Result := False;
  if not Assigned(E) then Exit(False);

  NuevoTipo := E.Tipo;
  NuevaAddr := E.Addr;
  NuevoSubTipo := E.SubTipo;
  NuevoTexto := E.Texto;
  NuevaRot := E.Rot;
  NuevaAccion := E.GrupoAccion;

  if not ElegirTipoElemento(NuevoTipo) then Exit(False);

  S := IntToStr(NuevaRot);
  if not InputQuery('Rotación', 'Rotación (0..7, pasos de 45º):', S) then Exit(False);

  if not TryStrToInt(Trim(S), NuevaRot) then
  begin
    MessageDlg('Rotación no válida.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if (NuevaRot < 0) or (NuevaRot > 7) then
  begin
    MessageDlg('La rotación debe estar entre 0 y 7.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if NuevoTipo = etTexto then
  begin
    if not InputQuery('Editar texto', 'Texto:', NuevoTexto) then Exit(False);
    NuevoTexto := Trim(NuevoTexto);
    if NuevoTexto = '' then
    begin
      MessageDlg('El texto no puede estar vacío.', mtError, [mbOK], 0);
      Exit(False);
    end;

    E.Tipo := etTexto;
    E.Texto := NuevoTexto;
    E.SubTipo := '';
    E.Addr := 0;
    E.GrupoNombre := '';
    E.GrupoAccion := agActivar;
    E.Rot := NuevaRot;
    Result := True;
    Exit;
  end;

  if NuevoTipo = etGrafico then
  begin
    if not ElegirSubTipoGrafico(NuevoSubTipo) then Exit(False);

    S := IntToStr(E.Addr);
    if not InputQuery('Dirección switch', 'Dirección de switch asociada (0 = siempre visible):', S) then
      Exit(False);

    if not TryStrToInt(Trim(S), NuevaAddr) then
    begin
      MessageDlg('Dirección no válida.', mtError, [mbOK], 0);
      Exit(False);
    end;

    if NuevaAddr < 0 then
    begin
      MessageDlg('La dirección no puede ser negativa.', mtError, [mbOK], 0);
      Exit(False);
    end;

    E.Tipo := etGrafico;
    E.SubTipo := NuevoSubTipo;
    E.Texto := '';
    E.Addr := NuevaAddr;
    E.GrupoNombre := '';
    E.GrupoAccion := agActivar;
    E.Rot := NuevaRot;

    if E.Addr > 0 then
      E.EstadoBool := False
    else
      E.EstadoBool := True;

    Result := True;
    Exit;
  end;

  if NuevoTipo = etControlGrupo then
  begin
    NuevoTexto := E.GrupoNombre;
    if not InputQuery('Nombre del grupo', 'Grupo:', NuevoTexto) then Exit(False);
    NuevoTexto := Trim(NuevoTexto);

    if NuevoTexto = '' then
    begin
      MessageDlg('Debe indicar el nombre del grupo.', mtError, [mbOK], 0);
      Exit(False);
    end;

    S := AccionGrupoToStr(NuevaAccion);
    if not InputQuery('Acción del grupo', 'Acción: Activar o Desactivar', S) then Exit(False);

    if not StrToAccionGrupo(S, NuevaAccion) then
    begin
      MessageDlg('Acción no válida.', mtError, [mbOK], 0);
      Exit(False);
    end;

    E.Tipo := etControlGrupo;
    E.Addr := 0;
    E.SubTipo := '';
    E.Texto := '';
    E.GrupoNombre := NuevoTexto;
    E.GrupoAccion := NuevaAccion;
    E.Rot := NuevaRot;
    Result := True;
    Exit;
  end;

  S := IntToStr(NuevaAddr);
  if not InputQuery('Editar dirección', 'Dirección del elemento:', S) then Exit(False);

  if not TryStrToInt(Trim(S), NuevaAddr) then
  begin
    MessageDlg('Dirección no válida.', mtError, [mbOK], 0);
    Exit(False);
  end;

  if NuevoTipo = etSwitch then
  begin
    if NuevoSubTipo = '' then
      NuevoSubTipo := 'desvio';

    if not ElegirSubTipoSwitch(NuevoSubTipo) then Exit(False);

    Resp := MessageDlg(
      'Renombrar tipo',
      '¿Desea renombrar el tipo "' + NuevoSubTipo + '"?',
      mtConfirmation,
      [mbYes, mbNo],
      0
    );

    if Resp = mrYes then
      if not RenombrarSubTipoSwitch(NuevoSubTipo) then Exit(False);

    if not EditarArchivosSubTipoSwitch(NuevoSubTipo) then Exit(False);
  end
  else
    NuevoSubTipo := '';

  E.Tipo := NuevoTipo;
  E.Addr := NuevaAddr;
  E.SubTipo := NuevoSubTipo;
  E.Texto := '';
  E.GrupoNombre := '';
  E.GrupoAccion := agActivar;
  E.Rot := NuevaRot;

  SaveSwitchCatalog;
  Result := True;
end;

procedure TForm_ControlMaqueta.GetMouseRealPos(out RX, RY: Integer);
var
  P: TPoint;
begin
  P := PaintBox1.ScreenToClient(Mouse.CursorPos);

  RX := ScreenToWorldX(P.X);
  RY := ScreenToWorldY(P.Y);
end;

procedure TForm_ControlMaqueta.DoZoom(WheelDelta: Integer; MousePos: TPoint);
var
  OldZoom: Double;
  P: TPoint;
  WorldX, WorldY: Integer;
begin
  OldZoom := Zoom;

  if WheelDelta > 0 then
    Zoom := Zoom * 1.1
  else
    Zoom := Zoom / 1.1;

  if Zoom < ZoomMin then Zoom := ZoomMin;
  if Zoom > ZoomMax then Zoom := ZoomMax;

  PaintBox1.Width := Round(AreaWidth * Zoom);
  PaintBox1.Height := Round(AreaHeight * Zoom);

  P := PaintBox1.ScreenToClient(MousePos);

  WorldX := Round((P.X + ScrollBox1.HorzScrollBar.Position) / OldZoom);
  WorldY := Round((P.Y + ScrollBox1.VertScrollBar.Position) / OldZoom);

  ScrollBox1.HorzScrollBar.Position :=
    Round(WorldX * Zoom - P.X);

  ScrollBox1.VertScrollBar.Position :=
    Round(WorldY * Zoom - P.Y);

  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.ScrollBox1MouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
begin
  if not (ssCtrl in Shift) then Exit;

  DoZoom(WheelDelta, MousePos);

  Handled := True;
end;

procedure TForm_ControlMaqueta.InsertarElemento(X, Y: Integer);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
  RotVal: Integer;
  VSize: Integer;
begin
  if ControlMaqueta1.Zonas.Count = 0 then Exit;

  AplicarPropsAInsercion;

  if X > AreaWidth then X := AreaWidth;
  if Y > AreaHeight then Y := AreaHeight;

  Z := ControlMaqueta1.Zonas[0];

  E := TElementoMaqueta.Create;
  E.Tipo := TipoInsertar;
  E.SubTipo := SubTipoInsertar;
  E.Addr := AddrInsertar;
  E.X := Snap(X);
  E.Y := Snap(Y);
  E.Texto := '';

  if not TryStrToInt(Trim(ERot.Text), RotVal) then
    RotVal := 0;
  if RotVal < 0 then RotVal := 0;
  if RotVal > 7 then RotVal := 7;
  E.Rot := RotVal;

  if not TryStrToInt(Trim(EFontSize.Text), VSize) then
    VSize := 14;
  if VSize < 6 then
    VSize := 6
  else if VSize > 100 then
    VSize := 100;
  E.FontSize := VSize;

  if E.Tipo = etTexto then
  begin
    E.Texto := Trim(ETexto.Text);
    if E.Texto = '' then
    begin
      E.Free;
      MessageDlg('El texto no puede estar vacío.', mtError, [mbOK], 0);
      Exit;
    end;
    E.ColorTexto := PColorTexto.Color;
    E.Addr := 0;
    E.SubTipo := '';
    E.GrupoNombre := '';
    E.GrupoAccion := agActivar;
  end;

  if E.Tipo = etGrafico then
  begin
    E.Texto := '';
    E.GrupoNombre := '';
    E.GrupoAccion := agActivar;

    if E.Addr > 0 then
      E.EstadoBool := False
    else
      E.EstadoBool := True;
  end;

  if E.Tipo = etControlGrupo then
  begin
    if Trim(EGrupoNombre.Text) = '' then
    begin
      E.Free;
      MessageDlg('Debe indicar el nombre del grupo.', mtError, [mbOK], 0);
      Exit;
    end;

    if CbGrupoAccion.ItemIndex < 0 then
    begin
      E.Free;
      MessageDlg('Debe indicar la acción del grupo.', mtError, [mbOK], 0);
      Exit;
    end;

    E.Addr := 0;
    E.Texto := '';
    E.SubTipo := '';
    E.GrupoNombre := Trim(EGrupoNombre.Text);
    E.GrupoAccion := TAccionGrupo(CbGrupoAccion.ItemIndex);
    E.ColorTexto := PColorTexto.Color;
  end;

  if E.Tipo in [etSensor, etRail, etSwitch] then
  begin
    E.Texto := '';
    E.GrupoNombre := '';
    E.GrupoAccion := agActivar;
  end;

  Z.AddElemento(E);

  ElementoSeleccionado := E;
  PaintBox1.Invalidate;
end;

function TForm_ControlMaqueta.GetElementoAt(X, Y: Integer): TElementoMaqueta;
var
  Z: TZonaMaqueta;
  i: Integer;
  E: TElementoMaqueta;
  Img, DrawImg: TBitmap;
  Txt: string;
  Tw, Th: Integer;
begin
  Result := nil;

  for Z in ControlMaqueta1.Zonas do
    for i := Z.Elementos.Count - 1 downto 0 do
    begin
      E := Z.Elementos[i];

      // En modo operación, un gráfico ligado a switch y en OFF no se selecciona
      // En edición/inserción sí debe poder seleccionarse aunque esté OFF
      if (Modo = mmOperacion) and
         (E.Tipo = etGrafico) and (E.Addr > 0) and (not E.EstadoBool) then
        Continue;

      if E.Tipo in [etTexto, etControlGrupo] then
      begin
        if E.Tipo = etTexto then
          Img := CreateTextBitmap(PaintBox1.Canvas, E.Texto, 1.0, E.ColorTexto, E.FontSize)
        else
          Img := CreateTextBitmap(PaintBox1.Canvas, GetTextoControlGrupo(E), 1.0, E.ColorTexto, E.FontSize);

        DrawImg := Img;
        try
          if E.Rot <> 0 then
            DrawImg := RotateBitmap(Img, E.Rot * 45);

          Tw := DrawImg.Width;
          Th := DrawImg.Height;

          if (X >= E.X) and (X < E.X + Tw) and
             (Y >= E.Y) and (Y < E.Y + Th) then
          begin
            Result := E;
            Exit;
          end;
        finally
          if (DrawImg <> nil) and (DrawImg <> Img) then
            DrawImg.Free;
          Img.Free;
        end;

        Continue;
      end;

      Img := GetImage(E);
      if not Assigned(Img) then Continue;

      DrawImg := Img;
      try
        if E.Rot <> 0 then
          DrawImg := RotateBitmap(Img, E.Rot * 45);

        if (X >= E.X) and (X < E.X + DrawImg.Width) and
           (Y >= E.Y) and (Y < E.Y + DrawImg.Height) then
        begin
          Result := E;
          Exit;
        end;
      finally
        if (DrawImg <> nil) and (DrawImg <> Img) then
          DrawImg.Free;
      end;
    end;
end;

function TForm_ControlMaqueta.NormalizarRect(const R: TRect): TRect;
begin
  Result.Left := Min(R.Left, R.Right);
  Result.Right := Max(R.Left, R.Right);
  Result.Top := Min(R.Top, R.Bottom);
  Result.Bottom := Max(R.Top, R.Bottom);
end;

function TForm_ControlMaqueta.GetElementoBoundsWorld(E: TElementoMaqueta): TRect;
var
  Img, DrawImg: TBitmap;
  Txt: string;
  W, H: Integer;
begin
  Result := Rect(0, 0, 0, 0);
  if not Assigned(E) then Exit;

  Img := nil;
  DrawImg := nil;

  try
    if E.Tipo in [etTexto, etControlGrupo] then
    begin
      if E.Tipo = etTexto then
        Txt := E.Texto
      else
        Txt := GetTextoControlGrupo(E);

      Img := CreateTextBitmap(PaintBox1.Canvas, Txt, 1.0, E.ColorTexto, E.FontSize);
      DrawImg := Img;

      if E.Rot <> 0 then
        DrawImg := RotateBitmap(Img, E.Rot * 45);
    end
    else
    begin
      Img := GetImage(E);
      DrawImg := Img;

      if Assigned(Img) and (E.Rot <> 0) then
        DrawImg := RotateBitmap(Img, E.Rot * 45);
    end;

    if Assigned(DrawImg) then
    begin
      W := DrawImg.Width;
      H := DrawImg.Height;
      Result := Rect(E.X, E.Y, E.X + W, E.Y + H);
    end
    else
      Result := Rect(E.X, E.Y, E.X + 1, E.Y + 1);

  finally
    if (DrawImg <> nil) and (DrawImg <> Img) then
      DrawImg.Free;

    if (Img <> nil) and (E.Tipo in [etTexto, etControlGrupo]) then
      Img.Free;
  end;
end;

procedure TForm_ControlMaqueta.SeleccionarElementosEnRect(const RSel: TRect);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
  RE: TRect;
  RNorm: TRect;
begin
  if not Assigned(SelectedElements) then Exit;

  RNorm := NormalizarRect(RSel);
  SelectedElements.Clear;

  for Z in ControlMaqueta1.Zonas do
    for E in Z.Elementos do
    begin
      RE := GetElementoBoundsWorld(E);

      if IntersectRect(RE, RE, RNorm) then
        SelectedElements.Add(E);
    end;

  if SelectedElements.Count > 0 then
    ElementoSeleccionado := SelectedElements[SelectedElements.Count - 1]
  else
    ElementoSeleccionado := nil;

  MultiSelect := SelectedElements.Count > 1;

  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.PaintBox1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  ModoActual: TModoMaqueta;
  RealX, RealY: Integer;
  E: TElementoMaqueta;
  KeepMultiSelection: Boolean;
begin
  GetMouseRealPos(RealX, RealY);

  if ssShift in Shift then
    ModoActual := mmEdicion
  else
    ModoActual := Modo;

  if ModoActual = mmInsercion then
  begin
    if Button = mbLeft then
    begin
      InsertarElemento(RealX, RealY);
      ActualizarPanelPropiedades;
      PaintBox1.Invalidate;
    end;
    Exit;
  end;

  E := GetElementoAt(RealX, RealY);

    // ===== MENÚ CONTEXTUAL DE REGLAS SOBRE ELEMENTOS DEL MAPA =====
  if (Button = mbRight) and Assigned(E) and (E.Tipo in [etSensor, etRail, etSwitch]) then
  begin
    CrearMenuContextualElementoRegla(E);
    if Assigned(FPopupElementoRegla) then
      FPopupElementoRegla.PopUp;
    Exit;
  end;

  // ===== SELECCIÓN MÚLTIPLE CON CTRL =====
  if (Button = mbLeft) and (ssCtrl in Shift) then
  begin
    if ssShift in Shift then
      Modo := mmEdicion;

    if not Assigned(SelectedElements) then Exit;

    if Assigned(E) then
    begin
      if SelectedElements.IndexOf(E) >= 0 then
        SelectedElements.Remove(E)
      else
        SelectedElements.Add(E);
    end;

    if SelectedElements.Count > 0 then
      ElementoSeleccionado := SelectedElements[SelectedElements.Count - 1]
    else
      ElementoSeleccionado := nil;

    MultiSelect := SelectedElements.Count > 1;

    ActualizarPanelPropiedades;
    PaintBox1.Invalidate;
    Exit;
  end;

  // Si ya hay multiselección y haces click sobre uno de los seleccionados,
  // mantenemos la selección para poder arrastrarla completa.
  KeepMultiSelection :=
    MultiSelect and
    Assigned(SelectedElements) and
    Assigned(E) and
    (SelectedElements.IndexOf(E) >= 0);

  if not KeepMultiSelection then
  begin
    ElementoSeleccionado := E;

    if Assigned(SelectedElements) then
    begin
      SelectedElements.Clear;
      if Assigned(ElementoSeleccionado) then
        SelectedElements.Add(ElementoSeleccionado);
    end;

    MultiSelect := False;
  end
  else
  begin
    ElementoSeleccionado := E;
  end;

  if Assigned(ElementoSeleccionado) and (ModoActual = mmEdicion) then
    ActualizarPanelPropiedades
  else if not Assigned(ElementoSeleccionado) then
    ActualizarPanelPropiedades;

  PaintBox1.Invalidate;

  if (ModoActual <> mmEdicion) and not Assigned(ElementoSeleccionado) then Exit;

  case ModoActual of

    mmOperacion:
      if Button = mbLeft then
      begin
        if ElementoSeleccionado.Tipo = etSwitch then
          ControlMaqueta1.SetSwitch(
            ElementoSeleccionado.Addr,
            not ElementoSeleccionado.EstadoBool
          )
        else if ElementoSeleccionado.Tipo = etControlGrupo then
        begin
          if not Assigned(FormAutomatismos) then
            FormAutomatismos := TFormAutomatismos.Create(Application);

          FormAutomatismos.Control := ControlMaqueta1;

          case ElementoSeleccionado.GrupoAccion of
            agActivar:
              FormAutomatismos.ActivarGrupoExterno(ElementoSeleccionado.GrupoNombre);
            agDesactivar:
              FormAutomatismos.DesactivarGrupoExterno(ElementoSeleccionado.GrupoNombre);
          end;
        end;
      end;

      mmEdicion:
      begin
        if Button = mbRight then
        begin
          ActualizarPanelPropiedades;
          Exit;
        end;

        if Button = mbLeft then
        begin
          // Si se pulsa sobre vacío, iniciar selección por rectángulo
          if not Assigned(ElementoSeleccionado) then
          begin
            if Assigned(SelectedElements) then
              SelectedElements.Clear;

            MultiSelect := False;
            FSelectingRect := True;
            FSelectStartX := RealX;
            FSelectStartY := RealY;
            FSelectCurrentX := RealX;
            FSelectCurrentY := RealY;
            SetCaptureControl(PaintBox1);

            ActualizarPanelPropiedades;
            PaintBox1.Invalidate;
            Exit;
          end;

          DragActivo := True;
          SetCaptureControl(PaintBox1);

          if MultiSelect and Assigned(SelectedElements) and (SelectedElements.Count > 1) then
          begin
            OffsetDragX := RealX;
            OffsetDragY := RealY;
          end
          else
          begin
            OffsetDragX := RealX - ElementoSeleccionado.X;
            OffsetDragY := RealY - ElementoSeleccionado.Y;
          end;
        end;
      end;

  end;
end;

procedure TForm_ControlMaqueta.PaintBox1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  RealX, RealY: Integer;
  P: TPoint;
  Margin: Integer;
  Img, DrawImg: TBitmap;
  Txt: string;
  DeltaX, DeltaY: Integer;
  E: TElementoMaqueta;
begin
  GetMouseRealPos(RealX, RealY);

  if FSelectingRect then
  begin
    FSelectCurrentX := RealX;
    FSelectCurrentY := RealY;
    PaintBox1.Invalidate;
    Exit;
  end;

  if not DragActivo or not Assigned(ElementoSeleccionado) then Exit;

  Margin := 20;

  P := ScrollBox1.ScreenToClient(Mouse.CursorPos);

  if P.X > ScrollBox1.ClientWidth - Margin then
    ScrollBox1.HorzScrollBar.Position :=
      Min(
        ScrollBox1.HorzScrollBar.Range - ScrollBox1.ClientWidth,
        ScrollBox1.HorzScrollBar.Position + 10
      );

  if P.X < Margin then
    ScrollBox1.HorzScrollBar.Position :=
      Max(
        0,
        ScrollBox1.HorzScrollBar.Position - 10
      );

  if P.Y > ScrollBox1.ClientHeight - Margin then
    ScrollBox1.VertScrollBar.Position :=
      Min(
        ScrollBox1.VertScrollBar.Range - ScrollBox1.ClientHeight,
        ScrollBox1.VertScrollBar.Position + 10
      );

  if P.Y < Margin then
    ScrollBox1.VertScrollBar.Position :=
      Max(
        0,
        ScrollBox1.VertScrollBar.Position - 10
      );

  GetMouseRealPos(RealX, RealY);

  // ===== MOVER VARIOS ELEMENTOS SELECCIONADOS =====
  if MultiSelect and Assigned(SelectedElements) and (SelectedElements.Count > 0) then
  begin
    DeltaX := RealX - OffsetDragX;
    DeltaY := RealY - OffsetDragY;

    if (DeltaX = 0) and (DeltaY = 0) then Exit;

    for E in SelectedElements do
    begin
      E.X := E.X + DeltaX;
      E.Y := E.Y + DeltaY;

      if E.X < 0 then E.X := 0;
      if E.Y < 0 then E.Y := 0;
      if E.X > AreaWidth then E.X := AreaWidth;
      if E.Y > AreaHeight then E.Y := AreaHeight;
    end;

    OffsetDragX := RealX;
    OffsetDragY := RealY;

    PaintBox1.Invalidate;
    Exit;
  end;

  // ===== MOVER UN SOLO ELEMENTO =====
  ElementoSeleccionado.X := RealX - OffsetDragX;
  ElementoSeleccionado.Y := RealY - OffsetDragY;

  Img := GetImage(ElementoSeleccionado);
  DrawImg := Img;

  if not Assigned(Img) and (ElementoSeleccionado.Tipo in [etTexto, etControlGrupo]) then
  begin
    if ElementoSeleccionado.Tipo = etTexto then
      Txt := ElementoSeleccionado.Texto
    else
      Txt := GetTextoControlGrupo(ElementoSeleccionado);

    Img := CreateTextBitmap(PaintBox1.Canvas, Txt, 1.0,
      ElementoSeleccionado.ColorTexto, ElementoSeleccionado.FontSize);

    DrawImg := Img;
    if ElementoSeleccionado.Rot <> 0 then
      DrawImg := RotateBitmap(Img, ElementoSeleccionado.Rot * 45);
  end
  else if Assigned(Img) and (ElementoSeleccionado.Rot <> 0) then
    DrawImg := RotateBitmap(Img, ElementoSeleccionado.Rot * 45);

  if Assigned(DrawImg) then
  begin
    if ElementoSeleccionado.X < 0 then
      ElementoSeleccionado.X := 0;

    if ElementoSeleccionado.Y < 0 then
      ElementoSeleccionado.Y := 0;

    if ElementoSeleccionado.X > AreaWidth - DrawImg.Width then
      ElementoSeleccionado.X := AreaWidth - DrawImg.Width;

    if ElementoSeleccionado.Y > AreaHeight - DrawImg.Height then
      ElementoSeleccionado.Y := AreaHeight - DrawImg.Height;
  end;

  if (DrawImg <> nil) and (DrawImg <> Img) then
    DrawImg.Free;
  if (Img <> nil) and (ElementoSeleccionado.Tipo in [etTexto, etControlGrupo]) then
    Img.Free;

  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.PaintBox1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  E: TElementoMaqueta;
  RSel: TRect;
begin
  if FSelectingRect then
  begin
    FSelectingRect := False;
    SetCaptureControl(nil);

    RSel := Rect(FSelectStartX, FSelectStartY, FSelectCurrentX, FSelectCurrentY);
    SeleccionarElementosEnRect(RSel);
    Exit;
  end;

  if MultiSelect and Assigned(SelectedElements) then
  begin
    for E in SelectedElements do
    begin
      E.X := Snap(E.X);
      E.Y := Snap(E.Y);
    end;
  end
  else if Assigned(ElementoSeleccionado) then
  begin
    ElementoSeleccionado.X := Snap(ElementoSeleccionado.X);
    ElementoSeleccionado.Y := Snap(ElementoSeleccionado.Y);
  end;

  DragActivo := False;
  SetCaptureControl(nil);
  PaintBox1.Invalidate;
end;

function TForm_ControlMaqueta.ScreenToWorldX(X: Integer): Integer;
begin
  Result := Round(X / Zoom);
end;

function TForm_ControlMaqueta.ScreenToWorldY(Y: Integer): Integer;
begin
  Result := Round(Y / Zoom);
end;

function TForm_ControlMaqueta.WorldToScreenX(X: Integer): Integer;
begin
  Result := Round(X * Zoom);
end;

function TForm_ControlMaqueta.WorldToScreenY(Y: Integer): Integer;
begin
  Result := Round(Y * Zoom);
end;

procedure TForm_ControlMaqueta.DibujarElemento(E: TElementoMaqueta);
var
  Img, DrawImg: TBitmap;
  Txt: string;
  Tw, Th: Integer;
  sx1, sy1, sx2, sy2: Integer;
  adj: Integer;
begin
  if not Assigned(E) then Exit;

  // En modo operación, un gráfico ligado a switch solo se ve cuando está activo
  // En edición/inserción se debe dibujar siempre
  if (Modo = mmOperacion) and
     (E.Tipo = etGrafico) and (E.Addr > 0) and (not E.EstadoBool) then
    Exit;

  sx1 := WorldToScreenX(E.X);
  sy1 := WorldToScreenY(E.Y);

  if E.Tipo in [etTexto, etControlGrupo] then
  begin
    if E.Tipo = etTexto then
      Img := CreateTextBitmap(PaintBox1.Canvas, E.Texto, Zoom, E.ColorTexto, E.FontSize)
    else
      Img := CreateTextBitmap(PaintBox1.Canvas, GetTextoControlGrupo(E), Zoom, E.ColorTexto, E.FontSize);

    DrawImg := Img;
    try
      if E.Rot <> 0 then
        DrawImg := RotateBitmap(Img, E.Rot * 45);

      PaintBox1.Canvas.Draw(sx1, sy1, DrawImg);

      Tw := DrawImg.Width;
      Th := DrawImg.Height;

      if (Modo = mmEdicion) or (Modo = mmInsercion) then
      begin
        if E.Tipo = etTexto then
          Txt := 'TXT R=' + IntToStr(E.Rot)
        else
          Txt := 'GRUPO R=' + IntToStr(E.Rot);

        PaintBox1.Canvas.Font.Color := clYellow;
        PaintBox1.Canvas.Font.Style := [fsBold];
        PaintBox1.Canvas.Brush.Style := bsClear;
        PaintBox1.Canvas.Font.Height := Round(11 * Zoom);
        if PaintBox1.Canvas.Font.Height < 7 then
          PaintBox1.Canvas.Font.Height := 7;

        PaintBox1.Canvas.TextOut(
          sx1,
          sy1 - PaintBox1.Canvas.TextHeight(Txt) - 2,
          Txt
        );
      end;

      if ((Assigned(SelectedElements)) and (SelectedElements.IndexOf(E) >= 0)) or
         (Assigned(ElementoSeleccionado) and (E = ElementoSeleccionado)) then
      begin
        PaintBox1.Canvas.Pen.Color := clYellow;
        PaintBox1.Canvas.Pen.Width := 2;
        PaintBox1.Canvas.Brush.Style := bsClear;

        PaintBox1.Canvas.Rectangle(
          sx1 - 2,
          sy1 - 2,
          sx1 + Tw + 2,
          sy1 + Th + 2
        );
      end;
    finally
      if (DrawImg <> nil) and (DrawImg <> Img) then
        DrawImg.Free;
      Img.Free;
    end;

    Exit;
  end;

  Img := GetImage(E);
  if not Assigned(Img) then Exit;

  DrawImg := Img;
  try
    if E.Rot <> 0 then
      DrawImg := RotateBitmap(Img, E.Rot * 45);

    sx2 := sx1 + Round(DrawImg.Width * Zoom);
    sy2 := sy1 + Round(DrawImg.Height * Zoom);

    if sx2 <= sx1 then Inc(sx2);
    if sy2 <= sy1 then Inc(sy2);

    adj := Max(1, Round(Zoom));
    sx2 := sx1 + Round(DrawImg.Width * Zoom) + adj;
    sy2 := sy1 + Round(DrawImg.Height * Zoom) + adj;

    PaintBox1.Canvas.StretchDraw(
      Rect(sx1, sy1, sx2, sy2),
      DrawImg
    );

    if (E.Tipo = etRail) and (E.EstadoInt > 0) then
    begin
      Txt := IntToStr(E.EstadoInt);

      PaintBox1.Canvas.Font.Color := clWhite;
      PaintBox1.Canvas.Font.Style := [fsBold];
      PaintBox1.Canvas.Brush.Style := bsClear;
      PaintBox1.Canvas.Font.Height := Round(12 * Zoom);
      if PaintBox1.Canvas.Font.Height < 6 then
        PaintBox1.Canvas.Font.Height := 6;

      Tw := PaintBox1.Canvas.TextWidth(Txt);
      Th := PaintBox1.Canvas.TextHeight(Txt);

      PaintBox1.Canvas.TextOut(
        sx1 + (Round(DrawImg.Width * Zoom) - Tw) div 2,
        sy1 + (Round(DrawImg.Height * Zoom) - Th) div 2,
        Txt
      );
    end;

    if (Modo = mmEdicion) or (Modo = mmInsercion) then
    begin
      Txt := IntToStr(E.Addr) + ' R=' + IntToStr(E.Rot);

      PaintBox1.Canvas.Font.Color := clYellow;
      PaintBox1.Canvas.Font.Style := [fsBold];
      PaintBox1.Canvas.Brush.Style := bsClear;
      PaintBox1.Canvas.Font.Height := Round(11 * Zoom);
      if PaintBox1.Canvas.Font.Height < 7 then
        PaintBox1.Canvas.Font.Height := 7;

      Tw := PaintBox1.Canvas.TextWidth(Txt);
      Th := PaintBox1.Canvas.TextHeight(Txt);

      PaintBox1.Canvas.TextOut(
        sx1 + (Round(DrawImg.Width * Zoom) - Tw) div 2,
        sy1 - Th - 2,
        Txt
      );
    end;

    if ((Assigned(SelectedElements)) and (SelectedElements.IndexOf(E) >= 0)) or
       (Assigned(ElementoSeleccionado) and (E = ElementoSeleccionado)) then
    begin
      PaintBox1.Canvas.Pen.Color := clYellow;
      PaintBox1.Canvas.Pen.Width := 2;
      PaintBox1.Canvas.Brush.Style := bsClear;

      PaintBox1.Canvas.Rectangle(
        sx1,
        sy1,
        sx1 + Round(DrawImg.Width * Zoom),
        sy1 + Round(DrawImg.Height * Zoom)
      );
    end;

  finally
    if (DrawImg <> nil) and (DrawImg <> Img) then
      DrawImg.Free;
  end;
end;

procedure TForm_ControlMaqueta.PaintBox1Paint(Sender: TObject);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
  StartX, StartY: Integer;
  worldX0, worldY0: Integer;
  worldX1, worldY1: Integer;
  sx, sy, sx2, sy2, sx1, sy1, x, y: Integer;
begin
  PaintBox1.Canvas.Brush.Color := FondoMapa;
  PaintBox1.Canvas.FillRect(Rect(0, 0, PaintBox1.Width, PaintBox1.Height));

  PaintBox1.Canvas.Pen.Color := clGray;
  PaintBox1.Canvas.Brush.Style := bsClear;
  PaintBox1.Canvas.Rectangle(0, 0, PaintBox1.Width, PaintBox1.Height);

  if (Modo = mmEdicion) or (Modo = mmInsercion) then
  begin
    worldX0 := Floor(ScrollBox1.HorzScrollBar.Position / Zoom);
    worldY0 := Floor(ScrollBox1.VertScrollBar.Position / Zoom);
    worldX1 := Ceil((ScrollBox1.HorzScrollBar.Position + ScrollBox1.ClientWidth) / Zoom);
    worldY1 := Ceil((ScrollBox1.VertScrollBar.Position + ScrollBox1.ClientHeight) / Zoom);

    StartX := (worldX0 div 10) * 10;
    StartY := (worldY0 div 10) * 10;

    PaintBox1.Canvas.Pen.Color := $909090;

    x := StartX;
    while x <= worldX1 do
    begin
      sx := WorldToScreenX(x);
      PaintBox1.Canvas.Line(sx, 0, sx, PaintBox1.Height);
      Inc(x, 10);
    end;

    y := StartY;
    while y <= worldY1 do
    begin
      sy := WorldToScreenY(y);
      PaintBox1.Canvas.Line(0, sy, PaintBox1.Width, sy);
      Inc(y, 10);
    end;
  end;

   if Modo = mmOperacion then
    begin
      // Primera pasada:
      // dibujar todos los elementos excepto los gráficos asociados a switch que estén ON,
      // para que esos ON se pinten al final y queden delante.
      for Z in ControlMaqueta1.Zonas do
        for E in Z.Elementos do
        begin
          if (E.Tipo = etGrafico) and (E.Addr > 0) and E.EstadoBool then
            Continue;

          DibujarElemento(E);
        end;

      // Segunda pasada:
      // dibujar al final los gráficos asociados a switch que estén ON
      for Z in ControlMaqueta1.Zonas do
        for E in Z.Elementos do
          if (E.Tipo = etGrafico) and (E.Addr > 0) and E.EstadoBool then
            DibujarElemento(E);
    end
    else
    begin
      // En edición/inserción se dibuja todo, también los gráficos OFF
      for Z in ControlMaqueta1.Zonas do
        for E in Z.Elementos do
          DibujarElemento(E);
    end;

  if FSelectingRect then
  begin
    sx1 := WorldToScreenX(Min(FSelectStartX, FSelectCurrentX));
    sy1 := WorldToScreenY(Min(FSelectStartY, FSelectCurrentY));
    sx2 := WorldToScreenX(Max(FSelectStartX, FSelectCurrentX));
    sy2 := WorldToScreenY(Max(FSelectStartY, FSelectCurrentY));

    PaintBox1.Canvas.Brush.Style := bsClear;
    PaintBox1.Canvas.Pen.Color := clAqua;
    PaintBox1.Canvas.Pen.Style := psDash;
    PaintBox1.Canvas.Pen.Width := 1;
    PaintBox1.Canvas.Rectangle(sx1, sy1, sx2, sy2);
    PaintBox1.Canvas.Pen.Style := psSolid;
  end;
end;

procedure TForm_ControlMaqueta.ControlMaqueta1Sensor(Sender: TObject; Addr: Integer; State: Boolean);
begin
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.ControlMaqueta1Switch(Sender: TObject; Addr: Integer; State: Boolean);
var
  Z: TZonaMaqueta;
  E: TElementoMaqueta;
begin
  for Z in ControlMaqueta1.Zonas do
    for E in Z.Elementos do
    begin
      if (E.Tipo = etSwitch) and (E.Addr = Addr) then
        E.EstadoBool := State;

      if (E.Tipo = etGrafico) and (E.Addr = Addr) then
        E.EstadoBool := State;
    end;

  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
   CloseAction := caFree;
   Form_ControlMaqueta := nil;
end;

procedure TForm_ControlMaqueta.ControlMaqueta1RailCom(Sender: TObject; Sensor: Integer; DCC: Integer; Present: Boolean);
begin
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.OnRotarPanelClick(Sender: TObject);
var
  R: Integer;
begin
  if Assigned(ElementoSeleccionado) and (Modo = mmEdicion) then
  begin
    ElementoSeleccionado.Rot := (ElementoSeleccionado.Rot + 1) mod 8;
    ERot.Text := IntToStr(ElementoSeleccionado.Rot);
  end
  else
  begin
    if not TryStrToInt(Trim(ERot.Text), R) then
      R := 0;
    R := (R + 1) mod 8;
    ERot.Text := IntToStr(R);
  end;

  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.BtnAutomatismosClick(Sender: TObject);
begin
  if not Assigned(FormAutomatismos) then
    FormAutomatismos := TFormAutomatismos.Create(Application);

  FormAutomatismos.Control := ControlMaqueta1;
  FormAutomatismos.Show;
end;

procedure TForm_ControlMaqueta.CrearMapaVacioInicial;
begin
  LimpiarMapa;

  AreaWidth := 2000;
  AreaHeight := 1500;
  FondoMapa := clBlack;

  PaintBox1.Width := Round(AreaWidth * Zoom);
  PaintBox1.Height := Round(AreaHeight * Zoom);

  // Se deja una zona vacía para poder insertar elementos desde el principio
  ControlMaqueta1.AddZona('Zona 1');

  ElementoSeleccionado := nil;
  DragActivo := False;

  if Assigned(SelectedElements) then
    SelectedElements.Clear;

  MultiSelect := False;

  MarcarMapaActual('', True);

  Caption := 'Control maqueta - mapa vacío';
  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

procedure TForm_ControlMaqueta.OnAplicarTamanoMapa(Sender: TObject);
var
  W, H: Integer;
begin
  if not TryStrToInt(Trim(EAnchoMapa.Text), W) then
  begin
    MessageDlg('Ancho de mapa no válido.', mtError, [mbOK], 0);
    Exit;
  end;

  if not TryStrToInt(Trim(EAltoMapa.Text), H) then
  begin
    MessageDlg('Alto de mapa no válido.', mtError, [mbOK], 0);
    Exit;
  end;

  if W < 500 then W := 500;
  if H < 500 then H := 500;

  AreaWidth := W;
  AreaHeight := H;

  PaintBox1.Width := Round(AreaWidth * Zoom);
  PaintBox1.Height := Round(AreaHeight * Zoom);

  PaintBox1.Invalidate;
  ActualizarPanelPropiedades;
end;

// MAPAS

function TForm_ControlMaqueta.GetMapsPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'maps';
  if not DirectoryExists(Result) then
    CreateDir(Result);
end;

procedure TForm_ControlMaqueta.CargarListaMapas;
var
  SR: TSearchRec;
  Nombre: string;
begin
  if not Assigned(CBMapas) then Exit;

  CBMapas.Items.BeginUpdate;
  try
    CBMapas.Items.Clear;

    // Activar orden automático
    CBMapas.Sorted := True;

    if FindFirst(IncludeTrailingPathDelimiter(GetMapsPath) + '*.json', faAnyFile, SR) = 0 then
    begin
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          Nombre := ChangeFileExt(SR.Name, '');

          // Filtrar "copia"
          if Pos('copia', LowerCase(Nombre)) = 0 then
            CBMapas.Items.Add(Nombre);
        end;
      until FindNext(SR) <> 0;
      FindClose(SR);
    end;

    if CBMapas.Items.Count > 0 then
      CBMapas.ItemIndex := 0;

  finally
    CBMapas.Items.EndUpdate;
  end;
end;

procedure TForm_ControlMaqueta.CargarMapaInicial;
begin
  // Siempre arrancar con mapa vacío, sin cargar ningún mapa por defecto
  CrearMapaVacioInicial;
end;

procedure TForm_ControlMaqueta.BRefrescaMapaClick(Sender: TObject);
begin
  CargarListaMapas;
end;

procedure TForm_ControlMaqueta.BCargaRaMapaClick(Sender: TObject);
var
  FileName: string;
begin
  if not Assigned(CBMapas) then Exit;
  if CBMapas.ItemIndex < 0 then Exit;

  FileName := IncludeTrailingPathDelimiter(GetMapsPath) +
              CBMapas.Items[CBMapas.ItemIndex] + '.json';

  if not FileExists(FileName) then
  begin
    MessageDlg('El archivo no existe.', mtError, [mbOK], 0);
    Exit;
  end;

  if ControlMaqueta1.Zonas.Count > 0 then
    if MessageDlg(
         'Cargar mapa',
         'Se reemplazará el mapa actual. ¿Desea continuar?',
         mtConfirmation,
         [mbYes, mbNo],
         0
       ) <> mrYes then Exit;

  // Guardado automático del mapa actual antes de cargar otro
  GuardarMapaActualAutomaticamente;

  CargarMapaDeArchivo(FileName);
  MarcarMapaActual(FileName, False);
  Caption := 'Control maqueta - ' + ChangeFileExt(ExtractFileName(FileName), '');
end;

procedure TForm_ControlMaqueta.BCargarMapaClick(Sender: TObject);
var
  D: TOpenDialog;
begin
  D := TOpenDialog.Create(Self);
  try
    D.Title := 'Cargar mapa de maqueta';
    D.Filter := 'Mapas de maqueta (*.json)|*.json|Todos los archivos (*.*)|*.*';
    D.Options := [ofFileMustExist, ofPathMustExist];

    if not D.Execute then Exit;

    if ControlMaqueta1.Zonas.Count > 0 then
      if MessageDlg(
           'Cargar mapa',
           'Se reemplazará el mapa actual. ¿Desea continuar?',
           mtConfirmation,
           [mbYes, mbNo],
           0
         ) <> mrYes then Exit;

    // Guardado automático del mapa actual antes de cargar otro
    GuardarMapaActualAutomaticamente;

    CargarMapaDeArchivo(D.FileName);
    MarcarMapaActual(D.FileName, False);
    Caption := 'Control maqueta - ' + ChangeFileExt(ExtractFileName(D.FileName), '');
  finally
    D.Free;
  end;
end;

procedure TForm_ControlMaqueta.BGuardarMapaClick(Sender: TObject);
var
  D: TSaveDialog;
begin
  D := TSaveDialog.Create(Self);
  try
    D.Title := 'Guardar mapa de maqueta';
    D.Filter := 'Mapas de maqueta (*.json)|*.json|Todos los archivos (*.*)|*.*';
    D.DefaultExt := 'json';
    D.InitialDir := GetMapsPath;
    D.Options := [ofPathMustExist, ofOverwritePrompt];

    if D.Execute then
    begin
      GuardarMapaEnArchivo(D.FileName);
      MarcarMapaActual(D.FileName, False);
      Caption := 'Control maqueta - ' + ChangeFileExt(ExtractFileName(D.FileName), '');
      CargarListaMapas;
    end;
  finally
    D.Free;
  end;
end;

procedure TForm_ControlMaqueta.BColorFondoClick(Sender: TObject);
begin
  ColorDialog1.Color := FondoMapa;
  if ColorDialog1.Execute then
  begin
    FondoMapa := ColorDialog1.Color;
    PaintBox1.Invalidate;
  end;
end;

procedure TForm_ControlMaqueta.BEdicionMaquetaClick(Sender: TObject);
begin
  Modo := mmEdicion;
  ElementoSeleccionado := nil;
  DragActivo := False;
  Panel2.Visible := True;
  PanelBotones.Visible := False;
  ActualizarPanelPropiedades;
  PaintBox1.Invalidate;
end;

end.
