unit unitPrincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Forms, Controls, Graphics, Dialogs, StdCtrls,
  ClientLocoNet, ControlLoco, ControlMaqueta;

type

  { TForm_Principal }
  {
    Formulario principal de la aplicación.

    Responsabilidades:
    - Gestión de la conexión con el cliente LocoNet.
    - Visualización básica de eventos recibidos (log en Memo).
    - Lanzamiento de formularios auxiliares:
        * Control de locomotoras
        * Control de maqueta
        * Automatismos
        * Emergencia
  }

  TForm_Principal = class(TForm)

    { === Componentes visuales === }
    Button1: TButton;           // Conectar / Desconectar
    BtnAutomatismos: TButton;   // Acceso a automatismos
    Button3: TButton;           // Control locomotoras
    Button8: TButton;           // Control maqueta

    ClientLocoNet1: TClientLocoNet;

    Edit2: TEdit;               // Host
    Edit3: TEdit;               // Puerto

    Label1: TLabel;
    Label2: TLabel;

    Memo1: TMemo;               // Consola de eventos

    { === Eventos de UI === }
    procedure BtnAutomatismosClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);

    { === Eventos LocoNet === }
    procedure ClientLocoNet1LocoDir(Sender: TObject; Slot: Integer;
      Addr: Integer; Dir: Integer);

    procedure ClientLocoNet1LocoFunc(Sender: TObject; Slot: Integer;
      Addr: Integer; FuncNo: Integer; State: Boolean);

    procedure ClientLocoNet1LocoFuncs(Sender: TObject; Slot: Integer;
      Addr: Integer; Funcs: Word);

    procedure ClientLocoNet1LocoSpeed(Sender: TObject; Slot: Integer;
      Addr: Integer; Speed: Integer);

    procedure ClientLocoNet1RailCom(Sender: TObject; Sensor: Integer;
      DCC: Integer; Present: Boolean);

    procedure ClientLocoNet1Receive(Sender: TObject; const AText: string);

    procedure ClientLocoNet1Sensor(Sender: TObject; Addr: Integer;
      State: Boolean);

    procedure ClientLocoNet1Slot(Sender: TObject; Slot: Integer;
      Loco: Integer; Speed: Integer; Dir: Integer);

    procedure ClientLocoNet1Switch(Sender: TObject; Addr: Integer;
      State: Boolean);

    { === Ciclo de vida === }
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);

  private

    {
      Convierte un bitmask de funciones (F0–F8) en texto legible.

      Entrada:
        Funcs -> Word con bits de funciones activas

      Salida:
        Cadena tipo: "F0=ON  F1=OFF  ..."
    }
    function EstadoFuncionesTexto(Funcs: Word): string;

  public

  end;

var
  Form_Principal: TForm_Principal;

implementation

uses
  unitControlLocomotora,
  unitcontrolmaqueta,
  unitEmergencia,
  UnitAutomatismos,
  unitautomatizacionvisual;

{$R *.lfm}

{ ============================================================================ }
{ === Funciones auxiliares ==================================================== }
{ ============================================================================ }

function TForm_Principal.EstadoFuncionesTexto(Funcs: Word): string;
var
  i: Integer;
begin
  Result := '';

  for i := 0 to 8 do
  begin
    if Result <> '' then
      Result := Result + '  ';

    if (Funcs and (Word(1) shl i)) <> 0 then
      Result := Result + 'F' + IntToStr(i) + '=ON'
    else
      Result := Result + 'F' + IntToStr(i) + '=OFF';
  end;
end;

{ ============================================================================ }
{ === Eventos de interfaz ===================================================== }
{ ============================================================================ }

procedure TForm_Principal.Button1Click(Sender: TObject);
begin
  // Alterna entre conexión y desconexión del cliente LocoNet
  if Button1.Caption = 'Conectar' then
  begin
    ClientLocoNet1.Host := Edit2.Text;
    ClientLocoNet1.Port := StrToInt(Edit3.Text);

    ClientLocoNet1.Connect;
    Button1.Caption := 'Desconectar';
  end
  else
  begin
    ClientLocoNet1.Disconnect;
    Button1.Caption := 'Conectar';
  end;
end;

procedure TForm_Principal.BtnAutomatismosClick(Sender: TObject);
begin
  // Crear/controlar formulario de maqueta
  if not Assigned(Form_ControlMaqueta) then
  begin
    Form_ControlMaqueta := TForm_ControlMaqueta.Create(Application);
    Form_ControlMaqueta.ControlMaqueta1.LocoNet := ClientLocoNet1;
  end;

  // Crear formulario visual
  if not Assigned(FormAutomatizacionVisual) then
    FormAutomatizacionVisual := TFormAutomatizacionVisual.Create(Application);

  // Pasar el control de maqueta al formulario visual
  FormAutomatizacionVisual.Control := Form_ControlMaqueta.ControlMaqueta1;

  // Mostrar primero el formulario visual
  FormAutomatizacionVisual.Show;
  FormAutomatizacionVisual.BringToFront;

  // Arrancar el motor desde el propio formulario visual
  FormAutomatizacionVisual.EjecutarMotorDesdeExterno;
end;

procedure TForm_Principal.Button3Click(Sender: TObject);
var
  F: TForm2;
begin
  // Apertura de formulario de control de locomotoras
  F := TForm2.Create(Application);
  F.ControlLoco1.Client := ClientLocoNet1;
  F.Show;
end;

procedure TForm_Principal.Button8Click(Sender: TObject);
begin
  // Apertura o activación del formulario de maqueta
  if not Assigned(Form_ControlMaqueta) then
  begin
    Form_ControlMaqueta := TForm_ControlMaqueta.Create(Application);
    Form_ControlMaqueta.ControlMaqueta1.LocoNet := ClientLocoNet1;
    Form_ControlMaqueta.Show;
  end
  else
  begin
    Form_ControlMaqueta.Show;
    Form_ControlMaqueta.BringToFront;
    Form_ControlMaqueta.SetFocus;
  end;
end;

{ ============================================================================ }
{ === Eventos LocoNet ========================================================= }
{ ============================================================================ }

procedure TForm_Principal.ClientLocoNet1LocoDir(Sender: TObject;
  Slot: Integer; Addr: Integer; Dir: Integer);
begin
  Memo1.Lines.Add(
    'Slot: ' + IntToStr(Slot) +
    '  DCC: ' + IntToStr(Addr) +
    '  Direccion: ' + IntToStr(Dir)
  );
end;

procedure TForm_Principal.ClientLocoNet1LocoSpeed(Sender: TObject;
  Slot: Integer; Addr: Integer; Speed: Integer);
begin
  Memo1.Lines.Add(
    'Slot: ' + IntToStr(Slot) +
    '  DCC: ' + IntToStr(Addr) +
    '  Velocidad: ' + IntToStr(Speed)
  );
end;

procedure TForm_Principal.ClientLocoNet1LocoFunc(Sender: TObject;
  Slot: Integer; Addr: Integer; FuncNo: Integer; State: Boolean);
begin
  if State then
    Memo1.Lines.Add(
      'Slot: ' + IntToStr(Slot) +
      '  DCC: ' + IntToStr(Addr) +
      '  F' + IntToStr(FuncNo) + ' -> ON'
    )
  else
    Memo1.Lines.Add(
      'Slot: ' + IntToStr(Slot) +
      '  DCC: ' + IntToStr(Addr) +
      '  F' + IntToStr(FuncNo) + ' -> OFF'
    );
end;

procedure TForm_Principal.ClientLocoNet1LocoFuncs(Sender: TObject;
  Slot: Integer; Addr: Integer; Funcs: Word);
begin
  // Logging opcional de estado completo de funciones
  // Memo1.Lines.Add(
  //   'Slot: ' + IntToStr(Slot) +
  //   '  DCC: ' + IntToStr(Addr) +
  //   '  Funciones: ' + EstadoFuncionesTexto(Funcs)
  // );
end;

procedure TForm_Principal.ClientLocoNet1RailCom(Sender: TObject;
  Sensor: Integer; DCC: Integer; Present: Boolean);
begin
  Memo1.Lines.Add(
    'RailCom: ' + IntToStr(Sensor) +
    ' DCC: ' + IntToStr(DCC) +
    ' Present: ' + BoolToStr(Present, True)
  );
end;

procedure TForm_Principal.ClientLocoNet1Receive(Sender: TObject;
  const AText: string);
begin
  // Logging de recepción en bruto (deshabilitado)
  // Memo1.Lines.Add(AText);
end;

procedure TForm_Principal.ClientLocoNet1Sensor(Sender: TObject;
  Addr: Integer; State: Boolean);
begin
  Memo1.Lines.Add(
    'Sensor: ' + IntToStr(Addr) +
    '  Estado: ' + BoolToStr(State, True)
  );
end;

procedure TForm_Principal.ClientLocoNet1Slot(Sender: TObject;
  Slot: Integer; Loco: Integer; Speed: Integer; Dir: Integer);
begin
  Memo1.Lines.Add(
    'Slot: ' + IntToStr(Slot) +
    '  Loco: ' + IntToStr(Loco) +
    '  Velocidad: ' + IntToStr(Speed) +
    '  Dir: ' + IntToStr(Dir)
  );
end;

procedure TForm_Principal.ClientLocoNet1Switch(Sender: TObject;
  Addr: Integer; State: Boolean);
begin
  // Nota: usa mismo formato que sensor
  Memo1.Lines.Add(
    'Sensor: ' + IntToStr(Addr) +
    '  Estado: ' + BoolToStr(State, True)
  );
end;

{ ============================================================================ }
{ === Ciclo de vida =========================================================== }
{ ============================================================================ }

procedure TForm_Principal.FormCreate(Sender: TObject);
begin
  // Inicialización del formulario de emergencia
  FormEmergencia := TFormEmergencia.Create(Application);
  FormEmergencia.Client := ClientLocoNet1;
  FormEmergencia.TrackPowerOn := ClientLocoNet1.TrackPower;

  FormEmergencia.Show;
end;

procedure TForm_Principal.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  // Garantiza desconexión limpia del cliente LocoNet
  ClientLocoNet1.Disconnect;
end;

end.
