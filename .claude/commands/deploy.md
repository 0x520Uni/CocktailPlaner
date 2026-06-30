# deploy

Baut die Elm-App, pushed Quellcode auf GitHub und aktualisiert die GitHub-Pages-Live-Demo.

## Voraussetzungen (vom Nutzer vorher erledigt)

$ARGUMENTS

## Schritte

### 1. Build

```bash
elm make src/Main.elm --output=public/main.js --optimize
```

Prüfe dass der Build fehlerfrei ist. Bei Fehlern: Abbruch, Problem erklären.

### 2. Commit & Push (master)

Stage alle geänderten Dateien in `src/`, `public/`, `docs/`, `elm.json`:

```bash
git add src/ public/ docs/ elm.json
git commit -m "<sinnvolle Commit-Message>"
git push origin master
```

### 3. GitHub Pages aktualisieren (gh-pages Branch)

Der `gh-pages` Branch enthält nur den Inhalt von `public/`. Update via subtree:

```bash
git subtree split --prefix public -b gh-pages-deploy
git push origin gh-pages-deploy:gh-pages --force
git branch -D gh-pages-deploy
```

### 4. Work Log

```bash
echo "| $(date +%Y-%m-%d) | IMPL | MEDIUM | Deploy: <kurze Beschreibung der Änderung> |" >> docs/log.md
git add docs/log.md
git commit -m "docs: work log entry for deploy"
git push origin master
```

### 5. Bestätigung

Gib dem Nutzer folgende Links aus:

- Quellcode: https://github.com/0x520Uni/CocktailPlaner
- Live-Demo: https://0x520uni.github.io/CocktailPlaner/

**Hinweis:** GitHub Pages braucht ~1–2 Minuten bis die neue Version sichtbar ist. Direktlinks wie `/glossar` geben 404 — immer zuerst `/` laden, dann über die Navbar navigieren (SPA-Einschränkung).
