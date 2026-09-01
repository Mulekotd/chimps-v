# Memory bus

Cada cliente emite `valid`, `write`, `address`, `wdata` e `wmask`; o alvo responde
`ready`, `rdata` e `error`. Uma transação permanece estável enquanto `valid=1` e
`ready=0`. Endereços e dados são 32-bit; `wmask(0)` seleciona o byte menos
significativo. O árbitro aceita no máximo uma transação por ciclo e propaga a resposta
e o erro exclusivamente ao cliente selecionado.

`rtl/memory_bus.vhd` implementa as duas portas necessárias à referência: fetch de
instrução e dados. A arbitragem é combinacional, não tem estado, e dá prioridade fixa
à porta de dados quando ambas estão válidas. Assim, a camada de cache pode manter a
requisição estável até o handshake sem criar uma bolha extra. A integração do árbitro
com as L1 e o core continua uma tarefa distinta, pois o core de referência ainda usa a
RAM diretamente e não tem stall por `ready`.

## Reference check

Contrato baseado em interfaces request/response síncronas de hierarquias de memória (Hennessy & Patterson, 5ª ed., cap. 5) e na semântica de loads/stores byte-endereçados da especificação RV32I 2.1. Decisão: dados precedem fetch, mas a política não é visível à ISA. Aceite: `tb_memory_bus` encaminha leitura, escrita, máscara e resposta ao mestre correto. Contraprova: com ambas as portas válidas, a resposta de instrução fica inativa e um `error` chega somente à porta de dados selecionada.
