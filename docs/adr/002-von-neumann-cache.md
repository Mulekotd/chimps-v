# ADR 002 — RAM e cache unificadas

- Estado: aceito
- Data: 2026-10-19

Programa e dados residem na mesma RAM little-endian de 96 KiB e usam uma única cache L1. A cache tem 16 linhas diretamente mapeadas, uma word por linha, write-through e no-write-allocate. Uma cache única reduz estado e torna o caminho CPU → cache → RAM visível sem introduzir coerência entre I-cache e D-cache.

## Reference check

Hennessy & Patterson, 5ª ed., capítulo 5, fundamenta a distinção entre hit, miss, mapeamento direto e política de escrita. Aceite: dois loads para a mesma word após um store produzem miss e hit observáveis. Contraprova: um store em miss não instala linha e ainda alcança a RAM por write-through.
