# Log 0002 — Criação da skill de logging

- Data: 2026-09-01
- Tipo: prompt/output

## Prompt

Quero que crie uma skill para o agente determinando isso, para que qualquer pessoa que for desenvolver nesse projeto com IA também guarde os logs das suas conversas.

## Output

Criei a skill do projeto em [`.agents/skills/prompt-logging/SKILL.md`](/.agents/skills/prompt-logging/SKILL.md).

Ela determina que agentes devem registrar cada prompt e output visível em logs numerados dentro de [`/docs/prompts`](/docs/prompts), preservando os arquivos existentes e usando caminhos relativos nos links. Este pedido também foi registrado como o log 0002.

A validação estrutural foi concluída com sucesso. A validação automática oficial não pôde executar porque o `python.exe` do ambiente está bloqueado.
