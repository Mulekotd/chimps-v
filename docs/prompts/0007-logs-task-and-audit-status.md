# Log 0007 — Estado de tarefas e auditoria

- Data: 2026-09-19
- Tipo: prompt/output

## Prompt

Atualize os documentos TASKS.md e microarchitecture-audit.md com base nas implementações recentes que fiz de FPU, I-cache, D-cache em VHDL.

## Output

Atualizei [TASKS.md](/TASKS.md) e
[docs/microarchitecture-audit.md](/docs/microarchitecture-audit.md) para refletir:

- o perfil ISA, a stack em software e os traps já especificados;
- a L1 direta e wrappers existentes, ainda sem barramento/integrados ao core;
- a unidade RV32M e seu testbench como implementação isolada ainda pendente de
  execução no container e integração ao decoder/core;
- a ausência de MMIO/FIFO, CSRs, pipeline, D-cache associativa e RV32F completo.
