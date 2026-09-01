# Subconjunto FP integrado

O core sequencial integra o banco `fp_register_file` e a `fpu` para o subconjunto
binary32 sem arredondamento implementado: `FSGNJ.S`, `FSGNJN.S`, `FSGNJX.S`,
`FMIN.S`, `FMAX.S`, `FEQ.S`, `FLT.S`, `FLE.S`, `FCLASS.S`, `FMV.W.X` e `FMV.X.W`.
Os dois primeiros grupos escrevem FPR; comparações e `FCLASS.S` escrevem GPR;
os moves transferem o padrão binário entre os bancos.

No estado `FP_LAUNCH` o core pulsa `start`; em `FP_WAIT` retém PC, instrução e
operandos até `done`; `FP_RETIRE` escreve o FPR, quando aplicável, e avança o PC.
As flags produzidas pela FPU acumulam em `fp_fflags`, exposto para observação. Não
há ainda acesso via CSR, aritmética, conversões, `FLW`/`FSW`, `frm` ou rounding;
esses encodings permanecem ilegais e este marco não declara RV32F completo.

## Reference check

- **Componente e questão:** encaminhar encodings OP-FP single-precision aos FPRs e
  à FPU sem usar o banco GPR para operandos FP.
- **Referência:** RISC-V Unprivileged ISA v20260120, extensão F 2.2, seção *F
  Register State* e listagem RV32F: F possui 32 FPRs de FLEN=32; `FSGNJ.S`/
  `FMIN.S` escrevem FPR, enquanto comparações e `FCLASS.S` escrevem GPR.
- **Decisão:** o core usa bancos separados, `rs1`/`rs2` como índices FPR para
  OP-FP e o campo `rd` no banco definido pelo encoding. `fflags` acumula mas não
  é acessível por software até a integração Zicsr/fcsr.
- **Aceite:** `FMV.W.X`, `FSGNJ.S` e `FMV.X.W` transferem `-1.0` até um store GPR;
  `FCLASS.S` e `FEQ.S` escrevem os bits esperados no GPR. **Contraprova:**
  `FADD.S`, ainda não implementada, para o core como instrução ilegal sem escrita.
