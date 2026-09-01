# ADR 006 — Cache diretamente mapeada de uma word

- Estado: aceito
- Data: 2026-10-19

Cada uma das 16 linhas guarda uma única word e uma tag. Os bits `[5:2]` selecionam a linha; uma tag diferente causa substituição em load. O tamanho pequeno facilita mostrar no waveform o índice, tag, `valid`, hit, miss e acesso à RAM.

Write-through preserva a RAM após cada `SW` bem-sucedido; no-write-allocate evita um refill extra para store em miss. Associatividade, LRU, linhas de quatro words, dirty bits, write-back, flush e caches separadas foram descartados por não contribuírem para o objetivo da apresentação.

## Reference check

Hennessy & Patterson, 5ª ed., capítulo 5, sustenta o compromisso entre custo de hardware e misses de conflito. Aceite: um load em linha vazia incrementa `misses` e instala a word; o segundo incrementa `hits`. Contraprova: uma linha com tag diferente não pode ser classificada como hit.
