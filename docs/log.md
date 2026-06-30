# Work Log

Append new entries at the **bottom** using Bash — no file read required:
```bash
echo "| YYYY-MM-DD | TYPE | IMPORTANCE | Short summary |" >> docs/log.md
```
Types: `ADR` `FEATURE` `IMPL` `PLAN` `FIX` `REFACTOR` `DOCS`  
Importance: `HIGH` (architecture/feature) · `MEDIUM` (method/plan/UI element) · `LOW` (small change)  
Skip: single-line edits, typo fixes, reformatting.

---

| Date       | Type | Importance | Summary                                                   |
|------------|------|------------|-----------------------------------------------------------|
| 2026-06-26 | ADR  | HIGH       | ADR-0001: Elm as primary language — Accepted              |
| 2026-06-26 | ADR  | HIGH       | ADR-0002: No server, JSON string for persistence — Accepted |
| 2026-06-26 | ADR  | HIGH       | ADR-0003: Browser.application for URL navigation — Accepted |
| 2026-06-26 | ADR  | HIGH       | ADR-0004: TheCocktailDB as HTTP data source — Accepted    |
| 2026-06-26 | ADR  | HIGH       | ADR-0005: SVG for cocktail glass visualization — Accepted |
| 2026-06-26 | DOCS | MEDIUM     | Created work log system (docs/log.md) and updated CLAUDE.md |
| 2026-06-26 | PLAN | HIGH   | Project initialized: goals, constraints, academic context defined (/init) |
| 2026-06-26 | IMPL | MEDIUM | Playwright MCP configured in .mcp.json (npx @playwright/mcp@latest) |
| 2026-06-26 | DOCS | HIGH   | CLAUDE.md created: project guide, build commands, collaboration rules |
| 2026-06-26 | DOCS | MEDIUM | Knowledge base: cocktaildb-api.md + domain-glossary.md |
| 2026-06-26 | IMPL | HIGH   | Elm toolchain installed globally: elm 0.19.1, elm-format 0.8.8, elm-live |
| 2026-06-26 | IMPL | HIGH   | ELM_HOME cache warmed: 11 packages pre-downloaded (offline-ready) |
| 2026-06-26 | IMPL | HIGH   | Prototype built: 470-line Browser.application covering all 5 ADRs |
| 2026-06-26 | IMPL | HIGH   | All 5 ADRs validated via Playwright end-to-end browser automation |
| 2026-06-26 | FIX  | LOW    | PowerShell/npm shim bug documented: use Bash for elm-live |
| 2026-06-26 | IMPL | MEDIUM | Added YouTrack MCP server config to ~/.claude/mcp.json (HTTP, Bearer token from env var) |
| 2026-06-26 | IMPL | HIGH | Added SessionStart+Stop hooks to enforce mandatory docs/log.md entry; created .claude/settings.json |
| 2026-06-26 | DOCS | HIGH | KB consolidated: project-overview.md + adr-summary.md added; CLAUDE.md updated with KB table + YouTrack section |
| 2026-06-26 | DOCS | MEDIUM | YouTrack CP project created + 10 articles uploaded (KB + 5 ADRs) |
| 2026-06-29 | ADR  | MEDIUM     | ADR-0006: Bulma 0.9.4 + Animate.css 4.1.1 via CDN — Accepted |
| 2026-06-29 | ADR  | HIGH       | ADR-0007: SPA Routing — 3 Routes + Topbar — Accepted         |
| 2026-06-29 | ADR  | HIGH       | ADR-0008: Data loading + cache (Dict, skeleton, parallel)    |
| 2026-06-29 | ADR  | MEDIUM     | ADR-0009: Shared cocktail detail view (view recycling)       |
| 2026-06-29 | DOCS | HIGH       | KB vollständig aktualisiert: alle 9 ADRs, Glossar, API-Ref, project-overview |
| 2026-06-29 | PLAN | HIGH | Decided multi-module file structure (Option B): Main, Types, Route, Api, Codec, View/* — each file under ~150 lines; code style conventions set (English, verbose, commented) |
| 2026-06-29 | IMPL | HIGH | Created elm.json, public/index.html, src/Main.elm — hello world compiles and runs |
| 2026-06-29 | REFACTOR | MEDIUM | Split Main.elm — Model+Msg+types moved to Types.elm; Main.elm is now wiring only |
| 2026-06-29 | IMPL | HIGH | Full module structure in place: Route.elm, View/Topbar|Home|Shopping|Glossar.elm — routing live, placeholders ready |
| 2026-06-29 | IMPL | MEDIUM | Glossar als fullscreen Modal umgesetzt — overlay auf Home, schließen via NavigateTo HomeRoute |
| 2026-06-29 | IMPL | HIGH | Add elm/http + Api.elm: fetch category list from TheCocktailDB, wire into Glossar modal |
| 2026-06-29 | DOCS | LOW | Allowed all playwright MCP tools without prompts in .claude/settings.json |
| 2026-06-29 | FIX | MEDIUM | Fix init not firing category fetch on direct /glossar load; prevent double-fetch on NavigateTo |
| 2026-06-29 | IMPL | HIGH | Glossar 3-Spalten-Layout: Kategorie-Klick lädt Cocktailliste via filter.php |
| 2026-06-29 | FEATURE | HIGH | Glossar Spalte 3: Cocktail-Detail via lookup.php (Thumbnail, Zutaten, Rezept) |
| 2026-06-29 | FEATURE | HIGH | SVG Messbecher in Glossar Spalte 3: Zutaten als proportionale Farbschichten (elm/svg) |
| 2026-06-29 | IMPL | HIGH | UI-Redesign Glossar: Foto mit box-shadow, Zutaten als farbige Pill-Tags passend zu SVG-Schichten, Rezept in message-Box, responsive Breakpoints (900px/500px) via style.css |
| 2026-06-29 | DOCS | LOW | KB: UI-Konventionen und style.css in project-overview.md ergänzt |
| 2026-06-29 | FIX | LOW | SVG-Messbecher visuell vergroessert (max-width 160->260px), damit er neben dem Foto gleichwertig wirkt |
| 2026-06-29 | FIX | MEDIUM | SVG-Messbecher: Bereichsangaben wie '6-8 oz' in parseToken erkannt (untere Grenze), sonst falsche Verhaeltnisse |
| 2026-06-29 | FIX | LOW | Glossar-Detail: Foto und SVG auf gemeinsame feste Hoehe (340px) gesetzt, Ober-/Unterkante buendig |
| 2026-06-29 | IMPL | MEDIUM | Glossar-Detail neu strukturiert: Foto+SVG als gerahmte Media-Cards (style.css-Klassen), object-fit contain statt cover (kein Crop mehr), Detail-Breite auf 820px gedeckelt; KB aktualisiert |
| 2026-06-29 | DOCS | MEDIUM | Session-Erkenntnisse uebernommen: frontend-design-Skill projekt-scoped + Playwright-Perms (settings.json), CLAUDE.md Run/Verify+UI+Toolchain-Gotcha, KB Verifikation+Measure-Parsing, 3 Memory-Eintraege |
| 2026-06-29 | DOCS | HIGH | YouTrack-Sync: ADR-0006..0009 als CP-A-14..17 angelegt, KB (CP-A-4/5/6/13) + ADR-0001..0005 aktualisiert; CLAUDE.md + Memory: YouTrack-Mirror-Pflicht; Repo aufgeraeumt (14 Screenshots + .playwright-mcp/ geloescht) |
| 2026-06-29 | FEATURE | HIGH | Event-Verwaltung implementiert: Cards + Split-Panel + Create/Edit-Dialog + Cocktail-Suche via search.php |
| 2026-06-29 | REFACTOR | HIGH | Event-UI redesign: Karte klickbar, Inline-Edit statt Edit-Dialog, Leer-Zustand visuell, fadeIn-Animation |
| 2026-06-29 | FIX | HIGH | Duplizieren-Bug: a-Element durch button ersetzt (Browser.application Nav.load-Problem); Text-Overflow mit Ellipsis und min-width:0 gefixt |
| 2026-06-29 | FEATURE | HIGH | Shopping-View implementiert: IngredientAmount-Typ, oz/cl/tsp→ml-Konvertierung in Api.elm, Aggregation per Event, Packungsgrößen-Dropdown, Playwright verifiziert |
| 2026-06-30 | REFACTOR | MEDIUM | Remove local docs/adr + docs/knowledge; YouTrack is now sole source of truth |
| 2026-06-30 | DOCS | HIGH | Exploratory UI test: 30 test cases across 3 viewports, 13 bugs found (2 critical, 3 high, 5 medium, 3 low), TEST_REPORT.md created |
| 2026-06-30 | FIX | HIGH | 9 bugs fixed: mobile nav (burger), Einkaufsliste button, guestCount×portions, auto-select on delete, duplicate name validation, copy naming, 1-Gast singular, portions increment, empty name validation |
| 2026-06-30 | FEATURE | HIGH | Save/Load implementiert (Codec.elm + JSON-Dialoge), Font Awesome Icons, Glossar als Button in Topbar |
| 2026-06-30 | IMPL | HIGH | ADR-002 Load-Disclaimer + Glossar Name-Suche (search.php) + ADR-008 aktualisiert + ADR-009 withdrawn |
| 2026-06-30 | DOCS | MEDIUM | Projektbericht docs/report.md erstellt (Präsentation 16.7.) |
| 2026-06-30 | IMPL | HIGH | GitHub Repo + GitHub Pages deployed: https://github.com/0x520Uni/CocktailPlaner |
