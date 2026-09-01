# ADR 005 — Toolchain VHDL

- Estado: aceito
- Data: 2026-09-19

RTL e testbenches usam VHDL-2008 e GHDL no contêiner. `scripts/compile-rtl.sh` analisa, compila e executa todo `tb_*.vhd`; mudança RTL só é concluída com regressão verde. A versão de GHDL é fixada no Dockerfile.
