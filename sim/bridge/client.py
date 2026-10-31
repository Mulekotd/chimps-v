from multiprocessing.connection import Client

class ChimpClient:
    def __init__(self, host='127.0.0.1', port=5555, authkey=b'chimps-v'):
        self.host = host
        self.port = port
        self.authkey = authkey
        
    def _send(self, msg):
        conn = Client((self.host, self.port), authkey=self.authkey)
        conn.send(msg)
        res = conn.recv()
        conn.close()
        return res
    
    def load_program(self, words, base_addr=0):
        return self._send({'cmd': 'load_program', 'words': words, 'base_addr': base_addr})
    
    def reset(self, cycles=2):
        return self._send({'cmd': 'reset', 'cycles': cycles})
    
    def step(self, n=1):
        return self._send({'cmd': 'step', 'n':n})
    
    def run_until_halt(self, max_cycles=10_000):
        return self._send({'cmd': 'run_until_halt', 'max_cycles': max_cycles})
    
    def get_snapshot(self):
        return self._send({'cmd': 'get_snapshot'})
    
    def peek(self, addr):
        return self._send({'cmd': 'peek', 'addr':addr})
    
    def quit(self):
        try:
            return self._send({'cmd': 'quit'})
        except Exception:
            return {'ok': True}