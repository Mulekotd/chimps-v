# CONTEXT — CHIMPS-V

CHIMPS-V é um trabalho de Arquitetura de Computadores cujo escopo é propositalmente pequeno e explicável. O RTL em [rtl/](/rtl/) é a fonte de verdade; [specs/](/specs/) define os contratos normativos.

O produto demonstra cinco estágios in-order, bolhas para dependências RAW, um desvio condicional com flush, RAM unificada e uma cache L1 unificada diretamente mapeada. A meta é explicar cada ciclo entre CPU, cache e memória principal, não reproduzir uma plataforma RISC-V completa.

O subconjunto é `ADDI`, `ADD`, `SUB`, `LW`, `SW`, `BEQ` e `EBREAK`. A cache tem 16 linhas de uma word, write-through e no-write-allocate. Não há forwarding, predição, I-cache/D-cache separadas, associatividade, write-back, MMIO, UART, FIFOs, RV32M, CSRs, traps ou ABI. A biblioteca de pilha em `software/` é mantida como exercício independente de estruturas de dados e algoritmos. A GUI permanece no escopo do projeto, mas ainda não foi implementada.

O montador próprio planejado aceitará apenas esse subconjunto e gerará imagens little-endian para o carregador de teste. Sua entrega é posterior ao RTL, com testes de encoding, rótulos e diagnósticos; até lá os testbenches carregam words diretamente durante reset.

A demonstração está pronta quando `docker compose run --rm rtl` reproduz o programa de integração e seus contadores mostram pelo menos um hit e um miss. O histórico, decisões e trabalho restante referenciam as especificações sem redefinir seus requisitos.
