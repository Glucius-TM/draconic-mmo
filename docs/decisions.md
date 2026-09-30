# Decisiones y alternativas — FASE 0

Estado de arquitectura: propuesta pendiente. Solo los cimientos offline son implementación autorizada.

| ID | Opciones y trade-offs | Recomendación / estado |
|---|---|---|
| D01 | Repositorio nuevo evita mezclar plataformas; migrar uno anterior ahorraría estructura pero incorporaría supuestos ajenos | **Nuevo limpio, decisión explícita del usuario**. Nombre técnico `draconic-mmo`; título por decidir |
| D02 | Monolito de todo el reino: despliegue simple, aislamiento pobre. Microservicios completos: escala selectiva, coste de operación y consistencia alto. Núcleo modular + procesos por zona: equilibrio | **Núcleo modular y zonas separadas**, propuesto. Extraer servicios cuando mediciones/ownership lo requieran |
| D03 | TLS/TCP: interoperabilidad/madurez, bloqueo por pérdida. QUIC streams+datagramas: mejor aislamiento/pérdida, integración C++/UE y operación más complejas | **TLS 1.3/TCP en primera conexión**; gate de latencia/pérdida antes de movimiento para confirmar o pasar a QUIC |
| D04 | Protobuf: evolución y tooling, parsing/asignaciones. FlatBuffers: acceso directo, verificación/layout y evolución más delicados | **Protobuf** inicialmente. FlatBuffers se reconsidera con perfiles; ningún formato desplegado aún |
| D05 | GAS como lógica de ambos lados exige servidor Unreal o duplicación; GAS solo visual puede ayudar pero acopla conceptos. Proyección C++ propia representa contrato externo | **Proyección propia**; GAS aplazado. Servidor propio obligatorio por instrucción del usuario |
| D06 | Autenticación propia: control y coste de proteger credenciales. OIDC gestionado: operación delegada, coste/proveedor. IdP autohospedado: protocolo estándar, mantenimiento propio | **OIDC estándar con proveedor por elegir**, sin inventar endpoints ni cuentas de prueba. Si se prefiere cuentas propias, diseño y revisión antes |
| D07 | Un shard gigante: experiencia continua pero cuello. Zonas/instancias con shards: escalable pero transferencias y afinidad. Instancias de todo: menos mundo persistente | **Zonificación + shards por zona e instancias privadas**; propiedad exclusiva con fencing |
| D08 | Stored procedures extensivas centralizan datos pero acoplan lógica; SQL transaccional en servicio permite tests/ownership; Redis como verdad perdería garantías | **PostgreSQL transaccional y Redis efímero**; versiones y licencias exactas antes de introducir dependencias |
| D09 | Scripts C++: control/performance, recompilar contenido lógico. DSL declarativo: seguro si expresividad acotada. Lua/WASM: flexible y más sandbox/tooling | **Datos declarativos + estados C++** inicialmente; sandbox solo al aparecer una necesidad probada |
| D10 | Windows cliente + Linux servidor reduce matriz; Windows/Linux servidor desde inicio detecta portabilidad pero duplica CI. Consolas amplían certificación/coste | **PC Windows cliente; CI del servidor configurada para Windows/Linux, ejecución remota pendiente**, producción Linux propuesta; otras plataformas fuera del slice |

Las recomendaciones no están aceptadas por silencio. La siguiente fase espera validación del diseño y de las opciones
con impacto. Detalles de transporte y datos: `data-and-protocol.md`. API/estado de capacidades UE: `ue58-verification.md`.

Decisiones aún del usuario: título/lore definitivo, hardware cliente mínimo, regiones/latencia objetivo, equipo y
presupuesto, proveedor de identidad, infraestructura, monetización y licencia del código propio. Nada de ello se
resuelve publicando un repo o instalando servicios sin especificación.
