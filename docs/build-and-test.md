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
Las pruebas no dependen de `assert`, de modo que Release también comprueba contratos.

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

Ejecutar secuencialmente y detenerse si falla cualquier comando. Sanitizers ASan/UBSan se reservan a compiladores
compatibles; su preset no prueba nada hasta ejecutarse. La evidencia local de esta entrega es Windows; CI y Linux
deben distinguirse de esa evidencia hasta disponer de resultados de ejecución.

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
El catálogo concreto y los resultados ejecutados están en `phase0-evidence.md`.

## Cliente — Unreal Build Tool

Seguir [client/README.md](../client/README.md): build `DraconicClientEditor Win64 Development` con UE 5.8.3 y
smoke test `Draconic.Foundation.ClientModuleLoaded` en `UnrealEditor-Cmd` con `-nullrhi`.
El comando documentado fija cultura inglesa solo para ese proceso y evita escribir configuración durante la prueba;
no cambia las preferencias del editor del usuario. No incorporar archivos de configuración autogenerados con tokens.
Verificar el resultado del test en un directorio de informe nuevo; salida cero por sí sola no demuestra un test ejecutado.
Las APIs usadas y su documentación oficial están en [ue58-verification.md](ue58-verification.md).

No hay mapas ni contenido para cocinar en esta fase. Packaging, Game target y plataformas adicionales siguen sin
verificar salvo evidencia expresa. El test headless no acredita FPS, memoria GPU, shaders ni calidad visual.

## CI y puertas futuras

El workflow del servidor hace configure/build/CTest Windows y Linux y sanitizers Linux. No requiere credenciales de
producción. El cliente necesita un runner propio con motor UE 5.8.3 y licencias válidas; no se crea un job que pase
omitiendo silenciosamente el motor. Antes de integrar gameplay, habilitar esa ejecución y verificar sus informes.

PostgreSQL/Redis, migraciones, TLS, bots y carga se incorporarán junto a su implementación tras aprobación.
No presentar mocks de esos sistemas como evidencia de integración. Cambios sensibles requerirán fallos inyectados,
fuzzing y recuperación; consultar `data-and-protocol.md` y `technical-debt.md`.
