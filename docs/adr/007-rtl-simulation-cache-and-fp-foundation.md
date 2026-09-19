# ADR 007 — Fundação RTL de simulação, cache e ponto flutuante

- Estado: aceito
- Data: 2026-09-19

## Decisão

O RTL será analisado e executado somente em simulação com GHDL e VHDL-2008. O
cache direto existente é o bloco reutilizável da L1: transações de leitura sofrem
refill de uma linha de 16 B e escritas fazem write-through com atualização da cópia
local. I-cache e D-cache são instâncias especializadas desse bloco; a I-cache recusa
escritas. A política D-cache associativa/write-back descrita como evolução no
contexto continua dependente do pipeline e do barramento compartilhado, inexistentes
neste marco.

A fundação FP implementa o estado `f0`–`f31`, a classificação IEEE binary32 e as
operações sem arredondamento (`FSGNJ*`, `FMIN.S`, `FMAX.S`, `FEQ.S`, `FLT.S`,
`FLE.S` e `FCLASS.S`). As operações aritméticas, conversões, `FLW/FSW`, `fcsr` e a
integração no decoder/pipeline não estão completas; portanto este repositório não
declara ainda conformidade `RV32F` completa.

## Reference check

- Questão: quais são o estado e as regras observáveis da extensão F antes de
  integrar uma FPU ao núcleo.
- Referência normativa: RISC-V Unprivileged ISA, extensão F v2.2, §§20.1.1–20.1.3
  e §§20.1.7–20.1.9; IEEE 754-2008 é a norma de aritmética indicada pela extensão.
- Decisão: usar 32 FPRs de 32 bits, preservar os bits nas operações de movimento,
  retornar NaN canônico `0x7fc00000` em `FMIN/FMAX` quando ambos operandos são NaN
  e sinalizar `NV` nas comparações especificadas com NaN.
- Critério: o testbench deve distinguir `+0`, `-0`, subnormal, infinito, qNaN e
  sNaN; deve ainda comprovar `FSGNJ`, `FMIN` com zero assinado e `FLT` com NaN.
  Contraprova: uma entrada sNaN deve produzir `NV`, e qualquer comparação com NaN
  deve resultar em zero.

## Consequências

As interfaces de FP são síncronas e têm latência de uma borda de clock para tornar
`start`/`done` e flags observáveis. O próximo marco deve acrescentar aritmética com
rounding modes, `fcsr`, load/store FP e hazards; até lá, programas que usem essas
instruções devem ser rejeitados pelo decoder.
