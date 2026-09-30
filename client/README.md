# Cliente C++ — Fase 0

Proyecto UE 5.8 sin gameplay ni contenido artístico. El módulo primario se registra en el motor y contiene una prueba
de integración mínima que comprueba que el descriptor del proyecto lo carga en el editor. La prueba no afirma que
exista un juego, transporte de red, movimiento, renderizado de mundo ni conexión con el servidor.

## Compilar en Windows

Desde la raíz del repositorio, en PowerShell:

```powershell
$EngineRoot = 'C:/Program Files/Epic Games/UE_5.8'
$Project = (Resolve-Path './client/DraconicClient.uproject').Path
& "$EngineRoot/Engine/Build/BatchFiles/Build.bat" DraconicClientEditor Win64 Development "-Project=$Project" -WaitMutex -NoHotReloadFromIDE -MaxParallelActions=2
if ($LASTEXITCODE -ne 0) { throw 'La compilación del editor falló.' }
```

La instalación observada es 5.8.3. Los targets fijan `BuildSettingsVersion.V7` e
`EngineIncludeOrderVersion.Unreal5_8`, corroborados con la plantilla oficial instalada de UE 5.8. La asociación del
`.uproject` identifica la familia 5.8; no sustituye la comprobación de `Engine/Build/Build.version` en un runner.
Visual Studio 2022 17.14 o posterior está soportado por Epic para 5.8. En esta máquina UBT selecciona MSVC
14.44.35228 y Windows SDK 10.0.22621.0.

El target `DraconicClient` usa el tipo UBT `Game`, compatible con el motor binario instalado; su nombre designa el
cliente de este producto. No es un servidor UE, ni contiene implementación de servidor. El backend C++ independiente
se construye con CMake. El tipo UBT `Client` se reevaluará antes del empaquetado, según la distribución del motor y
las plataformas elegidas. No se entrega paquete ejecutable cocinado en Fase 0.

## Ejecutar el smoke test real

Después de compilar, desde la misma consola:

```powershell
$Report = Join-Path (Split-Path $Project) ('Saved/Automation/' + [guid]::NewGuid().ToString('N'))
& "$EngineRoot/Engine/Binaries/Win64/UnrealEditor-Cmd.exe" $Project -unattended -nullrhi -nosplash -nosound -nowrite -culture=en '-LogCmds=LogAutomationTest Log' '-ExecCmds=Automation RunTest Draconic.Foundation;Quit' "-ReportExportPath=$Report"
if ($LASTEXITCODE -ne 0) { throw 'La ejecución del editor falló.' }
Get-Content -LiteralPath (Join-Path $Report 'index.json')
```

Exigir que el informe fresco contenga `Draconic.Foundation.ClientModuleLoaded` con estado `Success`; un código de
salida cero sin ese resultado no demuestra que el test se ejecutara. Los logs e informes son evidencia local efímera
bajo `client/Saved/` y no se versionan. `-nullrhi` permite verificar carga de módulos sin exigir una GPU concreta;
deliberadamente no valida renderizado, assets, shaders, UI ni experiencia de juego. `-nowrite` impide que esta prueba
reescriba configuración; `-culture=en` fija la cultura del proceso de prueba para las comprobaciones de cadenas del
motor, sin cambiar el idioma guardado del editor del usuario. `-LogCmds=LogAutomationTest Log` aumenta el detalle de
los tests de arranque y conserva sus errores. El plugin AndroidFileServer está deshabilitado explícitamente porque
el cliente de esta fase no usa despliegue Android ni necesita su servidor de archivos o su token autogenerado.

## Extensiones pendientes de aprobación

Antes de añadir subsistemas, protocolo o gameplay, escribir y validar su diseño en `docs/`. Mantener dependencias
privadas y añadir módulos solo cuando tengan una responsabilidad implementada. No habilitar GAS, Iris o Mass por
anticipado. Las razones y el inventario de APIs consultadas están en `../docs/ue58-verification.md`.
