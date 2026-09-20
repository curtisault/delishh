# delishh

A personal recipe archive — browse, search, filter, print — built in
the acid-Y2K institutional idiom. Elm + Vite, no Node. The design
language is set out in full in `docs/design-standard.md`; that doc is
the authority on how this looks and why.

## Doc map

| Doc | Owns |
|-----|------|
| `docs/design-standard.md` | DS-01 — look, feel, voice, type, colour, the recipe document, cook mode, print, the lexicon, hard constraints. **The prose of record.** |
| `src/Page/DesignStandard.elm` | DS-01 rendered through the house chrome, at `/design-standard` |
| `public/design-standard.html` | A frozen, self-contained copy of DS-01 with its fonts inlined — readable and mailable without the app booting. When it and the markdown disagree, **the markdown governs.** |

## Commands

Toolchain pinned in `mise.toml` (`mise install`): deno 2, elm 0.19.1,
elm-test-rs. `mise.toml` is the **single source of truth** for every
tool version — CI installs from the same file via `jdx/mise-action`.

**There is no Node and no npm.** Deno is the only JavaScript runtime:
it runs Vite, wrangler, and the compiled Elm test bundle. Dependencies
and tasks live in `deno.json`. The surviving `package.json` holds one
`overrides` block and must hold nothing else — it is the only way to
force a transitive npm version, and deleting it silently reinstates a
`cross-spawn` ReDoS advisory. If something will not run under Deno,
fix that — do not reintroduce node.

`elm-test-rs` comes from a **fork** because upstream's Deno support
still calls three APIs Deno 2 removed; `mise.toml` documents it and
says when to drop back to upstream.

Neither the Elm compiler nor the test runner is a package; both
resolve off PATH, so `mise install` is required before
`deno task build` or `deno task test` will work.

- `deno task dev` — Vite dev server
- `deno task build` — production build to `dist/`
- `deno task test` — elm-test-rs under Deno
- `deno task deploy` — build, then `wrangler pages deploy dist`

## Architecture rules

- `src/Route.elm` — pure routing; adding a route means adding a line
  to `public/_redirects` (scoped, no wildcard — that friction is
  deliberate) and a variant to the round-trip list in
  `tests/RouteTests.elm`, which the compiler cannot check for you.
- `src/Doc.elm` — the document format: shared chrome (masthead,
  contents rail, § numbering, clause marks, search, footer). **It
  numbers and frames; pages render.** Never teach it page content —
  the moment `Doc` knows what a recipe card is, it has stopped being
  a format.
- `src/Page/*.elm` — pure views, one per route; each hands `Doc.view`
  one ordered section list. The rail and the § numbers are *derived*
  from that list, so they cannot disagree with it. In-prose `§`
  cross-references are the one thing maintained by hand: reordering
  sections means grepping for `§`.
- `src/Main.elm` — the TEA shell; all state lives here, including
  `#anchor` scrolling (`jumpTo`) — `Browser.application` swallows the
  browser's own fragment jumps — and the theme preference
  (System/Light/Dark), applied to `<html>` by boot.js via the
  `saveTheme` port because Elm owns only `<body>`.
- `src/Viewport.elm` — whether a URL change moves the reader, as one
  pure tested function. **Do not inline this decision.** When a page
  starts mirroring its state into `?query=`, name it in
  `Main.arrivalMirrors` and add its `Nav.replaceUrl`; an echo of the
  shell's own write moves nobody. Getting this half-right (guarding
  the scroll-to-top and forgetting the anchor jump) is the classic
  failure, and `ViewportTests` holds the whole table.
- `src/Search.elm` — the site index. Hand-written, machine-checked:
  `terms` must appear in the section they claim, `aliases` must not.
  The query lives in the model, never the URL, and any real
  navigation clears it. `Doc` takes a `Chrome` (active section +
  query + handler); a non-empty query replaces the sheet's sections
  with results.
- Two ports exist: `saveTheme` (out) and `sectionSeen` (in). The
  second is a port because `elm/browser` has no scroll subscription;
  boot.js reads the active section on scroll, resize and DOM
  mutation, rAF-throttled. The active style must never affect layout,
  or marking a section could move it.
- There is currently **no subscription but `sectionSeen`**. Add one
  only when something on screen genuinely changes on its own. A
  cooking timer will qualify; a document will not.
- CSS: `theme.css` = tokens only; `fonts.css` = `@font-face` only;
  `sheet.css` = components. **Breakpoints are in `rem`, never `px`,
  and there is no device detection anywhere** — a narrow window is a
  narrow layout. Nothing may clip and nothing hides behind a gesture.
  **60rem is the one narrow tier**: the rail drops to its search box
  and the site nav's routes move into a disclosure panel, positioned
  absolutely so `--nav-h` never changes and opening it shifts no
  layout. Bar items are `flex: none` — a shrinking flex child prints
  through its neighbour inside a fixed-height bar.
- Raw hex outside `theme.css` is a bug, and so is `font-stretch` or a
  synthesised weight on the display voice — only one 700 cut ships.
- **An acid names a physical process** (DS-01 §04): volt = the
  actionable, cyan = cold chain, orange = heat and hazard, magenta =
  live. One acid dominates per surface, a second may cameo, never
  three. **Acid never lands on a quantity**, and **information is
  never colour-only** — a thermal class carries its word as well as
  its mark, which is the same rule that makes the black-and-white
  printout work.
- Four type voices, strictly cast (DS-01 §05): Archivo Expanded 700
  display, Inter 500 procedure, JetBrains Mono data, Instrument Serif
  human. The human voice is never used for procedure.
- Wide content (reference tables, grids) scrolls inside its own
  `.doc-scroller`; **the page body never scrolls sideways.**
- `public/404.html` must exist and `public/_redirects` must stay
  wildcard-free: together they keep Cloudflare Pages' SPA fallback
  off. Deleting either serves `index.html` as `text/html` for missing
  hashed assets, and `public/_headers` then caches that mistake for a
  year. CI fails the build if you break it.
- `public/404.html` inlines a subset of `theme.css`'s tokens by hand
  — it cannot link the hashed bundle. Change a colour in one, change
  it in the other.

## Not yet in force

- **Fonts.** `public/fonts/` ships Archivo Expanded and JetBrains Mono
  only. DS-01 §05 also casts **Inter 500** (procedure) and
  **Instrument Serif 400** (human); both currently fall through to
  system faces. Adding one means: the `.woff2` under a *new* filename
  (`/fonts/*` is cached immutably), its OFL text beside it, an
  `@font-face` block in `fonts.css`, the token in `theme.css`, and a
  `<link rel=preload>` in `index.html` if it is above the fold.
- **The product.** `Page.Home` and `Page.About` are placeholders that
  exist so the chrome has something to frame. Nothing in DS-01 §§06–09
  — the ten-block recipe document, the index, cook mode, the printed
  sheet — is built yet.
