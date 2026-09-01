---
name: markdown-without-hard-wrapping
description: Create or edit Markdown files without manual hard wrapping; use when a task writes or changes .md content.
metadata:
  short-description: Keep Markdown paragraphs unwrapped
---

# Markdown without hard wrapping

When creating or editing any `.md` file, write each paragraph, list item, block quote, and table cell as one continuous line. Do not insert manual line breaks to fit the text to an editor width.

Use line breaks only where Markdown requires them: between paragraphs, between list items, after headings, inside code blocks, and between table rows. Never allow inline text such as bold, italics, `code`, or links to span lines.

Do not reformat pre-existing Markdown that is unrelated to the current change. Apply this rule only to new content or lines the task actually edits, unless the user explicitly requests a full conversion.

## Example

Wrong (hard wrap, including a list item):

- Reviewed scope: `CONTEXT.md`, ADRs, specifications, RTL, testbenches, scripts,
  Compose, CLI, and target software

The core retains requests until `ready`, runs M/FP with `start/done`, and stops on an error
or invalid encoding.

Correct:

- Reviewed scope: `CONTEXT.md`, ADRs, specifications, RTL, testbenches, scripts, Compose, CLI, and target software

The core retains requests until `ready`, runs M/FP with `start/done`, and stops on an error or invalid encoding.
