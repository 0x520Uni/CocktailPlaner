# kb-sync

Synchronisiert Änderungen zum YouTrack-Wissensbasis.
Aufruf: `/kb-sync <was geändert wurde>`

## Schritte

### 1. Betroffene Artikel ableiten

Aus $ARGUMENTS bestimmen welche YouTrack-Artikel aktualisiert werden müssen:

| Änderungs-Typ | Artikel |
|---|---|
| Neues ADR | CP-A-13 aktualisieren + neues Child unter CP-A-7 anlegen |
| Neuer Domain-Begriff | CP-A-5 (Domain Glossary) |
| Toolchain-Änderung | CP-A-4 (Project Overview) |
| Neuer CocktailDB-Endpoint | CP-A-6 (API Reference) |

### 2. Aktuellen Inhalt holen

```
GET https://0x520.youtrack.cloud/api/articles/{idReadable}?fields=content,summary
Authorization: Bearer $YOUTRACK_TOKEN_0x520
```

Bevorzuge den YouTrack MCP-Server (konfiguriert in `~/.claude/mcp.json`).

### 3. Inhalt aktualisieren und hochladen

```
POST https://0x520.youtrack.cloud/api/articles/{idReadable}
Authorization: Bearer $YOUTRACK_TOKEN_0x520
Content-Type: application/json

{"content": "<aktualisierter Inhalt>"}
```

Für ein neues ADR-Child-Artikel:
```json
{
  "summary": "ADR-00XX: Titel",
  "content": "...",
  "project": {"id": "0-3"},
  "parentArticle": {"id": "180-113"}
}
```

### 4. Work Log

```bash
echo "| YYYY-MM-DD | DOCS | MEDIUM | KB-Sync: $ARGUMENTS |" >> docs/log.md
```
