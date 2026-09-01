---
name: check-references
description: Check new CHIMPS-V hardware or low-level software implementations against the project's computer-architecture bibliography and the official RISC-V specification when ISA compatibility is relevant.
---

# Check References

Use this skill whenever implementing a CHIMPS-V component from scratch: an ISA feature, datapath, control path, memory, cache, bus/peripheral interface, assembler, linker/runtime, compiler support, or FPGA integration. Do not apply it to a mechanical refactor or isolated bug fix unless the change alters an architectural behavior.

## Reference hierarchy

- For a claimed RISC-V behavior, the [official RISC-V specifications](https://docs.riscv.org/reference/home/index.html) are normative. Do not call an extension or encoding RISC-V-compatible unless it conforms to the relevant ratified specification.
- For RISC-V explanations, examples, programming conventions, and cross-checks, you may also consult the [RISC-V Programming book](https://riscv-programming.org/book/riscv-book.html). Treat it as a secondary educational reference: when it differs from or is less precise than the official specification, the official specification takes precedence.
- For VHDL implementations, consult the [IEEE Standard VHDL Language Reference Manual](https://edg.uchicago.edu/~tang/VHDLref.pdf) for language syntax and semantics, especially when the RTL depends on standard VHDL behavior.
- Use the following bibliography for architectural rationale, terminology, trade-offs, and validation strategy:
  - Hennessy & Patterson, *Arquitetura de Computadores: Uma Abordagem Quantitativa*, 5th ed.
  - Patterson & Hennessy, *Organização e Projeto de Computadores: A Interface Hardware/Software*, 4th ed.
  - Stallings, *Arquitetura e Organização de Computadores*.
  - Tanenbaum, *Organização Estruturada de Computadores*, chapters 1, 2 and 4 of the 3rd ed.
  - Esmeraldo, *Fundamentos e Práticas em Arquitetura e Organização de Computadores*, 1st ed.

## Required reference check

Before implementation, identify the component's contract: inputs, outputs, clock/reset behavior, latency, ordering, errors/traps, memory ordering where applicable, and observable software behavior.

Then record a concise **Reference check** in the feature spec, design note, or ADR containing:

- the component and the architectural question it addresses;
- the consulted standard or bibliographic reference, including section/page when available;
- the resulting decision and any intentional deviation;
- at least one observable acceptance criterion and its contraprova.

For RTL, ensure that cycle behavior is explicit: combinational versus registered paths, memory read/write latency, reset semantics, stalls, hazards, handshakes, and clock-domain boundaries. For software tooling, ensure that the binary format, endianness, instruction encoding, memory map, calling/startup convention, and error reporting agree with the implemented hardware contract.

## RISC-V compatibility

When implementing a RISC-V instruction, extension, trap, CSR, ABI-facing feature, or toolchain integration:

1. identify the exact RISC-V ISA profile and extensions supported;
2. verify instruction encoding, register semantics, alignment, exceptions, and privilege requirements against the official specification;
   Use the [RISC-V Programming book](https://riscv-programming.org/book/riscv-book.html) as an additional source for explanatory context, programming examples, ABI-facing conventions, and terminology, but do not use it alone to establish normative ISA compatibility;
3. keep unsupported instructions/extensions explicit and make the assembler/compiler reject them clearly;
4. add directed tests with valid behavior, invalid encoding or boundary behavior, and a software-visible contraprova.

If CHIMPS-V uses a custom ISA or custom extension, give it a distinct documented namespace and encoding. Do not reuse reserved RISC-V encodings or claim RISC-V toolchain compatibility without a documented compatibility boundary.

## Completion criteria

Do not conclude a new implementation solely because simulation or synthesis succeeds. Confirm the reference check, the hardware/software contract, directed positive and negative tests, and the expected behavior at the relevant integration boundary (RTL testbench, assembler output, FPGA peripheral, or software program).
