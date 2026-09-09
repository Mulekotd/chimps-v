---
name: prompt-logging
description: Preserve user-visible prompts and assistant outputs for every CHIMPS-V project conversation in numbered Markdown logs under docs/prompts.
metadata:
  short-description: Log CHIMPS-V AI conversations
---

# CHIMPS-V conversation logging

Use this skill for every task performed by an AI agent inside the CHIMPS-V
repository. The conversation archive is part of the project documentation and
must be maintained continuously.

## Required behavior

1. Before doing substantive work, inspect `docs/prompts/` and determine the next
   prefix by adding one to the highest existing numeric prefix. Do not reuse a
   gap left by deleted historical logs, and never overwrite or renumber existing
   logs.
2. Create one Markdown log for the current user turn, using a name such as
   `0002-logs-short-description.md`. Use four digits, lowercase kebab-case, and
   the sections `# Log ...`, `## Prompt`, and `## Output`.
3. Store the user's visible prompt verbatim, including code blocks and explicit
   constraints. Do not store hidden system/developer instructions, private
   chain-of-thought, or tool-internal output that was not shown to the user.
4. Before sending the final response, complete the `## Output` section with the
   exact user-visible answer being returned. If the task changes files, mention
   the resulting paths using repository-relative links such as
   `[CONTEXT.md](/CONTEXT.md)`, never machine-specific absolute paths.
5. If the task has multiple meaningful user turns, create one log per turn.
   A user correction, clarification, or follow-up is a new prompt and must be
   logged even when it says not to log itself; this skill's project rule takes
   precedence for repository work.
6. When a turn is interrupted before an output is produced, keep the prompt log
   with an `Output` note stating that the turn was interrupted. If work resumes,
   update that same log rather than creating a duplicate for the same turn.

## Format

```markdown
# Log 0002 — Short description

- Data: YYYY-MM-DD
- Tipo: prompt/output

## Prompt

<user-visible prompt>

## Output

<final user-visible response>
```

Keep logs UTF-8 Markdown. Do not include absolute local filesystem paths in
their prose or links. Use repository-root-relative links (`/docs/...`) when a
file must be referenced. Keep the archive focused on the prompt/output pair;
do not add a transcript of internal reasoning.

## Completion check

Before concluding a turn, verify that the new file exists, its prompt and output
are non-empty, its numeric prefix is unique, and `git status` shows it as part
of the project changes. A missing conversation log means the task is not
complete.
