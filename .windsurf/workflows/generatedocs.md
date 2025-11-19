---
description: Assemble project docs from existing markdown + code tree
auto_execution_mode: 1
---

steps:
  - Read repo tree; list *.md under /docs and /integration_test/**.
  - For each file, extract headings + key snippets (no new facts).
  - Merge into a single HOW-TO with numbered chapters & code blocks.
  - Create or update docs/Allure_Schemathesis_Integration_HOWTO.md
  - Summarize changes; list sources used.