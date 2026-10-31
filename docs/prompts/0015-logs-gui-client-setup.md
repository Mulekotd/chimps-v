# Log 0015 — GUI client setup for the simulation server

- Data: 2026-10-31
- Tipo: prompt/output

## Prompt

```text
i need to build a GUI now, using only the client to comunicate with the risk-v cpu. Is there any more setup i need to do?
```

## Output

Almost ready. Three setup blockers are fixed; only the GUI toolkit still needs installing.

## What I fixed

- [sim/cocotb/Makefile](/sim/cocotb/Makefile) now selects tests with `COCOTB_TEST_MODULES`. The old file-level `MODULE` default shadowed it, so `make COCOTB_TEST_MODULES=server_test` silently ran the smoke test. `make MODULE=server_test` still works, with cocotb's deprecation warning.
- `sim/bridge` is now the single package for both the cocotb driver and the client. The Makefile exports `sim/` on `PYTHONPATH`, and [chimp_sim.py](/sim/bridge/chimp_sim.py) moved there from `sim/cocotb/bridge`.
- `peek_word()` no longer advances the clock. It used to take a rising edge while reset was asserted, and `load_valid=0` clears the RAM on every reset edge, so `peek()` returned zeros.
- Added [test_bridge_api.py](/sim/cocotb/test_bridge_api.py), covering load → peek → step → `run_until_halt`.

## Start the server

```bash
cd ~/chimps-v/sim/cocotb
source ../.venv/bin/activate
make COCOTB_TEST_MODULES=server_test
```

It listens on `127.0.0.1:5555` with `authkey=b'chimps-v'` and blocks while idle. Simulation time does not advance between commands, which is what makes single-stepping stable.

## Import the client

Put `sim/` on the path, not `sim/cocotb/`:

```python
import sys
sys.path.insert(0, "/home/pirat/chimps-v/sim")
from bridge.client import ChimpClient
```

```python
client = ChimpClient()
client.reset()
client.load_program([(0, 0x00500093), (4, 0x00100073)])
client.step(1)
print(client.get_snapshot())
client.quit()
```

Available commands: `load_program(words, base_addr=0)` (plain words or `(address, word)` pairs), `reset(cycles=2)`, `step(n)`, `run_until_halt(max_cycles)`, `get_snapshot()`, `peek(addr)`, `quit()`.

## Install a GUI toolkit

`tkinter` is not installed in either the venv or the system Python:

```bash
sudo apt install python3-tk
```

WSLg is active (`DISPLAY=:0`), so Tk windows open on the Windows desktop. If you prefer, use `pip install PySide6` or a browser-based UI; both can keep using only `ChimpClient`.

## Rules to respect

- Sequence is `reset` → `load_program` → `step`/`run_until_halt`. While reset is asserted with `load_valid=0`, the RAM is cleared on every clock edge, so never reset after loading.
- Check each response's `ok` field; errors come back as `{'ok': False, 'error': ...}`.
- Client calls block, and the server handles one connection at a time. Run them from one worker thread, not the Tk main loop, and serialize calls.
- `run_until_halt` can run thousands of cycles; keep it off the UI thread.
- `quit` ends the server and the `make` process.

## Verification

```text
make sim                                   PASS
make COCOTB_TEST_MODULES=test_bridge_api   PASS
server flow (load/peek/step/halt/quit)     PASS, halted at cycle 8
```

Want me to scaffold `sim/gui/` with the client import and a background-thread command queue?
