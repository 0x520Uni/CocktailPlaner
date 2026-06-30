# UI Workflow Rules

## Design First

Before starting any visual or UI task (layout, styling, SVG glass, responsive behaviour):
invoke the `frontend-design` skill first. Do not freelance the UI before consulting it.
Follow the UI conventions in CP-A-4 (YouTrack) — Bulma utilities, component classes
in `public/style.css`, colour matching via `View.CocktailSvg.ingredientColors`.

## Verify Before Done

Before declaring any UI change done: run `/verify`.
This runs Playwright and takes screenshots at 1680px, 1280px, and 480px.
Look at every screenshot — a passing `elm make` says nothing about appearance.

## SPA Gotcha

`http://localhost:8765/glossar` returns 404 on a plain static server (no SPA fallback).
Always load `http://localhost:8765/` first, then navigate via the navbar.

There is intentionally no automated test suite — `/verify` is the QA step.
