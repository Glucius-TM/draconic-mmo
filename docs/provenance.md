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
| Blender 5.2.2 LTS | disponible; no utilizado para crear contenido en FASE 0 | instalación local; ningún asset importado |
| PostgreSQL / Redis | arquitectura propuesta | no incorporados; fijar versiones, licencias y hashes en FASE 1 |
| Protobuf / proveedor TLS / OIDC | arquitectura propuesta | no incorporados; evaluar versiones y compatibilidad antes de programar |

Para cada dependencia futura: nombre, origen oficial, versión exacta, digest, licencia, avisos requeridos, consumidor,
responsable de actualizaciones, SBOM y política de vulnerabilidades. Verificar licencias con el texto oficial de la
versión elegida; no asumir que todas las versiones de un producto tienen los mismos términos.
No se añade licencia open source por defecto ni se afirma autorización de terceros sin evidencia.

Cada asset futuro necesita autor/origen, derechos de uso/distribución, archivo fuente, versión, hash, herramienta,
unidad/escala y derivaciones. No reutilizar nombres, personajes, zonas, iconos, siluetas reconocibles ni interfaces
de otra franquicia. Los nombres de ficción en `world-concept.md` son propuestas sujetas a validación; su disponibilidad
marcaria no está verificada.
