# Log 0012 — Ponte Python para o teste cocotb

- Data: 2026-10-31
- Tipo: prompt/output

## Prompt

i am getting this error when running make:

```
rm -f results.xml
    \
    /usr/bin/ghdl -i --std=08   --workdir=sim_build --work=work /home/pirat/chimps-v/rtl/chimps_pkg.vhd /home/pirat/chimps-v/rtl/memory_backing_store.vhd /home/pirat/chimps-v/rtl/memory_bus.vhd /home/pirat/chimps-v/rtl/cache_l1.vhd /home/pirat/chimps-v/rtl/pipeline.vhd /home/pirat/chimps-v/rtl/chimps_v_system.vhd && \
    /usr/bin/ghdl -m --std=08   --workdir=sim_build -Psim_build --work=work chimps_v_system
rm -f results.xml
COCOTB_TEST_MODULES=test_chimps_v_system COCOTB_TESTCASE=  COCOTB_TOPLEVEL=chimps_v_system TOPLEVEL_LANG=vhdl       \
    /usr/bin/ghdl -r --std=08  --time-resolution=ps --workdir=sim_build -Psim_build --work=work chimps_v_system  --vpi=/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb/libs/libcocotbvpi_ghdl.so
loading VPI module '/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb/libs/libcocotbvpi_ghdl.so'
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:242  in gpi_load_users                  Loaded entry library: '/usr/lib/x86_64-linux-gnu/libpython3.14.so.1.0'
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:233  in gpi_load_users                  Running entry func 'initialize' from loaded library '/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb/simulator.cpython-314-x86_64-linux-gnu.so'
     -.--ns INFO     pygpi                              ..ib/pygpi/embed.cpp:114  in initialize                      Using Python 3.14.0 interpreter at /home/pirat/chimps-v/sim/.venv/bin/python3
     -.--ns INFO     gpi                                ../gpi/GpiCommon.cpp:74   in gpi_print_registered_impl       GPI: VPI support registered
VPI module loaded!
     0.00ns INFO     cocotb.initialize                  Seeding Python random module with 1793462710
     0.00ns WARNING  gpi                                vpi_iterate returned NULL for type vpiInstance for object NULL
     0.00ns INFO     cocotb.initialize                  Initialized cocotb v2.1.0 from /home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb
     0.00ns INFO     cocotb.initialize                  Running on GHDL version 5.0.1 (Ubuntu 5.0.1+dfsg-1ubuntu1) [Dunoon edition]
Traceback (most recent call last):
  File "/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/pygpi/entry.py", line 42, in load_entry
    entry_func()
  File "/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb/regression.py", line 1190, in _run_regression
    _setup_regression_manager()
  File "/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb/regression.py", line 1156, in _setup_regression_manager
    _manager_inst.discover_tests(*modules)
  File "/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb/regression.py", line 255, in discover_tests
    mod = import_module(module_name)
  File "/usr/lib/python3.14/importlib/__init__.py", line 88, in import_module
    return _bootstrap._gcd_import(name[level:], package, level)
  File "<frozen importlib._bootstrap>", line 1406, in _gcd_import
  File "<frozen importlib._bootstrap>", line 1371, in _find_and_load
  File "<frozen importlib._bootstrap>", line 1342, in _find_and_load_unlocked
  File "<frozen importlib._bootstrap>", line 938, in _load_unlocked
  File "/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/_pytest/assertion/rewrite.py", line 185, in exec_module
    exec(co, module.__dict__)
  File "/home/pirat/chimps-v/sim/cocotb/test_chimps_v_system.py", line 66, in <module>
    from bridge.chimp_sim import ChimpSim
ModuleNotFoundError: No module named 'bridge'
make: *** [/home/pirat/chimps-v/sim/.venv/lib/python3.14/site-packages/cocotb_tools/makefiles/simulators/Makefile.ghdl:81: results.xml] Error 1
```

## Output

The error was a missing `bridge` package: [test_chimps_v_system.py](/sim/cocotb/test_chimps_v_system.py) imports `bridge.chimp_sim`, but that module did not exist.

Added [bridge/chimp_sim.py](/sim/cocotb/bridge/chimp_sim.py) with the `ChimpSim` driver used by the test: clock startup, reset, `load_word`/`load_program`, cycle snapshots, and `run_until_halt`. Added [bridge/__init__.py](/sim/cocotb/bridge/__init__.py) to expose it.

`make sim` now passes: `TESTS=1 PASS=1`, halting after 725 ns with `illegal=0`. Generated build artifacts were removed from the repository.
