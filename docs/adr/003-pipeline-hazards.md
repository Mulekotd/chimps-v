# ADR 003 — Bolhas em vez de forwarding

- Estado: aceito
- Data: 2026-10-19

A pipeline tem IF, ID, EX, MEM e WB. Quando ID lê um registrador que uma instrução válida em ID/EX, EX/MEM ou MEM/WB ainda escreverá, ID é mantido e uma bolha entra em EX. Não há forwarding, predição ou tratamento de hazard além de RAW. `BEQ` resolve em EX e anula IF/ID quando tomado.

## Reference check

Patterson & Hennessy, 4ª ed., capítulos sobre pipeline e hazards, descreve o conflito RAW e a inserção de bolha como alternativa a forwarding. Aceite: `ADDI x1,...` seguido de consumidor recebe o resultado novo. Contraprova: sem as bolhas, o store dependente observaria o valor anterior.
