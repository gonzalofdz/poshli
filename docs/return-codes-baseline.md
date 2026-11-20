# Fase 0: Auditoria de codigos de retorno

**Proyecto:** Poshli  
**Fecha:** 2026-11-17  
**Entorno:** Linux, shell de auditoria `dash`  
**Bundle probado:** `poshli.sh` (sincronizado con `src/`, verificado con `make check-bundle`)  
**Objetivo:** obtener el comportamiento real de cada funcion publica en los casos clave y compararlo con README, DEVELOPER.md, CONTRIBUTING.md, comentarios de funcion y tests.

## 1. Metodologia

- Se cargo `poshli.sh` en un script limpio.
- Se ejecuto cada funcion publica con los casos: exito, argumento vacio `''`, sin argumentos, entrada invalida, ruta inexistente/no regular (para fs).
- Para funciones con salida, se silencio stdout/stderr; solo se registro el status de salida.
- Se repitio la tabla con `dash`, `bash --posix` y `busybox sh`; los resultados fueron identicos.
- Se comparo con los documentos del proyecto y los tests.

## 2. Tabla de comportamiento real

| Modulo | Funcion | Tipo README | success | empty | missing | invalid | not-exist | not-regular | notes |
| :----- | :------ | :---------- | :-----: | :---: | :-----: | :-----: | :-------: | :---------: | :---- |
| num | num_is_integer | predicate | 0 | 1 | 1 | 1 | - | - | |
| num | num_is_natural | predicate | 0 | 1 | 1 | 1 | - | - | |
| num | num_is_number | predicate | 0 | 1 | 1 | 1 | - | - | |
| num | num_is_hex | predicate | 0 | 1 | 1 | 1 | - | - | |
| num | num_is_bin | predicate | 1 | 1 | 1 | 1 | - | - | |
| num | num_is_octal | predicate | 0 | 1 | 1 | 1 | - | - | |
| num | num_is_bool | predicate | 1 | 1 | 1 | 1 | - | - | |
| num | num_randomize | operational | 0 | 1 | 2 | 1 | - | - | output 0..limit-1 |
| fs | fs_is_file | predicate | 0 | 1 | 2 | 1 | 1 | 1 | |
| fs | fs_is_dir | predicate | 0 | 1 | 2 | 1 | 1 | 0 | |
| fs | fs_is_readable | predicate | 0 | 1 | 2 | 1 | 1 | 0 | |
| fs | fs_is_writable | predicate | 0 | 1 | 2 | 1 | 1 | 0 | |
| fs | fs_is_exec | predicate | 0 | 1 | 2 | 1 | 1 | 0 | |
| fs | num_is_empty_file | predicate | 0 | 1 | 2 | 1 | 1 | 1 | |
| fs | fs_is_plain_text | operational | 0 | 1 | 2 | 1 | 1 | 1 | tambien 1 si no legible |
| str | str_empty | predicate | 0 | 0 | 0 | 1 | - | - | vacio == true |
| str | str_starts_with | predicate | 0 | 0 | 1 | 1 | - | - | |
| str | str_ends_with | predicate | 0 | 0 | 1 | 1 | - | - | |
| str | str_contains | predicate | 0 | 0 | 1 | 1 | - | - | |
| str | str_trim | transformer | 0 | 0 | 0 | - | - | - | trata vacio como vacio |
| str | str_lower | transformer | 0 | 0 | 0 | 1 | - | - | invalid UTF-8 -> 1 |
| str | str_upper | transformer | 0 | 0 | 0 | 1 | - | - | invalid UTF-8 -> 1 |
| str | str_len | transformer | 0 | 0 | 0 | 1 | - | - | invalid UTF-8 -> 1 |
| str | str_len_bytes | transformer | 0 | 0 | 0 | - | - | - | |
| str | str_replace | transformer | 0 | 0 | 2 | - | - | - | search vacio -> identidad |
| encoding | encoding_base64_encode | operational | 0 | 0 | 2 | - | - | - | no partial output on error |
| encoding | encoding_base64_decode | operational | 0 | 0 | 2 | 1 | - | - | - | |

Leyenda:
- `success`: argumento valido.
- `empty`: argumento vacio `''`.
- `missing`: sin argumentos.
- `invalid`: argumento malformado segun el contrato de la funcion.
- `not-exist` / `not-regular`: aplicables solo a funciones de fs.

## 3. Discrepancias encontradas

### D1: Predicados con argumento faltante no son uniformes

| Funcion | Status real en `missing` | Dice README | Dice DEVELOPER.md | Dice CONTRIBUTING.md | Tests |
| :------ | :----------------------: | :---------- | :---------------- | :------------------- | :---- |
| `num_is_*` | 1 | "treated as false" (1) | 2 | 2 (generico) | 1 |
| `str_starts_with/ends_with/contains` | 1 | "1 if arguments are missing" | 2 | 2 (generico) | 1 |
| `str_empty` | 0 | "no argument or empty -> true" | 2 | 2 (generico) | no test directo |
| `fs_is_*` | 2 | excepcion documentada (l. 350) | 2 | 2 (generico) | 2 |

**Observacion:** Los tests de `num` y `str` ya reflejan el criterio README (missing = false/1, salvo `str_empty` que es true por contrato). Los tests de `fs` reflejan el criterio DEVELOPER.md (missing = 2).

### D2: Inconsistencia interna en README

- Seccion *Return Code Conventions* dice: los predicados devuelven 0/1; un argumento ausente se trata como falso.
- Seccion *Filesystem* (l. 350) dice: "Unlike the boolean predicates in `num.sh` and `str.sh`, the file-system predicates still return `2` when the path argument is missing."
- Estas dos afirmaciones se contradicen: o los predicados nunca usan 2 por missing, o los de fs son una excepcion.

### D3: DEVELOPER.md contradice README y tests para predicados

- DEVELOPER.md 3.1: "Predicate Functions ... Return `2` if required arguments are missing."
- Esto solo coincide con `fs_is_*`. Los predicados de `num` y `str` (y `str_empty`) no lo hacen.

### D4: CONTRIBUTING.md asume un unico status para argumentos faltantes

- CONTRIBUTING.md 7.3: "missing argument checks (status `2`)".
- No distingue entre predicados y transformadores, lo que choca con el comportamiento real y con README.

### D5: `num_is_bin '42'` y `num_is_bool '42'` devuelven 1 (correcto)

No es una discrepancia, pero se incluye en la tabla como punto de control.

## 4. Estado de funciones operativas

Las funciones operativas (`num_randomize`, `fs_is_plain_text`, `str_replace`, `encoding_base64_*`) ya son coherentes con el contrato propuesto en D1 del PLAN.md:

- `0` en exito.
- `1` en entrada invalida o fallo de la operacion.
- `2` en uso invalido (argumento obligatorio faltante).

`str_trim/lower/upper/len/len_bytes` no tienen argumentos obligatorios; tratan el caso missing como cadena vacia y devuelven 0, lo cual esta documentado explicitamente en README y tests.

## 5. Recomendacion para las decisiones del PLAN.md

- **D1 (que significa `2`):** Opcion (a) del PLAN.md: `2` solo para uso invalido en funciones *operativas*. Los predicados deben devolver 0/1; un argumento faltante es "falso" (1), salvo excepciones documentadas como `str_empty`.
- **D2 (alcance):** Aplicar el cambio solo a `fs_is_*` para alinearlos con `num_is_*` y `str_starts_with/ends_with/contains`.
- **D3 (version):** El cambio es observable. En 0.x puede ser un PATCH si se considera correccion de inconsistencia, o un MINOR si se considera cambio de comportamiento publico. Recomendacion de agente: MINOR (`0.6.0`) por cautela.
- **D4 (excepciones):** Conservar `str_empty` tal cual (missing = true = 0) porque su contrato lo define explicitamente.

## 6. Archivos afectados si se aprueba el cambio

- `src/fs.sh`: cambiar `return 2` por `return 1` en `fs_is_file`, `fs_is_dir`, `fs_is_readable`, `fs_is_writable`, `fs_is_exec`, `fs_is_empty_file`.
- `tests/test_fs.sh`: cambiar asserts de status 2 a status 1 para argumento faltante.
- `README.md`: eliminar o reformular la nota de excepcion de la l. 350; ajustar descripciones de `fs_is_*` si mencionan `2` por missing.
- `.github/DEVELOPER.md`: ajustar seccion 3 para distinguir predicados (0/1) de transformadores/productoras (0/1/2).
- `.github/CONTRIBUTING.md`: matizar "missing argument checks" segun el tipo de funcion.
- `poshli.sh`: regenerar con `make bundle` tras cambiar `src/fs.sh`.
- `POSHLI_VERSION`: decidir en D3 (no tocar hasta aprobacion).

## 7. No se detectaron discrepancias adicionales

- `encoding_base64_*` cumplen su contrato documentado.
- Las funciones de `str.sh` cumplen su contrato, salvo la tension ya conocida sobre predicados vs. transformadores.
- Los resultados fueron identicos en `dash`, `bash --posix` y `busybox sh`.

## 8. Erratas historicas (nota anadida posteriormente)

Este documento es una instantanea historica de la Fase 0 y no se reescribe. Se anotan las siguientes erratas conocidas:

- `num_is_bin` y `num_is_bool`: el resultado correcto del caso de exito es `0`, no `1` (la tabla de la seccion 2 los muestra como `1`).
- `num_is_empty_file` es un error tipografico; la funcion correcta es `fs_is_empty_file`.
- La recomendacion de version `0.6.0` de la seccion 5 queda superada por la decision D3 aprobada: se mantiene `0.5.0`.
