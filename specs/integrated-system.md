# Sistema integrado de referência

`chimps_v_system` é o ponto de integração RTL para a referência sequencial. O
loader escreve words little-endian na RAM backing enquanto `rst=1`; as caches são
invalidadas pelo mesmo reset, e o core só inicia fetch depois que ele é removido.

O core emite uma requisição de instrução ou de dados e a mantém até `ready`. A
I-cache direta e a D-cache de duas vias compartilham `memory_bus`, cuja prioridade
fixa é da porta de dados. A RAM backing aceita no máximo uma requisição word-aligned
por ciclo, devolve `error` para endereços fora dos 96 KiB e não faz alias.

O core retém PC, instrução e operandos entre `valid` e `ready`. Operações RV32M
iniciam a unidade M uma vez e só aposentam depois de `done`. Falha de fetch, dados
ou instrução sem encoding implementado interrompe o core sem escrever GPR ou RAM.
O estado FP documentado em `fp-subset.md` está conectado: aritmética, FMA,
conversões W/WU, `FLW`/`FSW` e os CSRs `fflags`/`frm`/`fcsr`. RMM, flags precisas
para todos os casos e validação diferencial ampla continuam fora deste marco;
portanto, o projeto não anuncia RV32F completo.

## Estrutura canônica

Há somente uma implementação ativa para cada responsabilidade: `core_rv32i_single`
é o core sequencial com interface de memória; `memory_backing_store` é a RAM única;
e `cache_l1` parametrizado implementa as duas L1. Os antigos core ligado diretamente
à RAM, RAM de duas portas e cache direta write-through foram removidos, pois eram
versões paralelas do mesmo caminho e poderiam divergir em máscaras, limites e
latência.

## Reference check

- **Componente e questão:** ligação core–cache–barramento–RAM e aposentadoria de
  RV32M sem repetir uma requisição durante uma espera.
- **Referências:** RISC-V Unprivileged ISA, RV32I 2.1, *Load and Store
  Instructions* e alinhamento de `IALIGN=32`; extensão M 2.0, *Multiplication
  Operations* e a tabela de divisão por zero/overflow; Hennessy & Patterson,
  5ª ed., cap. 5, para a interface de requisição/resposta de memória.
- **Decisão:** requests são estáveis até `ready`; words fora da RAM e words
  desalinhadas recebem `error`; DIV/REM preservam os resultados definidos pela M
  para divisor zero e overflow. O erro é uma parada de diagnóstico deste marco,
  não uma implementação dos CSRs de trap.
- **Aceite:** uma imagem carregada durante reset executa `ADDI`, `MUL`, `SW` e
  `LW` através de ambas as caches e grava o valor esperado na RAM. **Contraprova:**
  o fetch seguinte de `0x00000000` para o core, e uma carga/alinhamento inválido
  no backing store, param sem efeito arquitetural adicional.
