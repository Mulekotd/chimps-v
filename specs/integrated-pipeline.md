# Pipeline integrada

`pipeline` é a única implementação ativa do caminho de execução. Ela é uma pipeline in-order com registradores IF/ID, ID/EX, EX/MEM e MEM/WB. Cada registrador tem um bit `valid`; `pipeline_valid` expõe os quatro bits para observação na simulação.

IF mantém uma requisição de instrução até `instruction_ready`. ID aceita somente o subconjunto definido em [simplified-architecture.md](/specs/simplified-architecture.md), lê os GPRs e insere bolhas até que um produtor RAW tenha passado por WB. EX executa aritmética, endereço ou comparação de `BEQ`; um branch tomado descarta IF/ID. MEM mantém `LW` ou `SW` até `data_ready`. WB grava o destino, exceto `x0`, que permanece zero.

`EBREAK` interrompe novas buscas, deixa instruções mais antigas escoarem e então eleva `halted`. Encoding não suportado, falha de memória ou endereço de word desalinhado eleva `illegal_instruction` e encerra o núcleo. Não há implementação de trap, CSR ou modo privilegiado.
