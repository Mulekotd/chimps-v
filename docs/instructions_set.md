# Instruções reconhecidas pelo decoder

Este documento mapeia a implementação atual de [`rtl/decoder.vhd`](/rtl/decoder.vhd). Ele descreve os sinais produzidos pelo decoder.

`valid = 0` indica um encoding rejeitado. A aceitação pelo decoder não basta para garantir a semântica arquitetural: o núcleo também precisa executar os sinais gerados. As limitações conhecidas estão no fim deste documento.

## RV32I inteiro

| Grupo       | Instruções aceitas                                                     | Condição de encoding                                                                            | Controles principais                                              |
| ----------- | ---------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Registrador | `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`   | `OP` (`0110011`); `funct7=0000000`, exceto `SUB` e `SRA` (`0100000`)                            | `reg_write`; ALU usa `rs1` e `rs2`                                |
| Imediato    | `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI` | `OP-IMM` (`0010011`); shifts aceitam somente `funct7=0000000` ou `0100000` conforme a instrução | `reg_write`, `alu_src`, `IMM_I`                                   |
| U-type      | `LUI`, `AUIPC`                                                         | `0110111` e `0010111`                                                                           | `reg_write`, `IMM_U`; `LUI` copia o imediato e `AUIPC` soma ao PC |
| Load        | `LB`, `LH`, `LW`, `LBU`, `LHU`                                         | `LOAD` (`0000011`), `funct3=000`, `001`, `010`, `100`, `101`                                    | `reg_write`, `mem_read`, `mem_to_reg`, `IMM_I`                    |
| Store       | `SB`, `SH`, `SW`                                                       | `STORE` (`0100011`), `funct3=000`, `001`, `010`                                                 | `mem_write`, `IMM_S`                                              |
| Branch      | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`                             | `BRANCH` (`1100011`), `funct3=000`, `001`, `100`, `101`, `110`, `111`                           | `branch`, `IMM_B`; somente `BNE` ativa `branch_ne`                |
| Jump        | `JAL`, `JALR`                                                          | `1101111`; ou `1100111` com `funct3=000`                                                        | `reg_write`, `jump`; `JALR` também ativa `jalr` e usa `IMM_I`     |

## Extensão M

Todas usam `OP` (`0110011`) com `funct7=0000001`. O decoder ativa `m_enable`, grava o GPR de destino e seleciona a operação pelo `funct3`.

| `funct3` | Instrução |
| -------- | --------- |
| `000`    | `MUL`     |
| `001`    | `MULH`    |
| `010`    | `MULHSU`  |
| `011`    | `MULHU`   |
| `100`    | `DIV`     |
| `101`    | `DIVU`    |
| `110`    | `REM`     |
| `111`    | `REMU`    |

## Subconjunto FP binary32

As operações abaixo usam `OP-FP` (`1010011`), exceto FMA e loads/stores. O decoder rejeita formatos diferentes de binary32 e `rm=101`/`110` nas operações que arredondam.

| `funct7`  | Condição adicional         | Instruções aceitas                | Destino e controles                               |
| --------- | -------------------------- | --------------------------------- | ------------------------------------------------- |
| `0010000` | `funct3=000`, `001`, `010` | `FSGNJ.S`, `FSGNJN.S`, `FSGNJX.S` | FPR; `fp_enable`, `fp_write`                      |
| `0010100` | `funct3=000`, `001`        | `FMIN.S`, `FMAX.S`                | FPR; `fp_enable`, `fp_write`                      |
| `1010000` | `funct3=000`, `001`, `010` | `FLE.S`, `FLT.S`, `FEQ.S`         | GPR; `fp_enable`, `fp_result_to_gpr`, `reg_write` |
| `1110000` | `rs2=00000`, `funct3=001`  | `FCLASS.S`                        | GPR; `fp_enable`, `fp_result_to_gpr`, `reg_write` |
| `1110000` | `rs2=00000`, `funct3=000`  | `FMV.X.W`                         | GPR; `fp_move_to_int`, `reg_write`                |
| `1111000` | `rs2=00000`, `funct3=000`  | `FMV.W.X`                         | FPR; `fp_move_from_int`, `fp_write`               |
| `0000000`, `0000100`, `0001000`, `0001100` | `rm` válido | `FADD.S`, `FSUB.S`, `FMUL.S`, `FDIV.S` | FPR; `fp_enable`, `fp_write` |
| `0101100` | `rs2=00000`, `rm` válido | `FSQRT.S` | FPR; `fp_enable`, `fp_write` |
| `1100000` | `rs2=00000`/`00001`, `rm` válido | `FCVT.W.S`, `FCVT.WU.S` | GPR; `fp_result_to_gpr`, `reg_write` |
| `1101000` | `rs2=00000`/`00001`, `rm` válido | `FCVT.S.W`, `FCVT.S.WU` | FPR; operando vem de GPR |

`FMADD.S`, `FMSUB.S`, `FNMSUB.S` e `FNMADD.S` usam os opcodes R4 `1000011`, `1000111`, `1001011` e `1001111`, com `fmt=00`, três fontes FPR e `rm` válido. `FLW` e `FSW` usam respectivamente `0000111` e `0100111`, ambos com `funct3=010`, endereço `rs1 + imediato` e transferência sem alterar os 32 bits.

## Fence e SYSTEM

| Grupo                     | Encoding aceito pelo decoder                                             | Sinais gerados                       |
| ------------------------- | ------------------------------------------------------------------------ | ------------------------------------ |
| `FENCE`                   | opcode `0001111`, `funct3=000`                                           | `valid=1`; nenhum efeito de dados    |
| `ECALL`, `EBREAK`, `MRET` | `SYSTEM` (`1110011`), respectivamente `00000073`, `00100073`, `30200073` | `valid=1`; nenhum controle adicional |
| `fflags`, `frm`, `fcsr` | `SYSTEM` com CSR `0x001`, `0x002` ou `0x003` e `funct3=001`, `010`, `011`, `101`, `110` ou `111` | leitura/escrita do estado FP |

`SYSTEM` com `funct3=100`, qualquer outro `SYSTEM` com `funct3=000` e qualquer outro opcode são rejeitados (`valid=0`).

## Limitações entre decoder e núcleo

- O núcleo usa `branch_ne` somente para inverter uma comparação de igualdade. Portanto, embora o decoder aceite `BLT`, `BGE`, `BLTU` e `BGEU`, suas comparações ordenadas ainda não possuem controle próprio no datapath.
- O núcleo executa apenas os CSRs de estado FP (`fflags`, `frm`, `fcsr`); os demais SYSTEM, `ECALL`, `EBREAK` e `MRET` continuam sem execução completa.
- Loads e stores são classificados pelo decoder, mas largura, extensão de sinal e máscara de bytes dependem da implementação do caminho de memória. Consulte o RTL do núcleo e da memória ao verificar esses efeitos.
- RMM ainda usa a aproximação RNE no modelo RTL, e flags/subnormais requerem a validação diferencial ampla planejada com SoftFloat antes de declarar RV32F completo.
