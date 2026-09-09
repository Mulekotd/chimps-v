# Log 0005 — Auditoria da implementação VHDL

- Data: 2026-09-08
- Tipo: prompt/output

## Prompt

Verifique se a minha implementação em VHDL dos microcircuitos atende as demandas que foram levantadas no escopo deste projeto em CONTEXT.md.

Depois disso, documente em um arquivo em /docs o que cada circuito faz e como eles se comunicam entre si no final. Também seria legal criar um diagrama em mermaid para deixar mais fácil a visualização da microarquitetura atual.

Também documente como devemos seguir para os próximos passos de implementação: definir uma ISA, integrar diretamente com os circutos, etc.

## Output

Criei [`/docs/microarchitecture-audit.md`](/docs/microarchitecture-audit.md) com:

- matriz de conformidade entre o RTL atual e o escopo do [`/CONTEXT.md`](/CONTEXT.md);
- descrição de cada microcircuito em [`/rtl`](/rtl) e suas interfaces;
- explicação do fluxo single-cycle atual;
- diagrama Mermaid da microarquitetura implementada;
- lista de lacunas: pipeline, hazards, caches, MMIO/FIFOs, `M`, `F`, CSRs, GUI, assembler e Docker/CI;
- roadmap para definir a ISA, estabilizar a referência RV32I, integrar o pipeline, memória, extensões e GUI;
- critérios objetivos para considerar a microarquitetura integrada.

Conclusão: a implementação atual é uma referência funcional RV32I single-cycle parcial. Ela ainda não atende ao escopo final do projeto, mas fornece uma base adequada para verificação e evolução incremental.
