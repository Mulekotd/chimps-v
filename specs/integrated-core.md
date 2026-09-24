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

### Métricas de cache

`cache_l1` incrementa `accesses` uma vez quando aceita `req` em `idle`; `hits` e
`misses` são mutuamente exclusivos na consulta da linha, e `writebacks` incrementa
quando a escrita completa de uma linha suja é aceita pelo backing store. `service_cycles`
conta os ciclos entre a aceitação e a resposta, enquanto `stall_cycles` exclui o ciclo
`respond`, pois nesse ponto o cliente já pode avançar. `chimps_v_system` expõe esses
seis contadores para I-cache e D-cache, além de `amat = service_cycles / accesses`
por divisão inteira, ou zero se não houve acesso.

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
- Cache e métricas: Hennessy & Patterson, 5ª ed., cap. 5, para contabilização de
  misses e penalidade de serviço. Aceite: uma sequência 2-way com escrita mascarada,
  conflito LRU e flush preserva os bytes e apresenta contadores observáveis;
  contraprova: erro durante refill retorna `error` sem tornar a linha válida e AMAT
  é zero antes de qualquer acesso.
