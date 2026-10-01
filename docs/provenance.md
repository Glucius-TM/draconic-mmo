# Procedencia, dependencias y originalidad

FASE 0 escrita desde cero para este repositorio. No importa código, assets, esquemas ni datos de otros juegos.
El servidor foundation solo utiliza la biblioteca estándar C++ y CMake/CTest. El cliente referencia el motor UE
instalado por el usuario; el motor no se redistribuye ni se incorpora al repositorio.

AzerothCore se consultó únicamente como referencia conceptual de separación entre identidad y simulación de mundo
en su [guía de ejecución de procesos](https://www.azerothcore.org/wiki/run-worldserver-and-authserver-in-visual-studio).
No se descargó su código, base de datos, tablas, scripts ni assets. No se porta ningún comportamiento de su protocolo.
Se respeta la prohibición del usuario independientemente de cualquier interpretación de licencia.

| Componente | Uso actual | Procedencia / estado |
|---|---|---|
| Código foundation y módulo cliente | fuente original de FASE 0 | licencia del proyecto pendiente del titular |
| UE 5.8.3 | dependencia local del build cliente | instalación Epic del usuario; no vendorizada |
| CMake/CTest | build/test | herramienta instalada; licencia oficial del proveedor |
| MSVC / SDK de Windows | compilación Windows | toolchain local Microsoft; no vendorizada |
| PowerShell ≥7.2 / .NET incluido | herramientas originales de verificación UE | runtime instalado; no vendorizado |
| actions/checkout v7.0.1 | checkout en CI | repositorio oficial, commit `3d3c42e5aac5ba805825da76410c181273ba90b1`, MIT |
| actions/upload-artifact v7.0.1 | evidencia de pruebas en CI | repositorio oficial, commit `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a`, MIT |
| Blender 5.2.2 LTS | disponible; no utilizado para crear contenido en FASE 0 | instalación local; ningún asset importado |
| PostgreSQL / Redis | arquitectura propuesta | no incorporados; fijar versiones, licencias y hashes en FASE 1 |
| Protobuf / proveedor TLS / OIDC | arquitectura propuesta | no incorporados; evaluar versiones y compatibilidad antes de programar |

Para cada dependencia futura: nombre, origen oficial, versión exacta, digest, licencia, avisos requeridos, consumidor,
responsable de actualizaciones, SBOM y política de vulnerabilidades. Verificar licencias con el texto oficial de la
versión elegida; no asumir que todas las versiones de un producto tienen los mismos términos.
No se añade licencia open source por defecto ni se afirma autorización de terceros sin evidencia.
Las acciones se consumen desde [actions/checkout](https://github.com/actions/checkout/tree/v7.0.1) y
[actions/upload-artifact](https://github.com/actions/upload-artifact/tree/v7.0.1); no se copia su fuente al proyecto.
Los compiladores y paquetes de las imágenes hospedadas de CI no son un entorno hermético: sus versiones quedan en
los logs de cada ejecución. Fijar una imagen/toolchain por digest sigue pendiente antes de prometer reproducibilidad
binaria; los presets y commits de acciones fijados solo ofrecen reproducibilidad del procedimiento.

Cada asset futuro necesita autor/origen, derechos de uso/distribución, archivo fuente, versión, hash, herramienta,
unidad/escala y derivaciones. No reutilizar nombres, personajes, zonas, iconos, siluetas reconocibles ni interfaces
de otra franquicia. Los nombres de ficción en `world-concept.md` son propuestas sujetas a validación; su disponibilidad
marcaria no está verificada.
