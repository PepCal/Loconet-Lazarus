unit MaquetaModel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, Graphics;

type
  {
    Tipos de elementos soportados dentro del modelo de maqueta.
  }
  TElementoTipo = (etSensor, etSwitch, etRail, etTexto, etGrafico, etControlGrupo);

  {
    Acción asociada a un elemento de control de grupo.
  }
  TAccionGrupo = (agActivar, agDesactivar);

  {
    Elemento básico del modelo de maqueta.

    Esta clase representa cualquier objeto lógico o visual presente en una
    zona de la maqueta: sensores, desvíos, detectores RailCom, textos,
    gráficos o controles de grupo.

    Campos principales:
    - ID: identificador lógico del elemento.
    - Tipo: categoría del elemento.
    - SubTipo: variante concreta dentro del tipo.
    - Texto: contenido textual asociado.
    - Rot: rotación en pasos de 45 grados (0..7).
    - ColorTexto / FontSize: propiedades de representación para texto.
    - Addr: dirección LocoNet/DCC asociada cuando aplica.
    - Nombre: nombre descriptivo.
    - EstadoBool / EstadoInt: estado actual del elemento.
    - GrupoNombre / GrupoAccion: datos de agrupación.
    - X, Y: posición del elemento.
  }
  TElementoMaqueta = class
  public
    ID: string;
    Tipo: TElementoTipo;
    SubTipo: string;
    Texto: string;
    Rot: Integer;   // 0..7, pasos de 45 grados

    ColorTexto: TColor;
    FontSize: Integer;

    Addr: Integer;
    Nombre: string;

    EstadoBool: Boolean;
    EstadoInt: Integer;

    GrupoNombre: string;
    GrupoAccion: TAccionGrupo;

    X, Y: Integer;

    constructor Create;
    function GetStateIndex: Integer;
  end;

  { Lista de elementos de maqueta }
  TListaElementos = specialize TFPGObjectList<TElementoMaqueta>;

type
  {
    Recurso gráfico visual asociado a un fichero de imagen.

    Se utiliza para mantener un bitmap cargado en memoria a partir de un
    archivo externo, identificado por nombre y ruta.
  }
  TGraficoVisual = class
  public
    Nombre: string;
    FileName: string;
    Img: TBitmap;

    constructor Create;
    destructor Destroy; override;

    procedure LoadImage;
  end;

  { Lista de recursos gráficos visuales }
  TGraficoVisualList = specialize TFPGObjectList<TGraficoVisual>;

type
  {
    Zona de maqueta.

    Cada zona contiene una colección de elementos y permite búsquedas simples
    por dirección.
  }
  TZonaMaqueta = class
  private
    FElementos: TListaElementos;
  public
    Nombre: string;

    constructor Create;
    destructor Destroy; override;

    procedure AddElemento(E: TElementoMaqueta);
    function FindByAddr(Addr: Integer): TElementoMaqueta;

    property Elementos: TListaElementos read FElementos;
  end;

implementation

{ TElementoMaqueta }

constructor TElementoMaqueta.Create;
begin
  inherited Create;

  ColorTexto := clWhite;
  GrupoAccion := agActivar;
  GrupoNombre := '';
  FontSize := 14;
end;

function TElementoMaqueta.GetStateIndex: Integer;
begin
  case Tipo of
    etSensor, etSwitch:
      if EstadoBool then
        Result := 1
      else
        Result := 0;

    etRail:
      if EstadoInt = 0 then
        Result := 0
      else if EstadoInt = -1 then
        Result := 1
      else
        Result := 2;
  else
    Result := 0;
  end;
end;

{ TZonaMaqueta }

constructor TZonaMaqueta.Create;
begin
  inherited Create;
  FElementos := TListaElementos.Create(True);
end;

destructor TZonaMaqueta.Destroy;
begin
  FElementos.Free;
  inherited Destroy;
end;

procedure TZonaMaqueta.AddElemento(E: TElementoMaqueta);
begin
  FElementos.Add(E);
end;

function TZonaMaqueta.FindByAddr(Addr: Integer): TElementoMaqueta;
var
  E: TElementoMaqueta;
begin
  Result := nil;

  for E in FElementos do
    if E.Addr = Addr then
      Exit(E);
end;

{ TGraficoVisual }

constructor TGraficoVisual.Create;
begin
  inherited Create;
  Img := TBitmap.Create;
end;

destructor TGraficoVisual.Destroy;
begin
  Img.Free;
  inherited Destroy;
end;

procedure TGraficoVisual.LoadImage;
var
  Pic: TPicture;
begin
  if not FileExists(FileName) then
    Exit;

  Pic := TPicture.Create;
  try
    Pic.LoadFromFile(FileName);
    Img.Assign(Pic.Bitmap);
  finally
    Pic.Free;
  end;
end;

end.
