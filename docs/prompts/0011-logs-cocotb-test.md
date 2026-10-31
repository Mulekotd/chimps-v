# Log 0011 — Teste cocotb até EBREAK

- Data: 2026-10-31
- Tipo: prompt/output

## Prompt

okay, now make cocotb test that starts a clock, mimics the load_word sequence from the testbench, releases reset, then steps cycle by cycle printing dut.current_pc.value and dut.current_instruction.value until dut.halted.value == 1.

## Output

Added [sim/cocotb/test_chimps_v_system.py](/sim/cocotb/test_chimps_v_system.py). It drives a 10 ns clock, reproduces all ten `load_word` transactions from [tests/vhdl/tb_chimps_v_system.vhd](/tests/vhdl/tb_chimps_v_system.vhd), releases reset, and logs `PC=0x... instruction=0x...` after each rising edge until `halted` is asserted. It also asserts the loader accepts every word, the run completes within 20 µs, `halted=1`, and `illegal_instruction=0`.

The default `make` flow in [sim/cocotb/Makefile](/sim/cocotb/Makefile) now runs it. Result: `TESTS=1 PASS=1`; the pipeline halted after 715 ns.
