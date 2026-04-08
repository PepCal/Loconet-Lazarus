# Loconet-Lazarus
Componentes Loconet para Lazarus
FreePascal que permiten trabajar con redes LocoNet sobre TCP, incluyendo control de locomotoras, gestión de sensores/desvíos y modelo completo de maqueta.
---
Componentes incluidos
`TClientLocoNet`
Cliente de comunicación con el gateway LocoNet (TCP).
Conexión TCP (`SEND` / `RECEIVE`)
Decodificación de protocolo LocoNet
Gestión de slots
Resolución automática DCC ↔ Slot
Eventos para sensores, locomotoras, desvíos y RailCom
---
`TControlLoco`
Control de una locomotora individual por dirección DCC.
Velocidad y dirección
Funciones F0–F8
Sincronización automática con la red
Eventos de cambio
---
`TControlMaqueta`
Gestión global de la maqueta.
Modelo de zonas y elementos
Actualización automática desde LocoNet
Cola temporizada de comandos de desvíos
Eventos de alto nivel
---
Modelo (`MaquetaModel`)
Estructuras de datos de la maqueta:
`TElementoMaqueta`
`TZonaMaqueta`
`TGraficoVisual`
---
Arquitectura
```
UI (Lazarus)
   │
   ▼
TControlMaqueta
   │
   ▼
TControlLoco
   │
   ▼
TClientLocoNet
   │
   ▼
LocoNet TCP Gateway
```
---
Instalación
Clonar o descargar el repositorio
Abrir `loconetpkg.lpk` en Lazarus
Pulsar Install
Reiniciar Lazarus
Los componentes aparecerán en la paleta:
```
LocoNet
```
---
Dependencias
Este paquete requiere:
Lazarus (LCL)
FreePascal (FCL)
Estas dependencias forman parte de la instalación estándar de Lazarus,  
por lo que no es necesario instalar librerías externas adicionales.
---
Uso básico
```pascal
var
  Client: TClientLocoNet;
  Loco: TControlLoco;

begin
  Client := TClientLocoNet.Create(nil);
  Client.Host := '192.168.1.100';
  Client.Connect;

  Loco := TControlLoco.Create(nil);
  Loco.Client := Client;
  Loco.DCC := 3;

  Loco.Speed := 50;
  Loco.Direction := 1;
  Loco.SetFunction(0, True);
end;
```
---
Flujo de datos
Envío de comandos
```
UI → Control → Client → LocoNet
```
Recepción de eventos
```
LocoNet → Client → Control → UI
```
---
Eventos principales
Cliente
`OnSensor`
`OnSwitch`
`OnRailCom`
`OnLoco`
`OnLocoSpeed`
`OnLocoDir`
Control de locomotora
`OnChange`
`OnFunctionChange`
`OnFunctionsChange`
Control de maqueta
`OnSensor`
`OnSwitch`
`OnRailCom`
---
aracterísticas técnicas
✔ LocoNet sobre TCP (compatible con JMRI)
✔ Decodificación de opcodes (A0, A1, A2, B0, B2, E7, D0)
✔ Gestión automática de slots
✔ Resolución DCC ↔ Slot
✔ Cola de desvíos con temporización
✔ Arquitectura basada en eventos
✔ Integración nativa con Lazarus
---
Limitaciones actuales
Funciones limitadas a F0–F8
`FindByAddr` devuelve un solo elemento
Cola de desvíos FIFO simple
No incluye persistencia de maqueta
---
Documentación
Incluye:
Manual técnico
Documento de ayuda HTML
---
Compatibilidad
Lazarus 2.x+
FreePascal 3.x+
Windows (probado)
Compatible con JMRI (LocoNet TCP)
---
Autor
Pepe
---
Licencia
MIT License
---
Recomendación
Si te resulta útil:
Dale estrella al repositorio
