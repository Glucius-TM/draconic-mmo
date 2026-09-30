# Evidencia de FASE 0

Trabajo iniciado: **2026-09-29**. Revisión de cierre: **2026-09-30**.
Repositorio local nuevo e independiente `draconic-mmo`.
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
- CTest Debug: **12/12 aprobados**, 0 fallos.
- Build Release: completado correctamente.
- CTest Release: **12/12 aprobados**, 0 fallos.
- clang-format 19.1.5: seis archivos C++/headers comprobados con `--dry-run --Werror`, salida 0.
- Diagnóstico Release: ejecución real con `config_valid`, `offline_validation` y `services_started=0`.

CTest contiene 1 test unitario con 5 grupos de escenarios y 11 tests de CLI. No son 24 escenarios distintos por
ejecutarse también en Release. Se comprueban códigos de salida y contenido; las pruebas de `--help` y `--version`
no dependen exclusivamente de una coincidencia de texto que podría ocultar un retorno fallido.

Logs locales de build/test conservados en `.build/verification/` e ignorados por Git.
Comandos reproducibles en [build-and-test.md](build-and-test.md).

## Cliente UE 5.8.3

- `DraconicClientEditor Win64 Development`: **Succeeded**, salida 0; build inicial de ocho acciones en 57,82 s.
  Revalidación del descriptor final el 2026-09-30: **Succeeded**, 11,15 s.
- `Draconic.Foundation.ClientModuleLoaded`: **Success**, 1 aprobado, 0 fallos y 0 pendientes.
- El informe del test registra 0 errores y 0 warnings; el log confirma `TEST COMPLETE. EXIT CODE: 0`.
- La ejecución headless usa `-nullrhi`: comprueba integración/carga del módulo, no renderizado.

Evidencia final: `client/Saved/Logs/phase0-build-20260930.log`,
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

## Verificación de diseño y limpieza

Revisión independiente de arquitectura, datos/protocolo, tests y CI. Se corrigieron: descripción de ejecución de CI,
identidad federada OIDC, presupuesto GPU único de 13 ms, cálculo de margen de capacidad, disponibilidad de nombres
no verificada y comprobación de códigos de salida de los tests CLI.
Las cifras de escala y rendimiento son propuestas, nunca resultados de carga. Las APIs utilizadas en el cliente
tienen referencias oficiales UE 5.8 y contraste local en `ue58-verification.md`.

## No verificado o no implementado

- Pipeline remoto de GitHub Actions, Linux GCC/Clang y ASan/UBSan: workflow configurado, no ejecutado en esta entrega.
- UE Game target, cooking, packaging, mapas, GPU/performance, navegación y reconciliación.
- PostgreSQL/Redis reales, migraciones aplicadas, TLS/Protobuf, identidad, bots, carga y recuperación.
- Sistemas de gameplay, contenido artístico, administración, despliegue y operación de producción.

**GitHub:** no se creó repositorio remoto. El conector disponible permite trabajar con repositorios pero no ofrece
una operación de creación; el navegador mostró la pantalla de inicio de sesión al intentar abrir el formulario de
repositorio nuevo. No se introdujeron credenciales ni se modificó ningún repositorio remoto. La creación local sí
está completada, sin remoto configurado. Publicación y CI remota quedan pendientes de acceso y nombre definitivo.

La FASE 1 permanece pendiente de validación del usuario. La deuda detallada está en `technical-debt.md`.
