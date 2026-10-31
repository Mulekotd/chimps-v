# Log 0013 — Awaitable `ChimpSim.start_clock` with clock period

- Data: 2026-10-31
- Tipo: prompt/output

## Prompt

```text
TypeError: ChimpSim.start_clock() takes 1 positional argument but 2 were given
```

## Output

`ChimpSim.start_clock()` is now an `async` method that accepts an optional clock period, so the test's `await sim.start_clock(CLOCK_PERIOD_NS)` works.

Changes in [chimp_sim.py](/sim/cocotb/bridge/chimp_sim.py):

- `start_clock(clock_period_ns=None)` builds the `Clock` with the requested period when it is called.
- `reset()` now awaits `start_clock()`.
- `load_program()` accepts `(address, word)` pairs as well as plain words.
- `snapshot()` defaults to the last stepped cycle, so `print(sim.snapshot())` reports the final cycle.

`make sim` from `sim/cocotb` passes:

```text
TESTS=1 PASS=1 FAIL=0 SKIP=0
{'cycle': 62, 'pc': 32, 'instruction': 1048691, 'halted': 1, 'illegal': 0, 'retired': 1, 'pipeline_valid': 0}
```

Generated `sim_build/`, `results.xml`, and `__pycache__/` artifacts were removed afterwards.
