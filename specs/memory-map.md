# Mapa de memória

| Faixa | Uso |
| --- | --- |
| `0000_0000`–`0001_7FFF` | RAM unificada de 96 KiB: programa e dados |

A RAM é little-endian e implementa máscaras por byte internamente, mas o core atual gera somente acessos de word com máscara `1111`. Não há MMIO, UART, região de stack especial ou registrador de controle de simulação. Endereço de word fora da RAM ou desalinhado gera erro.
