# Log 0005 — Início da implementação em VHDL

- Data: 2026-09-08
- Tipo: prompt/output

## Prompt

Quero iniciar a implementação dos microcircuitos em VHDL. Por onde eu devo começar? Quais microcircuitos eu devo desenvolver levendo em consideração a microarquitetura que estruturamos?

## Output

Comece por um vertical slice mínimo de `RV32I`, validando o caminho completo de uma instrução antes de implementar cache, FPU ou a GUI. A ordem recomendada é:

1. VHDL-2008, `numeric_std`, GHDL + VUnit/OSVVM, contratos em packages e testbenches antes do RTL.
2. PC, registradores, ALU, gerador de imediatos, decoder, banco de registradores e RAM unificada.
3. Núcleo RV32I não pipeline com `ADDI`, `ADD`, `SUB`, `LW`, `SW` e `BEQ`.
4. Pipeline IF/ID/EX/MEM/WB e seus registradores de estágio.
5. Forwarding, hazards, stalls e flushes.
6. I-cache, D-cache, MMIO e FIFOs.
7. MUL/DIV e, por último, FPU IEEE 754.
8. Snapshots de ciclo para a GUI desde o início, com a janela implementada depois do primeiro trace correto.

O primeiro conjunto de arquivos deve conter `chimps_pkg.vhd`, `pc_reg.vhd`, `register_file.vhd`, `alu.vhd`, `imm_gen.vhd`, `decoder.vhd`, `ram.vhd`, `core_rv32i_single.vhd` e seus testbenches. O primeiro programa de aceitação deve executar `addi`, `add`, `lw`, `sw` e `beq`, verificando PC, registradores, RAM e quantidade de ciclos.

Regras importantes: separar lógica combinacional de registradores de estado, usar `valid`/`stall`/`flush` explicitamente, não usar `wait for` no RTL sintetizável, manter uma única RAM principal e tratar SoftFloat apenas como oráculo de teste da FPU. O `CONTEXT.md` ainda menciona SystemVerilog em alguns pontos; antes da implementação definitiva, registrar VHDL como decisão no ADR/toolchain.
