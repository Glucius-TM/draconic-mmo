# MMORPG dracónico — propuesta de arquitectura

Revisión: 2026-10-01. **FASE 0. Estado: PROPUESTO, pendiente de validación.**
`draconic-mmo` es un identificador técnico provisional, no el título comercial.
Repositorio nuevo y autónomo. No importa código, datos ni diseños de otros proyectos del usuario.

## 1. Objetivo y límite de esta entrega

Mundo abierto original de dragones humanoides: progresión profunda, combate táctico, economía persistente,
cooperación y conflicto. Cliente UE 5.8 en C++, servidor propio C++20, PostgreSQL y Redis.
El objetivo de miles de jugadores es **por reino distribuido**, no miles de actores en una única simulación o pantalla.
La referencia de profundidad sirve para detectar responsabilidades; no define fórmulas, tablas, protocolo ni contenido.

FASE 0 implementa únicamente build, herramientas de diagnóstico offline y proyecto UE mínimo. No hay aún
autenticación, sockets, persistencia ni gameplay. Los bloques siguientes son destino arquitectónico, no servicios
existentes. Véase la evidencia real en [phase0-evidence.md](phase0-evidence.md) y el criterio de cierre en
[phase0-acceptance.md](phase0-acceptance.md). Compilar los cimientos no valida el diseño de los sistemas futuros.

## 2. Topología propuesta

```text
                         INTERNET / cliente no confiable
                  [Cliente UE C++ + UI + presentación]
                          |                 |
                    HTTPS/TLS 1.3      protocolo propio/TLS 1.3
                          |                 |
                     [Identidad]       [Gateway de sesión] x N
                          |                 | sesión/epoch autenticados
                          +-----[Directorio de reinos]----+
                                            |
                        red privada, mTLS e identidad de servicio
                                            |
                         [Coordinador de reino / asignación]
                          |               |               |
                   [Zona A, shard 1] [Zona A, shard 2] [Instancia PvE/PvP]
                          |               |               |
                          +------ comandos durables ------+
                                            |
                       [Servicios de reino, proceso modular inicial]
                      personajes | economía | grupos | chat | administración
                            |                  |
                    [PostgreSQL]         [Redis efímero]
                            |
                      outbox / auditoría / recuperación

               Telemetría: métricas + trazas + logs estructurados
```

**Despliegue inicial recomendado:** identidad y gateway separados como límites de exposición; un proceso de mundo
por zona/instancia; servicios de reino agrupados en un ejecutable modular. PostgreSQL y Redis son servicios reales
externos. No un microservicio por sistema desde el primer día. Se propone que FASE 1 arranque con un único mundo
vacío y un único reino, después de validar su diseño. Chat, subastas y grupos solo se extraen a procesos
independientes por carga, aislamiento o equipos. El bloque de identidad integra un proveedor OIDC por elegir;
las credenciales del proveedor no pertenecen al servidor del juego.

Terminología propia: reino = población/economía persistente; zona = partición geográfica de simulación;
shard = copia de una zona; instancia = sesión privada de actividad; celda de interés = vecindario visible.
La célula World Partition del cliente no es automáticamente una zona del servidor.

## 3. Límites y dependencias

Flechas de **dependencia de código**: `A -> B` significa que A puede importar B; no indica el recorrido de mensajes.

```text
apps -> application, adapters                 (composición de implementaciones)
adapters -> application/ports, domain         (TLS, SQL, Redis implementan puertos)
application -> application/ports, domain      (casos de uso y límites transaccionales)
application/ports -> domain, foundation       (contratos con tipos propios)
domain -> foundation                         (reglas puras; sin puertos de infraestructura)
foundation -> biblioteca estándar C++
transport adapter -> protocol-generated      (tipos generados terminan en el adaptador)

Flujo de datos separado:
bytes -> adapter/parser -> comando propio validado -> application -> domain
```

Domain nunca incluye headers UE, SQL, sockets ni mensajes generados. Los contratos de salida viven en application;
los adaptadores concretos se inyectan al componer el ejecutable. El cliente depende del contrato público a través
de su transporte; no enlaza los módulos de dominio del servidor. Servidor independiente de Unreal Build Tool.
No se comparte implementación de combate con el cliente: solo contratos públicos y predicción de movimiento cuando
su diseño esté aprobado. Ningún catálogo privado de loot, IA o control administrativo se exporta al cliente.
Separar estado persistente, definiciones de contenido inmutables versionadas y estado temporal de simulación.

| Módulo futuro | Propiedad de datos / responsabilidad | Dependencias permitidas |
|---|---|---|
| identity | vínculo issuer/subject con cuenta local, elegibilidad, revocación y sesiones de juego | proveedor OIDC, PostgreSQL de identidad, límites de admisión; credenciales locales solo si se aprueba esa alternativa |
| gateway | conexiones, límites, rutas, epochs de sesión | identidad, coordinador, transporte interno |
| realm | elegibilidad y directorio de reinos | identity, catálogo de reinos |
| character | creación, nombres, progresión durable | PostgreSQL; recibe resultados autorizados de mundo |
| world | tick, movimiento, entidades, combate, interés | definiciones, navegación, puertos durables |
| economy | inventario, moneda, comercio, subastas, correo de entregas | PostgreSQL transaccional, outbox |
| social | grupos, hermandades, invitaciones, presencia | PostgreSQL para membresía, Redis para presencia |
| chat | canales, permisos, moderación, silencios | social, identity; límites propios |
| instances | asignación, admisión, recuperación, lockouts | realm, social, world |
| operations | capacidades GM, auditoría, métricas, herramientas | APIs administrativas privadas |

Los puertos son contratos de diseño, no interfaces vacías creadas en FASE 0.

## 4. Simulación y movimiento

Propuesta inicial: tick fijo de **20 Hz (50 ms)**, input a 20 Hz y snapshots 10 Hz; medir antes de consolidar.
Una cola de comandos acotada por zona; un único escritor lógico por entidad. Lecturas paralelizables mediante
snapshots inmutables. Workers auxiliares resuelven navegación/I/O sin modificar entidades fuera del tick.
El servidor ordena comandos por tick, sesión y secuencia aceptada; fija máximos por cliente y frame.
Sobrecarga: rechazar admisiones y reducir frecuencia de datos cosméticos antes de atrasar simulación sin límite.
Pausar/rechazar operaciones durables si sus colas se saturan. No acumular ticks infinitos para ponerse al día.

El cliente envía intención, dirección y secuencia; nunca posición final, velocidad autorizada ni resultado de impacto.
Autoridad valida estado, límites temporales, pendientes, colisiones, modo de locomoción y permisos.
Snapshots incluyen tick servidor y último input procesado. El cliente corrige a ese estado, reejecuta inputs pendientes
y suaviza solo la representación visual. Entidades remotas usan interpolación acotada, sin extrapolación ilimitada.
Teletransportes son órdenes del servidor que invalidan el historial anterior de predicción/input. El epoch de autoridad
cambia al transferir o reasignar al propietario, no por un desplazamiento dentro de la misma autoridad. El contrato
de movimiento detallará su propia generación de reinicio. Latencia no concede metros extra ni ataques adicionales.

Riesgo principal: servidor sin Chaos necesita geometría de colisión/navegación propia coherente con el cliente.
Propuesta: exportar offline volúmenes estáticos y malla de navegación con hash/versionado común. No suponer física
determinista entre Unreal y otro motor. Antes de movimiento completo habrá un diseño específico y pruebas de bordes,
escalones, colisiones, cambio de zona, pérdida/reordenación y discrepancias de contenido.

## 5. Combate y amplitud de sistemas (sin implementación)

Kernel de combate del servidor orientado a eventos del tick: validación de acción → reserva de recursos → cast/GCD
→ resolución → efectos → eventos de amenaza/recompensa. Tiempo monotónico y operaciones enteras o punto fijo con
redondeo definido para reglas sensibles. Sin reloj de cliente. No se eligen valores de balance en esta fase.
Definiciones propias versionadas: atributos base, ratings/curvas, requisitos de talentos, efectos y condiciones.
Identidad de instancia separada de plantilla; semilla RNG del servidor y trazas reproducibles en tests, no revelada.

| Familia | Diseño que debe aprobarse antes de programar | Invariantes de aceptación |
|---|---|---|
| cuentas/reinos/personajes | sesión, slots, nombres, selección, bloqueo/revocación | un dueño activo; aislamiento de reino |
| clases/talentos/atributos | recursos, árbol como DAG, coste/respec, orden de modificadores | sin ciclos ni puntos duplicados |
| combate | GCD, cooldowns, cast/channel, alcance/LOS, recursos, muerte | acción rechazada sin gasto; daño solo servidor |
| auras/DoT/HoT/threat | stacking, refresh, dispel, ticks, prioridad de IA | expiración y simultaneidad deterministas |
| loot/inventario | elegibilidad, distribución, contenedores, equipamiento | entrega única; slots y ownership consistentes |
| misiones | objetivos event-driven, ramas, prerequisitos, recompensa | completar/reclamar idempotente |
| profesiones/economía | aprendizaje, recetas, consumo, ledger, subastas | no duplicar materiales ni crear moneda por carrera |
| grupos/hermandades/chat | autoridad, invitaciones, roles, canales, moderación | revocación y privacidad consistentes |
| mazmorras/raids/IA | lifecycle, lockout, fases, reset, evade, telegraphs | transición y recompensas recuperables |
| PvP/battlegrounds | equipos, matchmaking, rating propio, abandono | estado común autoritativo y sin colusión trivial |
| eventos de mundo | calendario UTC, ámbito, concurrencia, rollback | un evento por ID/version sin doble recompensa |
| GM/panel | RBAC por capacidades, motivo, trazas, aprobación sensible | ningún booleano global admin; auditoría durable |

Scripting recomendado inicialmente: datos declarativos y máquinas de estados C++ compiladas con límites de trabajo.
Alternativa Lua/WASM para diseñadores requiere sandbox, cuotas, auditoría y determinismo; pospuesta hasta validar
necesidad. Nada de scripts remotos arbitrarios ni código proporcionado por clientes.

## 6. Cliente y contenido del mundo

Módulos propuestos: ClientShell (lifecycle), Session (cuentas y conexión), NetTransport (I/O y codecs),
Presentation (actores y animación), UI (Slate/UMG C++) y Content (datos públicos). Subsystems de GameInstance para
sesión, World para proyección local del mundo y LocalPlayer para input/UI cuando se implementen y verifiquen sus APIs.

World Partition gestiona streaming visual; el servidor gestiona interés y límites físicos de zonas de forma separada.
El cambio de contenido se verifica con `content_version` antes de entrar. El bake de colisión/navegación comparte
versión con mapa y manifiesto de assets. No cargar todo un continente para conectar a un servidor.

GAS no será autoridad del combate: el servidor externo no ejecuta GameplayAbilities de UE. Recomendación:
estado de habilidades y cooldowns proyectado por C++ propio; Niagara/animación/UI consumen resultados. Evaluar GAS
solo como adaptador de presentación si evita duplicación. Iris no transporta automáticamente el protocolo propio.
Mass se reserva para multitudes cosméticas si el perfil lo justifica. Estado documental 5.8 y APIs concretas en
[ue58-verification.md](ue58-verification.md); ninguna capacidad se presume estable por su nombre.

Presupuesto propuesto para PC objetivo pendiente: 60 fps = 16,67 ms; Game Thread p95 ≤5 ms y GPU p95 ≤13 ms,
no se suman como tareas seriales. Escenario obligatorio de validación: 100 personajes visibles y combate denso.
Empezar 1080p, mallas/animaciones con LOD, reducción por distancia, Niagara con topes y culling de auras lejanas.
Nanite orientado a entorno estático donde convenga; Lumen/VSM con niveles de calidad, distancia y presupuesto de
sombras. No prometer estas cifras en el portátil actual. GPU mínima y fidelidad artística requieren decisión del usuario.
Unreal Insights, capturas GPU y escenarios reproducibles acompañarán cualquier afirmación de rendimiento.

## 7. Persistencia, red y transferencia

Especificación propuesta: [data-and-protocol.md](data-and-protocol.md). PostgreSQL decide derechos durables;
Redis es prescindible para integridad económica. Los estados de sesión/transferencia llevan epoch/fencing;
ni un timeout ni perder una clave Redis autoriza dos escritores. Registro de recibos y outbox en misma transacción
que el cambio económico. No prometer exactly-once de red: entrega reintentable más efecto idempotente.

Inicialmente TLS 1.3/TCP y Protobuf con versión y límites. Comparar QUIC con datagramas mediante pérdida/latencia
antes de movimiento masivo; adoptar librería mantenida, sin inventar cifrado. TLS no sustituye autorización ni
idempotencia de comandos. Deshabilitar 0-RTT para acciones mutantes. Tráfico entre servicios autenticado y privado.

## 8. Escala y disponibilidad

Hipótesis de dimensionado, **no resultados**: reino de 3.000 concurrentes / 150 activos por proceso ≈20 procesos
de zona, más 30% de capacidad adicional ≈26 equivalentes; instancias y picos requieren presupuesto adicional.
No activar ese número de procesos por fórmula: el cuello depende de NPCs, interés, IA, ancho de banda y hardware.
A 20 KiB/s enviados por jugador, 3.000 suponen ≈58,6 MiB/s de payload (≈492 Mbit/s) antes de TLS/TCP, retransmisiones
y tráfico interno. 20 KiB/s es presupuesto provisional que hay que medir, no ancho garantizado.
Los 26 equivalentes suponen distribución equilibrada y capacidad utilizable: no prueban tolerancia a perder un
host, pues varios procesos pueden compartirlo. La concentración en una sola zona puede agotar CPU o interés
aunque el resto del reino esté vacío. La admisión depende de la zona de destino además del total del reino.

Antes de aceptar capacidad se fijarán hardware, builds y contenido; población de NPCs, densidad de jugadores,
frecuencia de acciones y matriz RTT/pérdida. Se proponen cargas separadas de dispersión, concentración en una
zona, reconexión masiva y caída de un host; cada una registrará tick p99, colas, memoria y bytes/s. El umbral
de tick y el margen de recuperación se decidirán antes de medir, sin descartar los intervalos sobrecargados.
Los clientes de carga deberán ejecutarse en máquinas separadas del servidor. En FASE 0 no existe este banco.

Interés espacial mediante grid o estructura equivalente, filtros por fase/instancia y prioridad. En pelea densa,
no replicar cada entidad a todos: topes y niveles de frecuencia. Afinidad de grupo para seleccionar shard;
histeresis y puntos seguros de transferencia evitan mover jugadores cada pocos segundos. Zonas calientes escalan
por copias o división geográfica; jamás dividir una única pelea de forma automática sin diseño específico.

Un nodo PostgreSQL primario por ámbito transaccional al principio, réplica para HA/lecturas no críticas y copias PITR.
Lecturas de saldos/propiedad siempre consistentes. Escalado por reino cuando la evidencia lo exija; evitar
transacciones distribuidas de comercio entre reinos en el slice. Redis con TTL, ACL, límites de memoria y política
de degradación por cada familia de claves. El coordinador valida leases durables, no quorum improvisado de caché.

Fallo de zona: cortar autoridad/ingreso, revocar lease, recuperar checkpoint confirmado y recibos antes de reasignar.
Movimiento reciente puede perderse según intervalo declarado; compras confirmadas no deben perderse. Despliegue:
drain, snapshots compatibles, migración expand/contract, canary y rollback de binario solo si esquema compatible.
Objetivos provisionales: servicio 99,5% en piloto; RTO de zona ≤5 min; RPO de posición ≤5 s; RPO de economía
confirmada 0 ante caída de proceso. El fallo regional exige replicación durable y política adicional, no lo cubre
una promesa de RPO local. Todo objetivo requiere prueba de restauración/failover antes de operar con usuarios.

## 9. Seguridad y operación

Gateway limita conexiones, tamaño/frame, frecuencia/opcode, tiempo de handshake y colas. Aplicación valida cuenta,
realm, dueño, estado, secuencia, permisos y coste. Fuzzing de parser antes de exponer puertos. Inyección SQL evitada
con parámetros. Secretos fuera del repo, rotación de credenciales, roles SQL mínimos y red restringida.
TLS y límites no solucionan DDoS volumétrico: proveedor de protección/CDN/borde requiere contratación y pruebas.

Métricas: tick p50/p95/p99, atraso, profundidad de cola, inputs rechazados por causa, RTT/jitter, bytes por jugador,
latencia SQL/locks, pool, outbox lag, transferencias atascadas, duplicados evitados y saldo de ledger.
Logs JSON con trace/session IDs opacos, event code, versión, realm/zone y severidad; cardinalidad controlada,
sin tokens ni PII. Administradores con MFA/capacidades, acceso separado, comandos validados y auditoría append-only.
Panel web es futuro alcance operativo; no se crea en FASE 0.

## 10. Calidad, cierre y navegación

Pruebas futuras: unitarias de dominio, integración real PostgreSQL/Redis/transporte, fuzzing, clientes simulados,
soak, fallos en puntos de commit y transferencia, regresión de contenido, profiling cliente y recuperación de backups.
Cada fase debe aportar evidencia de lo que realmente implementa. Bots y test doubles no sustituyen un cliente UE
conectado ni una DB real. Se exige ejecutar condiciones de rechazo además del camino feliz.

- Decisiones con alternativas: [decisions.md](decisions.md).
- Fases, estimaciones y puertas de validación: [roadmap.md](roadmap.md).
- Ficción original propuesta: [world-concept.md](world-concept.md).
- Procedencia: [provenance.md](provenance.md).
- Compilación: [build-and-test.md](build-and-test.md).
- Matriz de requisitos, evidencia y cierre: [phase0-acceptance.md](phase0-acceptance.md).
- Deuda y riesgos: [technical-debt.md](technical-debt.md).

No se autoriza FASE 1 por la mera existencia de este documento.
