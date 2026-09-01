# Log 0009 — Skill de remoção de legado

- Data: 2026-09-20
- Tipo: prompt/output

## Prompt

Crie uma skill para que sempre que uma nova implementação for feita o código legado ou o código sem mais utilidade seja apagado.

## Output

Criei a skill `legacy-pruning` em `.agents/skills/legacy-pruning/SKILL.md` e a
validei com o verificador de skills. Ela exige, após uma implementação que substitua
um caminho existente, auditar dependências, remover fonte/testes/wrappers/manifests/
documentação obsoletos, confirmar que não restaram referências e executar a
regressão relevante.

Também adicionei `AGENTS.md`, que torna essa auditoria obrigatória no projeto após
cada substituição ou consolidação e evita remoções especulativas em mudanças apenas
aditivas.
