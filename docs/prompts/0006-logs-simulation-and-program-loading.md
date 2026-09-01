# Log 0006 — Simulação e carregamento de programas

- Data: 2026-09-18
- Tipo: prompt/output

## Prompt

Precisamos de algumas atualizações arquiteturais no projeto.

- Não iremos desenvolver o projeto em cima de hardware real, ou seja, não utilizaremos FPGA. Dessa forma, a execução do circuito deverá ser totalmente simulada.
- Outro detalhe, como estamos desenvolvendo uma microarquitetura com RISC-V, não precisamos implementar um assembler, certo? Se não me engano li algo relacionado a isso... Caso realmente não seja necessário, remova a parte de implementar assembler dos arquivos que tiverem isso documentado.

As atualizações devem ser feitas em CONTEXT.md, TASKS.md e microarcitecture-audit.md.

## Output

Atualizações concluídas.

Não é necessário implementar um assembler para desenvolver ou simular uma microarquitetura RISC-V. A ISA define os encodings binários das instruções; o circuito pode receber diretamente imagens `.bin`/`.hex`, geradas externamente ou escritas como words codificadas nos testes. Um assembler próprio só seria necessário se fosse um objetivo didático ou uma ferramenta do projeto. A especificação oficial inclusive separa a definição da ISA da sintaxe de Assembly.

Atualizei [CONTEXT.md](/CONTEXT.md), [TASKS.md](/TASKS.md) e [docs/microarchitecture-audit.md](/docs/microarchitecture-audit.md) para:

- excluir FPGA, ASIC, síntese e hardware real; a execução e verificação passam a ser integralmente simuladas no container;
- substituir o montador por um carregador de imagens `.bin`/`.hex`;
- adaptar GUI/TUI, estrutura do repositório, comandos de demonstração, fases e critérios de aceite a esse fluxo;
- manter um toolchain RISC-V externo apenas como opção para gerar ou validar imagens, nunca como componente a implementar.

A referência normativa consultada foi a [especificação oficial RV32I](https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html), que define instruções de 32 bits e remete a sintaxe Assembly a documentação separada.
