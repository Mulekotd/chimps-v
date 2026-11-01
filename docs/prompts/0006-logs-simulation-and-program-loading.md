# Log 0006 — Simulação e carregamento de programas

- Data: 2026-09-18
- Tipo: prompt/output

## Prompt

Precisamos de algumas atualizações arquiteturais no projeto.

- Não iremos desenvolver o projeto em cima de hardware real, ou seja, não utilizaremos FPGA. Dessa forma, a execução do circuito deverá ser totalmente simulada.

As atualizações devem ser feitas em CONTEXT.md, TASKS.md e microarcitecture-audit.md.

## Output

Atualizações concluídas.

Atualizei [CONTEXT.md](/CONTEXT.md), [TASKS.md](/TASKS.md) e [docs/microarchitecture-audit.md](/docs/microarchitecture-audit.md) para:

- excluir FPGA, ASIC, síntese e hardware real; a execução e verificação passam a ser integralmente simuladas no container;
- adaptar GUI, estrutura do repositório, comandos de demonstração, fases e critérios de aceite a esse fluxo;
- manter um toolchain RISC-V externo apenas como opção para gerar ou validar imagens, nunca como componente a implementar.

A referência normativa consultada foi a [especificação oficial RV32I](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html), que define instruções de 32 bits e remete a sintaxe Assembly a documentação separada.
