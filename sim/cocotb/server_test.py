from multiprocessing.connection import Listener

import cocotb
from bridge.chimp_sim import ChimpSim


@cocotb.test()
async def sim_server(dut):
    sim = ChimpSim(dut)
    await sim.start_clock(10)
    await sim.reset()

    # Blocking accept keeps simulation time frozen while no client is connected.
    address = ('127.0.0.1', 5555)
    listener = Listener(address, authkey=b'chimps-v')
    dut._log.info(f"Server listening on {address}")

    while True:
        conn = listener.accept()
        try:
            msg = conn.recv()
            cmd = msg.get('cmd')

            # Would use match-case, but this has more compatibility
            if cmd == 'load_program':
                await sim.load_program(msg['words'], msg.get('base_addr', 0))
                conn.send({'ok': True, 'snapshot': sim.snapshot()})
            elif cmd == 'reset':
                await sim.reset(msg.get('cycles', 2))
                conn.send({'ok': True, 'snapshot': sim.snapshot()})
            elif cmd == 'step':
                snaps = await sim.step(msg.get('n', 1))
                conn.send({'ok': True, 'snaps': snaps, 'snapshot': sim.last})
            elif cmd == 'run_until_halt':
                snaps = await sim.run_until_halt(msg.get('max_cycles', 10000))
                conn.send({'ok': True, 'snaps': snaps, 'snapshot': sim.last})
            elif cmd == 'get_snapshot':
                conn.send({'ok': True, 'snapshot': sim.snapshot()})
            elif cmd == 'peek':
                val = await sim.peek_word(msg['addr'])
                conn.send({'ok': True, 'value': val})
            elif cmd == 'quit':
                conn.send({'ok': True})
                break
            else:
                conn.send({'ok': False, 'error': 'unknown_cmd'})
        except EOFError:
            pass
        except Exception as e:
            conn.send({'ok': False, 'error': str(e)})
        finally:
            conn.close()
    listener.close()
