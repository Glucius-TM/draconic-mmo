# Cliente C++ — Fase 0

Proyecto UE 5.8 sin gameplay ni contenido artístico. El módulo primario se registra en el motor y contiene una prueba
de integración mínima que comprueba que el descriptor del proyecto lo carga en el editor. La prueba no afirma que
exista un juego, transporte de red, movimiento, renderizado de mundo ni conexión con el servidor.

## Verificar build y smoke test en Windows

Con PowerShell **7.2 o posterior**, Visual Studio C++/SDK y el motor **5.8.3** instalado:

```powershell
pwsh -NoProfile -NonInteractive -File ./tools/unreal/verify.ps1 -EngineRoot 'C:/Program Files/Epic Games/UE_5.8'
if ($LASTEXITCODE -ne 0) { throw 'Falló la verificación del cliente.' }
```

El comando se muestra desde la raíz. También se puede invocar por ruta absoluta desde otra carpeta: el script
resuelve proyecto y resultados respecto a su propia ubicación, sin depender del directorio actual. Alternativamente,
configurar `UE_ENGINE_ROOT` y omitir `-EngineRoot`. No busca ni instala motores automáticamente. Antes de ejecutar
UBT exige 5.8.3 en `Engine/Build/Build.version` y comprueba las rutas. No acepta parches distintos por silencio.

La instalación observada es 5.8.3. Los targets fijan `BuildSettingsVersion.V7` e
`EngineIncludeOrderVersion.Unreal5_8`, corroborados con la plantilla oficial instalada de UE 5.8. La asociación del
`.uproject` identifica la familia 5.8; no sustituye la comprobación de `Engine/Build/Build.version` en un runner.
Visual Studio 2022 17.14 o posterior está soportado por Epic para 5.8. En esta máquina UBT selecciona MSVC
14.44.35228 y Windows SDK 10.0.22621.0.

El target `DraconicClient` usa el tipo UBT `Game`, compatible con el motor binario instalado; su nombre designa el
cliente de este producto. No es un servidor UE, ni contiene implementación de servidor. El backend C++ independiente
se construye con CMake. El tipo UBT `Client` se reevaluará antes del empaquetado, según la distribución del motor y
las plataformas elegidas. No se entrega paquete ejecutable cocinado en Fase 0.

El script compila `DraconicClientEditor Win64 Development` con un máximo de **dos acciones paralelas** y después
ejecuta exclusivamente `Draconic.Foundation.ClientModuleLoaded`. Los límites predeterminados son 1.200 segundos
para build y 600 para el test, configurables con `-BuildTimeoutSeconds` y `-TestTimeoutSeconds`. `-MaxParallelActions`
admite 1 o 2. Un timeout termina el árbol del proceso iniciado por el script; nunca busca ni cierra procesos por nombre.

## Criterios automáticos de éxito

Cada ejecución crea `.build/unreal/<UTC>-<GUID>/` con logs de UBT/editor e informe de Automation. Nunca reutiliza ni
reanuda informes anteriores. Solo escribe `verification.json` de éxito después de comprobar:

- Códigos de salida cero de build y editor, dentro de sus respectivos timeouts.
- Un único `report/index.json`, JSON válido sin claves duplicadas, menor de 4 MiB y con campos/tipos obligatorios.
- Evidencia escrita dentro de esta ejecución, incluido `reportCreatedOn` UTC (tolerancia de un segundo por su precisión).
- Exactamente el test `Draconic.Foundation.ClientModuleLoaded` en estado `Success`, sin resultados extra/duplicados.
- `succeeded=1`; `failed`, `notRun`, `inProcess`, `succeededWithWarnings`, errores y warnings del test iguales a cero.
- Log fresco con un único marcador de fin satisfactorio y sin errores/fatales, `Condition failed`, warnings de
  Automation ni fallos de tests de arranque. Los avisos de otras herramientas opcionales se conservan en el log;
  no se presentan como cobertura de esas herramientas.

Un código cero del editor sin el informe correcto produce **fallo del script**. Se conservan también los logs de
ejecuciones fallidas. Los resultados generados no se versionan. `-nullrhi` permite verificar carga de módulos sin exigir una GPU concreta;
deliberadamente no valida renderizado, assets, shaders, UI ni experiencia de juego. `-nowrite` impide que esta prueba
reescriba configuración; `-culture=en` fija la cultura del proceso de prueba para las comprobaciones de cadenas del
motor, sin cambiar el idioma guardado del editor del usuario. `-LogCmds=LogAutomationTest Log` aumenta el detalle de
los tests de arranque y conserva sus errores. El plugin AndroidFileServer está deshabilitado explícitamente porque
el cliente de esta fase no usa despliegue Android ni necesita su servidor de archivos o su token autogenerado.

## Probar el validador sin Unreal

```powershell
pwsh -NoProfile -NonInteractive -File ./tests/tooling/test-unreal-validation.ps1
if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas de tooling.' }
```

Estas pruebas usan un fixture representativo del formato 5.8, casos de falso éxito y procesos PowerShell reales para
comprobar códigos de salida y terminación por timeout. No requieren UE, Pester ni descargas. No sustituyen el smoke
test del motor. No se habilita un runner UE autohospedado para PRs públicas; requiere infraestructura dedicada y una
política de ejecución de código confiable antes de añadirlo.

## Extensiones pendientes de aprobación

Antes de añadir subsistemas, protocolo o gameplay, escribir y validar su diseño en `docs/`. Mantener dependencias
privadas y añadir módulos solo cuando tengan una responsabilidad implementada. No habilitar GAS, Iris o Mass por
anticipado. Las razones y el inventario de APIs consultadas están en `../docs/ue58-verification.md`.
