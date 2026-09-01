# Log 0008 — Skill de testes e revisão RTL

- Data: 2026-09-19
- Tipo: prompt/output

## Prompt

Crie uma nova skill para que a cada novo circuito implementado em RLT, seja desenvolvido o seu respectivo teste.

A skill também deve saber quando criar testes em outras partes da aplicação, por exemplo, futuramente na implementação do Frontend, etc.

Por fim, revise as implementações RTL e compare com o que ainda falta terminar em TASKS.md, marcando como concluído tudo que já feito.

## Output

Criei a skill [test-first-implementation](/.agents/skills/test-first-implementation/SKILL.md). Ela exige testes e execução de evidências a cada mudança observável, com rotas específicas para RTL/VHDL, integração de hardware, frontend/GUI e serviços/APIs.

Revisei o RTL e os testbenches contra [TASKS.md](/TASKS.md). Não havia novas caixas a marcar: as entregas existentes já estão assinaladas, enquanto os itens em aberto ainda dependem de partes reais ausentes, como `memory_bus`, integração das caches ao core, pipeline, RV32M no decoder/core, Zicsr e a extensão F completa.

Não foi possível executar a regressão neste ambiente porque Docker não está instalado; o fluxo previsto permanece `docker compose run --rm rtl`.
