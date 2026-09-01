---
name: legacy-pruning
description: Audit and remove superseded CHIMPS-V implementation code whenever a new RTL, simulator, CLI, or interface implementation replaces an older path. Do not use for additive changes that leave all existing behavior current.
metadata:
  short-description: Remove superseded implementation paths
---

# Prune superseded implementation paths

Apply this skill whenever an implementation adds a replacement for an existing
CHIMPS-V circuit, memory/cache path, service, CLI interface, file format, or UI
component. The completed change must leave one canonical production path for each
responsibility.

## Audit before removal

Identify whether the new code replaces, rather than extends, an existing behavior.
Trace production callers from the relevant build manifest and entrypoint using
`rg`; include tests, scripts, documentation, and generated-interface consumers.

Do not remove a component merely because the current top-level does not instantiate
it when it is explicitly retained as a tested foundation for a declared future
architecture milestone. Record that boundary in the applicable spec or ADR.

## Consolidation

When a replacement is complete, remove its obsolete source, dedicated tests,
wrappers, build-manifest entries, fixtures, and documentation claims in the same
change. Update callers to use the canonical implementation. Do not keep an adapter
or duplicate implementation solely for compatibility unless the user explicitly
requires a supported migration period.

Keep one of each of the following unless the architecture deliberately requires
more: production owner of architectural state, canonical request/response interface,
and implementation of a cache, bus, loader, or execution path.

## Completion evidence

Before finishing, verify that:

- `rg` finds no active references to removed identifiers outside historical prompt
  logs or intentional migration notes;
- the build manifest lists only supported production sources;
- tests cover the canonical path and removed tests are not the sole evidence for a
  retained contract; and
- the relevant regression passes.

If the audit finds no replacement or no obsolete code, make no speculative deletion
and report that conclusion.
