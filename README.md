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

Dieses Projekt wird mit **Claude Code** als KI-Pair-Programmer entwickelt. Die Konfiguration im `.claude/`-Ordner steuert das Verhalten des Agenten.

### `.claude/settings.json` — Berechtigungen & Hooks

```jsonc
{
  "permissions": { ... },   // Welche Tools ohne Rückfrage erlaubt sind
  "hooks": { ... },         // Automatische Aktionen bei Session-Events
  "enabledPlugins": { ... } // Aktivierte Claude-Plugins
}
```

**Hooks im Detail:**

| Hook | Aktion |
|---|---|
| `SessionStart` | Zählt aktuelle Zeilen in `docs/log.md` und speichert den Wert als Baseline |
| `Stop` | Vergleicht Zeilenzahl mit Baseline — bricht ab wenn kein Log-Eintrag geschrieben wurde |

Der Stop-Hook erzwingt, dass nach jeder bedeutsamen Arbeit ein Eintrag in `docs/log.md` existiert. Nur reine Chat-Antworten ohne Tool-Nutzung sind ausgenommen.

### `.claude/commands/deploy.md` — `/deploy` Skill

Aufrufbar mit `/deploy` in Claude Code. Führt folgende Schritte aus:

1. `elm make --optimize` — Produktions-Build
2. `git add / commit / push` auf `master`
3. `git subtree split` — updated den `gh-pages` Branch (nur `public/`)
4. Work-Log-Eintrag in `docs/log.md`
5. Gibt Live-Demo-URL aus

**Verwendung:**
```
/deploy
Vorher: Playwright-Test auf 3 Viewports, elm-format, report.md aktualisiert
```

Der Text nach `/deploy` landet als `$ARGUMENTS` im Skill und dokumentiert was vor dem Deploy erledigt wurde.

### `CLAUDE.md` — Projekt-Instruktionen für den Agenten

Die `CLAUDE.md` im Root wird von Claude Code bei jedem Session-Start geladen. Sie enthält:

- Hard Constraints (nur pure Elm, kein Server)
- Toolchain-Befehle
- UI-Regeln (wann der `frontend-design`-Skill aufgerufen werden muss)
- Verifikations-Ablauf (Playwright, 3 Viewports)
- Wissensbase-Pflicht (YouTrack als Quelle)
- Work-Log-Pflicht

### `.mcp.json` — MCP-Server

Konfiguriert den Playwright-MCP-Server für Browser-Automatisierung (UI-Tests, Screenshots). Enthält keine Tokens oder Secrets.

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
