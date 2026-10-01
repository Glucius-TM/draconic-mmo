# FASE 0 — requisitos, evidencia y cierre

Revisión: 2026-10-01. **Cimientos implementados; arquitectura propuesta; aceptación del usuario pendiente.**
Este documento define qué revisar. No certifica una aceptación ni convierte pruebas futuras en ejecutadas.
Los responsables son roles propuestos; no implican que exista un equipo contratado.

## Dos condiciones de cierre distintas

1. **Entrega técnica:** fuentes reproducibles, pruebas de los cimientos, documentación consistente, procedencia y
   deuda explícitas. Cada verificación aporta commit, entorno, comando y resultado. CI se acredita por URL/run/commit;
   tener un workflow no acredita su ejecución. Una limitación sin resolver conserva estado NO VERIFICADO.
2. **Validación de diseño:** el usuario acepta o corrige las opciones necesarias y autoriza el alcance siguiente.
   El autor no se concede esta aprobación. Publicar el repositorio tampoco abre FASE 1.

La entrega técnica puede revisarse aunque existan pendientes declarados. Para dar por cerrada la fase se deben
resolver sus bloqueos o acordar expresamente cuáles se trasladan, con responsable y criterio de cierre.

## Matriz de trazabilidad

La evidencia efectiva y sus limitaciones se consultan en [phase0-evidence.md](phase0-evidence.md); no se duplican aquí
recuentos que puedan quedar obsoletos. Las filas de diseño verifican la existencia de una propuesta, no su funcionamiento.

| ID / requisito | Entregable y estado | Responsable de cierre | Evidencia o prueba exigida |
| --- | --- | --- | --- |
| P00-01 / repositorio autónomo y reglas | IMPLEMENTADO: `AGENTS.md`, estructura y procedencia | Mantenimiento | Historial propio; revisión de archivos versionados y exclusión de secretos, binarios y contenido ajeno; [provenance.md](provenance.md) |
| P00-02 / C++20 + CMake | IMPLEMENTADO; evidencia local registrada | Ingeniería servidor | Configurar desde checkout limpio, Debug/Release, CTest y retorno distinto de cero ante fallos; [build-and-test.md](build-and-test.md) |
| P00-03 / pruebas negativas de cimientos | IMPLEMENTADO; alcance offline | Ingeniería servidor / QA | Configuración inválida, límites, CLI, errores de lectura y salida JSON; evidencia de rechazo sin filtrar valores sensibles |
| P00-04 / cliente UE 5.8 C++ | IMPLEMENTADO; build Editor/test registrados | Ingeniería cliente | UBT + prueba propia con informe fresco; API oficial y headers en [ue58-verification.md](ue58-verification.md); no acredita packaging ni render |
| P00-05 / CI automatizada | IMPLEMENTADO como configuración; ejecución según evidencia | Mantenimiento / QA | Runs vinculados al commit para cada plataforma/configuración anunciada; una fila pendiente no se presenta como aprobada |
| P00-06 / módulos, dependencias y autoridad | PROPUESTO | Arquitectura + usuario | [architecture.md](architecture.md) §§2–7; ausencia de dependencia dominio→infraestructura; decisión D02 |
| P00-07 / datos, red y recuperación | PROPUESTO, sin implementación | Arquitectura / seguridad + usuario | [data-and-protocol.md](data-and-protocol.md); límites de confianza OIDC; invariantes A01–A07; decisiones D03/D04/D06/D08 |
| P00-08 / escala, riesgos y estimación | PROPUESTO, sin carga medida | Arquitectura / operación + usuario | Supuestos de población/hardware/densidad y escenarios explícitos; [roadmap.md](roadmap.md); presupuesto y hardware por decidir |
| P00-09 / originalidad y amplitud sistémica | PROPUESTO; contenido definitivo pendiente | Diseño + usuario | Matriz de sistemas en arquitectura; [world-concept.md](world-concept.md); procedencia de futuras incorporaciones; no garantiza disponibilidad comercial de nombres |
| P00-10 / deuda y aprobación entre fases | IMPLEMENTADO como registro; aprobación pendiente | Arquitectura + usuario | [technical-debt.md](technical-debt.md), [decisions.md](decisions.md); mensaje de aceptación identificable y diseño específico validado antes de sistemas grandes |

## Qué no acredita FASE 0

La herramienta offline no abre sesiones ni listeners. El test del módulo UE no demuestra renderizado, streaming,
movimiento, combate o conexión. Las tablas y mensajes propuestos no son migraciones ni un protocolo desplegado.
Miles de concurrentes, exclusión de doble autoridad, seguridad de identidad, restauración y anti-replay necesitan
implementación e integración en sus fases. La matriz A01–A07 define fallos observables para diseñar esas pruebas;
no hay simulación ficticia que sustituya PostgreSQL, transporte, proveedor de identidad ni cliente reales.

Para la siguiente revisión: confirmar D02/D03/D04/D06/D08/D10; después validar contratos detallados de identidad,
sesión, dependencias, framing y migraciones. La petición actual mantiene el trabajo dentro de FASE 0.
