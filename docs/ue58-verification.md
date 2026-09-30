# Verificación de Unreal Engine 5.8 — Fase 0

Consulta: 2026-09-29; seguimiento de configuración y diagnóstico: 2026-09-30. Ámbito: fundación de compilación y carga del cliente, sin gameplay. Este registro distingue
documentación oficial, evidencia local y propuestas; no equipara una API existente con un sistema implementado.

## Motor y herramientas observados

`C:/Program Files/Epic Games/UE_5.8/Engine/Build/Build.version` indica **5.8.3**, changelist **58210709**,
compatible changelist **55116800**, rama `++UE5+Release-5.8`. El engine incluye UnrealBuildTool, UnrealHeaderTool,
`UnrealEditor-Cmd.exe` y la plantilla C++ Blank. UBT detecta Visual Studio Build Tools 2022 17.14 y selecciona MSVC
14.44.35228 (directorio 14.44.35207) y SDK Windows 10.0.22621.0.

La [matriz oficial de Visual Studio para UE 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine)
admite VS 2022 17.14 o posterior. No se asume que un editor instalado implique un compilador disponible; ambos se
comprobaron por separado. Se limita UBT a dos acciones paralelas en esta máquina de 16 GB.

## APIs usadas: documentación consultada antes de implementarlas

| Archivo / superficie | Símbolos o propiedades | Verificación oficial |
| --- | --- | --- |
| `.uproject` | `FileVersion`, `EngineAssociation`, `Modules`, `Category`, `Description` | [FProjectDescriptor 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Projects/FProjectDescriptor) |
| Descriptor de módulo | `Name`, `Type`, `LoadingPhase`; valores `Runtime` y `Default` | [FModuleDescriptor 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Projects/FModuleDescriptor), [estructura de módulos](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-modules) |
| Plugin deshabilitado | `Plugins`, `Name`, `Enabled: false` para `AndroidFileServer` | [FPluginReferenceDescriptor 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Projects/FPluginReferenceDescriptor), [Android File Server 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/android-file-server-for-unreal-engine) |
| `*.Target.cs` | `TargetRules`, `TargetInfo`, `Type`, `TargetType.Game`, `TargetType.Editor`, `DefaultBuildSettings`, `IncludeOrderVersion`, `ExtraModuleNames` | [referencia UBT de targets](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-build-tool-target-reference) |
| `*.Build.cs` | `ModuleRules`, `ReadOnlyTargetRules`, `PCHUsage`, `PCHUsageMode.UseExplicitOrSharedPCHs`, `PrivateDependencyModuleNames` | [propiedades de módulos](https://dev.epicgames.com/documentation/en-us/unreal-engine/module-properties-in-unreal-engine) y [módulos](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-modules) |
| Entrada del módulo | `IMPLEMENT_PRIMARY_GAME_MODULE`, `FDefaultGameModuleImpl`; cabecera `Modules/ModuleManager.h` | [registro de módulos](https://dev.epicgames.com/documentation/unreal-engine/gameplay-modules-in-unreal-engine), [FDefaultGameModuleImpl 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Core/FDefaultGameModuleImpl) |
| Smoke test | `IMPLEMENT_SIMPLE_AUTOMATION_TEST`, `RunTest(const FString&)`, `EAutomationTestFlags::EditorContext`, `SmokeFilter` | [tests C++](https://dev.epicgames.com/documentation/unreal-engine/write-cplusplus-tests-in-unreal-engine), [flags 5.8](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Core/EAutomationTestFlags) |
| Aserción de carga | `FModuleManager::Get`, `IsModuleLoaded`, `TestTrue`; cabeceras `Modules/ModuleManager.h`, `Misc/AutomationTest.h` | [FModuleManager 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Core/FModuleManager), [IsModuleLoaded 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/API/Runtime/Core/FModuleManager/IsModuleLoaded), [TestTrue 5.8](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/Core/FAutomationTestBase/TestTrue) |
| Ejecución de prueba | `Automation RunTest`, `Quit`, `ReportExportPath`, `nullrhi`, `unattended` | [ejecutar automation tests](https://dev.epicgames.com/documentation/unreal-engine/run-automation-tests-in-unreal-engine), [argumentos CLI](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-command-line-arguments-reference) |
| Prueba sin escribir configuración y diagnóstico | `nowrite`, `culture=en`, `LogCmds=LogAutomationTest Log` | [argumentos CLI 5.8](https://dev.epicgames.com/documentation/en-us/unreal-engine/unreal-engine-command-line-arguments-reference), [logging 5.8](https://dev.epicgames.com/documentation/unreal-engine/logging-in-unreal-engine?lang=en-US) |

La guía de módulos conserva un snippet histórico con una firma incompleta del macro. Se contrastó con la cabecera
oficial instalada `Engine/Source/Runtime/Core/Public/Modules/ModuleManager.h`, que declara tres argumentos, y con
`Templates/TP_Blank/Source/TP_Blank/TP_Blank.cpp`. Los valores concretos `BuildSettingsVersion.V7` y
`EngineIncludeOrderVersion.Unreal5_8` se corroboraron en `Templates/TP_Blank/Source/TP_Blank.Target.cs` de 5.8.3;
la web documenta las propiedades pero no enumera esos valores. El guard `WITH_DEV_AUTOMATION_TESTS` se corroboró en
`Engine/Source/Runtime/Core/Public/Misc/AutomationTest.h`. No se copiaron clases de gameplay ni assets de plantillas.

## Decisiones propuestas para sistemas futuros

**World Partition:** usarlo para streaming y organización de assets del cliente. Epic lo describe como gestión por
celdas y fuentes de streaming; eso no proporciona autoridad, distribución entre procesos ni traspaso de jugadores
del servidor propio. El diseño deberá mapear identificadores de región del backend a contenido del cliente y mantener
el AOI de red separado del radio visual. Ningún mapa se ha creado en Fase 0.
[Documentación World Partition 5.8](https://dev.epicgames.com/documentation/unreal-engine/world-partition-in-unreal-engine).

**GAS:** Epic documenta habilidades, atributos y efectos alrededor de actores y componentes Unreal. Recomendación
de arquitectura: reglas de combate en C++ independiente en el servidor, y un adaptador C++ de presentación en el
cliente. Usar GAS solo para presentación requeriría impedir una segunda fuente de verdad de costes, auras y cooldowns.
Alternativas: GAS con servidor UE simplifica esa integración pero cambia el stack pedido; portar/reproducir su modelo
de ejecución en el backend eleva mantenimiento y riesgo de divergencia. Propuesta pendiente de aprobación, sin GAS
habilitado ni combate implementado.
[Gameplay Ability System 5.8](https://dev.epicgames.com/documentation/unreal-engine/gameplay-ability-system-for-unreal-engine).

**Iris:** existe una discrepancia oficial. Las notas de 5.8 anuncian disponibilidad para producción para licensees;
la introducción aún muestra una advertencia Experimental y el índice del plugin una advertencia Beta. Se registra el
desfase sin afirmar que toda la documentación está sincronizada. Iris resuelve replicación del ecosistema Unreal y
no conecta directamente con el protocolo de un servidor C++ independiente. No se habilita para esta fundación. Antes
de una posible adopción se exigirían verificación de la revisión exacta y una prueba de interoperabilidad.
[Notas 5.8](https://dev.epicgames.com/documentation/unreal-engine/unreal-engine-5-8-release-notes),
[introducción Iris](https://dev.epicgames.com/documentation/unreal-engine/introduction-to-iris-in-unreal-engine),
[índice Iris](https://dev.epicgames.com/documentation/unreal-engine/API/PluginIndex/Iris).

**Mass:** las notas 5.8 describen cambios relevantes en concurrencia, módulos y fragmentos; MassEntity aparece como
módulo Runtime, mientras las propias notas identifican componentes de MassGameplay como experimentales. No extrapolar
el estado de un componente al conjunto. Candidato posterior para representación de multitudes tras un perfil reproducible;
no forma parte del servidor externo ni se añade todavía como dependencia.
[MassEntity](https://dev.epicgames.com/documentation/unreal-engine/API/Runtime/MassEntity),
[conceptos de Mass](https://dev.epicgames.com/documentation/unreal-engine/overview-of-mass-entity-in-unreal-engine),
[notas 5.8](https://dev.epicgames.com/documentation/unreal-engine/unreal-engine-5-8-release-notes).

**Renderizado y perfilado:** propuesta de presupuesto inicial, pendiente de hardware objetivo: 60 fps / 16,67 ms,
game thread p95 ≤ 5 ms, GPU p95 ≤ 13 ms, y medir por separado animación, UI, streaming y aplicación de snapshots.
Los tiempos CPU/GPU se solapan; no se deben sumar como un único frame. Probar 20/100/200 personajes visibles con LOD,
reducción de frecuencia de animación y de sombras y presupuestos para Niagara. Nanite, Lumen y VSM requieren niveles
de calidad y hardware acordados, no su activación indiscriminada. Las invalidaciones de caché VSM por geometría móvil
merecen especial atención en multitudes. Unreal Insights será la herramienta de captura. Ninguno de estos presupuestos
está medido o alcanzado en Fase 0.
[requisitos de hardware](https://dev.epicgames.com/documentation/unreal-engine/hardware-and-software-specifications-for-unreal-engine),
[VSM](https://dev.epicgames.com/documentation/unreal-engine/virtual-shadow-maps-in-unreal-engine),
[Lumen](https://dev.epicgames.com/documentation/unreal-engine/lumen-technical-details-in-unreal-engine),
[guía de Unreal Insights](https://dev.epicgames.com/documentation/unreal-engine/trace-quick-start-guide-in-unreal-engine).

## Estado de verificación ejecutable

AndroidFileServer se deshabilita explícitamente: es una utilidad de despliegue Android ajena a esta fase y viene
habilitada por defecto en el motor. Su implementación instalada genera un token al inicializar sus settings y llama
a `TryUpdateDefaultConfigFile` (`AndroidFileServerRuntimeSettings.cpp`, líneas 32–36). Se retiraron los INI
autogenerados antes del primer commit; el test posterior usa `-nowrite`, comprobado también en
`Core/Private/Misc/ConfigCacheIni.cpp`, función `AreWritesAllowedGlobally`. No se añaden tokens ni ajustes de ejes de
entrada generados automáticamente como configuración de producto. Los documentos oficiales del plugin y de CLI
anteriores sustentan estas opciones; no se modifica el motor instalado.

- **Compilación inicial verificada:** `DraconicClientEditor Win64 Development` terminó con `Result: Succeeded`, código 0,
  8 acciones y 57,82 segundos en UE 5.8.3. Compiló y enlazó `UnrealEditor-DraconicClient.dll` y el test C++.
  Evidencia local: `client/Saved/Logs/phase0-build.log`.
- **Smoke test inicial ejecutado:** `Draconic.Foundation.ClientModuleLoaded` terminó en `Success`. El informe creado el
  2026-09-29 a las 09:23:43 UTC registra 1 aprobado, 0 fallos, 0 pendientes, 0 en ejecución y 0 aprobados con warnings;
  el propio test tiene 0 warnings y 0 errores. Duración del test: 0,0156 s; no incluye el arranque del editor.
  Evidencia: `client/Saved/Automation/phase0-20260929/index.json` y
  `client/Saved/Logs/phase0-automation.log`, que confirma `TEST COMPLETE. EXIT CODE: 0`.
- **Procesos:** el editor headless y UBT terminaron. No queda un editor de esta prueba ejecutándose.
- **Verificación final tras deshabilitar AndroidFileServer, 2026-09-30:** UBT terminó de nuevo con `Succeeded`,
  código 0, en 11,15 s; regeneró metadata al cambiar el descriptor. El test headless con `-culture=en -nowrite` y
  logs de Automation al nivel `Log` terminó con código 0. El informe de las 08:43:43 UTC registra el test del proyecto
  en `Success`, 1 aprobado, 0 fallos, 0 pendientes y 0 warnings/errores; duración de la prueba 0,0164 s. En el log
  detallado hay 430 resultados de tests de arranque aprobados, 0 resultados de arranque fallidos, 0 entradas
  `: Error:` y 0 apariciones de `Condition failed`. No se regeneró ningún archivo en `client/Config`; no quedan
  procesos del editor headless o UBT. Evidencia final: `client/Saved/Logs/phase0-build-20260930.log`,
  `client/Saved/Logs/phase0-automation-20260930-en.log` y
  `client/Saved/Automation/phase0-20260930-en/index.json`.
- **Límite de evidencia:** los resultados son locales en Windows, no una ejecución de CI. No se ejecutó el target
  `Game`, ni cooking, packaging, Linux, pruebas de renderizado ni pruebas de red.

### Investigación de los 14 diagnósticos del primer arranque

El primer arranque, con cultura del sistema `es-ES`, emitió 14 entradas `LogAutomationTest: Error: Condition failed`
a las 09:22:51 UTC, antes de la sesión seleccionada `Draconic.Foundation`, que empezó a las 09:23:43 UTC. La revisión
acotada de los fuentes oficiales instalados de 5.8.3 encontró:

1. `Runtime/Launch/Private/LaunchEngineLoop.cpp:4376` llama a `FAutomationTestFramework::RunSmokeTests` durante el
   arranque. Esa ejecución incluye pruebas del motor además de las registradas por el proyecto.
2. `Runtime/Core/Public/Misc/LowLevelTestAdapter.h:130` genera el texto genérico desde el macro `CHECK`. La salida
   no incluye la expresión fallida.
3. `Runtime/Core/Private/Misc/AutomationTest.cpp:1243` imprime los nombres/resultados al nivel `Log`, y los errores
   al nivel `Error`. La categoría se declara con umbral inicial `Warning` en la línea 31. Esto explica por qué el
   primer log muestra errores sin el nombre del test. La rutina de arranque también desactiva capturas de stack.
4. `Runtime/Core/Tests/Experimental/UnifiedError/UnifiedErrorTests.cpp:479` y `:512` contienen pruebas con
   comparaciones literales en inglés. El primer log muestra salidas del mismo sistema traducidas al español. Son
   un candidato concreto de fallo dependiente de cultura; no es evidencia de fallo del renderer.
5. En la ejecución final con cultura `en`, los 14 tests de la familia `FUnifiedErrorTest_*` aparecen como `Success`,
   junto con el resto de resultados de arranque; desaparecen los 14 diagnósticos.

**Conclusión y límite:** la evidencia apoya un problema de pruebas internas del motor sensible a la cultura del
proceso. No permite atribuir cada uno de los 14 errores originales a una expresión concreta porque el primer log
no capturó esa información. No se afirma que fueran fallos esperados o inocuos. La ruta de validación documentada
fija `-culture=en` solo para el proceso de prueba, aumenta la información de log y conserva los dos informes. No
se silenciaron categorías, no se excluyeron pruebas, ni se modificaron fuentes del motor o idioma persistente del
editor. Una investigación más profunda de la ejecución en español queda fuera de esta verificación de fundación.

Se creó el directorio `Content` para corregir el aviso inicial de observación de un directorio inexistente. La
ejecución final también verifica que ese aviso ya no aparece. Los avisos de herramientas opcionales del engine y
plataformas no instaladas no constituyen una validación de esas herramientas o plataformas.

El código del cliente implementa exclusivamente registro del módulo y un smoke test de carga. No valida
reconciliación, seguridad, conexiones, gameplay, packaging, rendimiento ni despliegue.
