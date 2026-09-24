# CHIMPS-V

CHIMPS-V é um simulador de uma microarquitetura RISC-V descrita em VHDL-2008. O RTL é a fonte de verdade; ferramentas de host apenas carregam programas, dirigem a simulação e apresentam snapshots.

## Decisões arquiteturais

| Tema            | Decisão                                                                                      |
| --------------- | -------------------------------------------------------------------------------------------- |
| ISA             | Alvo `RV32IMF_Zicsr`; somente subconjuntos integrados e testados são declarados disponíveis. |
| Core            | Referência sequencial multi-ciclo com uma instrução em voo; destino pipeline in-order.       |
| Dados           | XLEN/FLEN 32, memória byte-addressable e little-endian, `x0=0`.                              |
| Memória         | RAM Von Neumann unificada, I-cache e D-cache separadas sobre o mesmo backing store.          |
| Cache           | I-cache direta; destino da D-cache é 2-way, write-back e write-allocate.                     |
| Extensões       | MUL/DIV e FPU usam handshake multi-ciclo; Zicsr fornece estado de trap e FP.                 |
| I/O             | UART e controle de simulação serão MMIO, sem opcodes privados.                               |
| Programa        | O único formato de imagem aceito é `.bin`, formado por bytes little-endian.                  |
| Host/alvo       | `cli/` roda no host; `software/` contém C e runtime RISC-V executados pelo core.             |
| Observabilidade | GUI e CLI devem consumir o mesmo `CycleSnapshot` versionado.                                 |
| Ferramentas     | GHDL/VHDL-2008 e Docker Compose; C11 para o CLI.                                             |

Os detalhes e limitações atuais estão em [auditoria](docs/audits/microarchitecture.md), [ADRs](docs/adr/) e [tarefas do projeto](docs/project/tasks.md).

## Usar o RTL

Construa e execute toda a regressão:

```sh
docker compose build rtl
docker compose run --rm rtl
```

Para executar somente a análise estática:

```sh
docker compose run --rm rtl scripts/lint-rtl.sh
```

O serviço monta o repositório em `/workspace`, compila todas as fontes listadas em `scripts/compile-rtl.sh` e executa cada `tests/vhdl/tb_*.vhd`. Um retorno zero indica que todos os testbenches concluíram sem `severity error`.

O core ainda não recebe arquivos diretamente. Os testbenches carregam words pela porta `load_*` durante reset. A ligação do loader do CLI ao GHDL está registrada no backlog.

## Usar o CLI inicial

Teste e construa no host:

```sh
make -C cli test
make -C cli
```

Valide e carregue uma imagem no buffer do CLI:

```sh
cli/build/chimps-v load path/to/program.bin
cli/build/chimps-v load path/to/program.bin --address 0x100
```

O comando rejeita extensão incorreta, imagem vazia, tamanho que não seja múltiplo de quatro, endereço desalinhado e imagem que ultrapasse a RAM. Para usar o ambiente containerizado:

```sh
docker compose build cli
docker compose run --rm cli
```

Neste marco, `load` valida e mantém a imagem no processo; execução, stepping e trace ainda serão conectados ao simulador.

## Software executado pelo core

Código destinado ao processador fica em `software/`, separado do CLI nativo. O diretório já contém o ponto de entrada, linker script e endereços MMIO para futuros programas C. Um toolchain RISC-V externo produzirá exclusivamente imagens `.bin`.
