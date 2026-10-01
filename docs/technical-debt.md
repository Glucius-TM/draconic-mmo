# Deuda y riesgos pendientes

FASE 0 no es un release de producción. Esta lista separa carencias de los cimientos de sistemas todavía no autorizados.
Prioridad: P0 bloquea exposición o integridad; P1 bloquea el siguiente hito; P2 limita mantenibilidad/escala.

| ID | Prioridad / tipo | Pendiente y riesgo | Cierre verificable |
|---|---|---|---|
| F00 | P1 — decisión | arquitectura y decisiones D02–D10 propuestas | validación explícita del usuario antes de FASE 1 |
| F01 | P1 — CI, cierre parcial | bootstrap remoto Windows/Linux/sanitizers aprobado; validar ejecución de esta mejora | workflow de la mejora ejecutado con resultados de cada job; ver `phase0-evidence.md` |
| F02 | P1 — cliente | CI del motor UE y packaging no preparados; verificador local implementado y ejecutado | runner licenciado aislado, ejecución de código confiable, test con informe, build/cook del primer contenido |
| F03 | P1 — dependencia | versiones, hashes, licencias TLS/Protobuf/SQL/Redis por seleccionar | matriz aprobada, lock y SBOM reproducibles |
| F04 | P1 — producto | título, canon, alcance del slice y PC objetivo por elegir | brief aprobado con presupuesto y métricas |
| F05 | P2 — herramientas | configuración ASCII offline mínima, sin esquema de servicios completo | diseño de configuración de FASE 1; no aceptar secretos por logs/CLI |
| F06 | P2 — compatibilidad | guía Iris y notas 5.8 difieren en estado | reevaluación exacta si se decide usarlo; actualmente no es dependencia |
| F07 | P2 — diagnóstico del motor | tests internos UE mostraron 14 errores con localización inicial; la repetición en inglés pasó sin errores | mantener cultura explícita en pruebas; no atribuir corregido el motor ni cada aserción inicial sin evidencia adicional; ver `ue58-verification.md` |
| F08 | P2 — reproducibilidad | imágenes CI hospedadas y SDK/compiladores pueden cambiar aunque las acciones estén fijadas | toolchain e imagen fijados por versión/digest, SBOM y rebuild comprobado; no prometer identidad binaria hoy |
| F09 | P2 — distribución | instalación de desarrollo comprobada, redistribuibles y máquina limpia sin verificar | paquete probado en host limpio con runtimes explícitos; no requiere desplegar servicios en FASE 0 |
| S01 | P0 — sistema futuro | red, identidad, TLS, anti-replay y cuotas no implementados | diseño aprobado, amenazas y pruebas reales negativas antes de abrir puertos |
| S02 | P0 — sistema futuro | persistencia, migraciones, backup/restore, fencing ausentes | DB real, caídas/transferencias inyectadas, restore demostrado |
| S03 | P0 — sistema futuro | ledger/idempotencia, inventario y economía ausentes | carreras, commit ambiguo, doble entrega y conciliación con tests reales |
| S04 | P1 — sistema futuro | representación de colisión común cliente/servidor | pipeline bake versionado y trayectorias contra ambos motores |
| S05 | P1 — sistema futuro | gameplay/sistemas amplios solo diseñados | fases específicas y aceptación; nunca marcar completos por tener diagramas |
| S06 | P1 — arte | sin assets/rig/animaciones/mundo original | producción artística, procedencia y perfiles en hardware objetivo |
| S07 | P1 — escala | 3.000/reino y budgets CPU/red no medidos | bots distribuidos + clientes reales, escenarios densos y soak |
| S08 | P1 — operación | secretos, DDoS, observabilidad, administración, moderación y alertas | infraestructura y runbooks, ejercicios de incidentes, límites de coste |
| S09 | P1 — seguridad | superficie administrativa futura y revisión externa | RBAC/capacidades, MFA, auditoría y revisión antes de operación pública |
| S10 | P2 — release | licencia del código propio y nombre comercial por decidir | decisión del titular y revisión de procedencia antes de distribución |

Esta fase no instala servicios, compra hardware ni promete una fecha de lanzamiento. Las estimaciones y supuestos
de equipo están en `roadmap.md`. Los estados de pruebas concretos se registran en `phase0-evidence.md`.
