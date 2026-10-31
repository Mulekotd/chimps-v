# Log 0010 — Makefile do cocotb

- Data: 2026-10-31
- Tipo: prompt/output

## Prompt

write the sim/makefile for me... sim/cocotb/Makefile - Needs to compile the RTL sources in the same order as scripts/compile-rtl.sh does (chimps_pkg.vhd, memory_backing_store.vhd, memory_bus.vhd, cache_l1.vhd, pipeline.vhd, chimps_v_system.vhd). Use TOPLEVEL_LANG=vhdl, SIM=ghdl, and set TOPLEVEL=chimps_v_system.

## Output

Created [sim/cocotb/Makefile](/sim/cocotb/Makefile) with GHDL + cocotb 2.1 configuration. It sets `SIM=ghdl`, `TOPLEVEL_LANG=vhdl`, `TOPLEVEL=chimps_v_system`, lists the six RTL sources in the same order as `scripts/compile-rtl.sh`, and passes `--std=08` to analysis, elaboration, and execution.

I smoke-tested it with a temporary cocotb module: compilation/elaboration loaded `chimps_v_system` and the test passed (`TESTS=1 PASS=1`). Generated artifacts were removed from the repository. The default `COCOTB_TEST_MODULES` is `test_chimps_v_system`; override it when the Python test module has another name.
