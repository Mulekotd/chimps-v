# Microarquitetura simplificada — auditoria e guia

- Data: 2026-10-19
- Escopo: RTL, testes, scripts, Compose, biblioteca de pilha e documentação; CLI, runtime e programa executável alvo estão excluídos

## Resultado

O projeto foi consolidado em um único caminho de demonstração: `pipeline` → `memory_bus` → `cache_l1` → `memory_backing_store`. A pipeline tem estágios IF/ID/EX/MEM/WB; a cache é unificada, diretamente mapeada, com 16 linhas de uma word, write-through e no-write-allocate. A regressão RTL cobre dependência RAW por bolhas, store/load, hit, miss, rejeição de encoding inválido e flush de `BEQ`.

## Limite preservado

O montador é um requisito futuro, documentado em [specs/simplified-architecture.md](/specs/simplified-architecture.md), e não substitui uma implementação existente. Portanto, não há fonte de montador a podar neste marco.

## Biblioteca de pilha

A biblioteca `software/include/stack.h` e `software/src/stack.c` é mantida como exercício de estruturas de dados e algoritmos. Ela implementa uma pilha LIFO de `uint32_t` sobre armazenamento fornecido pelo chamador, sem heap, runtime ou MMIO; não declara compatibilidade com ABI ou instruções RISC-V.

### Verificação de referências

- Componente e contrato: `TSTACK` inicializa um buffer do chamador e expõe `push`, `pop` e `top` com ordem LIFO; capacidade esgotada retorna `TSTACK_OVERFLOW`, pilha vazia retorna `TSTACK_UNDERFLOW` e argumentos ou estado inválidos retornam `TSTACK_INVALID`.
- Referência: Tanenbaum, *Organização Estruturada de Computadores*, 3ª ed., capítulos 1, 2 e 4, para a organização LIFO de uma pilha. Não há alegação de compatibilidade com ABI ou instruções RISC-V, portanto a especificação ISA não é aplicável a esta biblioteca.
- Decisão: preservar a API sem alocação dinâmica para que possa ser exercitada tanto em testes hospedados quanto no futuro software alvo.
- Aceite: duas inserções seguidas de `top` e duas remoções retornam os valores na ordem inversa. Contraprova: `pop` em pilha vazia não altera a saída e retorna `TSTACK_UNDERFLOW`; uma inserção além da capacidade retorna `TSTACK_OVERFLOW` sem alterar a pilha.

## Interface gráfica pendente

A GUI permanece no escopo do projeto, mas ainda não possui implementação. A remoção do CLI e de MMIO simplifica o marco atual e não remove a futura interface gráfica. Por enquanto, a observação da simulação ocorre por sinais do topo e waveform, conforme [specs/cycle-snapshot.md](/specs/cycle-snapshot.md).

## Palavra e endereçamento

A palavra arquitetural, registradores, instruções, endereços e dados têm 32 bits. Instruções e `LW`/`SW` são alinhados a quatro bytes. A RAM unificada possui 96 KiB, é byte-addressable e little-endian, mas a pipeline gera apenas words com máscara `1111`.

## Decodificação e etapas observáveis

Os requisitos normativos estão em [specs/simplified-architecture.md](/specs/simplified-architecture.md). O CHIMPS-V não usa microcódigo, decoder separado ou FSM multi-ciclo: a `pipeline` reconhece o pequeno subconjunto e transfere dados entre IF/ID, ID/EX, EX/MEM e MEM/WB.

| Estágio | Responsabilidade |
| --- | --- |
| IF | Mantém PC e requisição até receber uma instrução pela cache. |
| ID | Aceita apenas uma instrução do subconjunto, lê `rs1`/`rs2` e insere bolhas para RAW. |
| EX | Soma/subtrai, calcula endereço ou compara `BEQ`; branch tomado descarta IF/ID. |
| MEM | Mantém `LW`/`SW` até a resposta da cache e da RAM. |
| WB | Grava `rd`, preservando `x0=0`, e emite `retired`. |

As instruções aceitas são `ADDI`, `ADD`, `SUB`, `LW`, `SW`, `BEQ` e `EBREAK`. `EBREAK` interrompe fetch e escoa instruções anteriores. Encodings fora da lista ou falhas da memória resultam em `illegal_instruction=1`.

## Conjunto de instruções implementado

Os encodings e a semântica normativa do subconjunto estão em [specs/isa-rv32i-chimps-v1.md](/specs/isa-rv32i-chimps-v1.md).

| Instrução | Opcode | Condição adicional | Efeito |
| --- | --- | --- | --- |
| `ADDI` | `0010011` | `funct3=000` | `rd ← rs1 + immI` |
| `ADD` | `0110011` | `funct3=000`, `funct7=0000000` | `rd ← rs1 + rs2` |
| `SUB` | `0110011` | `funct3=000`, `funct7=0100000` | `rd ← rs1 - rs2` |
| `LW` | `0000011` | `funct3=010` | `rd ← Mem[rs1 + immI]` |
| `SW` | `0100011` | `funct3=010` | `Mem[rs1 + immS] ← rs2` |
| `BEQ` | `1100011` | `funct3=000` | se iguais, `pc ← pc + immB` |
| `EBREAK` | `1110011` | word `00100073` | encerra a simulação após escoamento |

Todas as demais instruções são rejeitadas; elas não são parcialmente decodificadas nem prometidas ao montador planejado.

## Cache e RAM

A cache é unificada, diretamente mapeada, e contém 16 linhas de uma word. `LW` em linha inválida ou tag diferente é miss e busca a word na RAM; a repetição é hit. Um `SW` bem-sucedido sempre alcança a RAM (write-through) e atualiza somente uma linha já presente (no-write-allocate). Os contadores do topo permitem demonstrar `accesses = hits + misses`.
