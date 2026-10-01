# MMORPG dracónico — FASE 0

Repositorio limpio e independiente, creado desde cero. `draconic-mmo` es un identificador técnico provisional;
el título del juego está pendiente. Cliente **Unreal Engine 5.8 C++**, servidor **C++20** propio.

**Esta entrega contiene cimientos compilables y un diseño para revisión. No contiene gameplay ni un servidor online.**
La siguiente fase requiere confirmación explícita del usuario.

## Empezar por aquí

- [Arquitectura propuesta](docs/architecture.md): diagramas, módulos, dependencias, mundo, escala y operación.
- [Datos y protocolo](docs/data-and-protocol.md): esquema lógico, autoridad, transacciones, anti-replay y migraciones.
- [Decisiones y alternativas](docs/decisions.md): recomendaciones que se deben validar.
- [Compilar y probar](docs/build-and-test.md): comandos reproducibles y alcance de las pruebas.
- [Evidencia de FASE 0](docs/phase0-evidence.md): qué se ejecutó y qué continúa sin verificar.
- [Criterios de aceptación](docs/phase0-acceptance.md): requisitos, responsables y puertas de cierre.
- [Deuda técnica](docs/technical-debt.md), [fases y estimaciones](docs/roadmap.md),
  [concepto original del mundo](docs/world-concept.md), [procedencia](docs/provenance.md).

## Estructura efectiva

```text
AGENTS.md                   reglas de C++/UE, autoridad y puertas entre fases
CMakeLists.txt              build de servidor, sin dependencia de Unreal
CMakePresets.json           Windows/Linux, Debug/Release y sanitizers Linux
cmake/                      política de compilación e instalación comprobada
server/include/draconic/    contratos del validador offline
server/src/                 parser acotado, JSON y herramienta de diagnóstico
server/config/              configuración de ejemplo sin secretos
tests/                      pruebas del foundation y del comportamiento del ejecutable
tests/tooling/              pruebas negativas del verificador de informes UE
tools/unreal/               build y verificación reproducible del cliente instalado
client/                     proyecto C++ UE 5.8 y prueba de carga del módulo
docs/                       diseño, decisiones, evidencia, fases y deuda
.github/workflows/          CI de servidor, instalación y herramientas de verificación
```

Las futuras carpetas de red, migraciones, contenido, servicios e infraestructura se crearán con implementaciones
reales y diseño aprobado; no se añaden árboles vacíos para aparentar sistemas existentes.

## Build rápido del servidor en Windows

Desde la raíz de este repositorio, con CMake ≥3.24 y Visual Studio 2022 con compilador C++/SDK:

```powershell
cmake --preset windows-msvc
cmake --build --preset windows-debug
ctest --preset windows-debug
cmake --build --preset windows-release
ctest --preset windows-release
```

El cliente se compila mediante UBT, de forma independiente. Con PowerShell 7.2 o posterior:

```powershell
pwsh -NoProfile -File ./tools/unreal/verify.ps1 -EngineRoot 'C:/Program Files/Epic Games/UE_5.8'
```

El verificador comprueba la versión 5.8.3, compila el Editor y exige un informe nuevo del test exacto,
sin errores de automatización, incluidos los de arranque del motor. Conserva logs y devuelve fallo si la
prueba no se ejecutó. Su prueba headless verifica carga del módulo; no mide renderizado ni demuestra conectividad.
Consultar [instrucciones y límites del cliente](client/README.md).

El foundation tiene **20 pruebas CTest** (unitaria, CLI e instalación), ejecutadas en Debug/Release.
Las pruebas de las herramientas UE usan informes sintéticos y procesos reales: **no sustituyen la ejecución del motor**.
Los resultados concretos y enlaces de CI están en [la evidencia](docs/phase0-evidence.md).

PostgreSQL, Redis, TLS y Protobuf están especificados como diseño futuro, no instalados ni simulados por la herramienta.
No se ha elegido licencia para distribuir el código propio. No se incluye código, contenido ni assets de terceros juegos.
