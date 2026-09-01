# ADR 002 — RAM unificada e caches separadas

- Estado: aceito
- Data: 2026-09-19

Programa e dados residem na mesma RAM little-endian. I-cache e D-cache são clientes independentes de um barramento compartilhado; a RAM não contém política de cache. Erros do backing store retornam ao solicitante; durante write-back, a linha suja é preservada para nova tentativa.

## Reference check

Hennessy & Patterson, 5ª ed., capítulos de hierarquia de memória, fundamenta a separação entre armazenamento e política de cache. Aceite: um refill lê quatro words alinhadas; contraprova: erro de memória não valida a linha nem entrega dado válido.
