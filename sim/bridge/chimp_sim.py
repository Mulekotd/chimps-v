"""Reusable cocotb driver for the CHIMPS-V top-level system."""

from cocotb.clock import Clock
from cocotb.triggers import ReadOnly, RisingEdge, Timer

DEFAULT_CLOCK_PERIOD_NS = 10


class ChimpSim:
    """Drive ``chimps_v_system`` like ``tests/vhdl/tb_chimps_v_system.vhd``."""

    def __init__(self, dut, clock_period_ns=DEFAULT_CLOCK_PERIOD_NS):
        self.dut = dut
        self.clock_period_ns = clock_period_ns
        self.clock = None
        self._clock_started = False
        self.cycle = 0
        self._last_snapshot = {}

    async def start_clock(self, clock_period_ns=None):
        """Start the 50:50 clock with the first rising edge after half a period."""
        if clock_period_ns is not None:
            self.clock_period_ns = clock_period_ns
        if self._clock_started:
            return
        self.clock = Clock(self.dut.clk, self.clock_period_ns, unit="ns")
        self.clock.start(start_high=False)
        self._clock_started = True

    def _set_idle_inputs(self):
        dut = self.dut
        dut.load_valid.value = 0
        dut.load_address.value = 0
        dut.load_data.value = 0
        dut.load_mask.value = 0xF
        dut.debug_address.value = 0

    async def reset(self, cycles=1):
        """Start the clock and hold the system in reset for ``cycles`` edges."""
        self._set_idle_inputs()
        self.dut.rst.value = 1
        await self.start_clock()
        for _ in range(cycles):
            await RisingEdge(self.dut.clk)
        self.cycle = 0
        return self._capture()

    async def load_word(self, address, value):
        """Apply one ``load_word`` transaction from the VHDL testbench."""
        dut = self.dut
        dut.load_address.value = address
        dut.load_data.value = value
        dut.load_valid.value = 1
        await RisingEdge(dut.clk)
        if int(dut.load_ready.value) != 1:
            raise AssertionError(
                f"loader did not accept aligned RAM word at 0x{address:08x}"
            )

    async def load_program(self, program, base_address=0):
        """Load ``(address, word)`` pairs or consecutive 32-bit words."""
        for index, entry in enumerate(program):
            if isinstance(entry, (tuple, list)) and len(entry) == 2:
                address, word = entry
            else:
                address, word = base_address + index * 4, entry
            await self.load_word(int(address), int(word))
        self.dut.load_valid.value = 0

    def _capture(self):
        """Sample the observable top-level state for the current cycle."""
        dut = self.dut
        self._last_snapshot = {
            "cycle": self.cycle,
            "pc": int(dut.current_pc.value),
            "instruction": int(dut.current_instruction.value),
            "halted": int(dut.halted.value),
            "illegal": int(dut.illegal_instruction.value),
            "retired": int(dut.retired.value),
            "pipeline_valid": int(dut.pipeline_valid.value),
            "cache_accesses": int(dut.cache_accesses.value),
            "cache_hits": int(dut.cache_hits.value),
            "cache_misses": int(dut.cache_misses.value),
        }
        return self._last_snapshot

    def snapshot(self):
        """Capture the observable top-level state at the current cycle."""
        return self._capture()

    @property
    def last(self):
        """Most recent snapshot taken while stepping the simulation."""
        return self._last_snapshot

    def is_halted(self):
        """Whether the pipeline has retired an EBREAK."""
        return int(self.dut.halted.value) == 1

    @staticmethod
    async def _leave_read_only():
        """Advance one simulator step so inputs can be driven again."""
        await Timer(1, unit="step")

    async def step(self, n=1):
        """Release reset, advance ``n`` cycles, and collect one snapshot per cycle."""
        self.dut.load_valid.value = 0
        self.dut.rst.value = 0
        snapshots = []
        for _ in range(n):
            if self.is_halted():
                break
            await RisingEdge(self.dut.clk)
            await ReadOnly()
            self.cycle += 1
            snapshots.append(self._capture())
        await self._leave_read_only()
        return snapshots

    async def run_until_halt(self, max_cycles=2000):
        """Release reset, step one cycle at a time, and return the snapshots."""
        self.dut.load_valid.value = 0
        self.dut.rst.value = 0
        snapshots = []
        for _ in range(max_cycles):
            await RisingEdge(self.dut.clk)
            await ReadOnly()
            self.cycle += 1
            snapshot = self._capture()
            snapshots.append(snapshot)
            self.dut._log.info(
                "PC=0x%08x instruction=0x%08x",
                snapshot["pc"],
                snapshot["instruction"],
            )
            if snapshot["halted"]:
                await self._leave_read_only()
                return snapshots

        await self._leave_read_only()
        raise TimeoutError(
            f"chimps_v_system did not halt within {max_cycles} cycles"
        )

    async def peek_word(self, address):
        """Read one backing-store word through the debug port without clocking."""
        self.dut.debug_address.value = address & 0xFFFFFFFC
        await ReadOnly()
        value = int(self.dut.debug_data.value)
        await self._leave_read_only()
        return value
