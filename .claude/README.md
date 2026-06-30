# Agent Harness — CocktailPlaner

Dieses Verzeichnis konfiguriert das Verhalten von Claude Code in diesem Projekt.

---

## Das 3-Schichten-Modell

| Schicht | Dateien | Wann aktiv |
|---|---|---|
| **Context** | `CLAUDE.md` (Root) | Jede Session — Projektfakten, Toolchain |
| **Rules** | `.claude/rules/*.md` | Jede Session — Verhaltensregeln, Pflichten |
| **Commands** | `.claude/commands/*.md` | On-demand — nur wenn `/befehl` aufgerufen wird |

**Idee:** `CLAUDE.md` beschreibt *was* das Projekt ist. Rules beschreiben *wie* der Agent
sich verhalten soll. Commands beschreiben *was* er auf Abruf tut.

---

## Rules (`.claude/rules/`)

Werden automatisch in jede Session geladen — der Agent muss sie nicht explizit anfordern.

| Datei | Inhalt |
|---|---|
| `always.md` | Work-Log-Pflicht, Erklären vor Implementieren, Code-Stil |
| `ui.md` | `frontend-design` Skill zuerst, `/verify` vor "Done", SPA-Gotcha |
| `kb.md` | YouTrack-Sync nach ADR/Glossar/API-Änderungen, Artikel-Mapping |

---

## Commands (`.claude/commands/`)

Nur aktiv wenn der Nutzer `/befehlsname` eingibt. Erhalten optionale Argumente via `$ARGUMENTS`.

| Befehl | Wann aufrufen | Was passiert |
|---|---|---|
| `/deploy` | Nach abgeschlossenen Änderungen | Build → Git commit → Push → gh-pages update → Log |
| `/verify` | Nach UI-Änderungen, vor "Done" | Playwright QA: Build → Server → 6 Screenshots (3 Seiten × 3 Viewports) |
| `/kb-sync <was>` | Nach ADR/Glossar/API-Änderungen | YouTrack-Artikel aktualisieren → Log |

---

## Hooks (`.claude/settings.json`)

Hooks laufen automatisch bei Session-Events — kein manueller Aufruf nötig.

| Hook | Trigger | Aktion |
|---|---|---|
| `SessionStart` | Beim Starten einer Session | Zählt aktuelle Zeilenzahl von `docs/log.md` als Baseline |
| `Stop` | Beim Beenden einer Session | Vergleicht Zeilenzahl mit Baseline — blockiert wenn keine neue Zeile geschrieben wurde |

**Warum:** Erzwingt dass nach jeder bedeutsamen Arbeit ein Eintrag in `docs/log.md` existiert.
Der Hook gibt eine klare Fehlermeldung aus und verhindert das Beenden bis der Eintrag da ist.

---

## MCP-Server (`.mcp.json`)

| Server | Befehl | Zweck |
|---|---|---|
| `playwright` | `npx @playwright/mcp@latest` | Browser-Automatisierung für `/verify` und manuelle UI-Tests |

Alle Playwright-Tools sind in `settings.json` ohne Rückfrage erlaubt (`mcp__playwright__*`).

Der YouTrack-MCP-Server ist in `~/.claude/mcp.json` konfiguriert (globale Einstellung, nicht
im Repo — enthält den Bearer-Token).

---

## Memory (automatisch)

Claude Code pflegt automatisch ein Gedächtnis über Sessions hinweg.

**Ort:** `~/.claude/projects/<projekt-hash>/memory/`  
**Typen:** `user` (Nutzerprofil), `feedback` (Korrekturen), `project` (Kontext), `reference` (externe Links)  
**Automatisch:** Der Agent speichert Erkenntnisse ohne expliziten Aufruf, wenn er etwas
Wichtiges über den Nutzer oder das Projekt lernt.  
**Manuell:** "Merke dir, dass..." speichert sofort; "Vergiss..." löscht den Eintrag.

Aktuell gespeichert (Übersicht in `~/.claude/projects/.../memory/MEMORY.md`):
- Projektkontext + Deadline
- Code-Stil-Präferenzen
- Erklär-vor-Implementieren-Regel
- Playwright-Verifikationspflicht
- YouTrack-Mirror-Pflicht

---

## Dateiübersicht

```
.claude/
├── README.md              # Diese Datei
├── settings.json          # Permissions + Hooks + aktivierte Plugins
├── rules/
│   ├── always.md          # Core: Log, Erklären, Stil
│   ├── ui.md              # UI: Design-Skill + Verifikation
│   └── kb.md             # KB: YouTrack-Sync
└── commands/
    ├── deploy.md          # /deploy
    ├── verify.md          # /verify
    └── kb-sync.md         # /kb-sync
```
