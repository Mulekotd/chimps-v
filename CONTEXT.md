# CONTEXT — CHIMPS-V

> Documento vivo de produto, arquitetura e execução. Toda alteração de escopo deve
> atualizar este arquivo, as especificações em `specs/` e os testes correspondentes.

## 1. Visão do projeto

**CHIMPS-V** é uma ferramenta educacional, empacotada em Docker, para montar,
executar e observar ciclo a ciclo uma microarquitetura RISC-V própria. A aplicação
deve tornar visíveis o caminho de dados, unidade de controle, registradores,
pipeline, caches, memória e I/O, conectando cada instrução a seus efeitos de
hardware e métricas de desempenho.

O resultado não é apenas um emulador de ISA: é um simulador de uma
**microarquitetura explícita**, com estado temporal e sinais observáveis. A
implementação do núcleo será feita do zero em RTL/SystemVerilog; bibliotecas podem
ser usadas como oráculos de teste, mas não substituem os circuitos do processador.

### Objetivos de aprendizagem

- Relacionar uma instrução RISC-V ao seu fluxo pelos estágios do pipeline.
- Demonstrar hazards, encaminhamento, stalls, flushes e seus impactos em CPI.
- Demonstrar hierarquia de memória: hit/miss, write-back, substituição e latência.
- Demonstrar o contrato IEEE 754 por meio de operações de ponto flutuante,
  arredondamentos e exceções acumuladas.
- Permitir experimentação reproduzível: alterar uma configuração, executar o mesmo
  programa e comparar métricas/traces.

### Não objetivos da primeira entrega

- Sistema operacional, MMU/paginação, modos Supervisor/Hypervisor, multicore,
  coerência de cache, execução fora de ordem, predição dinâmica e extensões C/A/V.
- Síntese em FPGA/ASIC. O RTL deve ser sintetizável na maior parte possível, mas a
  entrega obrigatória é a simulação no container.

## 2. Decisões arquiteturais iniciais

| Item | Decisão de referência | Justificativa |
|---|---|---|
| ISA visível | `RV32IMF_Zicsr` (RV32I + multiplicação/divisão + ponto flutuante single + CSRs mínimos) | Escopo educacional realista, 32 bits simplificam endereçamento e o `F` cumpre o requisito de IEEE 754. |
| Endereçamento | 32 bits, byte-addressable, little-endian | Convenção comum e plenamente definida pela especificação RISC-V. |
| Registros | 32 GPRs de 32 bits (`x0` permanentemente zero); 32 FPRs de 32 bits | Segue RV32I/F. |
| Pipeline | 5 estágios in-order: IF, ID, EX, MEM, WB | Visual, didático e suficiente para demonstrar hazards. |
| FPU | Unidade RTL dedicada, multi-ciclo, não pipeline inicialmente | Mantém o caminho crítico da ALU curto e torna latência/ocupação visíveis. |
| Memória | RAM unificada de dados e instruções, mapeada em memória | Implementa Von Neumann. |
| Caches L1 | I-cache e D-cache separadas, configuráveis, com backing na mesma RAM | Não transforma a máquina em Harvard: a memória primária continua única; separar L1 elimina a contenção IF×MEM e torna a demonstração mais clara. |
| I/O | MMIO com buffers FIFO de entrada e saída | Modela periféricos sem criar instruções fora da ISA. |
| Interface | TUI interativa de terminal | Atende à GUI pedida sem exigir servidor gráfico e funciona bem em Docker. |
| Empacotamento | Docker/Compose, execução sem dependência de instalação local | Reproduzibilidade da demonstração e avaliação. |

### Escopo funcional por marco

1. **MVP — `RV32I`**: montador, RAM, registradores, ALU, control-flow, pipeline,
   hazards e TUI com execução passo a passo.
2. **Memória e I/O**: I-cache/D-cache, métricas, MMIO e buffers FIFO.
3. **Desempenho inteiro — `M`**: multiplicador/divisor RTL multi-ciclo, stalls e
   métricas de ocupação.
4. **Ponto flutuante — `F`**: registros FP, load/store FP, FPU e `fcsr`.
5. **Integração e demonstração**: Docker, testes de regressão, roteiros e exemplos.

Não avançar um marco enquanto suas especificações e sua suíte de testes não
estiverem verdes. O conjunto `RV32IMF_Zicsr` é a meta final; cada release deve
publicar claramente quais subconjuntos de instruções já são suportados.

## 3. Modelo do sistema

### 3.1 Von Neumann e mapa de memória

Uma única RAM armazena tanto o programa quanto os dados. O PC busca instruções
nela através da I-cache; loads/stores acessam a mesma RAM através da D-cache. O
montador/carregador escreve o binário nessa RAM antes da execução. A RAM não deve
ser duplicada em “memória de instruções” e “memória de dados”.

Proposta de mapa inicial (constantes configuráveis e documentadas no código):

| Faixa | Uso |
|---|---|
| `0x0000_0000`–`0x0000_FFFF` | código, dados estáticos e heap educacional |
| `0x0001_0000`–`0x0001_7FFF` | stack (cresce para baixo) |
| `0xFFFF_0000` | `UART_TX_DATA`: escrita de byte entra no FIFO de saída |
| `0xFFFF_0004` | `UART_TX_STATUS`: espaço disponível / ocupado |
| `0xFFFF_0008` | `UART_RX_DATA`: leitura remove byte do FIFO de entrada |
| `0xFFFF_000C` | `UART_RX_STATUS`: há byte disponível |
| `0xFFFF_0010` | `SIM_CONTROL`: halt/exit para o ambiente do simulador |

Definir formalmente a política para endereços desalinhados: na versão 1, detectar
e produzir trap/erro do simulador para acessos `LH/LW/FLW` desalinhados, em vez de
executar uma emulação silenciosa. Mostrar a causa e o PC na TUI.

### 3.2 Caminho de dados e controle

Componentes RTL mínimos:

- PC e seletor de próximo PC (`PC+4`, alvo de branch, `JAL`, `JALR`, trap/halt).
- I-cache, adaptador de RAM e registrador IF/ID.
- Decodificador combinacional, gerador de imediato e banco de registradores
  inteiros com duas portas de leitura e uma de escrita.
- Unidade de hazard e forwarding; registradores ID/EX, EX/MEM e MEM/WB com bits de
  validade.
- ALU combinacional e comparador de branches em EX.
- D-cache, unidade de load/store, extensão de sinal/zero e lógica MMIO.
- Banco de FPRs, FPU multi-ciclo e `fcsr` (`frm` + `fflags`).
- Controlador de traps/halt e contadores de desempenho.

O controle deve ser uma FSM explícita apenas onde necessário (miss de cache, FPU,
MUL/DIV, I/O bloqueante). O fluxo comum do pipeline deve ser registradores + lógica
combinacional, isto é, circuitos digitais e não uma interpretação de instruções em
software. O simulador/tela lê sinais do RTL a cada ciclo e não recria suas regras
em uma segunda implementação.

### 3.3 Pipeline e hazards

| Situação | Política inicial verificável |
|---|---|
| RAW de ALU | forwarding EX/MEM e MEM/WB para os operandos da EX |
| load-use | 1 bolha: congelar PC e IF/ID, injetar NOP em ID/EX |
| branch/JAL/JALR tomado | resolução em EX, invalidar instruções mais jovens em IF/ID e ID/EX; contar flush |
| cache miss | congelar estágios que dependem da transação; preservar registradores válidos |
| FPU/MUL/DIV ocupado | instrução produtora bloqueia o avanço necessário; nenhuma escrita fora de WB |
| store | efeitos de memória ocorrem apenas quando a instrução chega a MEM válida |
| exceção/halt | estado preciso: instruções mais jovens são anuladas; nenhuma instrução mais velha é perdida |

Usar sempre bits `valid`, `stall` e `flush` explícitos nos registradores de
pipeline. O trace deve incluir, por estágio, `pc`, instrução, `valid`, motivo do
stall/flush e valores relevantes. Isto evita que a visualização esconda bolhas.

**Fora de escopo inicial:** predição de saltos. Usar predição estática “não tomado”
na busca, que é simples de explicar e medir. Uma extensão opcional pode comparar
isso com um preditor de 1 bit, sem alterar o comportamento arquitetural.

### 3.4 Caches

Implementar os metadados e o datapath de cache em RTL (tag RAM, data RAM,
valid/dirty e comparadores). Parâmetros sugeridos para a configuração padrão:

| Parâmetro | I-cache | D-cache |
|---|---:|---:|
| Capacidade | 1 KiB | 1 KiB |
| Associatividade | mapeamento direto | 2 vias |
| Linha | 16 B | 16 B |
| Política de escrita | somente leitura | write-back + write-allocate |
| Substituição | n/a | pseudo-LRU por conjunto (ou round-robin no MVP) |
| Latência de hit | 1 ciclo | 1 ciclo |
| Penalidade de miss | configurável; padrão 10 ciclos | configurável; padrão 10 ciclos + write-back se dirty |

Regras a especificar e testar: decomposição de endereço (tag/index/offset), refill
de linha, seleção de vítima, write-back antes do refill, dados de store no miss,
acesso por bytes/máscaras, invalidação de I-cache quando o programa é carregado e
contadores `accesses`, `hits`, `misses`, `writebacks`, taxa de miss e AMAT. Não
introduzir coerência: há apenas um núcleo.

### 3.5 Ponto flutuante: IEEE 754 e RISC-V F

A meta `F` de precisão simples (`FLEN=32`) inclui `FLW/FSW`, aritmética
`FADD.S`/`FSUB.S`/`FMUL.S`/`FDIV.S`/`FSQRT.S`, fused multiply-add
`FMADD.S`/`FMSUB.S`/`FNMSUB.S`/`FNMADD.S`, comparação/classificação, sign-inject,
min/max, conversões e moves definidos pela extensão. Caso o cronograma aperte,
liberar primeiro um **subconjunto FP experimental** (load/store,
add/sub/mul/comparação/conversão); `FDIV.S`, `FSQRT.S` e FMA ficam para marco
posterior. Enquanto isso, a identificação da ISA não poderá alegar `F` completo.

Contrato obrigatório:

- Formato binary32: sinal, expoente e fração conforme IEEE 754-2019.
- Modos RISC-V `RNE`, `RTZ`, `RDN`, `RUP`, `RMM`, incluindo `rm=111` que usa
  `frm`; modo reservado resulta em instrução ilegal.
- `fflags` acumulados: `NV`, `DZ`, `OF`, `UF`, `NX`. Não gerar traps FP: o software
  consulta as flags, como determina a extensão RISC-V F.
- Tratar zero assinado, subnormais, infinitos e NaN. Produzir NaN canônico RISC-V
  (`0x7fc00000`) no modo padrão quando aplicável.
- Implementar a FPU como circuito: classificação, alinhamento de expoentes,
  operação de mantissas, normalização, guard/round/sticky, arredondamento e flags.
  Para divisão/raiz, usar algoritmo iterativo (por exemplo, restoring/Newton-Raphson
  conforme a especificação escolhida) com handshake `start/busy/done`.

Usar Berkeley SoftFloat apenas no **testbench** como modelo de referência
bit-a-bit. Uma divergência não pode ser “corrigida” com `float` do host, pois este
não garante a semântica precisa do `fcsr` e de todos os casos especiais.

### 3.6 I/O com buffering

O UART didático usa FIFOs RTL independentes para RX e TX. A TUI injeta caracteres
em RX e esvazia TX para exibição. O processador somente os observa por MMIO;
portanto, seu funcionamento é reproduzível por um arquivo/script de entrada. Em
modo inicial, leituras de RX vazio não bloqueiam: retornam 0 e o programa consulta
`UART_RX_STATUS`. Um modo opcional “blocking read” pode ser adicionado depois com
stall explícito e testado.

## 4. Experiência de terminal (TUI)

A “GUI de terminal” deve ser uma TUI navegável, não somente logs. Interface mínima:

```text
CHIMPS-V  ciclo 184  | RUNNING | CPI 1.37 | I$: 92.1% | D$: 75.0%
PC 0x00000024       instrução EX: add x5, x6, x7
IF  [v] 0x28 lw x8, 0(x5)     ID [v] ...     EX [v] ...  MEM [ ] —  WB [v] ...
stalls: load-use=3 cache=12 fpu=0 | flushes=4 | retired=134
Registradores: x0=00000000 x1=...        FPRs/fflags: f0=... NV=0 DZ=0 OF=0 UF=0 NX=1
I$ sets ...                              D$ sets ...          UART TX: "Olá"
[s] passo  [r] executar  [b] breakpoint  [m] memória  [c] caches  [t] trace  [q] sair
```

Recursos obrigatórios: carregar `.s`, montar, resetar, passo por ciclo, passo por
instrução aposentada, executar/pausar, breakpoint por PC, inspeção de RAM,
registradores, FPRs, pipeline e conjuntos de cache; painel de métricas; exportação
de trace em CSV/JSON. A tela deve indicar claramente se cada valor foi alterado no
ciclo atual, e toda configuração usada deve aparecer na execução/exportação.

## 5. Montador, formato de programa e depuração

Criar um montador próprio para o subconjunto suportado, com lexer, parser,
resolvedor de símbolos e codificador separados. Suportar labels, `.text`, `.data`,
`.word`, `.byte`, `.float` e pseudo-instruções documentadas (`nop`, `li`, `mv`,
`j`, `ret`, por exemplo). O montador deve produzir:

- imagem binária para a RAM;
- tabela de símbolos e mapa endereço → linha-fonte;
- diagnósticos com arquivo, linha, coluna e sugestão curta;
- listagem (`.lst`) que liga fonte, endereço e word codificada.

Definir uma linguagem mínima de assembly do CHIMPS-V e não aceitar silenciosamente
sintaxe de GNU assembler que ainda não é suportada. Em uma fase posterior, comparar
os encodings do montador com `riscv32-unknown-elf-as` em programas sem
pseudo-instruções do projeto.

## 6. Desenvolvimento orientado a especificação e testes

### 6.1 SDD como fonte de verdade

Antes da implementação, criar uma especificação Markdown por capacidade em
`specs/`, usando requisitos identificáveis:

```text
REQ-PIPE-LOAD-001: quando uma instrução em ID consome rd de um load válido em EX,
o núcleo deve inserir exatamente uma bolha e congelar PC/IF-ID por um ciclo.

Exemplo: lw x1, 0(x2); add x3, x1, x4
Então: x3 recebe o valor carregado, retired=2 e load_use_stalls aumenta em 1.
```

Modelo de arquivo: propósito e não-escopo; sinais/estado; requisitos “MUST/SHALL”;
casos de aceitação Given/When/Then; invariantes; timing/latência; erros; métricas;
links para testes. `docs/adr/` registra decisões irreversíveis ou com trade-offs
(ex.: write-back vs write-through, estratégia de FPU, política de branch).

Um requisito só é concluído quando há: especificação revisada, teste de aceitação,
teste de unidade/RTL pertinente, evidência de execução e entrada no changelog.

### 6.2 Pirâmide TDD e verificação

| Nível | O que comprovar | Exemplos |
|---|---|---|
| Unidade | funções puras do montador e blocos RTL isolados | imediato B/J, ALU, registrador x0, FIFO, tag/index/offset, round/sticky |
| Módulo RTL | protocolo por ciclo e invariantes | cache refill/write-back, hazard unit, FPU `busy/done`, RAM/MMIO |
| Integração | caminho completo programa → estado | `lw` seguido de `add`, branch tomado, saída UART, miss de cache |
| Arquitetural | semântica da ISA declarada | `riscv-arch-test`/`riscv-tests`, assinaturas e programas dirigidos |
| Aceitação TUI/Docker | fluxo do usuário e reprodutibilidade | container monta, executa exemplo e exporta trace sem intervenção |

Prática obrigatória por mudança: escrever o teste que falha, implementar o mínimo,
refatorar com todos os testes verdes. Todo bug ganha teste de regressão. O CI deve
falhar em lint, formatação, testes unitários, simulação RTL, testes de integração e
smoke test do container.

Invariantes transversais a verificar com assertions SystemVerilog:

- `x0 == 0` em todos os ciclos; escrita em `x0` é descartada.
- Uma instrução inválida/flushada não altera GPR, FPR, RAM, CSR ou MMIO.
- Cada instrução aposentada altera estado arquitetural no máximo uma vez.
- Dados de D-cache dirty são escritos na RAM antes da substituição.
- A resposta de uma transação ocorre somente para uma requisição pendente.
- `fflags` apenas acumulam até uma escrita explícita no CSR/reset.

Para validação diferencial, rodar programas de teste tanto no CHIMPS-V quanto num
modelo de referência RISC-V apropriado ao subconjunto, comparando PC, GPRs, FPRs,
`fcsr`, RAM e saída MMIO ao final. Para o `F`, incluir vetores gerados/avaliados com
SoftFloat. Para desempenho, a referência é o próprio timing especificado: comparar
trace por trace e não somente o estado final.

## 7. Organização sugerida do repositório

```text
.
├── CONTEXT.md                 # este contrato de projeto
├── README.md                  # início rápido e roteiro da demonstração
├── docs/
│   ├── adr/                   # decisões arquiteturais
│   ├── diagrams/              # fonte de diagramas e exports
│   └── demo/                  # roteiro e evidências
├── specs/                     # especificações versionadas (SDD)
├── rtl/                       # SystemVerilog sintetizável
│   ├── core/ cache/ memory/ io/ fpu/
├── sim/                       # harness, adaptadores e artefatos de trace
├── assembler/                 # lexer/parser/encoder/listagem
├── tui/                       # interface de terminal
├── programs/                  # exemplos Assembly e entradas de I/O
├── tests/
│   ├── unit/ rtl/ integration/ acceptance/ architectural/
├── scripts/                   # comandos reprodutíveis do projeto
├── Dockerfile
├── compose.yaml
└── .github/workflows/ci.yml
```

Escolha de ferramentas a validar no primeiro spike: SystemVerilog + Verilator para
simulação/lint, cocotb ou testbench SystemVerilog para testes, e Rust ou Python
para montador/harness/TUI. O RTL não pode depender da linguagem do harness. Fixar
versões de imagem, simulador, bibliotecas e toolchain no Dockerfile/lockfiles.

## 8. Docker e operação reprodutível

O container precisa possuir todas as ferramentas para montar, simular, testar e
abrir a TUI. Usar imagem multi-stage: etapa de build instala dependências e compila;
imagem final contém apenas runtime, binários e recursos necessários. Executar como
usuário não-root, expor diretório `/workspace` para programas/traces e documentar
comandos únicos, por exemplo:

```bash
docker compose run --rm chimpsv test
docker compose run --rm chimpsv run programs/demo_pipeline.s --step
docker compose run --rm chimpsv run programs/demo_cache.s --trace /workspace/out/cache.json
```

Critérios: build limpo em máquina sem toolchain RISC-V; comandos não dependem de
arquivos fora do repositório; versões são pinadas; testes executam offline após o
build; artefatos de demonstração e traces podem ser exportados.

## 9. Roadmap com entregáveis e gates

| Fase | Entregável | Gate de aceite |
|---|---|---|
| 0 — Fundação | ADRs, `specs/`, estrutura, Docker e CI | `docker compose … test` verde em checkout limpo |
| 1 — ISA/montador | RV32I definido, montador, loader e listagem | encoding/diagnósticos testados; exemplos montam |
| 2 — Núcleo base | PC, GPR, ALU, RAM, pipeline e TUI de passo | programas RV32I e hazards têm trace esperado |
| 3 — Caches/I-O | L1s, MMIO/FIFOs e painel de métricas | testes de hit/miss/write-back/FIFO e demo reproduzível |
| 4 — M e F | unidades multi-ciclo, FPR/fcsr e IEEE 754 | vetores bit-a-bit, flags e stalls corretos |
| 5 — Qualidade | regressão arquitetural, cobertura e documentação | CI verde; roteiro de apresentação executado no Docker |

Prioridade de demonstrações: (1) `lw`→uso imediato para bolha e forwarding; (2)
branch tomado para flush; (3) acesso repetido e conflitante para cache; (4) eco de
caracteres UART com FIFO; (5) `1.0/0.0`, NaN e arredondamento para FPU/`fflags`.

## 10. Métricas e critérios de sucesso

Exibir e exportar: ciclos, instruções aposentadas, CPI, IPC, stalls por causa,
flushes, branches/taxa de tomados, acessos/hits/misses/write-backs por cache, AMAT,
operações FPU/MUL/DIV e ciclos ocupados, bytes RX/TX e uso máximo dos FIFOs.

O projeto estará pronto para demonstração quando:

- qualquer pessoa puder construir e executar a demonstração apenas com Docker;
- a TUI mostrar corretamente estado e fluxo por ciclo para os cinco cenários;
- a ISA implementada estiver declarada e coberta por testes arquiteturais e
  diferenciais compatíveis;
- o caminho de cada requisito deste documento para sua spec, testes e evidência
  puder ser rastreado;
- erros de assembly, traps, hazards e misses forem visíveis e explicáveis na tela.

## 11. Riscos, limites e mitigação

| Risco | Impacto | Mitigação |
|---|---|---|
| Escopo de `F` e divisão/raiz | Alto | Entregar RV32I+pipeline+caches primeiro; projetar FPU multi-ciclo por etapas e declarar suporte real. |
| Diferença entre estado final e timing | Alto | trace por ciclo, assertions e testes de aceitação com contagens exatas. |
| Cache complexo demais | Médio | começar com I$ direta e D$ direta; evoluir D$ para 2 vias após write-back testado. |
| TUI consumir o cronograma | Médio | separar modelo de apresentação; primeiro CLI/headless + export, depois TUI. |
| Docker não reproduz build | Alto | CI constrói imagem do zero e executa smoke test em toda mudança. |
| Implementação “simulada em software” | Alto | RTL é fonte do estado microarquitetural; harness/TUI apenas dirige/observa RTL. |

## 12. Referências

### Especificações e testes primários

1. RISC-V International. *The RISC-V Instruction Set Manual, Volume I:
   Unprivileged Architecture*, Ratified Specifications Library, versão
   2026-01-20. https://docs.riscv.org/reference/isa/
2. RISC-V International. *RV32I Base Integer Instruction Set, Version 2.1*.
   https://docs.riscv.org/reference/isa/v20260120/unpriv/rv32.html
3. RISC-V International. *“M” Extension for Integer Multiplication and Division*.
   https://docs.riscv.org/reference/isa/unpriv/m-st-ext.html
4. RISC-V International. *“F” Extension for Single-Precision Floating-Point,
   Version 2.2*. https://docs.riscv.org/reference/isa/unpriv/f-st-ext.html
5. RISC-V International. *The RISC-V Instruction Set Manual, Volume II:
   Privileged Architecture* (consultar somente Machine mode/CSRs que forem
   declarados no escopo). https://docs.riscv.org/reference/isa/priv/priv-index.html
6. IEEE. *IEEE Std 754-2019 — IEEE Standard for Floating-Point Arithmetic*, 2019;
   ISO/IEC/IEEE 60559:2020. https://standards.ieee.org/ieee/754/6210/
7. RISC-V International. *RISC-V Architectural Certification Tests
   (`riscv-arch-test`)*. https://github.com/riscv/riscv-arch-test
8. RISC-V Software Source. *riscv-tests*. https://github.com/riscv-software-src/riscv-tests
9. Hauser, John R. *Berkeley SoftFloat Release 3e: Library Interface*, 2018.
   https://www.jhauser.us/arithmetic/SoftFloat.html (oráculo para testes FP, não
   implementação do núcleo).

### Livros fundamentais

10. Patterson, David A.; Hennessy, John L. *Computer Organization and Design
    RISC-V Edition: The Hardware Software Interface*, 2nd ed., Morgan Kaufmann,
    2020. ISBN 978-0128203316.
11. Hennessy, John L.; Patterson, David A. *Computer Architecture: A Quantitative
    Approach*, 6th ed., Morgan Kaufmann, 2019. ISBN 978-0128119051.
12. Harris, Sarah L.; Harris, David M. *Digital Design and Computer Architecture:
    RISC-V Edition*, Morgan Kaufmann, 2021. ISBN 978-0128200643.
13. Mano, M. Morris; Ciletti, Michael D. *Digital Design*, 6th ed., Pearson, 2017.
    ISBN 978-0134549897.

### Artigos e práticas de engenharia

14. Smith, Alan J. “Cache Memories.” *ACM Computing Surveys*, 14(3), 473–530,
    1982. https://doi.org/10.1145/356887.356892
15. Tomasulo, Robert M. “An Efficient Algorithm for Exploiting Multiple Arithmetic
    Units.” *IBM Journal of Research and Development*, 11(1), 25–33, 1967.
    https://doi.org/10.1147/rd.111.0025 (referência conceitual; OoO não integra o
    escopo inicial).
16. Tullsen, Dean M.; Brown, Michael Q.; Voelker, Geoffrey M. “Use of architectural
    simulation tools in education.” *WCAE ’95*, 1995.
    https://doi.org/10.1145/1275225.1275232
17. Beck, Kent. *Test Driven Development: By Example*. Addison-Wesley, 2002.
    ISBN 978-0321146533.
18. RFC Editor. *RFC 2119: Key words for use in RFCs to Indicate Requirement
    Levels*, 1997. https://www.rfc-editor.org/rfc/rfc2119 (vocabulário MUST/SHALL
    das especificações do projeto).
19. Docker. *Dockerfile reference* e *Compose specification*.
    https://docs.docker.com/reference/dockerfile/ e https://docs.docker.com/compose/

## 13. Próxima ação recomendada

Criar os ADRs 001–005 (ISA, Von Neumann+cache, pipeline/hazards, FPU, toolchain),
as specs `RV32I`, `pipeline` e `memory-map`, e um primeiro vertical slice:
`addi`/`add`/`lw`/`sw`/`beq` da fonte Assembly até a TUI em passo a passo. Esse
slice deve nascer no Docker e com testes antes de qualquer expansão de ISA.
