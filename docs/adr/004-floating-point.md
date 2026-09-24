# ADR 004 — Escopo de ponto flutuante

- Estado: aceito
- Data: 2026-09-19

FP usa binary32, 32 FPRs e o estado `fcsr` formado por `frm`/`fflags`. O core conecta operações de sinal, min/max, comparações, classificação, aritmética, FMA, conversões W/WU, `FLW`/`FSW` e os acessos Zicsr a `fflags`, `frm` e `fcsr`. O oráculo SoftFloat 3e confere vetores dirigidos. Conformidade RV32F completa permanece condicionada a RMM e validação diferencial extensa de flags/subnormais. A semântica normativa e os limites implementados estão em [`specs/fp-subset.md`](/specs/fp-subset.md).

## Reference check

RISC-V F v2.2 e IEEE 754-2019 definem representação, NaN, exceções e arredondamento. Aceite: sinais e resultado concordam com oráculo; contraprova: sNaN aciona NV.
