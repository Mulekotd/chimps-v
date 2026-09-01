# Barramento de memória

`memory_bus` recebe uma porta de instrução e uma de dados e apresenta uma única porta para `cache_l1`. Ele seleciona dados quando ambas chegam enquanto está livre e registra essa escolha até `memory_ready`. Assim, endereço, escrita, dados, máscara, resposta e erro voltam ao mesmo cliente durante toda a transação.

Clientes mantêm `valid` e os campos da requisição até `ready`. A cache mantém uma requisição à RAM até sua conclusão. Essa retenção é necessária porque a pipeline pode manter um acesso MEM enquanto IF solicita a próxima instrução.
