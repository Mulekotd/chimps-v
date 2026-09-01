---
name: test-first-implementation
description: Plan, create, and run proportionate tests whenever implementing or changing CHIMPS-V RTL circuits, frontends, services, or interfaces.
metadata:
  short-description: Require tests with implementations
---

# Tests alongside implementation

Use this skill when implementing or changing observable CHIMPS-V behavior: RTL/VHDL,
frontend, simulator, APIs, tools, GUI, or integration. Do not use it for purely textual,
formatting, or metadata changes with no executable behavior.

## Delivery rule

An implementation is not complete without updated and executed tests that cover the
new or changed behavior. Plan the cases before or during the change and deliver the
test in the same change; never defer it without documenting the reason and risk.

Choose the closest layer that proves the contract, and add integration coverage when
a component boundary changes. Avoid tests that merely reproduce the implementation;
validate observable inputs, outputs, states, and failures.

## Routing by change type

- **RTL/VHDL:** create or update `tests/vhdl/tb_<entity>.vhd`. Cover reset, nominal
  operation, limits/errors, and every new handshake, latency, stall, or state. For
  RISC-V instructions, cover valid encoding, architectural behavior, and an invalid
  or boundary case. Run `scripts/compile-rtl.sh` (or the equivalent Docker flow), and
  do not declare the task complete while any testbench fails.
- **Hardware integration:** in addition to unit testbenches, prove the contract
  between blocks, such as a `valid/ready` transaction, error propagation, data
  coherence, interrupt, cache, or complete instruction path.
- **Frontend/GUI:** create component tests for affected states, events, and
  accessibility, plus integration tests for flows, data, and simulator/API
  boundaries. Use an end-to-end test when only the complete interface can prove the
  behavior. Validate empty, loading, error, and success states where applicable.
- **Services, CLI, formats, and APIs:** test the public contract, input validation,
  errors, and persistence/serialization; add integration coverage at relevant
  external boundaries.

## Decisions and evidence

Keep each test small, deterministic, and in the subsystem's established directory
and convention. Update `specs/tasks.md` only when both the implementation and its
execution evidence fully satisfy the task. If anything remains, keep the task open
and state precisely what is missing.

For new architectural behavior, also follow `check-references`: record the contract,
reference, and at least one counterexample before treating the implementation as
complete.
