# CHIMPS-V — Plano de tarefas

Lista operacional derivada do [`/CONTEXT.md`](/CONTEXT.md) e da auditoria em
[`/docs/microarchitecture-audit.md`](/docs/microarchitecture-audit.md).

## Como usar

- Toda tarefa deve ter uma especificação em `specs/`, testes e evidência de execução.
- Marcar uma tarefa como concluída somente quando o teste correspondente estiver verde.
- Registrar decisões com trade-offs em `docs/adr/`.
- Preservar a separação: RTL é a fonte do estado microarquitetural; simulador/GUI
  observam e dirigem sinais, mas não reimplementam regras do processador.

## Prioridade imediata — referência e integração da L1

- [ ] Criar ADRs 001–006: ISA, Von Neumann/cache, pipeline/hazards, FPU,
  toolchain VHDL e GUI/`CycleSnapshot`.
- [ ] Criar `specs/isa-rv32i-chimps-v1.md` com o subconjunto inicial e encodings.
- [ ] Criar `specs/memory-map.md`, `specs/memory-bus.md` e `specs/cycle-snapshot.md`.
- [ ] Adicionar testbenches para `imm_gen`, decoder, register file e RAM.
- [ ] Criar testbench de integração do `core_rv32i_single` usando a porta `load_*`.
- [ ] Criar testbench da L1 direta: hit, miss, refill de quatro words, write-through,
  write-allocate, byte mask, erro da memória e contadores.
- [ ] Criar um adaptador `memory_bus` entre CPU, L1 e `main_memory` com
  `valid/ready/address/wdata/wmask/rdata/error`.
- [ ] Instanciar uma L1 de instruções e uma L1 de dados no caminho do core.

## Pipeline e microarquitetura

- [ ] Implementar registradores `IF/ID`, `ID/EX`, `EX/MEM` e `MEM/WB` com `valid`.
- [ ] Migrar a referência single-cycle para pipeline sem alterar o estado arquitetural.
- [ ] Implementar forwarding EX/MEM e MEM/WB.
- [ ] Implementar hazard unit para load-use, stalls e injeção de bolha.
- [ ] Implementar flush de branch/jump e estado preciso para instruções inválidas.
- [ ] Criar traces ciclo a ciclo para ALU→ALU, load→use, branch tomado e store.

## ISA, assembler e traps

- [ ] Completar o perfil RV32I: shifts, `SLTI*`, loads/stores byte/halfword, `FENCE`,
  `ECALL`/`EBREAK` e traps declarados.
- [ ] Separar `instruction_valid`, `illegal_instruction` e `halt/trap_cause`.
- [ ] Implementar assembler com labels, `.text`, `.data`, `.word`, `.byte`, `.float`,
  símbolos, listagem e diagnósticos.
- [ ] Fazer validação diferencial contra toolchain/modelo RISC-V para o subconjunto.

## Memória e I/O

- [ ] Validar a L1 direta como marco inicial de I-cache.
- [ ] Evoluir a D-cache para 2-way, dirty bit, write-back e write-allocate conforme
  o `CONTEXT.md`.
- [ ] Implementar MMIO fora da RAM: UART TX/RX, status e `SIM_CONTROL`.
- [ ] Implementar FIFOs RX/TX com `empty`, `full`, `count`, `push`, `pop` e testes.
- [ ] Expor acessos, hits, misses, write-backs, AMAT e stalls ao trace.

## Extensão M e ponto flutuante

- [ ] Implementar `MUL`, `MULH`, `MULHSU`, `MULHU`, `DIV`, `DIVU`, `REM` e `REMU`.
- [ ] Definir protocolo multi-ciclo `start/busy/done` e seus hazards.
- [ ] Implementar CSRs mínimos e `Zicsr` antes do `F`.
- [ ] Implementar FPRs, `FLW/FSW`, FPU binary32, `fcsr`, `frm` e `fflags`.
- [ ] Cobrir arredondamento, NaN, infinitos, subnormais e exceções com SoftFloat como
  oráculo de testbench.

## Observabilidade e entrega

- [ ] Definir e versionar `CycleSnapshot` com estado, sinais, barramentos, pipeline,
  cache, traps e métricas.
- [ ] Criar exportação JSON/CSV e replay determinístico de snapshots.
- [ ] Construir protótipo da GUI mostrando `ADDI` e `LW` no esquemático CPU↔RAM.
- [ ] Adicionar timeline, passo por ciclo, breakpoints, inspeção de registradores,
  RAM, cache e realce de barramentos.
- [ ] Manter CLI/TUI headless consumindo o mesmo snapshot da GUI.
- [ ] Criar Dockerfile, Compose e CI com GHDL/VUnit ou OSVVM.
- [ ] Executar testes arquiteturais, integração, smoke test Docker e roteiro de demo.

## Critério de conclusão

O projeto pode ser apresentado quando a ISA suportada estiver declarada, os testes
forem reproduzíveis no Docker, o pipeline e a hierarquia de memória produzirem
traces corretos, a GUI mostrar o caminho CPU↔RAM ciclo a ciclo e a execução
headless reproduzir os mesmos snapshots.
