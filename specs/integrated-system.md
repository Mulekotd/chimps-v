# Sistema integrado

`chimps_v_system` conecta `pipeline`, `memory_bus`, `cache_l1` e `memory_backing_store`. É o único ponto de integração RTL.

O carregador escreve words little-endian apenas com `rst=1`; a execução começa com `rst=0`. A RAM possui 96 KiB. `memory_bus` retém o cliente escolhido até a resposta da cache e dá prioridade a dados quando as duas requisições chegam livres ao mesmo ciclo. Isso evita trocar o destinatário enquanto a cache atende um miss.

`cache_l1` é compartilhada por fetch e dados. Ela expõe `cache_accesses`, `cache_hits` e `cache_misses`. O testbench integrado verifica uma escrita write-through, um miss de load, um hit no segundo load e o flush de uma instrução jovem após `BEQ`.
