# Arquitetura didática simplificada

Este documento é normativo para o marco de apresentação. O CHIMPS-V implementa um subconjunto explícito de RV32I, uma pipeline in-order de cinco estágios e uma RAM unificada protegida por uma cache L1 unificada diretamente mapeada. O objetivo é observar, ciclo a ciclo, CPU → cache → memória principal, incluindo hit e miss, sem recursos que não fazem parte da demonstração.

## Contrato do sistema

- A pipeline tem os estágios IF, ID, EX, MEM e WB, com no máximo uma instrução em cada registrador de estágio.
- O PC inicia em `0x0000_0000`; todas as instruções têm 32 bits e devem estar alinhadas a quatro bytes.
- A RAM tem 96 KiB, é byte-addressable e little-endian. O carregamento ocorre apenas enquanto `rst=1`.
- A cache é unificada, diretamente mapeada, possui 16 linhas de uma word (64 B), tem write-through e no-write-allocate. Um load que não encontra a linha faz uma leitura da RAM e a instala; um store sempre alcança a RAM e atualiza a linha somente se ela já estiver presente.
- A cache publica contadores de acessos, hits e misses. Um hit de leitura devolve a word sem acesso à RAM; o miss de leitura só conclui após a resposta da RAM.
- A RAM aceita uma requisição por vez. `memory_bus` dá prioridade à requisição de dados sobre a busca de instrução quando ambas concorrem.
- Durante uma espera de cache ou RAM, os registradores da pipeline ficam estáveis. Dependências RAW são resolvidas com bolhas no estágio ID até que o produtor escreva em WB; não há forwarding.
- `BEQ` é decidido em EX e descarta a instrução em IF/ID. `EBREAK` para o fetch, escoa instruções mais antigas e então encerra a simulação. Encoding não pertencente ao subconjunto ou acesso de word desalinhado encerra a simulação com `illegal_instruction=1`.

## Subconjunto RV32I

| Grupo | Instruções |
| --- | --- |
| Aritmética | `ADDI`, `ADD`, `SUB` |
| Memória | `LW`, `SW` |
| Controle | `BEQ`, `EBREAK` |

Qualquer outra instrução, inclusive extensões M, CSRs, byte/halfword, jumps e branches relacionais, é rejeitada. Não há MMIO neste marco. O projeto não declara suporte a ABI, sistema operacional, modo privilegiado ou compatibilidade com toolchains RISC-V externos além do encoding dessas instruções.

## Reference check

- **Componente e questão:** pipeline in-order, dependências, cache diretamente mapeada e encodings do subconjunto RV32I.
- **Referências:** RISC-V Unprivileged ISA, RV32I, versão 2.1, para os encodings e efeitos de `ADDI`, `ADD`, `SUB`, `LW`, `SW`, `BEQ` e `EBREAK`; Patterson & Hennessy, 4ª ed., capítulos sobre pipeline, hazards de dados e controle; Hennessy & Patterson, 5ª ed., capítulo 5, para hit, miss e cache diretamente mapeada.
- **Decisão:** bolhas em vez de forwarding, cache de uma word por linha e write-through/no-write-allocate. São desvios didáticos de desempenho, não da semântica arquitetural das instruções aceitas.
- **Aceite:** um programa com `ADDI`, dependência RAW, `SW`, dois `LW` no mesmo endereço e `BEQ` produz `8` na RAM, ao menos um miss e um hit, e não executa o store após o branch.
- **Contraprova:** um encoding `MUL` ou um load/store desalinhado encerra a execução sem produzir efeito arquitetural adicional; um store no caminho anulado não é executado nem altera a RAM.

## Montador planejado

O próximo artefato de software será `assembler/`, um montador próprio e independente do RTL. Ele aceitará somente as sete instruções acima, registradores `x0` a `x31`, números decimais/hexadecimais e rótulos para `BEQ`; produzirá uma imagem binária little-endian carregável pela porta `load_*` do sistema. Ele deve rejeitar instruções fora do subconjunto, registradores inválidos, rótulos ausentes, imediatos fora da faixa e desalinhamento, com diagnóstico de linha. A implementação do montador não faz parte deste marco de simplificação; sua especificação será convertida em testes de formato antes da implementação.
