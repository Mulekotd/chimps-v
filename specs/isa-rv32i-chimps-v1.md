# ISA CHIMPS-V v1

O perfil implementado é um subconjunto de RV32I com `IALIGN=32`: `ADDI`, `ADD`, `SUB`, `LW`, `SW`, `BEQ` e `EBREAK`. Os encodings e efeitos seguem a especificação RISC-V Unprivileged ISA, RV32I 2.1. O nome CHIMPS-V não define uma extensão RISC-V.

`LW` e `SW` usam words alinhadas. `BEQ` usa um deslocamento B alinhado e é resolvido em EX. `EBREAK` é usado como fim controlado da simulação, após o escoamento de instruções antigas. Todo encoding fora desta lista, acesso desalinhado ou erro da RAM é inválido para este marco e para a simulação com `illegal_instruction=1`.

Não há extensão M, instruções de byte/halfword, jumps, outros branches, `FENCE`, `ECALL`, CSR, AMO, ponto flutuante, modo privilegiado, ABI ou compatibilidade declarada com toolchains externos.
