# ADR 006 — Mapeamentos distintos para I$ e D$

- Estado: aceito
- Data: 2026-09-22

## Contexto

O sistema integrado possui uma RAM unificada e duas caches L1 separadas. A linha tem 16 B (quatro palavras de 32 bits) e ambas as caches armazenam 1 KiB de dados. O controlador é o mesmo `cache_l1`, parametrizado no topo [`rtl/chimps_v_system.vhd`](/rtl/chimps_v_system.vhd):

| Cache | Conjuntos | Vias | Capacidade | Política de escrita             |
| ----- | --------: | ---: | ---------: | ------------------------------- |
| I$    |        64 |    1 |      1 KiB | somente leitura                 |
| D$    |        32 |    2 |      1 KiB | write-back, write-allocate, LRU |

As caches compartilham o barramento e a RAM; um miss ou write-back pode parar o núcleo sequencial até o handshake `ready`. Portanto, além da capacidade, os conflitos de mapeamento afetam diretamente a quantidade de stalls observáveis.

## Decisão

### I$ diretamente mapeada

A I$ usa uma via por conjunto porque o fetch é somente leitura e o núcleo emite uma instrução por vez. Para cada endereço há apenas uma linha candidata:

- a busca compara uma única tag/base e não precisa selecionar via;
- não há linha suja nem write-back de instruções;
- a estrutura de estado e a explicação ciclo a ciclo permanecem pequenas e previsíveis para o objetivo educacional do projeto;
- o custo de um conflito é aceitável neste marco: a instrução é recarregada e o fetch fica parado até a resposta da RAM.

Com 64 conjuntos e linha de 16 B, o índice lógico da I$ ocupa os bits `[9:4]` do endereço. Linhas separadas por 1 KiB podem competir pelo mesmo conjunto; essa é uma consequência intencional e visível do mapeamento direto.

### D$ associativa por conjunto de duas vias

A D$ usa duas vias por conjunto porque dados têm padrões de acesso menos previsíveis: stack, variáveis, vetores e buffers podem alternar entre blocos que caem no mesmo conjunto. Com uma D$ direta, dois blocos conflitantes fariam ping-pong mesmo quando a capacidade total ainda seria suficiente.

Duas vias permitem manter dois blocos do mesmo conjunto antes de substituir uma vítima. Esse ganho reduz misses de conflito sem exigir o custo de uma cache totalmente associativa. O custo adicional é limitado e explícito no RTL: duas comparações de tag, seleção da via e um estado LRU por conjunto. Como a D$ é gravável, a vítima suja é escrita de volta antes do refill; essa política preserva coerência com a RAM unificada e torna o efeito de stores observável no flush e na substituição.

Com 32 conjuntos, duas vias e linhas de 16 B, o índice lógico da D$ ocupa `[8:4]`; o offset continua em `[3:0]`. A redução de 64 para 32 conjuntos mantém a mesma capacidade de 1 KiB ao reservar duas linhas para cada conjunto.

## Consequências

- I$ tem caminho de hit e substituição mais simples, mas não evita misses de conflito entre duas linhas de instrução com o mesmo índice.
- D$ suporta dois blocos concorrentes por índice, mas aumenta a lógica de lookup, a política de vítima e os casos de write-back/erro durante eviction.
- As duas caches preservam linhas de 16 B e a mesma capacidade de dados; a diferença de associatividade não muda os endereços, a ISA ou a ordem dos loads/stores definida pelas especificações.
- Uma D$ totalmente associativa foi descartada pelo número maior de comparadores e pela política de substituição mais difícil de explicar. Uma D$ direta foi descartada pelo aumento esperado de conflitos para dados graváveis. Uma I$ de duas vias foi descartada porque adicionaria essa complexidade a um caminho de fetch somente leitura sem necessidade demonstrada neste marco.

## Reference check

- **Componente e questão:** política de colocação das L1 e seu efeito em misses, stalls e write-back no contrato `valid/ready` do sistema integrado.
- **Referências:** Hennessy & Patterson, 5ª ed., cap. 5 (_Memory Hierarchy_), para compromisso entre associatividade, misses de conflito e custo de hit; Smith, _Cache Memories_, para a separação entre mapeamento, substituição e política de escrita. A especificação RISC-V Unprivileged v20260120 não impõe uma organização de cache; a decisão é transparente à ISA e deve preservar as semânticas de load/store já declaradas em [`specs/integrated-system.md`](/specs/integrated-system.md).
- **Decisão resultante:** uma I$ direta de 64 conjuntos privilegia simplicidade e previsibilidade; uma D$ de 32 conjuntos e duas vias reduz conflitos de dados mantendo custo de controle limitado.
- **Aceite:** dois blocos de dados que mapeiam no mesmo conjunto coexistem nas duas vias da D$; ao inserir uma terceira linha, a vítima suja é escrita na RAM antes do refill. Na I$, duas linhas com o mesmo índice disputam a única via e a segunda substitui a primeira sem write-back.
- **Contraprova:** se a D$ aceitar somente uma linha por conjunto, o segundo bloco conflitante já deve expulsar o primeiro; se a I$ tentar write-back de uma linha, a configuração somente leitura foi violada.
