"""Contract test for the ChimpSim API used by the server and GUI client."""

import cocotb

from bridge.chimp_sim import ChimpSim

PROGRAM = ((0, 0x00100073),)
EBREAK = 0x00100073


@cocotb.test()
async def bridge_api_contract(dut):
    """Exercise load, debug read, stepping, and halt through the public API."""
    sim = ChimpSim(dut)
    await sim.start_clock(10)
    await sim.reset(2)

    await sim.load_program(PROGRAM)
    assert await sim.peek_word(0) == EBREAK, (
        "debug port must expose the loaded RAM word"
    )
    assert sim.snapshot()["cycle"] == 0

    stepped = await sim.step(1)
    assert len(stepped) == 1
    assert stepped[0]["cycle"] == 1

    snapshots = await sim.run_until_halt(100)
    assert snapshots[-1]["halted"] == 1
    assert sim.last is snapshots[-1]
    assert sim.snapshot()["halted"] == 1
    assert {"cache_accesses", "cache_hits", "cache_misses"} <= sim.last.keys()
