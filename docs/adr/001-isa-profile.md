# ADR 001 — Perfil ISA por marcos

- Estado: aceito
- Data: 2026-09-19

O núcleo declara somente o subconjunto que possui decoder, execução e testes. O alvo é RV32IMF_Zicsr, mas marcos intermediários rejeitam extensões ainda não integradas. Instruções inválidas, desalinhamento e `ECALL`/`EBREAK` entram em trap preciso.

## Reference check

A decisão segue a especificação RISC-V Unprivileged ISA v20260120 (RV32I, M, F e
Zicsr). Aceite: encoding suportado altera somente o estado arquitetural previsto;
contraprova: encoding reservado produz causa de instrução ilegal.
