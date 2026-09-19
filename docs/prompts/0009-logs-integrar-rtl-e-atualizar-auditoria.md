# Log 0009 — Integrar RTL e atualizar auditoria

- Data: 2026-09-19
- Tipo: prompt/output

## Prompt

Preciso que atualize as fases no arquivo microarchitecture-audit.md. Apague as que já foram e mantenha apenas o que falta implementar.

Por último, implemente as tarefas que faltam nos tópicos:

- **Prioridade imediata — referência e integração da L1;**
- **ISA, carregamento e traps;**
- **Memória e I/O;**
- **Extensão M e ponto flutuante;**
- Criar CI com GHDL/VUnit ou OSVVM usando a imagem Docker;
- Executar testes arquiteturais, integração, smoke test Docker e roteiro de demo.

Ao termino, atualize tasks.md marcando o que foi concluído.

## Output

Atualizei a auditoria para manter somente as fases pendentes e implementei as entregas verificáveis desta rodada:

- `rtl/memory_bus.vhd` arbitra fetch/dados com `valid/ready`, escrita, máscara, dado e erro; `tb_memory_bus` comprova prioridade de dados e isolamento de resposta/erro.
- A L1 agora tem contraprova de erro de backing; a unidade M cobre as oito operações no Docker, incluindo overflow e divisão por zero.
- Adicionei CI em `.github/workflows/rtl.yml`, scripts para teste arquitetural e smoke Docker, e o roteiro em `docs/demo/rtl-demo.md`.
- Atualizei `specs/tasks.md`, marcando somente o barramento, CI, smoke/demo e a contraprova L1 como concluídos.

Validação executada: lint Docker e suíte Docker verde, com 14 testbenches.

As tarefas seguem abertas quando ainda dependem de trabalho real: core cacheado/pipeline, carregador `.bin`/`.hex`, traps/CSRs, MMIO/FIFOs, D-cache 2-way/write-back, integração de M e F ao core, oráculo SoftFloat e validação diferencial. Não as marquei como concluídas para não representar funcionalidades que o RTL ainda não implementa.
