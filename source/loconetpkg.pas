{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit loconetpkg;

{$warn 5023 off : no warning about unused units}
interface

uses
  ClientLocoNet, ControlLoco, ControlMaqueta, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('ClientLocoNet', @ClientLocoNet.Register);
  RegisterUnit('ControlLoco', @ControlLoco.Register);
  RegisterUnit('ControlMaqueta', @ControlMaqueta.Register);
end;

initialization
  RegisterPackage('loconetpkg', @Register);
end.
