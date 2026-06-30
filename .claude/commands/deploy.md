# deploy

Baut die Elm-App, pushed Quellcode auf GitHub und aktualisiert die GitHub-Pages-Live-Demo.
Vor dem Deploy: Arbeitsbericht aktualisieren, Wissensbasis prüfen, polishen und lokal spiegeln.

## Voraussetzungen (vom Nutzer vorher erledigt)

$ARGUMENTS

---

## Phase 0 — wie-ich-gearbeitet-habe.md aktualisieren

`docs/wie-ich-gearbeitet-habe.md` ist ein narrativer Überblick über die Projektphasen.
Er wird bei jedem Deploy aus dem aktuellen `docs/log.md` neu generiert.

### Vorgehen

1. `docs/log.md` vollständig lesen.
2. Einträge nach zeitlichen Schwerpunkten und inhaltlichen Clustern gruppieren
   (z.B. "Architektur-Entscheidungen", "API-Anbindung", "QA", "Deployment").
3. `docs/wie-ich-gearbeitet-habe.md` neu schreiben — keine Commit-Liste, sondern Prosa:
   - Was war die Absicht dieser Phase?
   - Welche Weichenstellungen gab es?
   - Was wurde unterwegs geändert und warum?
4. Ton: sachlich, knapp, keine explizite "Zusammenarbeit"-Sprache — Entscheidungsmomente
   fließen als natürliche Wendepunkte in den Text ein.

---

## Phase 1 — KB Review & Mirror

### 1a. Alle KB-Artikel von YouTrack holen

Bevorzuge den YouTrack MCP-Server. REST-Fallback:

```
GET https://0x520.youtrack.cloud/api/articles/{idReadable}?fields=id,idReadable,summary,content
Authorization: Bearer $YOUTRACK_TOKEN_0x520
```

Zu holende Artikel:

| idReadable | Inhalt |
|---|---|
| CP-A-4 | Project Overview (Constraints, Toolchain, Dateistruktur) |
| CP-A-5 | Domain Glossary (Recipe, Ingredient, Unit, Event, ShoppingList …) |
| CP-A-6 | TheCocktailDB API Reference (Endpoints, Response-Shapes) |
| CP-A-13 | ADR Summary (Übersichtstabelle aller ADRs) |
| CP-A-8 … CP-A-17 | ADR-0001 … ADR-0009 (einzelne Entscheidungsartikel) |

### 1b. Inhaltlich gegen Code prüfen

Für jeden Artikel: Code lesen (`src/`) und prüfen ob der Artikel noch stimmt.

Checkliste pro Artikel:

**CP-A-4 (Project Overview)**
- Dateistruktur aktuell? (alle Dateien in `src/` und `public/` gelistet?)
- Toolchain-Befehle identisch mit `CLAUDE.md`?
- GitHub-URL und Live-URL korrekt?

**CP-A-5 (Domain Glossary)**
- Alle Typen aus `src/Types.elm` definiert? (`Model`, `Msg`, `Route`, `Event`, `Ingredient`, `ShoppingItem` …)
- Neue Typen seit letztem Sync ergänzen.

**CP-A-6 (API Reference)**
- Alle HTTP-Calls aus `src/Api.elm` dokumentiert?
  - `fetchCategories`, `fetchByCategory`, `fetchCocktailDetail`, `searchCocktails`
- Response-Shapes (JSON-Felder) vollständig?

**CP-A-13 (ADR Summary)**
- Tabelle vollständig? Alle ADRs (ADR-0001…0009) vorhanden?
- Status jedes ADRs korrekt (Accepted / Proposed / Deprecated)?

**CP-A-8 … CP-A-17 (ADRs)**
- Kontext, Entscheidung, Konsequenzen — inhaltlich noch korrekt?
- Wenn eine Entscheidung revidiert wurde: Status und Inhalt anpassen.

### 1c. Fehlende oder veraltete Inhalte ergänzen

Für jeden Artikel bei dem Lücken oder Fehler gefunden wurden:

```
POST https://0x520.youtrack.cloud/api/articles/{idReadable}
Authorization: Bearer $YOUTRACK_TOKEN_0x520
Content-Type: application/json

{"content": "<vollständiger aktualisierter Inhalt>"}
```

Nur aktualisieren wenn sich wirklich etwas geändert hat — nicht bei identischem Inhalt.

### 1d. Lokal nach `docs/knowledge/` spiegeln

Jeden Artikel als Markdown-Datei speichern:

```
docs/knowledge/
├── CP-A-4.md      ← Project Overview
├── CP-A-5.md      ← Domain Glossary
├── CP-A-6.md      ← API Reference
├── CP-A-13.md     ← ADR Summary
├── CP-A-8.md      ← ADR-0001
├── CP-A-9.md      ← ADR-0002
├── CP-A-10.md     ← ADR-0003
├── CP-A-11.md     ← ADR-0004
├── CP-A-12.md     ← ADR-0005
└── ...
```

Dateiformat (Frontmatter + Inhalt von YouTrack):

```markdown
---
youtrack: CP-A-X
title: <summary aus YouTrack>
synced: YYYY-MM-DD
---

<content aus YouTrack>
```

---

## Phase 2 — Diagramme rendern + Docs als PDF exportieren

### 2a. Mermaid-Diagramme → PNG

Für jede `.mmd`-Datei in `diagrams/` ein PNG daneben erzeugen:

```bash
for f in diagrams/*.mmd; do
  npx -y @mermaid-js/mermaid-cli mmdc \
    -i "$f" \
    -o "${f%.mmd}.png" \
    -b white \
    -w 1600
done
```

Ergebnis: `diagrams/module-deps.png`, `diagrams/routing.png`, `diagrams/elm-architecture.png`,
`diagrams/api-flow.png`, `diagrams/shopping-calc.png`

### 2b. Docs → PDF

Markdown-Docs als PDF daneben ablegen:

```bash
npx -y md-to-pdf docs/report.md
npx -y md-to-pdf docs/wie-ich-gearbeitet-habe.md
```

Ergebnis: `docs/report.pdf`, `docs/how-we-worked.pdf`

Bei Fehler (Timeout, fehlende Abhängigkeiten): Warnung ausgeben, nicht abbrechen —
die PDF-Generierung ist optional, der Deploy soll trotzdem weiterlaufen.

---

## Phase 3 — Build

```bash
elm make src/Main.elm --output=public/main.js --optimize
```

Prüfe dass der Build fehlerfrei ist. Bei Fehlern: Abbruch, Problem erklären.

---

## Phase 4 — Commit & Push (master)

Stage Quellcode, Spiegel-Dateien, Diagramme und Log gemeinsam:

```bash
git add src/ public/ docs/ diagrams/ elm.json .claude/
git commit -m "<sinnvolle Commit-Message>"
git push origin master
```

---

## Phase 5 — GitHub Pages aktualisieren (gh-pages Branch)

Der `gh-pages` Branch enthält nur den Inhalt von `public/`:

```bash
git subtree split --prefix public -b gh-pages-deploy
git push origin gh-pages-deploy:gh-pages --force
git branch -D gh-pages-deploy
```

---

## Phase 6 — Work Log

```bash
echo "| $(date +%Y-%m-%d) | IMPL | MEDIUM | Deploy: <kurze Beschreibung> |" >> docs/log.md
git add docs/log.md
git commit -m "docs: work log entry for deploy"
git push origin master
```

---

## Phase 7 — Bestätigung

Ausgabe an den Nutzer:

- Quellcode: https://github.com/0x520Uni/CocktailPlaner
- Live-Demo:  https://0x520uni.github.io/CocktailPlaner/

**Hinweis:** GitHub Pages braucht ~1–2 Minuten bis die neue Version sichtbar ist.
Direktlinks wie `/glossar` geben 404 — immer zuerst `/` laden, dann per Navbar navigieren (SPA).
