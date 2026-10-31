# Log 0014 — Fix cocotb command server event loop and driver API

- Data: 2026-10-31
- Tipo: prompt/output

## Prompt

```text
i am getting this error when running make MODULE=server_test: Traceback (most recent call last):                                                          File "/home/pirat/chimps-v/sim/cocotb/server_test.py", line 21, in sim_server                                                            loop = asyncio.get_event_loop()                                                          File "/usr/lib/python3.14/asyncio/events.py", line 715, in get_event_loop                                                            raise RuntimeError('There is no current event loop in thread %r.'                                                                               % threading.current_thread().name)                                                      RuntimeError: There is no current event loop in thread 'MainThread'.     5.00ns INFO     cocotb.regression
```

## Output

`asyncio.get_event_loop()` cannot work here: cocotb 2 runs tests on its own scheduler, not an asyncio loop, so there is no loop to fetch or run an executor on. Switching to `get_running_loop()` only changes the error message; it still fails.

I removed asyncio from [server_test.py](/sim/cocotb/server_test.py). The server now uses blocking `accept`/`recv`, which pauses simulation while idle (nothing advances between commands) and resumes when a client connects.

I also aligned [chimp_sim.py](/sim/cocotb/bridge/chimp_sim.py) with the server's expected API:

- `reset(cycles=1)` holds reset for a number of cycles.
- `step(n)` returns one snapshot per cycle.
- `run_until_halt()` returns the per-cycle snapshots.
- `last` exposes the most recent snapshot.
- `peek_word(address)` reads memory through `debug_address`/`debug_data`.
- Snapshots now also include cache counters.
- Commands that finish in cocotb's read-only phase advance one simulator step (`Timer(1, unit="step")`) so the next command can drive inputs.

The duplicate, unused `sim/bridge/chimp_sim.py` was removed; the canonical driver is now `sim/cocotb/bridge/chimp_sim.py`.

Verification:

```text
make sim                     TESTS=1 PASS=1
make MODULE=server_test      TESTS=1 PASS=1   # client exercised load/reset/step/run_until_halt/peek/quit
```

`make MODULE=server_test` still prints cocotb's deprecation notice for `MODULE`; `make COCOTB_TEST_MODULES=server_test` avoids it.
