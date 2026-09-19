# ADR 003 — Pipeline e hazards

- Estado: aceito
- Data: 2026-09-19

O destino é pipeline in-order IF/ID/EX/MEM/WB com `valid` em todos os registradores.
RAW usa forwarding; load-use insere uma bolha; branch/jump tomado invalida instruções
jovens. Misses e unidades multi-ciclo congelam o estado válido.

## Reference check

Patterson & Hennessy, 4ª ed., capítulos de pipeline e hazards. Aceite: trace mostra
uma bolha para load-use; contraprova: consumidor não pode observar dado antigo.
