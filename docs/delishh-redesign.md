# delishh redesign — implementation plan

> Companion to `docs/design-standard.md` (DS-01 Revision 2).
> Created 2026-09-19. This doc owns *sequence and scope*; DS-01 owns
> look, feel, and voice. When the two disagree, DS-01 governs and
> this plan gets a dated amendment.

## Decision log

Ruled 2026-09-19, at the DS-01 Revision 2 reframe:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| Voice & tone | Playful acid-Y2K; no in-fiction institution. Recipe numbers and tested dates survive as useful structure, not fiction | Keeping a warmed-up institutional issuer; splitting fun-web/clinical-print voices |
| Content pipeline | One markdown file per recipe in `content/recipes/`; a Deno build script parses frontmatter + body into JSON consumed by Elm. Print is pure CSS `@media print` | Typst-compiled PDFs at build time (adds a toolchain; revisit only if CSS print hits a wall — see Open items); two markdown files per recipe (they drift) |
| Print templates | Four: `sheet` (1–2 pp default), `card` (1 p dense), `booklet` (≤4 pp long-form), `prep` (supplemental checklist). All black and white | A single universal template |
| Taxonomy | All four facet groups required in frontmatter: slot+course, flavor, method+effort, dietary+cuisine. Closed vocabularies, validated in CI | Optional/freeform tagging |
| Design standard delivery | `docs/design-standard.md` is rendered in-app through the content pipeline. `public/design-standard.html` (the frozen copy) is **dropped** | Maintaining the hand-frozen HTML mirror |

## What exists today

- Elm + Vite + Deno shell with working chrome: `Doc.elm` (document
  frame), `Route.elm`, `Search.elm`, `Viewport.elm`, theme switching,
  section tracking. **Keep all of it** — the TEA architecture and the
  Doc/Page split survive the redesign intact.
- `Page.Home` and `Page.About` are placeholders. No recipes exist.
- `public/design-standard.html` — a frozen HTML copy of the old DS-01;
  to be deleted (Phase 2).
- Fonts shipped: Archivo Expanded 700, JetBrains Mono 400/700.
  Missing: Inter 500, Instrument Serif 400.

## Phases

Ordered so each phase produces something visible, and so the print
sheet is proven before the browse experience is styled (DS-01 §13).

### Phase 1 — content pipeline & schema

The foundation everything else is a view of.

- [ ] `content/recipes/` directory; `content/docs/` optionally later
      for prose documents.
- [ ] `scripts/build-content.ts` (Deno):
  - Parses YAML frontmatter + markdown body per recipe.
  - Validates against the DS-01 §06 schema: required fields, closed
    vocabularies (slot, flavor, method, effort, dietary), unique
    recipe numbers, `time.total ≥ time.active`.
  - Runs the word check (DS-01 §11 banned list) against procedure
    blocks only — the note block is exempt.
  - Emits `public/content/index.json` (the facet index for browse/
    search) and `public/content/recipes/<slug>.json` (one per
    recipe).
  - Fails the build on any violation. Wire into `deno task build`
    and CI.
- [ ] Vocabulary module: one file owning the facet lists, imported by
      the build script — the single place a new flavor or method is
      added.
- [ ] Write the bench specimen: `content/recipes/salted-caramel.md`
      (Nº 47), exercising every block including watchpoints, rescues,
      and the note.

**Exit test:** `deno task build` fails loudly on a recipe with a
misspelled flavor, a reused number, or "simply" in a step.

### Phase 2 — design standard from markdown

- [ ] Extend the build script to render `docs/design-standard.md`
      into JSON sections consumable by `Doc.elm`'s section list
      (heading → section, prose → rendered blocks).
- [ ] `Page.DesignStandard` consumes the generated content instead of
      hand-maintained Elm markup.
- [ ] **Delete `public/design-standard.html`** and its `dist/` copy;
      check `_redirects`/`_headers` for references.
- [ ] Update `CLAUDE.md`: doc map (no frozen HTML copy; markdown is
      the single source, rendered in-app), and the "Not yet in force"
      section.

**Exit test:** editing a sentence in `docs/design-standard.md` and
rebuilding changes the `/design-standard` page with no Elm edits.

### Phase 3 — tokens, type, and the two-layer color system

- [ ] Add Inter 500 and Instrument Serif 400: `.woff2` under new
      filenames in `public/fonts/`, OFL texts, `@font-face` blocks,
      tokens, preloads if above the fold.
- [ ] `theme.css` refresh: four acids + text variants with measured
      contrast ratios in comments, both themes; shelf-layer tokens
      (tile/chip fills) vs page-layer tokens (accent marks) named
      distinctly so the loud/quiet split is enforceable in review.
- [ ] Sync the hand-inlined token subset in `public/404.html`.

### Phase 4 — the recipe page (web)

- [ ] `Route.Recipe slug` + `_redirects` line + round-trip test.
- [ ] `Page.Recipe`: fetch + decode the recipe JSON; render the ten
      blocks in order (DS-01 §06). Quiet-page discipline: one
      dominant acid, quantities in mono ink, chips carry words.
- [ ] Scaling control (×0.5–×3): per-unit rounding, the honest-note
      fallback for indivisible units, scale factor displayed
      permanently.
- [ ] Halftone/neutral-clamped photo treatment; absent block when no
      photo.

### Phase 5 — print templates

The sheet before the shelf. Pure CSS, `@media print`, no JS.

- [ ] `print.css`: shared ink discipline — black + one tint, no
      reversed body, 11pt/14pt floors, break law, physical-unit
      margins, the traceability footer (number · revision · scale ·
      print date · short URL).
- [ ] `sheet` template (the default), proven on Nº 47.
- [ ] `card`, `booklet`, `prep` templates; template selected by
      frontmatter `print:` field, reader-overridable before printing.
- [ ] Verify: monochrome laser output legible; ≤4 pages on a genuinely
      long recipe; footer intact on every page.

**Exit test:** print-preview of Nº 47 from Firefox and Chromium is
1–2 clean B&W pages with zero color ink and an intact footer.

### Phase 6 — the shelf (browse, search, filter)

- [ ] `Page.Home` becomes the shelf: four full-acid path tiles
      (By meal / By flavor / By effort / By needs).
- [ ] Facet browse: selecting within a path composes filters across
      paths; filter chips state what they exclude; excluded rows stay
      visible tagged with the excluding filter.
- [ ] Results list: dense rows, flavor chips, active *and* total
      time, default sort by last tested.
- [ ] Recipe search over the index JSON (extends or sits beside the
      existing site `Search.elm` — decide when the shapes are on the
      bench).
- [ ] Zero-results copy with a nearest-match action.

### Phase 7 — cook mode

- [ ] Arm's-length view per DS-01 §08: ≥20px body, step stamping,
      wake lock (with on-screen notice), permanent scale display.
- [ ] Step timer — the first legitimate subscription beyond
      `sectionSeen`, per the architecture rules.

### Phase 8 — cleanup & polish

- [ ] Retire `Page.About` placeholder or give it real content.
- [ ] Sweep remaining Revision-1 references (grep for the old
      institutional strings) across code and docs.
- [ ] Motion pass per DS-01 §10: shelf press/hover responses inside
      `prefers-reduced-motion: no-preference`.
- [ ] Lighthouse/perf check on a throttled phone profile.

## Open items

- **Prerendered recipe HTML.** The old standard required reading with
  JS off; as an Elm SPA that's not currently true. If it matters,
  Phase 5+ can add a build step emitting static HTML per recipe from
  the same JSON. Deferred until the print templates prove out —
  revisit then.
- **Typst.** If CSS print can't hit the layout quality wanted for
  `booklet` (running headers, precise page control), revisit
  Typst-generated PDFs as a *download* option layered on top. Not a
  replacement for CSS print.
- **Photos at print.** Halftone-at-build (preprocessed asset) vs
  CSS-filter-at-print. Decide on the bench in Phase 5.
- **Example print artifact.** The reference artifact the redesign
  brief pointed at was inaccessible (private link); the templates are
  designed from DS-01 §09 first principles. If there are specific
  traits from that example worth carrying, note them here.
