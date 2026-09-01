# ADR 006 — Snapshot como contrato de observabilidade

- Estado: aceito
- Data: 2026-09-19

GUI e TUI consomem snapshots versionados gerados pelo simulador; não leem sinais privados nem reimplementam decode. JSON é o primeiro formato e CSV é derivado. Aceite: replay do JSON reproduz o estado observável; contraprova: payload inválido é rejeitado por versão/campos obrigatórios.
