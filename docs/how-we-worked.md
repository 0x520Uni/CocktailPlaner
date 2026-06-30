# Wie wurde gearbeitet

*Entwicklungsphasen vom ersten Commit bis zur Live-Demo — automatisch generiert beim Deploy.*

---

## Phase 1 — Grundlage legen (26. Juni)

Bevor eine Zeile Elm geschrieben wurde, standen die Entscheidungen fest.
Fünf Architecture Decision Records wurden formuliert und abgenommen:
Elm als Kernsprache, kein Server, `Browser.application` für URL-Navigation,
TheCocktailDB als Datenquelle, SVG für das Cocktailglas.
Jeder ADR wurde sofort in YouTrack dokumentiert — als verbindliche Referenz,
nicht als nachträgliche Notiz.

Parallel: Toolchain global installiert, Elm-Paket-Cache lokal aufgewärmt (offline-ready),
`CLAUDE.md` als Projektgedächtnis für den Agenten angelegt,
SessionStart/Stop-Hooks eingerichtet damit kein Arbeitsschritt undokumentiert endet.

Am Abend war ein lauffähiger 470-Zeilen-Prototyp da, der alle fünf ADRs
per Playwright-Automatisierung end-to-end bestätigt hatte.

---

## Phase 2 — Architektur klären (29. Juni, früh)

Mit dem Prototyp in der Hand musste eine Weichenstellung getroffen werden:
eine Datei weiterführen oder sauber aufteilen?
Die Wahl fiel auf Variante B — klare Modul-Grenzen mit je einem Verantwortungsbereich:
`Types.elm` für alle Typen, `Route.elm` für URL-Parsing, `Api.elm` für HTTP und Decoder,
`Codec.elm` für Save/Load, `View/*` mit je einer Datei pro Ansicht.

Vier weitere ADRs (0006–0009) wurden entschieden:
Bulma als CSS-Framework via CDN, drei Routen mit Topbar, Lade- und Cachestrategie,
wiederverwendeter Cocktail-Detail-View. Alle in YouTrack veröffentlicht.

---

## Phase 3 — Kernfeatures (29. Juni)

### Glossar und API

Die erste echte Feature-Schicht: ein Fullscreen-Modal mit drei Spalten.
Links Kategorien (`/list.php`), Mitte Cocktailliste (`/filter.php`),
rechts das Detail (`/lookup.php`). Jede Spalte ist ein HTTP-Request;
bereits geladene Daten werden im `Dict` gecacht.

Als visuelles Herzstück entstand `View/CocktailSvg.elm`:
ein SVG-Cocktailglas mit proportionalen Farbschichten für jede Zutat.
Die Mengenangaben aus der API sind bewusst uneinheitlich —
`parseMeasureToAmount` in `Api.elm` normalisiert alles auf ml,
erkennt Brüche (`1/2`), Bereiche (`6-8 oz`) und alle gängigen Einheiten.

Das Glossar-Layout wurde zweimal überarbeitet bis Foto und SVG
auf gemeinsamer Höhe und mit konsistenter Rahmung wirkten.

### Event-Verwaltung

Auf der Home-Seite: Events anlegen, benennen, Gästezahl setzen, Cocktails hinzufügen.
Der ursprüngliche Edit-Dialog wurde durch Inline-Editing auf der Karte ersetzt —
im Test war der Dialog einen Klick zu viel. `<a>`-Elemente mussten durch `<button>`
ersetzt werden, weil sie in `Browser.application` Navigation auslösen.

### Einkaufsliste

`View/Shopping.elm` aggregiert alle Zutaten über alle Events hinweg,
konvertiert Einheiten und zeigt pro Zutat ein Dropdown für die Packungsgröße.
Das Ergebnis: konkrete Flaschen- und Packungsanzahl mit Restmengenangabe.

---

## Phase 4 — QA und Bugfixing (30. Juni, früh)

30 manuelle Testfälle auf drei Viewport-Breiten (1680 px, 1280 px, 480 px).
13 Probleme gefunden — 2 kritisch, 3 hoch, 5 mittel, 3 niedrig.

Kritisch: das Burger-Menü auf Mobile öffnete nicht, der Einkaufslisten-Button
in der Topbar führte ins Leere. Weitere Korrekturen:
`guestCount × portions`-Berechnung, Duplikat-Validierung beim Kopieren eines Events,
Singular-/Plural-Logik für „1 Gast", Portionen-Increment.

---

## Phase 5 — Finalisierung und Veröffentlichung (30. Juni)

**Save/Load:** `Codec.elm` kodiert den gesamten Model-State als JSON-String.
Download via `<a download>`, Upload via `<input type="file">`.
Beim Laden erscheint ein Disclaimer (Konformität mit ADR-0002).

**Glossar-Suche:** Parallel zur Kategorie-Navigation kann nach Name gesucht werden
(`/search.php`) — beide Pfade führen in denselben Detail-View.

**Deployment:** GitHub-Repo angelegt, GitHub Pages aus dem `gh-pages`-Branch bedient
(Subtree-Split: nur `public/` geht raus).

**Harness-Restrukturierung:** Das Claude-Agent-Setup wurde in drei Schichten aufgeteilt —
`CLAUDE.md` (Kontext), `.claude/rules/` (Verhaltensregeln), `.claude/commands/` (Skills).
Dazu: `/verify`-, `/kb-sync`- und `/deploy`-Skills, Harness-Dokumentation, schlanke README.

**Diagramme:** Fünf Mermaid-Diagramme in `diagrams/` dokumentieren Modulstruktur,
Routing, Elm-Architektur, API-Aufrufsequenz und Einkaufslisten-Berechnung.
Sie werden bei jedem Deploy als PNG gerendert.

---

## Zeitraum

| Datum | Schwerpunkt |
|---|---|
| 26. Juni | ADRs, Toolchain, Prototyp, Agent-Harness-Grundlage |
| 29. Juni | Alle Kernfeatures, UI-Iterationen, Modul-Struktur |
| 30. Juni | QA, Bugfixing, Save/Load, Deployment, Dokumentation, Diagramme |

Drei aktive Arbeitstage — von der leeren Datei bis zur öffentlichen Live-Demo.
