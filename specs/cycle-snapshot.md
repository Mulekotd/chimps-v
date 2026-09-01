# Observabilidade da simulação

Não há formato JSON, CLI ou GUI neste marco. A observação ocorre pelos sinais do topo e pelo waveform do simulador: `current_pc`, `current_instruction`, `pipeline_valid`, `retired`, `halted`, `illegal_instruction`, `cache_accesses`, `cache_hits`, `cache_misses` e `debug_data`.

Quando a implementação da GUI começar, a interface de observação adotada deverá receber especificação e testes próprios. Um formato de snapshot não faz parte deste marco.
