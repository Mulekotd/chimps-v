# Log 0004 — Atualização da interface gráfica

- Data: 2026-09-08
- Tipo: prompt/output

## Prompt

Vamos remodelar algumas coisas. A interface do projeto não será apenas um TUI, meu colega pretende implementar de fato uma interface em janela (com C++ ou Python). Está interface irá desenhar o ciclo de execução sequêncial do processador (fetch, decode, etc). Então ele vai mostrar todo o caminho de acesso em memória em um esquemático de CPU (registradores, barramentos) + Memória Principal e outras interações que forem interessantes. Preciso então que atualize o documento de CONTEXT.md para atender essa nova demanda.

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

