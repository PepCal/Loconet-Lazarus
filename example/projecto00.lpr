program projecto00;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, unitPrincipal, unitControlLocomotora, controlmaqueta, MaquetaModel,
  unitcontrolmaqueta, automatismosmaqueta, UnitAutomatismos,
unitautomatizacionvisual
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:=True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TForm_Principal, Form_Principal);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm_ControlMaqueta, Form_ControlMaqueta);
  Application.CreateForm(TFormAutomatismos, FormAutomatismos);
  Application.CreateForm(TFormAutomatizacionVisual, FormAutomatizacionVisual);
  Application.Run;
end.

