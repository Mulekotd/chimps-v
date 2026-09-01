# Log 0000 — Inicialização

- Data: 2026-09-01
- Tipo: prompt/output
- Origem: conversa inicial do projeto CHIMPS-V

## Prompt

Estou fazendo um trabalho da matéria de Arquiteturas de Computadores da faculdade, nele precisamos desenvolver uma microarquitetura do zero. Escolhemos RISC-V e o nome definido para o nosso projeto é "CHIMPS-V". Além disso, utilizaremos Docker para empacotar este projeto;

A descrição do trabalho é a seguinte:

```plaintext
Implementar uma ferramenta gráfica de simulação da microarquitetura
de um processador MIC-1 (ou RISC-V) para ajudar na
aprendizagem do assunto da disciplina
● Seria composta de um montador, os componentes da microarquitetura
explicitamente ilustrados e caches de dados e instruções.
● O projeto deve ser encapsulado em uma máquina virtual Virtualbox ou
container Docker
● Será necessário que os projetos apresentem a implementação de código e uma
demonstração do funcionamento do sistema.
```

Tendo isso em mente, preciso que faça um research e estruture no arquivo CONTEXT.md todo processo de desenvolvimento que devemos seguir para este projeto. Lembre-se de anotar todas as referências (livros, artigos, papers, etc)!

CONSTRAINTS:

- O projeto será desenvolvido seguindo padrões de Test Driven Development e Spec Driven Development;
- Prezamos por desempenho, então sempre que alguma funcionalidade puder ser implementada como circuito digital, faça dessa forma;
- A microarquitetura deve ser capaz de trabalhar com pontos flutuantes utilizando o padrão IEEE 754;
- A microarquitetura deve seguir o modelo de Von Neumann;

FEATURES:

- Memória Primária (RAM);
- Memória Cache;
- Pipelining;
- Buffering de I/O;
- GUI (Interface de terminal).

A princípio é isso, sinta-se livre para agregar valor ao projeto.

## Output

Estruturei o plano completo em [CONTEXT.md](/CONTEXT.md).

Inclui arquitetura RV32IMF_Zicsr, pipeline de cinco estágios, RAM Von Neumann com I$/D$ sobre a mesma memória, MMIO/FIFOs, TUI, Docker, SDD/TDD, roteiro de validação, roadmap, riscos, métricas e critérios de aceite.

Também deixei explícito que a FPU deve ser circuito RTL e que conformidade `F` completa exige FMA, divisão e raiz — antes disso, o projeto deve declarar apenas um subconjunto FP experimental. As referências incluem a especificação RISC-V ratificada, IEEE 754-2019, testes arquiteturais oficiais e bibliografia fundamental. [RISC-V ISA](https://docs.riscv.org/reference/isa/), [IEEE 754](https://standards.ieee.org/ieee/754/6210/).
