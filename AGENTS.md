# Instruções do projeto

## Organização e fonte de verdade

- `specs/` na raiz contém os requisitos normativos do produto. RTL, futuro montador e testes devem obedecê-los.
- `rtl/` e `tests/` contêm respectivamente a implementação VHDL e a verificação executável. `assembler/` será introduzido apenas quando o montador próprio for implementado.
- `docs/adr/` registra decisões; `docs/audits/` auditorias; `docs/project/` backlog e planejamento; `docs/prompts/` histórico auxiliar de conversas.
- README, ADRs, auditorias, backlog e prompts devem referenciar `specs/`, sem redefinir seus requisitos normativos.

## Implementações e legado

Após toda implementação que substitua ou consolide um caminho existente, use a skill `legacy-pruning` para auditar e remover código, testes, manifests e documentação obsoletos. Para mudanças puramente aditivas, a skill deve registrar que não há substituição antes de preservar os componentes existentes.
