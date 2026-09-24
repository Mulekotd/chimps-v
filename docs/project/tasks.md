# CHIMPS-V — trabalho restante

Este arquivo deriva da auditoria em `docs/audits/microarchitecture.md` e contém somente trabalho ainda necessário para concluir o projeto. Marque um item apenas quando sua implementação e seus testes estiverem verdes.

## Correções da referência

- [x] Corrigir a RAM de 96 KiB para indexar toda a faixa sem alias e retornar erro para endereços fora dela.
- [x] Completar RV32I no datapath: shifts, `SLTI/SLTIU`, branches assinados/não assinados, `LB/LBU/LH/LHU`, `SB/SH`, máscaras e extensão de sinal.
- [x] Implementar alinhamento e traps precisos para fetch, load e store.
- [x] Implementar `FENCE` e os efeitos de `ECALL` e `EBREAK`.
- [x] Separar instruction-valid, illegal-instruction, trap, halt e trap-cause.
- [x] Criar testes arquiteturais positivos e contraprovas para cada encoding RV32I.

## Memória, cache e I/O

- [x] Definir uma única interface `valid/ready` canônica para cache e barramento.
- [x] Conectar core, I-cache, D-cache, `memory_bus` e RAM com stall por espera/erro.
- [x] Consolidar a I-cache direta e a D-cache 2-way write-back/write-allocate, removendo os caminhos legados duplicados depois da migração.
- [x] Completar testes da D-cache para máscara, LRU, dirty eviction, flush e erro.
- [x] Invalidar/atualizar I-cache após carregamento de uma nova imagem `.bin`.
- [x] Implementar MMIO UART TX/RX e `SIM_CONTROL` fora da RAM.
- [x] Implementar FIFOs RX/TX com backpressure e testes.
- [x] Expor acessos, hits, misses, write-backs, ciclos de serviço, stalls e AMAT.

## Pipeline

- [ ] Implementar IF/ID, ID/EX, EX/MEM e MEM/WB com `valid`, stall e flush.
- [ ] Migrar a referência para pipeline preservando o estado arquitetural.
- [ ] Implementar forwarding EX/MEM e MEM/WB.
- [ ] Implementar detecção load-use, congelamento e inserção de bolha.
- [ ] Resolver branch/jump e aplicar flush preciso de instruções jovens.
- [ ] Criar traces ciclo a ciclo para dependências, branches, stores e misses.

## Extensões M, Zicsr e F

- [x] Integrar as oito operações M ao decoder, stall e write-back do core.
- [ ] Implementar CSRs mínimos, seis instruções Zicsr e testes de acesso ilegal.
- [ ] Implementar entrada de trap com `mtvec`, `mepc`, `mcause` e `mtval`, além de retorno quando o perfil adotado o exigir.
- [x] Integrar FPR, decoder FP, FPU e write-back ao core para o subconjunto sem arredondamento (`FSGNJ*`, min/max, comparação, classificação e moves).
- [x] Integrar `FLW`/`FSW` ao caminho de memória FP.
- [x] Implementar aritmética, FMA, conversões W/WU, `fcsr`, `frm` e `fflags` por CSR.
- [ ] Cobrir rounding modes, zeros, NaNs, infinitos, subnormais e flags contra SoftFloat 3e.

## CLI, trace e software alvo

- [ ] Conectar o loader `.bin` do CLI à porta de carga do RTL/GHDL.
- [ ] Acrescentar comandos de run, pause, step-cycle, step-instruction, breakpoint, inspeção de registradores/RAM/cache/FIFO e diagnóstico de trap.
- [ ] Implementar produtor e validador de `CycleSnapshot v1` em JSON.
- [ ] Implementar exportação CSV, replay determinístico e métricas no CLI.
- [ ] Criar build cruzado reproduzível para `software/`, gerando imagens `.bin`.
- [ ] Completar runtime C, suporte de stack/calls e biblioteca MMIO mínima.
- [ ] Adicionar programas de demo para hazards, cache, UART, M e F.

## GUI e entrega

- [ ] Criar a GUI desktop consumindo o mesmo `CycleSnapshot` do CLI.
- [ ] Implementar stepping, breakpoints, timeline, inspeção e realce dos barramentos.
- [ ] Implementar testes de componente, integração e acessibilidade da GUI.
- [ ] Incluir build/test do CLI e software alvo no CI.
- [ ] Adicionar VUnit ou OSVVM, validação diferencial RISC-V e SoftFloat/TestFloat.
- [ ] Executar smoke Docker completo e roteiro de demonstração ponta a ponta.
- [ ] Confirmar o workflow remoto de CI e registrar a evidência.
