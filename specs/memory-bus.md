# Memory bus

Cada cliente emite `valid`, `write`, `address`, `wdata`, `wmask` e `source`; o alvo
responde `ready`, `rdata` e `error`. Uma transação permanece estável enquanto
`valid=1` e `ready=0`. Endereços e dados são 32-bit; `wmask(0)` seleciona o byte menos
significativo. O árbitro aceita no máximo uma transação por ciclo e propaga o erro ao
cliente selecionado.

## Reference check

Contrato baseado em interfaces request/response síncronas de hierarquias de memória
(Hennessy & Patterson, 5ª ed.). Aceite: resposta retorna ao `source` correto;
contraprova: `valid` sem `ready` não muda endereço ou dados.
