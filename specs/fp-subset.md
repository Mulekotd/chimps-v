# Estado FP integrado

O core sequencial mantém 32 FPRs binary32 e os campos arquiteturais `fflags` e
`frm` do `fcsr`. Os CSRs `fflags` (`0x001`), `frm` (`0x002`) e `fcsr` (`0x003`)
aceitam as seis instruções Zicsr; bits reservados de `fcsr` leem zero. As flags
produzidas pela FPU acumulam em `fflags` e escrita por CSR as substitui.

São encaminhadas aos FPRs as operações de sinal, min/max, `FADD.S`, `FSUB.S`,
`FMUL.S`, `FDIV.S`, `FSQRT.S`, as quatro FMA, `FCVT.S.W[U]`, `FLW` e `FSW`.
Comparações, `FCLASS.S`, `FCVT.W[U].S` e `FMV.X.W` escrevem GPR; `FMV.W.X`
preserva o padrão de 32 bits no sentido inverso. `FLW`/`FSW` usam o mesmo endereço
base+offset e o mesmo handshake do caminho de dados inteiro.

No estado `FP_LAUNCH` o core pulsa `start`; em `FP_WAIT` retém PC, instrução e
operandos até `done`; `FP_RETIRE` escreve o FPR, quando aplicável, e avança o PC.
RNE, RTZ, RDN e RUP usam o `rm` estático ou o `frm` quando `rm=111`.

Este marco ainda não declara conformidade RV32F completa: o modelo IEEE usado no
RTL trata RMM como RNE e a regressão SoftFloat cobre vetores dirigidos, não uma
validação diferencial exaustiva de flags, subnormais e todos os empates.

## Reference check

- **Componente e questão:** encaminhar encodings OP-FP single-precision aos FPRs e
  à FPU sem usar o banco GPR para operandos FP.
- **Referência:** RISC-V Unprivileged ISA v20260120, extensão F 2.2, seção *F
  Register State* e listagem RV32F: F possui 32 FPRs de FLEN=32; `FSGNJ.S`/
  `FMIN.S` escrevem FPR, enquanto comparações e `FCLASS.S` escrevem GPR.
- **Decisão:** o core usa bancos separados, `rs1`/`rs2`/`rs3` como índices FPR
  para operações FP e o campo `rd` no banco definido pelo encoding. `fcsr` é
  composto de `frm` e `fflags`; exceções não causam trap.
- **Aceite:** `FADD.S`, `FLW`/`FSW`, `FMADD.S` e leitura/escrita de `fflags` por
  CSR aposentam com o destino esperado; os vetores dirigidos são conferidos por
  SoftFloat 3e. **Contraprova:** `rm=101` ou `110`, CSR diferente de `fflags`,
  `frm` ou `fcsr`, e formato FP diferente de binary32 param como ilegais.
