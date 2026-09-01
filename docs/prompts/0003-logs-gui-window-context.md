# Log 0003 — Atualização da interface gráfica

- Data: 2026-09-08
- Tipo: prompt/output

## Prompt

Vamos remodelar algumas coisas. O projeto não terá apenas um TUI, meu colega pretende implementar de fato uma interface de usuário (GUI).

Esta interface irá desenhar de maneira mais sofisticada o ciclo de execução sequêncial do processador. Mostrar todo o caminho de acesso em memória em um esquemático do Processador + Memória Principal além de outras interações que forem interessantes. Portanto, preciso que atualize o documento de CONTEXT.md para atender a essa nova especificação.

## Output

Atualizei [`/CONTEXT.md`](/CONTEXT.md) para tratar a GUI em janela como interface principal do CHIMPS-V.

As mudanças incluem:

- GUI desktop em C++/Qt ou Python/PySide, mantendo TUI/CLI como modo headless;
- contrato versionado `CycleSnapshot` entre simulador e frontend;
- esquemático CPU↔memória com registradores, barramentos, caches, RAM, FPU, pipeline e MMIO;
- timeline fetch → decode → execute → memory → write-back;
- realce de caminhos, sinais, stalls, flushes, hits, misses e traps;
- controles de execução, navegação por snapshots, breakpoints e inspeção de componentes;
- execução Docker com modo `--headless` e exportação de traces;
- roadmap, organização do repositório, métricas, riscos e critérios de aceite atualizados.
