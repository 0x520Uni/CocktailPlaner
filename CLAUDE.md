# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**CocktailPlaner** — An Elm web app that helps calculate cocktail ingredient quantities for events, accounts for bottle/package sizes, and generates shopping lists. Semester project (MLU Halle), presentation 2026-07-16.

## Hard constraints

- All core features must be in pure Elm. JavaScript is only permitted for optional extras.
- No server, no database.
- Required technologies: HTML, SVG, CSS, Elm, URL navigation, HTTP requests.

## Toolchain

```sh
npm install -g elm elm-live elm-format   # one-time global install

elm-live src/Main.elm --open -- --output=public/main.js   # dev server + hot reload
elm make src/Main.elm --output=public/main.js --optimize  # production build
elm-format src/ --yes                                      # format all Elm files
elm repl                                                   # interactive REPL
```

**Gotcha:** PowerShell's npm shims mangle the `--` separator, so `elm-live` must be
run from the **Bash** tool, not PowerShell. `elm make` / `elm-format` work in either.

## Frontend / UI work

For any visual or UI task (layout, styling, the SVG glass, responsive behaviour),
**invoke the `frontend-design` skill first** — it is Henry's intended design tool.
Do not freelance the UI before consulting it. Then follow the UI conventions table in
CP-A-4 (YouTrack, Project Overview) — Bulma utilities, component classes in
`public/style.css`, colour matching via `View.CocktailSvg.ingredientColors`.

## Run & verify locally

The app is a pure client-side SPA. To verify changes:

1. Build: `elm make src/Main.elm --output=public/main.js`
2. Serve the `public/` directory as a static site on **port 8765**.
3. **SPA deep-link gotcha:** a plain static server has no SPA fallback, so opening
   `http://localhost:8765/glossar` directly returns **404**. Always load
   `http://localhost:8765/` first, then click the nav link to reach a route.
4. Verify visually with the **Playwright MCP** at three viewport widths —
   ~1680 (wide), ~1280 (laptop), ~480 (phone) — and **look at the screenshots**.
   This is the standard QA step before calling UI work done.

There is intentionally **no** automated test suite (no elm-test / E2E): verification is
manual via Playwright, matching the exam scope (no over-engineering).

## Knowledge base & ADRs

**YouTrack is the sole source of truth** for KB and ADRs — there are no local copies.
Read these at the start of any new session:

| YouTrack article | Content |
|---|---|
| CP-A-4 | Project Overview (constraints, toolchain, file layout) |
| CP-A-5 | Domain Glossary (Recipe, Ingredient, Unit, Event, ShoppingList) |
| CP-A-6 | TheCocktailDB API Reference (endpoints, response shapes) |
| CP-A-13 | ADR Summary (one-table overview, cross-cutting consequences) |
| CP-A-7 + children CP-A-8…CP-A-17 | Architecture Decision Records ADR-0001…0009 |

Instance: `https://0x520.youtrack.cloud`, project **CP**.

To read an article (REST fallback):
```
GET https://0x520.youtrack.cloud/api/articles/{idReadable}?fields=content,summary
Authorization: Bearer $YOUTRACK_TOKEN_0x520
```

**KB maintenance rule** — update the relevant YouTrack article directly in the same session when:
- New ADR accepted → update CP-A-13 (ADR Summary); create a new child article under CP-A-7
- New domain term introduced → update CP-A-5 (Domain Glossary)
- Toolchain changes → update CP-A-4 (Project Overview)
- New TheCocktailDB endpoint used → update CP-A-6 (API Reference)
- Log every KB change in `docs/log.md` with type `DOCS`.

To create/update a YouTrack article:
1. Confirm `YOUTRACK_TOKEN_0x520` is set.
2. **Preferred:** use the `youtrack` MCP server tools (configured in `~/.claude/mcp.json`).
3. **Fallback:** REST API — `POST https://0x520.youtrack.cloud/api/articles/{idReadable}` with
   `{"content": "..."}` to update, or `POST .../api/articles` with
   `{"summary","content","project":{"id":"0-3"},"parentArticle":{"id":"180-113"}}` to
   create a new ADR child under CP-A-7.

## Work Log

After any significant action, append **one row** to `docs/log.md` using Bash — no read required:

```bash
echo "| YYYY-MM-DD | TYPE | IMPORTANCE | Short summary |" >> docs/log.md
```

Types: `ADR` `FEATURE` `IMPL` `PLAN` `FIX` `REFACTOR` `DOCS`  
Importance: `HIGH` (architecture, feature) · `MEDIUM` (method, plan, UI element) · `LOW` (small change)  
Skip: single-line edits, typo fixes, reformatting.

## Collaboration note

Every pattern introduced must be understood by Henry — explain all design decisions before implementing them.
