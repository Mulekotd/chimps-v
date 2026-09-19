---
name: test-first-implementation
description: Planeje, crie e execute testes proporcionais sempre que implementar ou alterar circuitos RTL, frontend, serviços ou interfaces do CHIMPS-V.
metadata:
  short-description: Exigir testes junto às implementações
---

# Testes junto à implementação

Use esta skill ao implementar ou alterar comportamento observável no CHIMPS-V: RTL/VHDL, frontend, simulador, APIs, ferramentas, GUI ou integração. Não a use para mudanças puramente textuais, formatação ou metadados sem comportamento executável.

## Regra de entrega

Uma implementação não está concluída sem testes atualizados e executados que cubram o comportamento novo ou alterado. Planeje os casos antes ou durante a alteração; entregue o teste na mesma mudança, nunca como tarefa futura sem registrar a razão e o risco.

Escolha a camada mais próxima que prova o contrato e acrescente integração quando a fronteira entre componentes mudar. Evite testes que apenas reproduzam a implementação; valide entradas, saídas, estados e falhas observáveis.

## Roteamento por tipo de mudança

- **RTL/VHDL:** crie ou atualize `tests/vhdl/tb_<entidade>.vhd`. Cubra reset, operação nominal, limites/erros e cada handshake, latência, stall ou estado novo. Para instruções RISC-V, cubra encoding válido, comportamento arquitetural e caso inválido ou limite. Rode `scripts/compile-rtl.sh` (ou o fluxo Docker equivalente) e não declare a tarefa concluída se qualquer testbench falhar.
- **Integração de hardware:** além dos testbenches unitários, prove o contrato entre blocos — por exemplo, transação `valid/ready`, propagação de erro, coerência de dados, interrupção, cache ou caminho completo de instrução.
- **Frontend/GUI:** crie testes de componente para estados, eventos e acessibilidade afetados; crie testes de integração para fluxos, dados e fronteiras com simulador/API. Use teste ponta a ponta quando somente a interface completa puder provar o comportamento. Valide estados vazio, carregando, erro e sucesso quando aplicáveis.
- **Serviços, CLI, formatos e APIs:** teste contrato público, validação de entrada, erro e persistência/serialização; acrescente integração nas fronteiras externas relevantes.

## Decisões e evidências

Mantenha o teste pequeno, determinístico e no diretório/convenção do subsistema. Atualize `TASKS.md` somente quando a implementação e sua evidência de execução satisfizerem integralmente a tarefa. Se uma parte ainda faltar, mantenha a tarefa aberta e descreva com precisão o que resta.

Para novo comportamento arquitetural, siga também `check-references`: registre o contrato, a referência e uma contraprova antes de considerar a implementação pronta.
