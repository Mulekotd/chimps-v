# Mapa de memória

| Faixa                     | Uso                                                 |
| ------------------------- | --------------------------------------------------- |
| `0000_0000`–`0000_FFFF`   | RAM: código, dados e heap                           |
| `0001_0000`–`0001_7FFF`   | stack, crescendo para baixo a partir de `0001_8000` |
| `FFFF_0000` / `FFFF_0004` | UART TX dado / status                               |
| `FFFF_0008` / `FFFF_000C` | UART RX dado / status                               |
| `FFFF_0010`               | SIM_CONTROL                                         |

Acessos fora dessas faixas respondem `error`. A RAM é little-endian e aceita máscara
por byte; halfword/word desalinhados retornam erro, convertido em trap pelo core.
