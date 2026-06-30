# CocktailPlaner

Elm SPA für die Planung von Cocktail-Events — berechnet Zutatenmengen, Flaschenanzahl und erstellt eine Einkaufsliste.

**Live-Demo:** https://0x520uni.github.io/CocktailPlaner/  
**Semester-Projekt:** MLU Halle, Präsentation 16.07.2026

---

## Schnellstart

```sh
# Dev-Server (Hot-Reload) — muss im Bash-Terminal laufen, nicht PowerShell
elm-live src/Main.elm --open -- --output=public/main.js

# Produktions-Build
elm make src/Main.elm --output=public/main.js --optimize

# Code formatieren
elm-format src/ --yes
```

Lokaler Server: `http://localhost:8765/` — immer zuerst `/` laden, dann über Navbar navigieren (SPA, kein Fallback-Routing).

---

## Projektstruktur

```
src/
├── Main.elm              # Browser.application — nur Wiring (init/update/view)
├── Types.elm             # Alle Typen: Model, Msg, Route, Event, Ingredient …
├── Route.elm             # URL-Parser: fromUrl / toPath
├── Api.elm               # HTTP-Funktionen + JSON-Decoder + Mengenberechnung
├── Codec.elm             # JSON-Encode/Decode für Save/Load
└── View/
    ├── Topbar.elm        # Navigationsleiste (responsiv, Burger-Menü)
    ├── Home.elm          # Event-Verwaltung + Cocktail-Suche
    ├── Shopping.elm      # Einkaufsliste mit Packungsgrößen-Dropdown
    ├── Glossar.elm       # 3-Spalten-Modal: Kategorien / Liste / Detail
    └── CocktailSvg.elm   # SVG-Cocktailglas (proportionale Zutaten-Schichten)

public/
├── index.html            # SPA-Shell: lädt main.js + Bulma + Font Awesome
├── main.js               # Elm-Kompilat (nicht manuell bearbeiten)
└── style.css             # App-spezifische Styles (Bulma-Erweiterungen)

docs/
├── log.md                # Work Log (jede Session pflegen)
└── report.md             # Projektbericht für die Präsentation
```

---

## Agent Harness (Claude Code)

Dieses Projekt wird mit **Claude Code** als KI-Pair-Programmer entwickelt.
Die vollständige Harness-Dokumentation liegt in [`.claude/README.md`](.claude/README.md).

**Kurzübersicht — 3-Schichten-Modell:**

| Schicht | Dateien | Wann aktiv |
|---|---|---|
| Context | `CLAUDE.md` | Jede Session — Projektfakten, Toolchain |
| Rules | `.claude/rules/*.md` | Jede Session — Verhaltensregeln, Pflichten |
| Commands | `.claude/commands/*.md` | On-demand — nur bei `/befehl`-Aufruf |

**Skills:**

| Befehl | Zweck |
|---|---|
| `/deploy` | Build → Git → GitHub Pages → Log |
| `/verify` | Playwright QA: 6 Screenshots auf 3 Viewports |
| `/kb-sync <was>` | YouTrack-Artikel aktualisieren |

---

## Deployment

GitHub Pages wird aus dem `gh-pages` Branch bedient. Dieser enthält ausschließlich den Inhalt von `public/`. Update via `/deploy` Skill oder manuell:

```sh
git subtree split --prefix public -b gh-pages-tmp
git push origin gh-pages-tmp:gh-pages --force
git branch -D gh-pages-tmp
```

---

## Technologien

| Technologie | Version | Zweck |
|---|---|---|
| Elm | 0.19.1 | App-Logik (kein JavaScript) |
| Bulma | 0.9.4 | CSS-Framework |
| Font Awesome | 6.5.0 | Icons |
| TheCocktailDB | v1 | Cocktail-API (HTTP) |
| elm/http | 2.0.0 | HTTP-Client |
| elm/svg | 1.0.1 | SVG-Cocktailglas |
| elm/url | 1.0.0 | URL-Routing |
