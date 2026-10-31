"""cocotb smoke test for the CHIMPS-V integrated system."""

CLOCK_PERIOD_NS = 10
RUN_TIMEOUT_US = 20

PROGRAM = (
    (0, 0x00500093),  # addi x1, x0, 5
    (4, 0x00308113),  # addi x2, x1, 3: RAW dependency
    (8, 0x04202023),  # sw x2, 64(x0)
    (12, 0x04002183),  # lw x3, 64(x0): data-cache miss
    (16, 0x04002203),  # lw x4, 64(x0): data-cache hit
    (20, 0x00000463),  # beq x0, x0, 8
    (24, 0x04102223),  # sw x1, 68(x0): must be flushed
    (28, 0x00100073),  # ebreak
    (32, 0x00100073),  # fetched while the first EBREAK drains
    (36, 0x00100073),  # keeps speculative fetch inside the subset
)


# async def load_word(dut, address, value):
#     """Apply one load_word transaction from tb_chimps_v_system."""
#     dut.load_address.value = address
#     dut.load_data.value = value
#     dut.load_valid.value = 1
#     await RisingEdge(dut.clk)
#     assert int(dut.load_ready.value) == 1, (
#         f"loader did not accept aligned RAM word at 0x{address:08x}"
#     )


# async def run_program(dut):
#     """Load the program, release reset, and print one line per clock cycle."""
#     dut.rst.value = 1
#     dut.load_valid.value = 0
#     dut.load_address.value = 0
#     dut.load_data.value = 0
#     dut.load_mask.value = 0xF
#     dut.debug_address.value = 0

#     Clock(dut.clk, CLOCK_PERIOD_NS, unit="ns").start(start_high=False)

#     for address, value in PROGRAM:
#         await load_word(dut, address, value)

#     dut.load_valid.value = 0
#     dut.rst.value = 0

#     while not int(dut.halted.value):
#         await RisingEdge(dut.clk)
#         await ReadOnly()
#         dut._log.info(
#             "PC=0x%08x instruction=0x%08x",
#             int(dut.current_pc.value),
#             int(dut.current_instruction.value),
#         )


# @cocotb.test()
# async def run_until_halted(dut):
#     await with_timeout(run_program(dut), RUN_TIMEOUT_US, "us")
#     assert int(dut.halted.value) == 1
#     assert int(dut.illegal_instruction.value) == 0

import cocotb

from bridge.chimp_sim import ChimpSim


@cocotb.test()
async def run_until_halted(dut):
    """Load a program into the CHIMPS-V integrated system and run it until halted."""
    sim = ChimpSim(dut)
    await sim.start_clock(CLOCK_PERIOD_NS)
    await sim.reset()
    await sim.load_program(PROGRAM)
    await sim.run_until_halt()
    print(sim.snapshot())