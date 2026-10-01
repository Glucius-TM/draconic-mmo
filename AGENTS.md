# MMORPG draconico — reglas de trabajo

## Alcance y autoridad

Repositorio independiente para un MMORPG original con cliente UE 5.8 C++ y servidor C++20 propio.
El usuario autorizó únicamente FASE 0. No implementar gameplay ni pasar de fase sin su confirmación.
La arquitectura de `docs/architecture.md` es una propuesta; no equivale a aprobación para implementar sus sistemas.
Antes de cualquier sistema grande: diseño en `docs/`, alternativas y criterios de aceptación, validación explícita.
Las instrucciones del usuario prevalecen. No importar reglas, código ni datos de otros proyectos.

## Originalidad y procedencia

- AzerothCore sirve exclusivamente de referencia conceptual: nunca copiar, traducir, portar ni adaptar código,
  esquemas/tablas, datos, scripts, protocolo binario, assets, nombres o lore de aquel proyecto.
- No contenido, nombres ni assets de Blizzard. Diseño propio de sistemas y ficción original.
- No añadir dependencias ni assets sin procedencia, licencia, versión y hash; ver `docs/provenance.md`.
- No declarar licencia del proyecto elegida por el usuario si aún no lo está.

## C++ del servidor

- C++20, RAII, propiedad explícita, tipos de ancho fijo en contratos, `std::chrono` para tiempos.
- Namespace `draconic`; nombres descriptivos `snake_case` en código del servidor. No macros salvo necesidad técnica.
- Sin `new/delete` propietario manual, globals mutables, casts C, UB, silenciamiento general de warnings ni catch vacío.
- Datos no confiables: límites de tamaño antes de asignar, números con rango, enums válidos, estado/contexto/ownership.
- Dominio no depende de UE, DB, sockets ni Redis. Adaptadores dependen de contratos; composición en ejecutables.
- No bloquear el tick con I/O. Consultas preparadas y transacciones explícitas; nunca concatenar SQL de usuarios.
- No implementar criptografía propia. No registrar contraseñas, tokens ni contenido privado de chat.
- Una prueba fallida devuelve código distinto de cero; no sustituir una integración por un mock y llamarla probada.

## Cliente UE

- Unreal Coding Standard. Cada API nueva requiere referencia oficial UE 5.8 y contraste con headers instalados,
  registrados en `docs/ue58-verification.md`. No asumir APIs de otra versión.
- Lógica en C++; no Blueprint gameplay. Excepciones de datos/materiales/Niagara y animación mínima se documentan.
- `UObject` bajo GC: referencias reflejadas `UPROPERTY`/`TObjectPtr` cuando proceda, `TWeakObjectPtr` para observadores.
  `TSharedPtr` solo para objetos C++ que no sean UObject. `UFUNCTION` únicamente cuando necesite reflexión.
- Red/parseo fuera del Game Thread; aplicar resultados acotados en Game Thread. No tocar UObjects desde workers.
- Reconciliación visual nunca otorga autoridad sobre daño, posición final, moneda o inventario al cliente.
- No activar GAS, Iris o Mass por conveniencia: diseño y estado UE 5.8 verificados primero.

## Build, pruebas y evidencia

- Servidor: CMake + CTest; comandos exactos y presets en `docs/build-and-test.md`.
- Cliente: Unreal Build Tool; comandos y limitaciones en `docs/ue58-verification.md`.
- Usar `tools/unreal/verify.ps1` para comprobar el Editor y el test exacto con informes nuevos; no aceptar solo exit 0.
  Ejecutar `tests/tooling/test-unreal-validation.ps1` si cambia el verificador. Sus fixtures no prueban Unreal.
- Builds fuera de fuente en `.build/`; binarios UE en sus carpetas generadas ignoradas. No subir motores ni SDKs.
- Ejecutar tests correspondientes al cambio, revisar errores y documentar lo realmente ejecutado.
- CI automática del servidor en Windows/Linux; Unreal requiere runner licenciado dedicado antes de habilitar CI.
- Estados permitidos: PROPUESTO, IMPLEMENTADO, VERIFICADO, NO VERIFICADO, BLOQUEADO. No decir production-ready
  sin evidencia de funcionalidad, seguridad, recuperación, carga y operación real.
- Cada fase cierra con código compilable, tests ejecutados, documentación y deuda en `docs/technical-debt.md`.
- Mantener la trazabilidad requisito/evidencia en `docs/phase0-acceptance.md`; no confundir aceptación técnica
  con autorización para la fase siguiente. Conservar los informes de CI cuando fallen las pruebas.
- No crear servicios que siempre devuelvan éxito ni listeners ficticios. Las herramientas offline deben decirlo.
- Cambios de fase, despliegue, publicación y decisiones irreversibles requieren la autorización correspondiente.

## Revisión

Leer `README.md`, `docs/architecture.md`, `docs/decisions.md` y `docs/phase0-evidence.md` antes de modificar.
Preservar cambios de otros colaboradores. No subir secretos. No reescribir historia ni borrar trabajo sin permiso.
Actualizar diseño y deuda cuando cambie una responsabilidad; evitar árboles vacíos y módulos sin consumidores.
