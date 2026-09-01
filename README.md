# CHIMPS-V

CHIMPS-V é uma demonstração educacional, em VHDL-2008, de uma microarquitetura RISC-V simplificada. A simulação mostra uma pipeline IF/ID/EX/MEM/WB e o caminho CPU → cache → memória principal, incluindo cache hits e misses. Os requisitos normativos estão em [specs/](/specs/).

O perfil implementado é um subconjunto de RV32I: `ADDI`, `ADD`, `SUB`, `LW`, `SW`, `BEQ` e `EBREAK`. A cache é unificada, diretamente mapeada, com 16 linhas de uma word, write-through e no-write-allocate. Dependências RAW inserem bolhas; não há forwarding.

## Executar a simulação

```sh
docker compose build rtl
docker compose run --rm rtl
```

O comando compila as fontes canônicas e executa todo `tests/vhdl/tb_*.vhd`. O teste integrado carrega um pequeno programa, verifica RAW, store/load, hit, miss e flush de branch.

## Interfaces e biblioteca de pilha

CLI e MMIO não fazem parte deste marco. A GUI permanece prevista para visualizar a execução, mas ainda não tem implementação; enquanto isso, a observação ocorre por waveform e pelos sinais do topo definidos em [specs/cycle-snapshot.md](/specs/cycle-snapshot.md).

`software/` preserva uma biblioteca LIFO independente para o exercício de estruturas de dados e algoritmos. Seu teste hospedado pode ser executado com `cc -std=c11 -Wall -Wextra -Werror -I. tests/software/test_stack.c software/src/stack.c -o /tmp/chimpsv-stack-test && /tmp/chimpsv-stack-test`.

## Montador próprio

O próximo artefato será `assembler/`: um montador próprio que aceitará somente o subconjunto documentado e produzirá imagens little-endian para a porta `load_*` do sistema. A especificação, os diagnósticos obrigatórios e o limite de escopo estão em [specs/simplified-architecture.md](/specs/simplified-architecture.md). Ele ainda não está implementado.
