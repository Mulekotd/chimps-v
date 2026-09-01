# Referência integrada: contrato e verificação

O nome histórico `core_rv32i_single` é preservado; a execução passa a ser
sequencial multi-ciclo, com uma instrução em voo. Fetch, execução, memória e
write-back são ordenados. Enquanto uma unidade ou cache está ocupada, PC e
operandos permanecem retidos. Isso resolve dependências RAW/WAW sem forwarding;
não constitui um pipeline de cinco estágios.

Reset síncrono limpa estado arquitetural e invalida caches. Loader escreve words
little-endian com reset ativo; execução só começa depois de desativar reset.
RAM ocupa 96 KiB conforme memory-map. Acessos inválidos não podem causar alias.
Traps precisos preservam destino e memória, gravam mepc/mcause/mtval e desviam
para mtvec. Sinais de trap e retirement são pulsos distintos. CSRs implementados
são documentados no código; não se declara uma plataforma privilegiada completa.

Caches usam resposta `valid/ready` de conclusão: pedido permanece estável até
ready. I-cache direta e D-cache 2-way compartilham RAM e árbitro. D-cache usa LRU,
dirty, write-back/write-allocate; erro durante eviction preserva a linha suja.
Métricas contam requisições uma vez, ciclos de serviço e stalls; AMAT = ciclos de
serviço/acessos, com zero para nenhuma requisição.

## Reference check

- Normativas: RISC-V RV32I 2.1, M 2.0, F 2.2, Zicsr 2.0 e Machine CSRs,
  edição 20260120, capítulos RV32I, M, F, Zicsr e Machine-Level ISA em
  https://docs.riscv.org/reference/isa/v20260120/ .
- F: cinco modos RNE/RTZ/RDN/RUP/RMM, NaN canônico, tininess após rounding,
  flags acumuladas; SoftFloat 3e é exclusivamente oráculo externo.
- Aceite: programas dependentes M e loads só aposentam após resposta, todos os
  encodings válidos e inválidos têm resultado/trap observável, cache devolve
  dados após eviction e reload; contraprovas incluem divisão por zero, CSR
  inexistente, endereço desalinhado, falha de backing, sNaN e rounding ties.
