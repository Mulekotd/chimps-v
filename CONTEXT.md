# CONTEXT — CHIMPS-V

> Documento vivo de produto e arquitetura. Mudanças de escopo atualizam especificações, testes e evidências.

## Produto e escopo

CHIMPS-V é um simulador educacional, determinístico e ciclo a ciclo de uma microarquitetura RISC-V. RTL VHDL é a fonte de verdade; GUI e CLI/TUI dirigem a simulação e consomem snapshots. A GUI mostra CPU, barramentos, caches, RAM e I/O; o modo headless serve a CI, automação e depuração.

Objetivos: relacionar instruções aos estágios IF/ID/EX/MEM/WB; observar hazards, stalls, flushes e CPI; demonstrar memória/cache e IEEE 754; reproduzir execuções por configuração, imagem de programa e trace.

## Decisões arquiteturais

| Item      | Decisão                                                                           |
| --------- | --------------------------------------------------------------------------------- |
| ISA-alvo  | RV32IMF_Zicsr; cada marco declara o subconjunto realmente disponível.             |
| Dados     | XLEN=32, little-endian, byte-addressable; 32 GPRs (x0=0) e 32 FPRs.               |
| Núcleo    | Pipeline in-order de cinco estágios; FPU e MUL/DIV inicialmente multi-ciclo.      |
| Memória   | RAM Von Neumann unificada; I-cache e D-cache separados sobre a mesma RAM backing. |
| I/O       | MMIO e FIFOs RX/TX; nenhum opcode fora da ISA.                                    |
| Interface | GUI desktop por snapshots versionados e CLI/TUI headless com o mesmo contrato.    |
| Entrega   | Docker/Compose e GHDL/VHDL-2008 para simulação, lint e testes.                    |

Marcos: RV32I, RAM, pipeline, carregador e trace; GUI; cache/MMIO; M; F; integração, Docker e demonstração. Não avançar com testes vermelhos.

O perfil de software e os encodings aceitos estão em [specs/isa-rv32i-chimps-v1.md](/specs/isa-rv32i-chimps-v1.md). A stack é uma convenção de software: `x2` é `sp`, cresce para baixo e usa `ADDI`, loads/stores, `JAL` e `JALR`; não há opcodes locais nem encodings reservados.

## Contratos do circuito

### Memória e carregamento

Uma RAM armazena programa e dados. O carregador escreve imagens `.bin` antes da execução e documenta endereço inicial, endianness, regiões e erros. O projeto não implementa assembler: Assembly, símbolos e toolchain externo são artefatos opcionais de geração e depuração.

| Faixa                   | Uso                                        |
| ----------------------- | ------------------------------------------ |
| 0x0000_0000–0x0000_FFFF | código, dados estáticos e heap educacional |
| 0x0001_0000–0x0001_7FFF | stack crescente para baixo                 |
| 0xFFFF_0000/04          | UART TX data/status                        |
| 0xFFFF_0008/0C          | UART RX data/status                        |
| 0xFFFF_0010             | SIM_CONTROL (halt/exit)                    |

LH, LW e FLW desalinhados geram trap/erro explícito. O barramento deve ter valid, ready, leitura/escrita, endereço, dados, máscara, error e origem.

### Datapath, pipeline e traps

O RTL inclui PC/próximo PC, decoder, imediatos, GPR/FPR, ALU, I/D-cache, RAM, load/store, MMIO, FPU, MUL/DIV, fcsr, traps e contadores. O fluxo comum usa registradores de pipeline; FSMs apenas para miss, FPU, MUL/DIV ou I/O bloqueante.

| Situação                  | Política                                          |
| ------------------------- | ------------------------------------------------- |
| RAW ALU                   | forwarding EX/MEM e MEM/WB                        |
| load-use                  | uma bolha: congela PC/IF-ID e injeta NOP em ID/EX |
| branch/jump tomado        | resolve em EX e invalida IF/ID e ID/EX            |
| miss/operação multi-ciclo | congela dependentes e preserva registros válidos  |
| store                     | efeito somente em MEM válido                      |
| exceção/halt              | estado preciso; instruções jovens anuladas        |

Todo registro de pipeline expõe valid, stall e flush; o trace contém PC, instrução, motivo e valores relevantes. A busca inicia com predição estática não tomada.

### Caches

Tags, dados, valid/dirty, comparadores e FSMs são RTL. A L1 direta de 1 KiB (64 conjuntos, linhas de 16 B, quatro words) é o primeiro bloco reutilizável: I-cache é somente leitura e D-cache direta usa write-through enquanto o pipeline/barramento compartilhado não existir. Ela conta acesso/hit/miss, faz refill, devolve erros e invalida a linha após erro de write-through.

O alvo final é I-cache direta de 1 KiB e D-cache de 1 KiB, duas vias, write-back/write-allocate, pseudo-LRU (round-robin no MVP), hit de um ciclo e miss configurável (padrão 10 ciclos). Dado dirty é escrito antes da vítima. Testes cobrem tag/index/offset, refill, máscara de bytes, conflito, write-back, invalidação da I-cache ao carregar imagem, erros e AMAT.

### Ponto flutuante

A meta F é binary32 (FLEN=32) com FLW/FSW, aritmética, FMA, comparações, classificação, conversões, moves, frm e fflags. RNE, RTZ, RDN, RUP, RMM e rm=111/frm seguem RISC-V; modos reservados são ilegais. As flags são NV, DZ, OF, UF, NX, sem traps FP. Casos: zero assinado, subnormal, infinito e NaN canônico 0x7fc00000.

A implementação só declara o subconjunto testado. FPRs, sign injection, min/max, comparações, classificação e moves de padrão binário passam pelo core com handshake explícito e acumulam `fflags` observável. Aritmética, conversões, load/store FP, acesso a `fcsr` e integração ao pipeline só liberam RV32F após validação contra SoftFloat.

### I/O e observabilidade

UART didático usa FIFOs RX/TX. RX vem de arquivo/script e TX é exibido pela TUI; RX vazio retorna zero por padrão. Um modo bloqueante exige stall explícito.

CycleSnapshot versionado (JSON inicialmente) contém ciclo, estado, instrução aposentada, estágios, GPR/FPR/CSRs, unidades funcionais, pipeline, barramentos, caches/RAM, MMIO, hazards, traps, métricas e configuração. Define endianness e estado pré/pós-clock; JSON/CSV permitem replay.

GUI e TUI têm passo por ciclo/instrução, execução, pausa, breakpoints, inspeção de RAM/cache/registradores/FIFO e métricas. A GUI destaca fetch→decode→execute→memory→write-back; a cor não é a única codificação. Ambas carregam `.bin` e exportam trace.

## Qualidade e operação

Cada requisito normativo fica em `specs/`, com testes e evidência correspondentes; decisões vão em `docs/adr/`, auditorias em `docs/audits/` e backlog em `docs/project/`. A pirâmide inclui unidade, módulo RTL, integração, arquitetural/diferencial e aceitação ciclo a ciclo. Gates executam lint, formatação, teste RTL, integração e smoke Docker.

Estrutura: `specs/` (fonte normativa), `docs/` (adr, audits, project, prompts), `rtl/`, `software/`, `cli/`, `tests/` e `scripts/`. Diretórios futuros só são introduzidos quando houver conteúdo implementado para eles.

Ferramentas: GHDL/VHDL-2008, VUnit ou OSVVM e Rust/Python para carregador/harness; Qt/C++ ou PySide/Python para GUI. O serviço Compose `rtl` executa GHDL na imagem, sem requerer GHDL instalado na máquina anfitriã. Fixar versões no Dockerfile/lockfiles.

```.sh
docker compose run --rm rtl scripts/lint-rtl.sh
docker compose run --rm rtl
```

Exportar ciclos, instruções aposentadas, CPI/IPC, stalls, flushes, branches, acessos/hits/misses/write-backs/AMAT, ocupação FPU/MUL/DIV e uso de FIFOs. A demonstração inclui forwarding, load-use, branch tomado, conflito de cache, UART e casos FP suportados.

O projeto está apresentável quando Docker reproduz a suíte; GUI e TUI produzem o mesmo snapshot; ISA suportada está declarada/testada; pipeline, memória e traps são explicáveis ciclo a ciclo; e cada requisito é rastreável.

Riscos: escopo F/divisão, divergência de timing, cache complexa, GUI que reimplementa o simulador e Docker não reprodutível. Mitigações: subconjunto declarado, traces/assertions, L1 direta inicial, CycleSnapshot único e CI do zero.

## Referências

- RISC-V International, Unprivileged ISA, RV32I e extensão F.
- IEEE 754-2019; Hennessy & Patterson; Patterson & Hennessy; Stallings; Tanenbaum; Esmeraldo; Smith, Cache Memories; Beck, TDD by Example; RFC 2119; Docker/Compose.
