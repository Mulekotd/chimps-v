# Trabalho restante

Este backlog deriva dos requisitos em [specs/](/specs/) e mantém somente trabalho compatível com a apresentação didática.

## Montador próprio

- [ ] Criar `assembler/` com parser de `ADDI`, `ADD`, `SUB`, `LW`, `SW`, `BEQ` e `EBREAK`.
- [ ] Implementar rótulos de `BEQ`, imediatos decimal/hexadecimal, registradores `x0`–`x31` e saída binária little-endian.
- [ ] Criar testes positivos de encoding e testes de rejeição para opcode, registrador, rótulo, imediato e alinhamento inválidos.
- [ ] Documentar invocação e o contrato do arquivo de saída depois que o montador existir.

## Apresentação e qualidade

- [ ] Preparar waveform/roteiro que identifique IF, ID, EX, MEM, WB, bolhas RAW, branch tomado, hit e miss.
- [ ] Acrescentar casos de teste pequenos para `SUB`, acesso desalinhado e encoding não suportado.
- [ ] Executar a regressão Docker no ambiente de apresentação e registrar a evidência.

## Interface gráfica

- [ ] Implementar uma GUI para visualizar a execução da microarquitetura. A GUI permanece prevista, mas ainda não há implementação; até ela existir, a observação é feita por waveform e sinais do topo.

Itens removidos do escopo: CLI, snapshots, MMIO/UART, runtime e programa executável alvo, RV32M, CSRs/traps, forwarding, predição, cache associativa e write-back. A biblioteca de pilha em `software/` permanece como exercício de estruturas de dados e algoritmos.
