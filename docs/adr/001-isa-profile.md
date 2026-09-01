# ADR 001 — Subconjunto RV32I explicável

- Estado: aceito
- Data: 2026-10-19

O perfil do trabalho é `ADDI`, `ADD`, `SUB`, `LW`, `SW`, `BEQ` e `EBREAK`. Extensões M, ponto flutuante, CSRs, sistema operacional, ABI e instruções RV32I fora dessa lista são excluídos.

## Reference check

A decisão usa RISC-V Unprivileged ISA, RV32I 2.1, para os encodings e efeitos das instruções aceitas. Aceite: cada encoding aceito produz apenas seu efeito arquitetural definido. Contraprova: `MUL` ou outra instrução fora do perfil para com `illegal_instruction=1` sem alterar estado adicional.
