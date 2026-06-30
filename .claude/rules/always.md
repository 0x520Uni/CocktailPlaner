# Core Rules

## Work Log

After every significant action (file created/edited, feature, fix, config changed):
append one row to `docs/log.md` using Bash — no file read required:

```bash
echo "| YYYY-MM-DD | TYPE | IMPORTANCE | Short summary |" >> docs/log.md
```

Types: `ADR` `FEATURE` `IMPL` `PLAN` `FIX` `REFACTOR` `DOCS`  
Importance: `HIGH` (architecture, feature) · `MEDIUM` (method, plan, UI element) · `LOW` (small change)  
Skip only: single-line edits, typo fixes, reformatting, pure chat with no tool use.

## Explain Before Implementing

Before implementing any new Elm pattern or architecture decision:
explain it to Henry in one sentence first. He must be able to defend every choice
at his oral exam (2026-07-16). Never introduce patterns silently.

## Code Style

Prefer readable code over clever code:
- English identifiers and comments
- Verbose logic over one-liners
- One short comment per function explaining the WHY (not the WHAT)
