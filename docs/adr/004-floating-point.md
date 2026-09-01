# ADR 004 — Escopo de ponto flutuante

- Estado: aceito
- Data: 2026-09-19

FP usa binary32 e 32 FPRs. O core já conecta sign injection, min/max, comparações,
classificação, `FMV.W.X`/`FMV.X.W` e o acumulador observável de `fflags`; `fcsr`
(`frm`/`fflags`) ainda não é acessível por CSR. A conformidade RV32F só é declarada
após operações, loads/stores, arredondamento e comparação contra SoftFloat.

## Reference check

RISC-V F v2.2 e IEEE 754-2019 definem representação, NaN, exceções e arredondamento. Aceite: sinais e resultado concordam com oráculo; contraprova: sNaN aciona NV.
