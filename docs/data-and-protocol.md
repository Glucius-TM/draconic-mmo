# MMORPG dracónico — datos y protocolo

Estado: **diseño pendiente de validación**, revisión 2026-10-01. Este documento define contratos originales para el proyecto nativo. No contiene migraciones ejecutables, mensajes generados ni una implementación de red. Los nombres de tablas son propuestas propias, no reproducciones de otro proyecto. Los presupuestos indicados son objetivos iniciales que deben medirse.

## 1. Decisiones que requieren validación

| Decisión | Recomendación | Alternativa y coste |
| --- | --- | --- |
| Persistencia | PostgreSQL: identidad global y una unidad transaccional económica por reino | Separar inventario, monedas y subastas en bases independientes obliga a coordinar transacciones distribuidas; reservarlo para una necesidad medida |
| Serialización | Protobuf con mensajes pequeños, tipados y validación de dominio posterior | FlatBuffers puede reducir trabajo de lectura, pero requiere verificar buffers y disciplina adicional de evolución; medir antes de cambiar |
| Transporte inicial | TLS 1.3/TCP; dos canales lógicos tipados, control y snapshots, sobre una conexión | QUIC con streams fiables y datagramas separa mejor el tráfico, con más complejidad de biblioteca, despliegue y pruebas de pérdida |
| Estado efímero | Redis para presencia, cuotas compartidas y proyecciones reconstruibles | Un almacén duradero de eventos puede añadirse cuando la distribución lo justifique; Redis no se convierte por ello en autoridad económica |
| Propiedad de simulación | Un propietario por entidad, epochs persistentes y transferencia por estados | Simulación activa-activa de la misma entidad complica conflictos y combate; fuera del alcance inicial |

La base de evaluación SQL es PostgreSQL 18; todavía hay que fijar el parche exacto y el artefacto verificable de despliegue. Se elige Redis como producto según la petición, pero quedan pendientes versión, edición y licencia: Redis 8 y posteriores ofrecen RSALv2, SSPLv1 o AGPLv3. No se asume que cualquier paquete Redis tenga licencia BSD ni se instala una versión antigua solo por su licencia. La selección se registrará antes de incorporarlo. [Versiones y licencia oficial de Redis](https://redis.io/legal/licenses/).

La elección de Protobuf es una decisión de mantenibilidad, no una afirmación de superioridad de rendimiento. Los resultados publicados por FlatBuffers corresponden a sus escenarios; nuestro flujo necesita una comparación con tamaños, entidades y CPU reales. [Benchmarks oficiales de FlatBuffers](https://flatbuffers.dev/benchmarks/).

## 2. Límites de propiedad

```text
Cliente UE --> gateway --> propietario de zona/instancia
                 |                    |
                 |                    +--> servicio de persistencia del reino
                 |                                      |
                 +--> identidad / personajes             +--> PostgreSQL del reino
                 +--> social / chat / economía            +--> outbox durable
                                                           |
                                 Redis <--- proyecciones ---+

Identidad global --> PostgreSQL de identidad
Cliente          -X-> PostgreSQL / Redis / servicios internos
```

El cliente propone intenciones; no confirma resultados, saldos, daño, botín ni posición válida. El gateway autentica, limita y enruta; la zona decide movimiento y combate; el propietario de cada dominio autoriza su mutación. Una interfaz de servicio no obliga a desplegar un proceso independiente desde el primer día.

La identidad global y cada reino son límites de datos distintos. Dentro del reino, inventario, monedas, correo con adjuntos y subastas comparten inicialmente la misma base y frontera transaccional, aunque tengan módulos y permisos separados. Las claves foráneas solo protegen relaciones dentro de la misma base; una referencia a una cuenta global exige comprobación mediante el servicio de identidad y un proceso explícito para bajas o revocaciones.

Las zonas no acceden a tablas ajenas mediante SQL libre. El servicio de persistencia valida identidad del proceso, reino, propietario, epoch y versión del agregado. Todas las consultas parametrizan valores y permiten identificadores SQL solo desde listas internas; nunca concatenan entrada del cliente. No hay conexiones ni consultas SQL por jugador y tick: pools acotados, guardados agrupados de estado no crítico y commits inmediatos para cambios económicos. El cliente recibe confirmación económica solo después del commit durable.

### Identidad externa y sesión de juego

La recomendación OIDC separa tres autoridades: el proveedor autentica a la persona; identity vincula `(issuer, subject)` a la cuenta y aplica suspensión/elegibilidad; el reino autoriza personaje y acciones. Autenticarse en el proveedor no concede acceso a un personaje ni capacidades GM. No se crean cuentas por un email recibido del cliente ni se fusionan vínculos automáticamente por coincidencia de email.

Para el cliente nativo se propone Authorization Code con PKCE y navegador externo, sin secreto de cliente incrustado. Son requisitos documentados para aplicaciones nativas; redirect URI, proveedor y registro de cliente quedan por diseñar. [RFC 8252, §§4–8](https://www.rfc-editor.org/rfc/rfc8252.html).

El futuro diseño debe identificar quién valida cada token, issuer permitido, firma/algoritmo, audiencia, vencimiento y correlación con el flujo iniciado; la validación de ID Token sigue el perfil OIDC seleccionado. Un ID Token dirigido al cliente no se acepta como credencial genérica del gateway. No basta decodificar un JWT. [Validación oficial de ID Token](https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation).

La emisión o canje de una sesión de juego requiere un contrato propio aprobado, con autenticación del solicitante, audiencia específica y límites de reutilización; no se inventa aquí un endpoint del proveedor. La revocación local debe cortar nuevas admisiones y acotar la vigencia de sesiones activas incluso si el token externo aún no ha vencido. Si el IdP o sus claves no pueden validarse, no se concede acceso nuevo; la continuidad de sesiones ya verificadas tendrá un plazo explícito. TTL, rotación, cierre de sesión y recuperación de cuenta se diseñarán antes de implementar; las pruebas con el proveedor real serán condiciones de cierre de FASE 1.

## 3. Modelo lógico de datos

Los identificadores persistentes se generan en el servidor. Se propone UUID para identidad y operaciones; IDs locales de entidad y tick de 64 bits para simulación. La representación de red evita enviar un UUID completo donde una referencia local validada sea suficiente. Cantidades y monedas usan enteros con límites de dominio y comprobación de overflow; nunca coma flotante para saldos.

| Ámbito / relación propuesta | Campos y claves relevantes | Invariantes y consultas principales |
| --- | --- | --- |
| Identidad: `account` | `account_id`, estado, fecha, revisión | Identificador estable; nunca almacenar contraseñas en claro |
| Identidad: `account_identity` | cuenta, proveedor/issuer validado, subject estable | Unicidad issuer/subject; vínculo federado para la propuesta OIDC; nunca usar email mutable como ID |
| Identidad: `session`; `credential` solo si se aprueba autenticación local | cuenta, hash de token; credencial local alternativa; expiración, revocación, generación | Tokens opacos generados criptográficamente; sesión activa ligada a cuenta; rotación y revocación explícitas |
| Catálogo: `realm` | ID, región, estado de admisión, protocolo y contenido admitidos | La disponibilidad publicada no da permisos de acceso |
| Reino: `character` | ID, cuenta global, reino, nombre normalizado, linaje/clase propios, revisión | Nombre único según política del reino; propiedad de cuenta verificada en cada selección |
| Reino: `character_checkpoint` | personaje, zona/instancia, transform validado, tick, revisión, versión de contenido | Restauración desde checkpoint confirmado; cadencia de movimiento independiente de economía |
| Reino: `authority_assignment` | ámbito/entidad, propietario de proceso, epoch, estado, plazo de lease | Una asignación vigente; epoch creciente; escritura condicional al propietario y epoch actuales |
| Reino: `zone_transfer` | transferencia, personaje, origen, destino, epochs, checkpoint, estado, expiración | Transferencia única activa por personaje; transición por comparación de estado/revisión |
| Reino: `item_instance`, `item_container`, `container_slot` | instancia, definición y versión, cantidad, contenedor, ranura | Una única ubicación por instancia; unicidad contenedor/ranura; cantidades positivas y acotadas; FKs del mismo reino |
| Reino: `wallet`, `ledger_transaction`, `ledger_entry` | propietario, moneda, saldo/revisión; operación; entradas débito/crédito | Saldo no negativo del jugador; contabilidad equilibrada por moneda; fuentes y sumideros explícitos |
| Reino: `operation_receipt` | principal, clave idempotente, tipo, argumentos normalizados, resultado y revisión | Unicidad principal/clave; repetir una operación devuelve su resultado, reutilizar la clave con otra intención se rechaza |
| Reino: `auction`, `auction_bid` | vendedor, contenedor de custodia, precio, vencimiento, revisión, estado | El objeto ofrecido ya está bajo custodia; adjudicación/cancelación/vencimiento compiten por una única transición |
| Reino: `mail_delivery` | destinatario, contenedor de adjuntos, operación de origen, reclamación | Una reclamación transaccional; no duplicar adjuntos al reconectar |
| Reino: `quest_progress`, `reward_claim` | personaje, definición/versionado, objetivos, identidad del hito/recompensa | Una concesión por elegibilidad/hito; el cliente no declara objetivos cumplidos |
| Reino: `ability_state`, `talent_selection`, `profession_progress` | personaje, definición/versionado, progreso y expiraciones necesarias | Solo estado persistente necesario; atributos derivados se recalculan desde definiciones aprobadas |
| Reino: `group`, `group_member`, `guild`, `guild_member`, `instance_binding` | miembros, roles, revisión, instancia y reinicio | Pertenencia y permisos verificados; consistencia de roster e invitaciones; lockouts ligados a identidad estable |
| Reino: `outbox_event`, `consumer_inbox` | evento, agregado/revisión, payload/versionado, entrega; consumidor/evento | Publicación al menos una vez; consumidores idempotentes y orden por agregado |
| Operación: `audit_event`, `schema_migration` | actor, acción, recurso, resultado; ID, checksum, fechas, build | Auditoría de privilegios y cambios de esquema; sin secretos ni datos sensibles completos en logs |

Las tablas de contenido son contratos propios futuros: habilidades, reglas de combate, curvas, profesiones, misiones, loot y encuentros se generan desde definiciones versionadas del proyecto. No se importa ningún catálogo, DBC, SQL ni script de otro juego. No se introduce un esquema genérico EAV para todos los sistemas; JSONB queda reservado a extensiones acotadas con versión y validación.

Los índices se diseñan a partir de consultas: personajes por cuenta/reino, ranuras por contenedor, subastas por reino/estado/vencimiento, entregas pendientes por destinatario y outbox pendiente. La partición física de tablas y la separación de bases se justifican con volumen y contención medidos. Una tabla particionada exige revisar qué unicidades pueden garantizarse globalmente.

Se usarán `NOT NULL`, `CHECK`, claves únicas y foráneas donde expresen invariantes locales. Un `CHECK` no garantiza por sí mismo reglas entre varias filas, como el equilibrio de un ledger o la capacidad total de una bolsa; estas requieren una transacción y una interfaz de escritura protegida. [Restricciones de PostgreSQL](https://www.postgresql.org/docs/18/ddl-constraints.html).

## 4. Economía sin doble gasto

Una compra futura sigue una sola transacción del reino: resolver autorización y contexto desde el servidor; reclamar la clave idempotente; bloquear y comprobar los recursos; calcular precio y cantidades con contenido aprobado; debitar, entregar, registrar ledger y recibo; añadir eventos al outbox; confirmar. Ningún efecto externo se publica antes del commit.

Para operaciones sobre filas conocidas se propone bloqueo de filas en orden estable y actualizaciones condicionadas por revisión. Para invariantes de conjunto o predicados complejos se evaluará `SERIALIZABLE`. Deadlocks y errores de serialización requieren reintentar la transacción completa, con límite y backoff; un timeout de commit obliga a consultar el recibo, no a asumir que falló. Estas son decisiones del proyecto basadas en las garantías documentadas de [aislamiento](https://www.postgresql.org/docs/18/transaction-iso.html) y [bloqueo](https://www.postgresql.org/docs/18/explicit-locking.html).

La unicidad del recibo y la mutación deben estar en el mismo commit. Conservar el recibo, o una marca durable equivalente de operación consumida, durante toda la vida válida de su clave; borrarlo por un TTL arbitrario permitiría repetir una compra antigua. Cada operación define caducidad verificable por el servidor. No se garantiza «exactamente una entrega» por la red: se garantiza que una intención identificada no produzca dos efectos comprometidos. Nuevas claves siguen pasando todas las reglas de elegibilidad, saldo y frecuencia.

Los argumentos del recibo se comparan como campos semánticos normalizados con versión de contrato. No se usa el hash de la serialización Protobuf como identidad canónica de una intención: incluso su serialización determinista no es una representación canónica estable. [Garantía oficial de serialización](https://protobuf.dev/programming-guides/serialization-not-canonical/).

El ledger distingue cuentas del jugador de cuentas de sistema para creación/destrucción autorizada de moneda. El equilibrio se verifica por transacción y moneda en la interfaz de escritura; auditorías periódicas concilian ledger, saldos y objetos. El rol SQL de runtime no debe poder saltarse esa interfaz con actualizaciones arbitrarias. La implementación exacta de restricciones diferidas, permisos y conciliación requiere el diseño de economía aprobado.

Un objeto no puede existir a la vez en mochila y subasta: la custodia es una ubicación del mismo objeto, no una copia. Reclamaciones de recompensas también tienen identidad de negocio única, además de la clave elegida por el cliente. En la primera arquitectura no hay compraventa entre reinos; habilitarla requiere un diseño específico de custodia y recuperación.

## 5. Redis, eventos y pérdida de dependencias

Redis conserva presencia con TTL, contadores de admisión, cachés de lectura y vistas reconstruibles de listados. Los saldos, objetos, adjudicaciones y propiedad autoritativa no dependen de una entrada Redis. Las cuotas locales del gateway siguen activas si Redis cae; las operaciones que requieren una cuota global se degradan de manera conservadora o se rechazan temporalmente, sin abrir acceso ilimitado.

El outbox reside en la misma transacción que el cambio del agregado. Un publicador reclama lotes con plazo y reintentos; al caer tras publicar y antes de confirmar, puede repetir. Cada consumidor persiste su inbox junto con su efecto local. Se transporta revisión del agregado: los consumidores ignoran versiones antiguas y detectan huecos antes de aplicar deltas. No se exige orden total entre agregados independientes.

Redis Pub/Sub puede acelerar avisos prescindibles; no entrega garantizadamente eventos a consumidores desconectados. No sostiene por sí solo correo, recompensas ni transferencias. [Semántica oficial de Pub/Sub](https://redis.io/docs/latest/develop/pubsub/).

La caída de PostgreSQL bloquea admisiones y mutaciones duraderas. Una zona puede mantener una ventana acotada de simulación puramente efímera si conserva autoridad válida, pero no concede recompensas, confirma compras ni transfiere jugadores sin persistencia. Al expirar la autoridad se congela/desconecta de forma controlada; no se continúa indefinidamente en un estado divergente.

## 6. Transferencias, leases y fencing

Un lease es un permiso temporal; un epoch es una generación creciente que permite rechazar escrituras de un propietario anterior. Un proceso pausado puede despertar después de perder su lease: que siga vivo no prueba que tenga autoridad. Redis también advierte de esta necesidad de fencing en sistemas de locks distribuidos. Aquí la asignación y sus epochs se arbitran en PostgreSQL, no mediante un lock Redis. [Guía oficial de locks Redis](https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/).

```text
Activa en A,e
   -> Barrera inicial: gateway congela la ruta del personaje y confirma la pausa
   -> Preparada: A drena acciones en curso; barrera durable congela escrituras y confirma checkpoint
   -> Lista: B carga ese checkpoint, todavía sin simular ni conceder efectos
   -> Commit: transacción cambia propietario A,e -> B,e+1
   -> Barrera de ruta: gateway descarta resultados antiguos y activa B,e+1
   -> Activa en B,e+1; A libera memoria
```

El token de transferencia se genera en servidor, caduca y se consume una vez, ligado a cuenta, personaje, reino, destino y transferencia. No basta para autorizar una escritura si el epoch ya no es vigente. El cliente no elige una dirección interna ni un shard arbitrario.

Cada commit duradero comprueba propietario, epoch y estado bajo la misma transacción que su cambio. La asignación usa el reloj de la autoridad persistente para vencimientos; los workers usan temporizadores monotónicos conservadores para detenerse. Incrementar epochs nunca reutiliza un valor anterior. Si falla la confirmación del cambio, el coordinador consulta el estado durable y reanuda idempotentemente.

La comprobación no puede ser una lectura suelta seguida de otra transacción: mutación, renovación y reasignación deben serializar sobre el mismo registro de autoridad. Se propone bloquear ese registro, comprobar propietario/epoch/estado/plazo vigente y mantener el bloqueo hasta terminar el cambio. Así una reasignación espera a una mutación ya autorizada, o invalida la siguiente; ningún worker renueva un lease ya vencido como si siguiera vigente. Se limitará el tiempo de transacción para que la propia barrera no bloquee indefinidamente. No se mantiene una transacción SQL abierta mientras se espera una respuesta de red.

La barrera durable rechaza escrituras de A posteriores al checkpoint, incluidas las que ya estaban en colas. B solo se activa desde ese checkpoint y generación confirmados. Una recuperación debe consultar también recibos y revisiones económicas: reproducir un checkpoint antiguo no puede reemplazar saldos ni inventario más recientes. La generación de conexión (`session_generation`) y la de autoridad (`authority_epoch`) son distintas; reconectar no confiere propiedad de simulación.

Fencing de DB no basta: gateway y receptores entre zonas también rechazan comandos, snapshots y resultados con epochs viejos. La ruta del personaje se congela durante la barrera hasta que el gateway ha adoptado la nueva generación; una caché de presencia no autoriza el traspaso. Un worker aislado no puede enviar efectos directamente al cliente saltándose esa puerta. NPCs e instancias necesitan el mismo principio en el ámbito de propietario de zona/instancia.

Las rutas del gateway también caducan: al perder comunicación con la autoridad no se conservan indefinidamente. El plazo debe dejar margen conservador para detener tráfico antes de la reasignación; tras reinicio se consulta estado vigente. Si no puede probarse una única ruta activa, se cierra la sesión antes de admitir otra. La política exacta de plazos y relojes necesita pruebas de pausa de proceso y partición; esta propuesta no demuestra aún exclusión mutua distribuida.

Si A muere antes del checkpoint, se recupera desde el último checkpoint confirmado y una nueva generación. Puede perderse movimiento efímero; no una operación económica ya confirmada bajo la política de durabilidad acordada. Si B muere tras el commit, se recupera B con otra generación o se asigna un nuevo propietario; no se reactiva A con su epoch anterior. No se promete continuidad sin pausa durante particiones.

El primer vertical slice usa límites de zona explícitos y una breve transición. Interacciones de combate a través de fronteras espaciales, fantasmas de entidades y transferencia transparente quedan para otro diseño validado. El estado durable de cooldowns, auras y elegibilidad necesario para impedir ventajas por reconexión debe formar parte del checkpoint del sistema correspondiente.

### Matriz de fallo y resultado exigido

Todos estos casos son **NO VERIFICADOS**: son criterios para la futura integración real, no tests ejecutados en FASE 0.

| ID | Fallo inyectado | Resultado observable exigido |
| --- | --- | --- |
| A01 | A se pausa, vence el lease, B toma autoridad y A vuelve | Cero mutaciones o snapshots aceptados con epoch antiguo; no se renueva el permiso vencido |
| A02 | Acción durable compite con barrera de checkpoint | O bien forma parte del estado confirmado, o se rechaza; no queda una mutación aceptada fuera del checkpoint/recibos recuperables |
| A03 | Respuesta de commit se pierde y se repite la operación | Mismo recibo y un único efecto; la incertidumbre no se resuelve concediendo de nuevo |
| A04 | B cae después de cambiar propietario, antes de abrir ruta | Se recupera con generación nueva; A no recupera su permiso anterior; el cliente permanece pausado |
| A05 | Gateway conserva ruta antigua o reinicia durante relevo | No entrega resultados antiguos; reconstruye autoridad antes de admitir tráfico |
| A06 | Redis pierde todas sus claves o PostgreSQL deja de responder | Perder caché no otorga derechos; continúan cuotas locales y validación durable. Sin PostgreSQL se rechazan mutaciones/admisiones; autoridad caducada se detiene |
| A07 | Se restaura checkpoint anterior a una compra confirmada | Compra y custodia siguen conciliadas con el registro durable; no se reescribe la economía desde el snapshot |

## 7. Contrato de red propuesto

TLS 1.3 usa una biblioteca mantenida, certificados verificados y rotación operativa; no se diseña criptografía propia. Se desactiva 0-RTT para autenticación y comandos, inicialmente para todo el protocolo. TLS protege el transporte, pero la aplicación sigue necesitando deduplicación de reintentos. [TLS 1.3 y anti-replay, RFC 8446 §8](https://www.rfc-editor.org/rfc/rfc8446.html#section-8).

Una conexión inicial lleva dos clases de mensajes y dos colas acotadas: control fiable ordenado y snapshots de estado reemplazables. Se prioriza control y solo se conserva el snapshot pendiente más reciente por flujo compatible. Una vez entregados bytes a TCP, no pueden retirarse: la pérdida bloquea también datos posteriores y puede aumentar latencia. Dos canales lógicos no eliminan ese bloqueo. Se medirá con RTT, jitter y pérdida; si incumple el presupuesto, se propondrá QUIC con streams de control y datagramas para snapshots. Los datagramas QUIC no se retransmiten automáticamente y conservan control de congestión; exigen diseño de baseline, MTU y recuperación propios de la aplicación. [RFC 9221](https://www.rfc-editor.org/rfc/rfc9221.html).

Frame lógico propuesto, todavía sin `.proto`:

```text
longitud acotada + versión + tipo permitido + canal
session_generation + secuencia de canal + correlation_id
payload Protobuf tipado

Payload de comando durable: clave idempotente + argumentos limitados
Payload de input: input_seq + tick declarado + intención de movimiento
Payload de snapshot: tick servidor + epoch + baseline + último input procesado
```

La identidad del principal y la ruta autoritativa se derivan de la conexión validada, nunca de un campo de cuenta recibido. Una nueva conexión necesita autenticación/reanudación explícita, recibe una nueva generación y nuevos contadores; los frames de generaciones anteriores se rechazan. Los recibos duraderos sobreviven a esa rotación. Una política de sesión única por personaje evita dos conexiones activas, con relevo atómico y desconexión de la anterior.

Estados de conexión: `TLS -> negociación -> autenticada -> selección de reino/personaje -> activa -> drenaje/cierre`. Cada estado tiene mensajes permitidos y plazo. La negociación incluye protocolo major/minor, build y contenido compatible. No se acepta una versión solo porque el parser pueda leerla. Credenciales y tokens no aparecen en logs, URLs ni volcados de paquetes distribuidos.

Presupuestos iniciales a validar con pruebas: frame exterior hasta 64 KiB, payload de input hasta 1 KiB, profundidad y cardinalidades de Protobuf explícitas, sin compresión inicial; máximo 30 mensajes de input/s sostenidos con ráfaga acotada, control económico 5/s y chat 2/s por sesión como puntos de partida. El detalle por opcode, ventanas, cuotas por cuenta/IP/reino y bytes/s se aprobará antes de implementarlo. Los límites por IP no sustituyen los de cuenta y deben contemplar redes compartidas.

El gateway aplica límite de tamaño antes de reservar memoria, timeout de lectura/handshake, presupuesto de conexiones pendientes y colas máximas por sesión y proceso. Cuando control no puede drenarse a tiempo se rechaza o cierra la sesión con motivo; no se acumula memoria sin límite. La cuota debe limitar coste total y bytes, no solo número de mensajes. Los mensajes de administración viven en otra superficie autenticada, con roles, auditoría y sin acceso de jugadores normales.

Protobuf aporta codificación y compatibilidad de campos, no autorización ni validación de negocio. Se reservan IDs/nombres retirados; no se reciclan ni cambian tipos de campos usados. Las adiciones opcionales requieren pruebas entre versiones admitidas y valores de enum desconocidos se rechazan cuando afecten a decisiones. Se fijan juntos generador y runtime C++ para evitar incompatibilidad; la especificación final fijará el comportamiento de campos desconocidos según dirección y versión. [Evolución de mensajes](https://protobuf.dev/programming-guides/proto3/) y [garantías de runtime C++](https://protobuf.dev/support/cross-version-runtime-guarantee/).

## 8. Movimiento y validación autoritativa

La zona consume intenciones de movimiento a tick fijo y calcula posición, velocidad, colisión y restricciones. El timestamp del cliente es una pista limitada, no tiempo autoritativo. Rechaza inputs duplicados, demasiado antiguos o futuros, NaN/infinito, vectores fuera de rango, aceleración imposible y transiciones no permitidas. Alcance, línea de visión, objetivos y fase del combate se resuelven sobre el estado del servidor.

El cliente predice para responder inmediatamente y guarda un historial acotado. Al recibir un snapshot, aplica el estado confirmado, elimina inputs reconocidos y vuelve a simular los pendientes; interpola a otros jugadores. No se exige determinismo binario entre UE y el servidor propio. El algoritmo y datos de colisión mínimos deben concordar; tolerancias, correcciones visuales y presupuestos se validan con trayectorias grabadas. World Partition del cliente no determina qué zona es autoritativa.

No existe una compensación de lag ilimitada: el futuro diseño de combate debe fijar historial, ventana de rewind, unidades elegibles y política PvP. Un servidor autoritativo reduce modificaciones de estado fraudulentas, pero no demuestra por sí solo ausencia de bots o automatización. Las decisiones sensibles no usan secretos que dependan de permanecer ocultos dentro del ejecutable del cliente.

## 9. Migraciones y recuperación

Se propone una secuencia de migraciones inmutables por base, con ID creciente, checksum, requisitos mínimos y registro de aplicación. Un único job de despliegue migra mediante un rol específico; los servidores de juego no ejecutan DDL al iniciar. Cada binario declara intervalo de esquema compatible y rechaza arrancar fuera de él.

Estrategia expandir/migrar/contraer: añadir estructura compatible, desplegar lectores compatibles, rellenar por lotes reanudables, verificar invariantes, cambiar escrituras/lecturas y retirar lo anterior cuando no existan consumidores. No usar doble escritura entre bases como sustituto de una transacción. Los cambios que no pueden ejecutarse en transacción, como determinados índices concurrentes, tienen estado, recuperación y validación explícitos.

Antes de cambios destructivos: copia verificada, inventario de impacto y ensayo de restauración. Mantener backup base y archivado WAL con monitorización permite recuperación a un punto temporal; tener archivos de backup no prueba que puedan restaurarse. Se propone un ensayo periódico de restauración aislada y revisión de permisos de acceso. [Recuperación PITR de PostgreSQL](https://www.postgresql.org/docs/18/continuous-archiving.html).

Objetivos a presupuestar: evitar pérdida de economía confirmada ante fallo de un nodo con una política de réplica síncrona adecuada; RPO/RTO de desastre regional se fijarán según coste y proveedor. No se promete RPO cero universal. Restaurar solo un servicio a una fecha anterior puede invalidar recibos y eventos de otros servicios: el runbook debe detener admisiones, coordinar el punto de restauración, reconciliar outbox/inbox, invalidar sesiones y verificar saldos antes de reabrir.

## 10. Pruebas exigidas antes de declarar estos contratos implementados

- Parser: longitudes truncadas/excesivas, frames concatenados, profundidad, tipos/enums desconocidos, UTF-8, fuzzing, timeouts y colas saturadas; ASan/UBSan en plataformas compatibles.
- Sesión: token vencido/revocado, replay en misma conexión y tras reconexión, takeover de personaje, negociación incompatible y protocolo enviado fuera de estado.
- Persistencia: migración desde base vacía y versión anterior admitida, checksum alterado, corte de migración, incompatibilidad de binario y restauración real.
- Economía: compradores concurrentes, dos reclamaciones del mismo loot, saldo justo, overflow, cambio de argumentos con misma clave, commit ambiguo y crash antes/después de publicar outbox.
- Autoridad: worker pausado que despierta, pérdida de lease, caída de Redis, partición de DB, transferencia repetida, gateway con ruta antigua y caída en cada transición.
- Bots de integración: RTT 30/100/200 ms, jitter, pérdida 0/1/3/5 %, pausas de consumo, reconexión masiva y carga de admisión; registrar latencias p50/p95/p99, CPU, memoria, bytes/s y profundidad de colas.

Estas pruebas son criterios de fases posteriores. Fase 0 no puede presentarlas como ejecutadas, porque aún no existen implementaciones de DB, transporte, movimiento ni gameplay. Pendientes antes de Fase 1: validar decisiones, fijar dependencias y licencias, escribir diseño operativo de identidad y migraciones, especificar límites por mensaje y acordar políticas de sesión y recuperación.
