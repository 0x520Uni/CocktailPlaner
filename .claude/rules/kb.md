# Knowledge Base Rules

YouTrack (`https://0x520.youtrack.cloud`, project **CP**) is the sole source of truth
for all ADRs and KB articles. Update the relevant article in the same session when:

| Change | Article to update |
|---|---|
| New ADR accepted | CP-A-13 (ADR Summary) + new child article under CP-A-7 |
| New domain term introduced | CP-A-5 (Domain Glossary) |
| Toolchain change | CP-A-4 (Project Overview) |
| New TheCocktailDB endpoint used | CP-A-6 (API Reference) |

Run `/kb-sync <description of what changed>` to execute the sync.
Log every KB change in `docs/log.md` with type `DOCS`.

To create a new ADR child article via REST:
```
POST https://0x520.youtrack.cloud/api/articles
{
  "summary": "ADR-00XX: Title",
  "content": "...",
  "project": {"id": "0-3"},
  "parentArticle": {"id": "180-113"}
}
Authorization: Bearer $YOUTRACK_TOKEN_0x520
```
