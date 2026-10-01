# Evidencia de FASE 0

Trabajo iniciado: **2026-09-29**. Revisión de mejora: **2026-10-01**, fecha civil Europe/Madrid.
Repositorio nuevo e independiente [Glucius-TM/draconic-mmo](https://github.com/Glucius-TM/draconic-mmo).
Alcance: bootstrap, diagnóstico offline, build y diseño propuesto. Sin gameplay ni servidores online.

## Entorno comprobado

| Elemento | Evidencia local |
|---|---|
| Sistema | Windows 11, x64 |
| CPU / memoria | Intel Core i7-7700HQ, 4 núcleos / 8 hilos; aproximadamente 16 GiB |
| CMake | 3.29.2, generador Visual Studio 17 2022 |
| C++ | MSVC 19.44.35228; warnings del proyecto como errores |
| Unreal | 5.8.3, changelist 58210709, comprobado en `Engine/Build/Build.version` |
| UBT | MSVC toolchain 14.44.35228; Windows SDK 10.0.22621.0 |
| Blender | 5.2.2 LTS, versión comprobada; no utilizado para producir assets en esta fase |

## Servidor C++20

Se compilan una librería de validación y un ejecutable de diagnóstico offline. El parser acota bytes, líneas y
campos; rechaza claves desconocidas/duplicadas, números no canónicos/desbordados y caracteres no permitidos.
El CLI emite resultados JSON verificados, no registra el valor rechazado y declara que no arrancó servicios.

- Configure Windows: completado correctamente.
- Build Debug: completado correctamente.
- CTest Debug: **20/20 aprobados**, 0 fallos.
- Build Release: completado correctamente.
- CTest Release: **20/20 aprobados**, 0 fallos.
- clang-format 19.1.5: seis archivos C++/headers comprobados con `--dry-run --Werror`, salida 0.
- Diagnóstico Release: ejecución real con `config_valid`, `offline_validation` y `services_started=0`.
- Build Release con `BUILD_TESTING=OFF`, instalación y ejecución de los archivos instalados: aprobados.
- Rechazo de build dentro de fuente y de staging de prueba fuera del build: comprobados.

CTest contiene 1 test unitario con 5 grupos de escenarios, 18 tests de CLI y 1 de instalación. No son 40 tests distintos por
ejecutarse también en Release. Se comprueban códigos de salida y contenido; las pruebas de `--help` y `--version`
no dependen exclusivamente de una coincidencia de texto que podría ocultar un retorno fallido.
Las ampliaciones verifican archivos de 16 KiB exactos, líneas de 256 bytes exactos/excedidas, CRLF, rechazo de BOM y
caracteres de control, números de línea de error y rutas con espacios/Unicode. La prueba de instalación ejecuta el
binario instalado con el ejemplo instalado y valida JSON/versión. No equivale a probar un paquete en un Windows limpio.

Logs locales conservados e ignorados por Git:
`.build/verification/phase0-hardening-windows-debug.log`, `phase0-hardening-windows-release.log`,
`phase0-hardening-no-tests-install.log`, `phase0-hardening-in-source-rejection.log` y `phase0-hardening-install-guard.log`.
Comandos reproducibles en [build-and-test.md](build-and-test.md).

## Cliente UE 5.8.3

- `DraconicClientEditor Win64 Development`: **Succeeded**, salida 0; build inicial de ocho acciones en 57,82 s.
  Revalidación del descriptor final el 2026-09-30: **Succeeded**, 11,15 s.
- `Draconic.Foundation.ClientModuleLoaded`: **Success**, 1 aprobado, 0 fallos y 0 pendientes.
- El informe del test registra 0 errores y 0 warnings; el log confirma `TEST COMPLETE. EXIT CODE: 0`.
- La ejecución headless usa `-nullrhi`: comprueba integración/carga del módulo, no renderizado.

Evidencia histórica del bootstrap: `client/Saved/Logs/phase0-build-20260930.log`,
`client/Saved/Logs/phase0-automation-20260930-en.log` y
`client/Saved/Automation/phase0-20260930-en/index.json`. Motor y datos generados no se versionan.

La primera ejecución del 2026-09-29 emitió **14 mensajes `LogAutomationTest: Error: Condition failed` antes del test**.
La investigación identificó comparaciones de cadenas inglesas en tests internos del motor como causa probable bajo
localización española. Se repitió con `-culture=en` exclusivamente en el proceso de prueba y logging más detallado,
sin suprimir categorías: **0 líneas de error**, **0 `Condition failed`** y 430 tests internos de arranque aprobados.
Estos 430 son tests del motor, no pruebas propias del proyecto. El informe fresco acredita además el test propio.
La causa es una inferencia respaldada por fuente/ejecución; el primer log no permite mapear cada mensaje a su aserción.
Se deshabilitó AndroidFileServer, ajeno al proyecto, y se usa `-nowrite` para evitar INI/tokens autogenerados.
La investigación y límites se registran en [ue58-verification.md](ue58-verification.md).

### Verificador reproducible de esta mejora

`tools/unreal/verify.ps1` ejecutado con el motor real 5.8.3: build Editor y editor headless con **salida 0**;
`Draconic.Foundation.ClientModuleLoaded` **Success**, informe fresco y log aceptados por el validador.
Evidencia: `.build/unreal/20260930T221609Z-821f451563c94c3f93de980b9c2659d4/verification.json`,
`build.stdout.log`, `automation.log` y `report/index.json`. El test se ejecutó entre 22:16:17 y 22:17:16 UTC
del 2026-09-30 (2026-10-01 en Europe/Madrid). El alcance sigue siendo build/carga del módulo.

El verificador rechaza informes ausentes, antiguos, corruptos, duplicados, de otro test, con contadores o eventos
inconsistentes; rechaza errores de arranque aunque el test seleccionado tenga éxito y conserva logs al fallar.
Los tests `tests/tooling/test-unreal-validation.ps1` prueban ese rechazo con fixtures sintéticos y procesos reales
para códigos de salida y timeout. **35 comprobaciones aprobadas localmente**; no son tests del motor ni de gameplay.

## GitHub y CI

La entrega inicial se publicó en `main`, commit `d2db3d6498aa1f16953b73552727368eb051a212`; su árbol
coincide exactamente con el commit local inicial `6434a7a`. La
[ejecución inicial 36784219638](https://github.com/Glucius-TM/draconic-mmo/actions/runs/36784219638)
tiene **7 jobs aprobados**: MSVC Debug/Release, GCC Debug/Release, Clang Debug/Release y ASan/UBSan.
Esa ejecución corresponde a los **12 tests originales**, no acredita los 20 tests de esta mejora.

La mejora se prepara en `phase0-hardening`, con evidencia de la nueva ejecución pendiente de publicación/verificación.
Su workflow amplía la matriz con instalación sin tests en Windows/Linux y verificación de las herramientas UE sin motor,
y conserva JUnit/logs. No hay job de compilación del motor UE en CI. La evidencia del motor sigue siendo local.

## Verificación de diseño y limpieza

Revisión de arquitectura, datos/protocolo, tests y CI. Se aclararon las dependencias de código frente al flujo de
mensajes; autenticación OIDC frente a autorización local; serialización de mutaciones, renovación y reasignación de
autoridad; barrera durable, colas y caducidad de rutas. La matriz A01–A07 son pruebas futuras, NO VERIFICADAS.
La nueva matriz de [aceptación](phase0-acceptance.md) liga diez requisitos a entregables, responsables y evidencia.
Las cifras de escala y rendimiento son propuestas, nunca resultados de carga. Las APIs utilizadas en el cliente
tienen referencias oficiales UE 5.8 y contraste local en `ue58-verification.md`.

## No verificado o no implementado

- Ejecución remota de las mejoras: pendiente de confirmar; ejecución del bootstrap acreditada arriba.
- UE Game target, cooking, packaging, mapas, GPU/performance, navegación y reconciliación.
- PostgreSQL/Redis reales, migraciones aplicadas, TLS/Protobuf, identidad, bots, carga y recuperación.
- Sistemas de gameplay, contenido artístico, administración, despliegue y operación de producción.

La FASE 1 permanece pendiente de validación del usuario. La deuda detallada está en `technical-debt.md`.
