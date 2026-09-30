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
- [Deuda técnica](docs/technical-debt.md), [fases y estimaciones](docs/roadmap.md),
  [concepto original del mundo](docs/world-concept.md), [procedencia](docs/provenance.md).

## Estructura efectiva

```text
AGENTS.md                   reglas de C++/UE, autoridad y puertas entre fases
CMakeLists.txt              build de servidor, sin dependencia de Unreal
CMakePresets.json           Windows/Linux, Debug/Release y sanitizers Linux
cmake/                      política de compilación
server/include/draconic/    contratos del validador offline
server/src/                 parser acotado, JSON y herramienta de diagnóstico
server/config/              configuración de ejemplo sin secretos
tests/                      pruebas del foundation y del comportamiento del ejecutable
client/                     proyecto C++ UE 5.8 y prueba de carga del módulo
docs/                       diseño, decisiones, evidencia, fases y deuda
.github/workflows/          CI del servidor
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

El cliente se compila mediante UBT, de forma independiente: [instrucciones del cliente](client/README.md).
Su prueba headless verifica carga del módulo; no mide renderizado ni demuestra conectividad.

PostgreSQL, Redis, TLS y Protobuf están especificados como diseño futuro, no instalados ni simulados por la herramienta.
No se ha elegido licencia para distribuir el código propio. No se incluye código, contenido ni assets de terceros juegos.
