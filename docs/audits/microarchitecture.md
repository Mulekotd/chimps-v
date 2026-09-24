# Auditoria arquitetural do CHIMPS-V

- Data: 2026-09-20
- Escopo revisado: `CONTEXT.md`, ADRs, especificações, RTL, testbenches, scripts, Compose, CLI e software alvo
- Evidência: regressão Docker concluída com 14 testbenches; CLI testado localmente

## Resultado executivo

O repositório contém uma referência RV32IM com subconjunto FP, sequencial multi-ciclo e executável em GHDL. PC, decoder, imediatos, GPR/FPR, ALU, unidade M, FPU I-cache, D-cache, árbitro e RAM backing formam um único caminho integrado. O core retém requests até `ready`, executa M/FP com `start/done` e interrompe em erro ou encoding inválido.

`fp_register_file`, `fp_pkg` e `fpu` atendem operações de sinal, min/max, comparações, classificação, aritmética, FMA e conversões W/WU. `FLW`/`FSW` e os CSRs `fflags`/`frm`/`fcsr` estão ligados ao estado arquitetural. RMM e validação diferencial ampla de flags/subnormais ainda impedem a declaração de RV32F completo.

O projeto está no **Marco 2 — referência integrada de memória, RV32M e subconjunto FP**. Ainda não é um processador `RV32IMF_Zicsr`, não possui pipeline IF/ID/EX/MEM/WB, CSRs, MMIO ou o simulador observável descrito no produto.

## Estado por subsistema

| Subsistema | Estado | Evidência e limite atual |
| --- | --- | --- |
| Toolchain RTL | Funcional | GHDL/VHDL-2008 em Docker; 13 testbenches verdes. |
| Core | Parcial | `core_rv32i_single` sequencial com handshake `valid/ready`, GPR, ALU e M. |
| RV32I | Parcial | Decoder reconhece mais encodings, mas byte/halfword, branches relacionais, traps e efeitos SYSTEM não estão implementados no datapath. |
| RV32M | Integrado | As oito operações usam `start/done`, stall e write-back no core. |
| RV32F | Estado arquitetural parcial | FPR, aritmética/FMA, conversões W/WU, `FLW`/`FSW`, `fcsr` e vetores SoftFloat; faltam RMM e validação diferencial ampla. |
| Zicsr/traps | Ausente | Não há CSR file, máquina de trap, `mtvec`, `mepc`, `mcause` ou `mtval`. |
| RAM | Integrada | `memory_backing_store` é a única RAM, com loader, máscaras, limite de 96 KiB e sem alias. |
| Barramento | Integrado | `memory_bus` arbitra I/D-cache para a RAM backing. |
| I-cache/D-cache | Integradas | `cache_l1` instancia I-cache direta e D-cache duas vias write-back/write-allocate. |
| MMIO/FIFOs | Ausente | O mapa está especificado; não há RTL UART, `SIM_CONTROL` ou FIFOs. |
| Snapshot/trace | Especificado | `CycleSnapshot v1` é texto; não há captura, JSON/CSV, replay ou CLI consumidora. |
| CLI | Inicial | Carrega e valida somente imagens `.bin`; ainda não controla GHDL nem produz snapshots. |
| Software alvo | Inicial | Runtime, linker script e mapa MMIO foram separados em `software/`; falta toolchain/build e programas. |
| GUI/TUI | Ausente | Não existem frontend, stepping, breakpoints ou visualização. |
| CI | Parcial | O fluxo Docker local existe; o workflow remoto deve ser confirmado e ampliado com CLI. |

## Topologia atual

```text
                         caminho integrado
 PC -> I-cache -> decoder -> GPR/imediato -> ALU/M -> D-cache
                  \                         /
                   \---- memory_bus -> RAM backing

                         caminho integrado
                         FPR/FPU (subconjunto FP)

 CLI .bin loader -> buffer do processo host (ainda sem ponte para o RTL)
 software/       -> futura imagem alvo RISC-V
```

O core é sequencial e mantém uma instrução em voo. Fetch, acesso a dados e RV32M retêm estado até a resposta; continua sem pipeline ou traps arquiteturais precisos. `cache_l1` é a única implementação L1, parametrizada para I-cache e D-cache.

## Achados prioritários

1. **Fechar RV32I na referência.** Implementar máscaras, alinhamento, extensão de sinal, todos os branches, `FENCE`, `ECALL/EBREAK` e trap preciso antes do pipeline.
2. **Criar o pipeline somente sobre uma referência estável.** Implementar registros IF/ID, ID/EX, EX/MEM e MEM/WB, forwarding, load-use stall e flush de controle.
3. **Fechar a conformidade RV32F.** Completar RMM, flags precisas e validação diferencial SoftFloat para subnormais, NaNs, infinitos e todos os arredondamentos.
4. **Transformar snapshot em contrato executável.** O mesmo produtor deve atender CLI/TUI e GUI, incluindo métricas de pipeline, cache, MMIO e unidades funcionais.
5. **Manter host e alvo separados.** `cli/` é software nativo que dirige a simulação; `software/` é C/assembly RISC-V executado pelo core e gera somente `.bin`.

## Critérios de finalização

- Regressões unitária, integração, arquitetural/diferencial e smoke passam no Docker.
- O subconjunto ISA declarado coincide com decoder, efeitos arquiteturais e traps.
- Pipeline e referência produzem o mesmo estado final para os programas aceitos.
- I/D-cache compartilham uma RAM sem alias; cada stall/miss/write-back é observável.
- CLI carrega `.bin`, dirige execução, stepping e breakpoints e exporta snapshots.
- Software C alvo possui runtime, linker, build reprodutível e programas de demo.
- GUI e CLI consomem o mesmo `CycleSnapshot` e reproduzem o mesmo trace.
- README, ADRs, specs e tarefas descrevem somente comportamento comprovado.

## Referências verificadas

Comportamento ISA deve seguir a biblioteca oficial RISC-V: RV32I 2.1, M 2.0, F 2.2, Zicsr 2.0 e Machine-level ISA. A especificação Zicsr exige operações atômicas read/modify/write e regras especiais para `rd=x0` e `rs1/uimm=0`. SoftFloat 3e é executado como oráculo de vetores binary32 dirigidos. A validação diferencial de rounding modes, flags e valores especiais ainda deve ser ampliada.

## Auditoria de legado — métricas e testes de cache (2026-09-23)

A ampliação de métricas e cobertura da `cache_l1` é aditiva: não substitui cache, interface de barramento, testbench ou caminho de produção existente. Portanto, não há fonte, manifesto, documentação ou teste legado a remover; `cache_l1` continua a única implementação canônica de I-cache e D-cache.

## Auditoria de legado — MMIO e FIFOs (2026-09-23)

UART/FIFOs são adições ao mapa de memória, sem implementação anterior substituída. Nenhum RTL ou teste legado foi removido; `byte_fifo` e `mmio_uart` são os únicos donos canônicos desses estados.

## Auditoria de legado — biblioteca de stack (2026-09-23)

`TSTACK` anterior dependia de heap inexistente no runtime alvo e tinha loops de contagem inválidos. Foi substituída pela API de armazenamento do chamador em `software/include/stack.h`; não há chamadores ativos da API antiga.
