# CocktailPlaner

Elm SPA zur Cocktail-Eventplanung — Zutatenmengen, Flaschenanzahl, Einkaufsliste.

**Live:** https://0x520uni.github.io/CocktailPlaner/ &nbsp;·&nbsp;
**Code:** https://github.com/0x520Uni/CocktailPlaner &nbsp;·&nbsp;
**Präsentation:** 16.07.2026, MLU Halle

---

## Starten

```sh
# Dev-Server (Hot-Reload) — im Bash-Terminal, nicht PowerShell
elm-live src/Main.elm --open -- --output=public/main.js

# Produktions-Build
elm make src/Main.elm --output=public/main.js --optimize
```

Lokaler Server: `http://localhost:8765/` — immer `/` laden, dann per Navbar navigieren (SPA).

---

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [docs/report.md](docs/report.md) | Projektbericht (Anforderungen, Architektur, Features) |
| [docs/how-we-worked.md](docs/how-we-worked.md) | Entwicklungsphasen im Überblick |
| [docs/log.md](docs/log.md) | Work Log (jeder Arbeitsschritt) |
| [docs/knowledge/](docs/knowledge/) | Wissensbasis-Spiegel (YouTrack → lokal) |
| [diagrams/](diagrams/) | Mermaid-Quellen + gerenderte PNGs |
| [.claude/README.md](.claude/README.md) | Agent-Harness-Dokumentation |

---

## Technologien

Elm 0.19.1 · Bulma 0.9.4 · Font Awesome 6.5.0 · TheCocktailDB API · elm/http · elm/svg · elm/url
