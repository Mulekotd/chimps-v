# Instruções do projeto

## Organização e fonte de verdade

- `specs/` na raiz contém os requisitos normativos do produto. RTL, software, CLI e testes devem obedecê-los.
- `rtl/`, `software/`, `cli/` e `tests/` contêm respectivamente implementação VHDL, software alvo, ferramentas do host e verificação executável.
- `docs/adr/` registra decisões; `docs/audits/` auditorias; `docs/project/` backlog e planejamento; `docs/prompts/` histórico auxiliar de conversas.
- README, ADRs, auditorias, backlog e prompts devem referenciar `specs/`, sem redefinir seus requisitos normativos.

## Implementações e legado

Após toda implementação que substitua ou consolide um caminho existente, use a skill `legacy-pruning` para auditar e remover código, testes, manifests e documentação obsoletos. Para mudanças puramente aditivas, a skill deve registrar que não há substituição antes de preservar os componentes existentes.
