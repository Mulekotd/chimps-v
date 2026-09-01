# CycleSnapshot v1

O objeto possui `version`, `cycle`, `pc`, `instruction`, `retired`, `trap`, `gpr`, `fpr`, `stages`, `memory`, `caches`, `mmio` e `metrics`. O estado é capturado após a borda de clock. `metrics` inclui ciclos, aposentadas, stalls, flushes, acessos, hits, misses e write-backs. Arrays de registradores usam índices arquiteturais e inteiros/words sem sinal em JSON.

Campos obrigatórios ausentes ou versão desconhecida invalidam o snapshot; isso evita que GUI/TUI infiram sinais não publicados.
