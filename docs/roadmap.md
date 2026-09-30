# Fases, validación y estimaciones

**Solo FASE 0 autorizada.** Cada fila requiere confirmación del usuario al cerrar la anterior y diseño específico
aprobado antes de implementar sistemas grandes. No interpretar la lista como orden de ejecución automática.

| Fase | Entregable | Criterio de salida y evidencia | Estimación orientativa |
|---|---|---|---|
| 0 | arquitectura, repo limpio, build C++/UE, CI y pruebas de cimientos | builds locales, tests reales, límites explícitos, revisión de decisiones | 3–7 días de ingeniería para endurecer/revisar, además del bootstrap inicial |
| 1 | identidad elegida, primer gateway TLS, contratos, DB/Redis, migraciones, login a mundo vacío | cliente UE y bot conectan; rechazo de token/frame/replay; reconexión; migración y rollback compatible | 4–8 semanas |
| 2 | personaje durable, zona gris de pruebas internas, movimiento/colisión/interés/reconciliación | 50 bots, pérdida/latencia inyectadas, transferencia entre 2 zonas y caída del dueño sin doble escritor | 6–10 semanas |
| 3 | combate, atributos, primera disciplina/talentos, auras/threat y NPC | determinismo de reglas, 2 clientes reales, edge cases simultáneos, profiling del tick | 6–10 semanas |
| 4 | misiones, loot, inventario, progresión y contenido del slice | loop 20–30 min, reconexión conserva progreso, recompensas únicas bajo retries/fallos | 6–10 semanas |
| 5 | grupo/chat, instancia cooperativa, encuentro por fases, herramientas GM básicas | 3–5 jugadores, reset/abandono/lockout, permisos y auditoría, bot soak 8h | 6–10 semanas |
| 6 | profesiones, comercio/subastas, hermandades, PvP y expansión progresiva | transacciones concurrentes/fallos, abuso económico, moderation y restauración ensayadas | 4–8 meses por oleadas de sistemas |
| 7 | raids, battlegrounds, mundo ampliado, operación/release | 3.000 bots en reino distribuido, soak 24–72h, cliente en hardware objetivo, failover y auditoría | 6–12+ meses; contenido continúa |

Estimaciones propias, no cotización ni promesa. Asumen un equipo núcleo de 4–6 personas técnicas experimentadas,
diseño/QA y artistas en paralelo, infraestructura disponible y alcance congelado por fase. No se suman ciegamente:
integración, contenido y validación tienen dependencias. Un slice convincente y operable es razonablemente un programa
de **6–12 meses** con ese equipo; profundidad comercial completa supone **varios años**, más personas y operación continua.
Una persona no puede sustituir ese equipo solo con generación automática de código.

## Recursos que no proporciona esta fase

- Arte original: anatomía/rig dracónico, animaciones, locomoción, ropa compatible, arquitectura, iconos, audio y VFX.
- Hardware de QA representativo y generadores de carga separados del cliente/editor. El equipo local observado tiene
  16 GiB aproximados y CPU portátil de 4 núcleos: sirve para cimientos, no para validar miles de concurrentes.
- Entornos de staging/producción, dominio, certificados, identidad, protección DDoS, backups y observabilidad.
- Operación de cuentas/moderación/soporte, localización, accesibilidad y procedimientos de incidentes.
- Presupuesto de infraestructura y equipo: se calcula tras elegir región, disponibilidad, precios verificados y
  medir bytes/CPU por jugador. No se inventa un coste mensual con datos ausentes.

## Plan concreto propuesto para FASE 1 (a validar)

1. Documento de identidad y lifecycle de sesión, proveedor elegido, threat model y criterios de rechazo.
2. Fijar licencias/versiones/hashes de TLS, Protobuf, cliente PostgreSQL, Redis y gestor de dependencias.
3. Documento de framing/negociación y límites definitivos; contratos generados con compatibilidad comprobable.
4. Migraciones reales mínimas cuenta/realm/sesión/recibo; DB vacía y upgrade desde versión previa en CI.
5. Gateway real, handshake y mundo vacío; sin combate ni código que simule un login exitoso.
6. Cliente UE conecta mediante C++; integración con PostgreSQL/Redis reales y fallo de dependencias.
7. Evidencia, auditoría de logs, carga pequeña reproducible y deuda antes de solicitar FASE 2.

La existencia de la propuesta no autoriza instalar/provisionar servicios de pago ni aceptar políticas en nombre del usuario.
