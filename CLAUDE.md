# CLAUDE.md

This file provides context and toolchain info to Claude Code.
Behavioral rules live in `.claude/rules/`. On-demand workflows in `.claude/commands/`.

## Project

**CocktailPlaner** — Elm SPA that calculates cocktail ingredient quantities for events,
accounts for bottle/package sizes, and generates shopping lists.
Semester project (MLU Halle), presentation 2026-07-16.

GitHub: https://github.com/0x520Uni/CocktailPlaner  
Live:   https://0x520uni.github.io/CocktailPlaner/

## Hard Constraints

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

## Knowledge Base (YouTrack)

**YouTrack is the sole source of truth** for KB and ADRs — there are no local copies.

| YouTrack article | Content |
|---|---|
| CP-A-4 | Project Overview (constraints, toolchain, file layout) |
| CP-A-5 | Domain Glossary (Recipe, Ingredient, Unit, Event, ShoppingList) |
| CP-A-6 | TheCocktailDB API Reference (endpoints, response shapes) |
| CP-A-13 | ADR Summary (one-table overview, cross-cutting consequences) |
| CP-A-7 + children CP-A-8…CP-A-17 | Architecture Decision Records ADR-0001…0009 |

Instance: `https://0x520.youtrack.cloud`, project **CP**.

REST fallback to read an article:
```
GET https://0x520.youtrack.cloud/api/articles/{idReadable}?fields=content,summary
Authorization: Bearer $YOUTRACK_TOKEN_0x520
```
