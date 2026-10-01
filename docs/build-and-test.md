# Compilación y pruebas

Ejecutar desde la raíz `draconic-mmo`. El build del servidor no depende de Unreal, Blender, PostgreSQL ni Redis en
FASE 0. Los presets no descargan dependencias. CMake ≥3.24; generador Visual Studio 2022 en Windows o Ninja y
compilador C++20 en Linux. Es posible que Visual Studio esté instalado sin el workload C++; el configure debe detectar
un compilador real, no basta con encontrar el instalador.

## Servidor — Windows

```powershell
cmake --preset windows-msvc
if ($LASTEXITCODE -ne 0) { throw 'Configure falló' }
cmake --build --preset windows-debug
if ($LASTEXITCODE -ne 0) { throw 'Build Debug falló' }
ctest --preset windows-debug
if ($LASTEXITCODE -ne 0) { throw 'Tests Debug fallaron' }
cmake --build --preset windows-release
if ($LASTEXITCODE -ne 0) { throw 'Build Release falló' }
ctest --preset windows-release
if ($LASTEXITCODE -ne 0) { throw 'Tests Release fallaron' }
```

Los directorios de salida viven bajo `.build/windows-msvc`. El compilador trata warnings del proyecto como errores.
Las pruebas no dependen de `assert`, de modo que Release también comprueba contratos. No configurar con `-B .`:
el proyecto rechaza compilaciones dentro del árbol fuente. En máquinas de memoria limitada añadir `--parallel 2` al build.

## Servidor — Linux / CI

```sh
cmake --preset linux-debug
cmake --build --preset linux-debug
ctest --preset linux-debug

cmake --preset linux-release
cmake --build --preset linux-release
ctest --preset linux-release

cmake --preset linux-sanitize
cmake --build --preset linux-sanitize
ctest --preset linux-sanitize
```

Ejecutar secuencialmente y detenerse si falla cualquier comando. Para comparar GCC y Clang, usar árboles de build
distintos; la matriz CI usa máquinas independientes. No cambiar el compilador sobre una caché ya configurada.
Sanitizers ASan/UBSan se reservan a compiladores compatibles; UBSan detiene la ejecución ante comportamiento indefinido.
El workflow fija también `ASAN_OPTIONS=detect_leaks=1:halt_on_error=1` y
`UBSAN_OPTIONS=halt_on_error=1:print_stacktrace=1`. Los resultados locales y remotos se distinguen por commit y
ejecución en [phase0-evidence.md](phase0-evidence.md).

## Instalación comprobada

CTest incluye `foundation.install`: instala el ejecutable y su ejemplo en un staging del propio build y ejecuta
los archivos instalados. Antes retira únicamente esos dos artefactos para que una instalación incompleta no pase
por usar archivos antiguos. El script rechaza un staging ajeno al directorio de build y rutas que escapen de él.
La instalación no incluye herramientas de desarrollo ni la biblioteca interna como SDK público.

Para comprobar además que el producto no depende de compilar sus tests, en PowerShell:

```powershell
cmake -S . -B .build/windows-no-tests -G 'Visual Studio 17 2022' -A x64 '-DBUILD_TESTING=OFF'
if ($LASTEXITCODE -ne 0) { throw 'Configure falló' }
cmake --build .build/windows-no-tests --config Release --parallel 2
if ($LASTEXITCODE -ne 0) { throw 'Build falló' }
$taskBuildPath = (Resolve-Path '.build/windows-no-tests').Path.Replace('\', '/')
cmake "-DBUILD_DIR=$taskBuildPath" "-DINSTALL_PREFIX=$taskBuildPath/stage" `
  '-DINSTALL_BINDIR=bin' '-DINSTALL_DATADIR=share' '-DEXECUTABLE_SUFFIX=.exe' `
  '-DCONFIG=Release' '-DEXPECTED_VERSION=0.1.0' -P cmake/CheckInstall.cmake
if ($LASTEXITCODE -ne 0) { throw 'Instalación o ejecución falló' }
```

En Linux: configurar un directorio distinto con `-G Ninja -DBUILD_TESTING=OFF -DCMAKE_BUILD_TYPE=Release`, compilarlo
y pasar sus rutas absolutas al mismo script; omitir `EXECUTABLE_SUFFIX`. Citar todos los argumentos `-D` en PowerShell.
Esta prueba verifica una instalación de desarrollo. No acredita un paquete redistribuible en una máquina limpia,
ni instala el runtime de MSVC, un servicio del sistema o componentes de red.

## Qué comprueba la herramienta offline

`draconic_foundation check-config <archivo>` acepta un archivo pequeño `clave=valor` y valida campos obligatorios,
duplicados/desconocidos, caracteres, tamaño y límites numéricos. Sus campos son configuración de proceso propuesta;
no representan reinos/shards provisionados. `--help` describe uso y códigos de salida; `--version` informa la versión.

Ejemplo de formato:

```ini
instance_name=local-zone-01
realm_id=1
shard_id=1
log_level=info
```

El resultado válido declara `mode=offline_validation` y `services_started=0`. No abre sockets ni comprueba acceso
a bases de datos. El validador no es el parser de red ni una prueba de seguridad de un servicio online.
Pruebas: límites, entradas malformadas, duplicación de claves, valores no canónicos, JSON escapado y errores del CLI.
Se prueban archivos de 16 KiB exactos y superiores al límite, líneas de 256 bytes y superiores, CRLF, rechazo de BOM y
caracteres de control, números de línea del error y rutas con espacios/Unicode. El contenido de configuración sigue
siendo ASCII por diseño; la ruta del archivo puede ser Unicode.
El catálogo concreto y los resultados ejecutados están en `phase0-evidence.md`.

## Cliente — Unreal Build Tool

Seguir [client/README.md](../client/README.md). El comando reproducible desde la raíz, con PowerShell ≥7.2, es:

```powershell
pwsh -NoProfile -File ./tools/unreal/verify.ps1 -EngineRoot 'C:/Program Files/Epic Games/UE_5.8'
```

Ejecuta build `DraconicClientEditor Win64 Development` con UE 5.8.3 y smoke test
`Draconic.Foundation.ClientModuleLoaded` en `UnrealEditor-Cmd` con `-nullrhi`.
El comando documentado fija cultura inglesa solo para ese proceso y evita escribir configuración durante la prueba;
no cambia las preferencias del editor del usuario. No incorporar archivos de configuración autogenerados con tokens.
El script exige el resultado del test en un directorio de informe nuevo, verifica sus contadores y el log de arranque,
acota la duración de los procesos y conserva evidencia bajo `.build/unreal/`. Salida cero por sí sola no demuestra un
test ejecutado. Para probar el propio verificador, sin tener Unreal instalado:

```powershell
pwsh -NoProfile -NonInteractive -File ./tests/tooling/test-unreal-validation.ps1
```

Esos casos negativos usan informes sintéticos; no constituyen evidencia de build ni ejecución de Unreal.
Las APIs usadas y su documentación oficial están en [ue58-verification.md](ue58-verification.md).

No hay mapas ni contenido para cocinar en esta fase. Packaging, Game target y plataformas adicionales siguen sin
verificar salvo evidencia expresa. El test headless no acredita FPS, memoria GPU, shaders ni calidad visual.

## CI y puertas futuras

El workflow hace configure/build/CTest con GCC y Clang en Linux, MSVC en Windows, sanitizers Linux, instalación con
`BUILD_TESTING=OFF` en ambos sistemas y tests del verificador UE sin motor. Los jobs CTest guardan JUnit y LastTest.log
durante 14 días, incluso ante fallos; los casos de tooling conservan sus informes sintéticos. Los registros del job
recogen configure/build y la instalación independiente. No se suben directorios completos de build ni secretos.
No requiere credenciales de producción y las acciones están fijadas a commits concretos.

El cliente necesita un runner con motor UE 5.8.3 y licencias válidas para CI del motor; no existe tal job todavía.
En un repositorio público un runner propio no debe ejecutar código de PR no confiable. Su diseño deberá restringir
los disparadores, aislar el host y proteger las credenciales antes de habilitarlo. La herramienta local ya proporciona
el contrato de verificación; antes de integrar gameplay debe usarse también en la CI segura del cliente.

PostgreSQL/Redis, migraciones, TLS, bots y carga se incorporarán junto a su implementación tras aprobación.
No presentar mocks de esos sistemas como evidencia de integración. Cambios sensibles requerirán fallos inyectados,
fuzzing y recuperación; consultar `data-and-protocol.md` y `technical-debt.md`.
