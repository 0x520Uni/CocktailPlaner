# verify

Visueller QA-Check: baut die App und prüft sie via Playwright auf 3 Viewport-Breiten.
Aufruf: `/verify` — kein Argument nötig.

## Schritte

### 1. Build

```bash
elm make src/Main.elm --output=public/main.js --optimize
```

Bei Fehlern: Abbruch, Problem erklären.

### 2. Static Server starten

```bash
cd public && npx --yes http-server -p 8765 -c-1 --silent &
```

Warte 1 Sekunde bis der Server läuft.

### 3. Home-Seite prüfen (3 Viewports)

Playwright: `http://localhost:8765/` laden.

Screenshot bei:
- 1680 × 900 (Wide Desktop)
- 1280 × 800 (Laptop)
- 480 × 850 (Phone)

Jeden Screenshot ansehen und kurz beschreiben was sichtbar ist.

### 4. Glossar prüfen (3 Viewports)

Glossar-Button in der Navbar klicken (kein Direktlink wegen SPA-Gotcha).

Screenshot bei:
- 1680 × 900
- 1280 × 800
- 480 × 850

Jeden Screenshot ansehen.

### 5. Befund ausgeben

Was stimmt, was ist auffällig (Layout, Überlappungen, fehlende Elemente, Texte).

### 6. Aufräumen

Playwright-Browser schließen, Server-Prozess beenden.
