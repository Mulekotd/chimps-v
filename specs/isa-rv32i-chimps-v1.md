# ISA CHIMPS-V v1 — perfil e contrato de software

- Estado: proposta implementável por marcos
- Perfil final pretendido: `RV32IMF_Zicsr`
- Perfil de aceite imediato: `RV32I_Zicsr` sem modos privilegiados

## Programa e stack

O programa inicia no PC `0x0000_0000`; `x2` é o ponteiro de pilha, inicializado pelo
carregador em `0x0001_8000`, e a stack cresce para endereços menores. Não há
instruções especiais de pilha: a convenção usa `ADDI x2,x2,-n`, `SW rs,off(x2)`,
`LW rd,off(x2)` e `ADDI x2,x2,n`. Chamadas usam `JAL x1,target` e retornos usam
`JALR x0,0(x1)`. Isso é software comum RV32I, não uma extensão local.

## Conjunto de instruções

| Grupo               | Instruções exigidas                                                                    |
| ------------------- | -------------------------------------------------------------------------------------- |
| Inteiro imediato    | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`, `LUI`, `AUIPC` |
| Inteiro registrador | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`                   |
| Memória             | `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW`                                       |
| Controle            | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`, `JAL`, `JALR`, `FENCE`, `ECALL`, `EBREAK`  |
| M                   | `MUL`, `MULH`, `MULHSU`, `MULHU`, `DIV`, `DIVU`, `REM`, `REMU`                         |
| Zicsr               | `CSRRW`, `CSRRS`, `CSRRC`, `CSRRWI`, `CSRRSI`, `CSRRCI`                                |
| F (marco posterior) | `FLW`, `FSW`, aritmética binary32, conversões, comparação/classificação e `fcsr`       |

`FENCE` é aceito como NOP no núcleo unicore sem dispositivo concorrente; `ECALL` e
`EBREAK` produzem trap. Instrução reservada, extensão não suportada, endereço
desalinhado e acesso MMIO inválido também produzem trap preciso.

## CSRs e traps do marco Zicsr

São implementáveis no modo Machine mínimo: `mstatus` (somente campos necessários),
`mtvec`, `mepc`, `mcause`, `mtval`, `mscratch`, `mcycle`, `minstret`, `fcsr`, `frm` e
`fflags`. Acesso a CSR não listado ou escrita em campo somente leitura gera trap de
instrução ilegal. `mcycle` conta ciclos e `minstret` conta instruções aposentadas;
uma escrita explícita em `minstret` substitui o incremento implícito naquele ciclo.

| Causa                             | `mcause` |
| --------------------------------- | -------- |
| instrução ilegal                  | 2        |
| breakpoint                        | 3        |
| endereço de instrução desalinhado | 0        |
| load desalinhado/falha            | 4 / 5    |
| store/AMO desalinhado/falha       | 6 / 7    |
| ecall de modo M                   | 11       |

Na entrada de trap, gravar `mepc`, `mcause` e `mtval`, anular instruções jovens e
desviar a `mtvec`. O `SIM_CONTROL` MMIO pode encerrar a simulação, mas não altera
encodings RISC-V.

## Reference check

- Referências normativas: RISC-V unprivileged RV32I, M, F e Zicsr; RISC-V privileged
  CSRs e Machine; referências fornecidas pelo solicitante.
- Decisão: a stack é convenção de software construída por loads/stores, `ADDI`, `JAL`
  e `JALR`; não serão usados encodings locais/reservados.
- Aceite: programa que salva `ra` e um registrador em `sp`, chama uma rotina e retorna
  preserva ambos; contraprova: `LW`/`SW` desalinhado escreve `mcause` adequado e não
  altera memória/registrador destino.
