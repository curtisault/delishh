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

Ruled 2026-09-19, at Phase 2:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| Prose rendering | A build-time AST: `scripts/markdown.ts` parses the DS-01 subset, `Prose.elm` renders it with the house classes | `dillonkearns/elm-markdown` parsing in the browser (a runtime dep, and markdown parsed on every load); keeping the page hand-written (the drift this phase exists to end) |
| Prose transport | **Generated Elm** (`src/Generated/`), not fetched JSON — unlike recipes. A document that ships with the app compiles in: no `elm/http`, no loading state, and `Page.DesignStandard.view` stays pure so `SearchTests` can keep holding every search term to the rendered page | Fetched JSON, which would end that machine-check and add a loading state to a page whose only job is to be read |
| Section numbering | `Doc` numbers sections from **00**, matching the markdown's own `## 00.` headings and every in-prose `§NN` | Renumbering the standard 01–14 (touches ~30 cross-references); having the build emit explicit numbers (breaks Doc's derived-numbering invariant) |

Ruled 2026-09-20, at the authoring contract:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| Recipe authoring requirements | `content/recipes/AGENTS.md` — hand-written prose (workflow, grammar, the why), with every fact in it recomputed from `vocabulary.ts` by `agents_test.ts` on each test run. Adding a facet value now means editing the vocabulary *and* the contract, and forgetting either fails the build | Generating the whole file from the vocabulary (loses the curated prose that makes a contract worth reading); pure hand maintenance (drifts — the About colophon already demonstrated how) |

Ruled 2026-09-21, at the revision retirement:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| The recipe number | `number:` retired (DS-01 §06 amendment, 2026-09-21). Identity is the **slug** — filename, URL, and now the printed footer's name line, so every page of a booklet says what it belongs to. The plate's serial slot goes to **the method**, the fact that already colours the page: `PICKLE · LAST BATCH 2026-08-02` is §04's "never colour-only" kept where it is loudest. The shelf's left rail carries the method word too | Keeping an insertion-order serial (tells a reader nothing about the food); a hand-counted "batch Nº" (the revision-counter disease again); provenance labels (not in the schema, cannot be required) |
| Revisions | The `revision:` counter and the History block are retired (DS-01 §06 amendment, 2026-09-21). **The change log is git's job** — every edit is already recorded there with a date and a reason, and readers do not need it. The counter's deeper fault: nothing forced it to move, so `REV 3` on a printed sheet was a hand-maintained claim about content, not a fact. Staleness on paper is now the sheet's **TESTED** against the site's; the story of how a recipe got here belongs in the note | Keeping the counter (metadata that can silently lie); a dated History block feeding a derived "last changed" (proposed, then superseded — reader-facing change tracking is the thing being removed); a git-derived changed date in the footer (couples the content build to git, and a shallow CI checkout would date every file to the head commit — a subtle lie replacing an honest one) |

Ruled 2026-09-21, at the print revision (Phase 10):

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| What print is | **A designed page, not a styled printout.** Phase 5 linearized the screen document and inherited its whitespace; the first real print run (the donuts booklet, 2026-09-21) spent four pages saying two pages of things. The reference is now the source cards themselves — recovered, printed, and cooked from — and the traits worth carrying are named below, one ruling each | Leaving print as the screen's shadow; Typst PDFs (still the escape hatch, still not needed — every fix below is CSS over the same document) |
| Ingredients on paper | **A row-aligned grid, not CSS multicolumn.** `columns: 2` balances by height, so wrapping names drift the two stacks and the hairline under each item pretends to be a table row that stops at the gutter — the "incoherent" read. The grid pairs `qty · name · qty · name` in shared rows, so every rule really does run where it appears to. Reading order becomes across-then-down, which a shopping list tolerates and an aligned rule repays | Keeping multicolumn and dropping the hairlines (loses the scan lines that make quantities findable at a glance); single column (Phase 5's own ruling against wasting the held half of the page stands) |
| The step line | **The cue moves to the step's number line in print** — right-aligned, the clock-and-tell where a standing reader looks first, body below. This is the source cards' step anatomy (head + clock, then body, then why) built from markup the steps already have. Screen keeps the cue beneath the body; print repositions, nothing is re-authored | A per-step `head:` field in the schema (new authoring burden duplicating the cue's job); leaving the cue buried under the body on paper |
| The duplex sheet | **The sheet form breaks before Watchpoints.** The blocks already split on the bench seam — Equipment/Ingredients/Steps are cook-side, Watchpoints/Rescues/Keeps/Note are reference — so the page break makes the sheet a duplex card: procedure on the front, recovery on the back, flippable with a wet hand. The source cards' front/back grammar, found already latent in the block order | A separate back-page template (a second renderer, the drift Phase 5 refused); breaking before Rescues (a watchpoint is read *before* trouble, and belongs with the reference side, not the procedure) |
| The gauge strip | **New optional frontmatter: `gauges:`** — up to five hand-authored label · value (· note) pairs, the recipe's operating numbers (`OIL 185 °C · holds`, `DONE AT 96 °C · center`). The single most useful trait of the source cards, and the one that cannot be derived: those numbers live in prose, and deriving them would be inference (§06's "nothing is ever inferred"). Hand-authored **printed content** is not hand-maintained metadata — a gauge is read at the bench and a wrong one fails the cook, which is the same force that keeps the steps honest. Rendered on screen *and* paper: the screen and the sheet are two renderings of one file, and content hidden from one of them disagrees with that | Deriving gauges from cues/equipment (inference, banned); print-only rendering (content the screen hides); a closed gauge vocabulary (these are the recipe's own numbers, not a facet) |
| Facet chips on paper | **Dropped from print, all of them.** Slot, flavor, effort, cuisine — and dietary — are browse furniture: facets exist to *find* a recipe, and a printed sheet is already found. Ink goes to the gauge strip instead, which answers questions the bench actually asks | Keeping dietary chips only (a verified flag matters when cooking for someone — but the ingredients are on the same page, and a half-kept chip row buys ambiguity with ink) |
| Density | **Page budgets enforced by design, not hoped for:** card = 1 page, sheet = 2 (one duplex leaf), booklet ≤ 4 full pages. The 11pt body floor stays — §09's standing reader is right — so the space comes out of what the floor does not protect: plate padding, block gaps, step padding, and the dead air the screen document carries between sections | Shrinking the body floor (breaks §09's own rule); leaving budgets as aspiration (the donuts booklet already showed what that produces) |
| Print QA target | **Print previews run against `deno task build` output, never the dev server.** The dev build overlays Elm's debugger badge fixed to the viewport corner, and fixed elements print on **every page** — the stray "89" on the first real print run. Not a bug in the sheet; a rule about how to look at it | A print.css rule hiding the badge (styling a dev tool into the product stylesheet) |

Ruled 2026-09-21, at the flavour meter:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| Flavour intensity | **A flavour entry may carry an authored level** (DS-01 §06 amendment, 2026-09-21): `spicy 2` — `1` background · `2` present · `3` defining, three levels by the EFFORTS reasoning. Bare word = unstated, never zero; the meter draws only judged levels (nothing is ever inferred). Parsed in `recipe.ts`, taught in AGENTS.md, both held together by `agents_test.ts` | A five-point scale (the difficulty-scale disease, named in `vocabulary.ts` since day one); deriving heat from the ingredient list (inference, banned); a separate `palate:` map (two homes for one fact) |
| The flavour marks | **Seven stencils, one per vocabulary word, as CSS mask data-URIs in `sheet.css`** painting in currentColor — droplet, sprig, chilli, lemon, mushroom, bean, crystal. Decoration-plus-reinforcement: the word never leaves the chip, so the mark can fail without the information failing. The SVGs carry no colour (a mask reads alpha), keeping "raw hex outside theme.css" intact | `elm/svg` inline markup (a new dependency, and styling decisions migrating out of CSS); icon-only chips (information carried by a pictogram alone — §04's rule applied to shape); pictograms as image files (payloads where CSS suffices) |
| The meter on chips | **Three cells, filled to the level, `aria-hidden`, with the meaning as visually-hidden words** ("defining, 3 of 3") — filled-vs-outlined is shape, not colour, so it needs no contrast pair and would survive a printer it never reaches (chips still do not print). Shared as `Flavor.chip`, one view for the plate and the shelf's rows | Empty cells for unstated (renders a judgement of zero nobody made); acid-filled cells (a level is a quantity's neighbour — the emphasis stays ink); per-surface chip markup (two meters that drift) |

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

### Phase 1 — content pipeline & schema ✅ done 2026-09-19

The foundation everything else is a view of.

- [x] `content/recipes/` — one markdown file per recipe, the source of
      record.
- [x] `scripts/vocabulary.ts` — every closed facet list, the units and
      their kinds, the block order, and the word rules. Data only; the
      single place a new flavour or method is added.
- [x] `scripts/recipe.ts` — `parseRecipe`, a pure function: frontmatter
      → schema, body → the ten blocks, plus every DS-01 rule that can
      be checked mechanically.
- [x] `scripts/build-content.ts` — walks the corpus, runs the
      cross-file checks (unique numbers, photo files exist), writes
      `public/content/index.json` and
      `public/content/recipes/<slug>.json`. Collects every problem
      before exiting non-zero; writes nothing on failure.
- [x] `scripts/recipe_test.ts` — 30 tests over the bench specimen, one
      per rule. Added beyond the original plan: the rules are regexes,
      and a regex without a test stops being enforced the first time
      someone edits it.
- [x] Bench specimen `content/recipes/salted-caramel.md` (Nº 47),
      exercising every block including a terminal rescue.
- [x] Wired into `deno task content`, which `dev`, `build` and `test`
      all run first — so a bad recipe fails the pull request, not
      production.

**Exit test — passing.** Verified caught: misspelled flavour, British
spelling of a key (with a "did you mean" suggestion), reused recipe
number, "simply" in a step, exclamation mark in a step, `142.5 g`,
decimal volume, a bare-duration cue, reordered blocks, a missing note,
history disagreeing with `revision:`, a photo named but absent. Errors
carry exact line numbers. The note block is exempt from the word rules
and a test pins that.

**Rules enforced beyond the original scope**, because the parse made
them free: the measurement ladder (whole grams, glyph fractions, no
decimals outside mass), "the clock is never alone" (a cue that is only
a duration fails), indivisible-unit tagging for the Phase 4 scaler,
`tested` not in the future, revision/history agreement, and a required
Note block.

### Phase 2 — design standard from markdown ✅ done 2026-09-19

- [x] `scripts/markdown.ts` — a parser for exactly the subset DS-01
      uses (headings, three inline marks, lists, tables of any width,
      blockquotes, fences). It **rejects** anything else rather than
      dropping it silently.
- [x] `scripts/build-docs.ts` — markdown → `src/Generated/DesignStandard.elm`.
- [x] `src/Prose.elm` — the block types and the renderer. Hand-written
      and reviewable; the generator emits data and knows no class name.
- [x] `src/Page/DesignStandard.elm` — 785 lines of hand-kept markup
      down to four lines of wiring.
- [x] Frontmatter (masthead) and `<!-- doc ... -->` directives added to
      `docs/design-standard.md`, so the markdown is the single source
      for the whole page rather than only its body.
- [x] **Deleted `public/design-standard.html`**, its `dist/` copy, and
      its `_headers` rule. `_redirects` needed no change (it only ever
      routed `/design-standard`). README updated.
- [x] `Doc.sectionNum` numbers from **00**, matching the markdown.
- [x] `sheet.css` — specimen blocks (`.doc-pre`) and n-column tables.
- [x] `Search.elm` — all 14 DS-01 entries rewritten against Rev 2
      prose. Seven Rev 1 terms (`cryovault`, `stratum`, `sourdough`,
      `HACCP`, `deadpan`, `lockout`, `toner`) no longer existed.
- [x] `scripts/docs_test.ts` — 20 tests over the generator and the
      markdown subset.
- [x] `CLAUDE.md` and `README.md` updated.

**Exit test — passing.** Editing the markdown and rebuilding changes
the page with no Elm edits; verified by rendering the built site.

**Two bugs this phase surfaced and fixed:**

- **Clause marks were off by one from their own section.** `Doc`
  rendered the section header from `i` but clause marks from `i + 1`,
  so §04's clauses read `§5.1`–`§5.10`. Caught by rendering the real
  page — no test covered the relationship between the two numbers.
- **The whole §-numbering was off by one** before the `sectionNum`
  change, which is what the numbering decision above was about. The
  generator now checks every `## NN.` heading against its position, so
  a reordered section fails the build instead of silently repointing
  every cross-reference in the standard.

### Phase 3 — tokens, type, and the two-layer color system ✅ done 2026-09-19

- [x] **Inter 500** (body) and **Instrument Serif 400** (human) added:
      latin and latin-ext `.woff2` under `public/fonts/`, both OFL
      licence texts beside them, `@font-face` blocks in `fonts.css`.
      All four voices of DS-01 §05 now ship self-hosted. Subsets are
      Google's own cuts, so the unicode-ranges are identical across
      all four families and no glyph falls between two definitions.
- [x] Inter preloaded in `index.html`; Instrument Serif deliberately
      **not** — the human voice appears in asides and at the foot of a
      recipe, never above the fold.
- [x] `theme.css` refresh: the acid tokens are now named by **layer**,
      `--shelf-*` (fills, browse surfaces) vs `--page-*` (marks, recipe
      surfaces), so DS-01 §04's loud/quiet split is reviewable from the
      token name without reading the component. `--accent` survives as
      the actionable role and aliases `--shelf-act`.
- [x] Every pair carries its **measured** ratio in a comment. Lowest in
      the system is ink-on-magenta at 5.26:1; everything clears AA.
- [x] `public/404.html` synced: Inter `@font-face` added (it declared
      the family but never shipped it), comment updated.
- [x] `scripts/contrast_test.ts` — 46 tests. Reads the real hexes out
      of `theme.css` and recomputes every pair, in both themes.
- [x] `scripts/fonts_test.ts` — 9 tests over the font wiring.

**The old acid tokens were free to rename.** `--acid-cyan`,
`--acid-orange`, `--acid-mag` and the four `*-tx` variants were
declared but consumed nowhere — the product that would use them isn't
built yet — so the layer naming landed with zero churn in `sheet.css`.

**Two silent failure modes are now machine-checked**, which is the
real deliverable of this phase:

- **A ratio comment that lies.** Those numbers are how the next person
  decides whether they have headroom to darken something. The test
  recomputes each one from the hex beside it, so a comment cannot
  drift from its colour. It caught three of my own annotations on the
  first run — `--tx` carries one ratio but is drawn on three grounds,
  which is why the comment convention now requires naming the
  background when a token has more than one.
- **A misspelled font family.** `@font-face` says `Inter`, the token
  says `Intre`, the stack falls through to a system sans, the page
  renders fine, and DS-01's entire type casting is void with nothing
  to show for it. The test holds every cast family to a declared face,
  every face to a committed `.woff2`, and every family to its OFL
  licence file.

### Phase 4 — the recipe page (web) ✅ done 2026-09-19

- [x] `Route.Recipe slug`, its `_redirects` rule, and round-trip plus
      slug tests.
- [x] `src/Recipe.elm` — the type and a strict decoder mirroring the
      build's JSON exactly. A missing field is a build that went
      wrong, not a recipe to render half of.
- [x] `src/Scale.elm` — the measurement ladder as a pure module, with
      `Factor` opaque so the view cannot invent ×1.37.
- [x] `src/Page/Recipe.elm` — the ten blocks, in order. An empty block
      is **absent**, never a heading over blank space.
- [x] `src/recipe.css` — its own sheet, because `sheet.css` says in
      its header that page components do not get appended to it.
- [x] Scale control ×0.5–×3, with the factor shown permanently once it
      is not ×1.
- [x] Neutral-clamped photo treatment; the block is absent when there
      is no photograph.
- [x] `tests/ScaleTests.elm` — 31 tests over the ladder.
- [x] Second fixture `content/recipes/fridge-pickles.md` (Nº 12).

**The recipe page deliberately does not wear `Doc`.** `Doc` frames
prose documents — masthead, contents rail, numbered sections, citable
`§N.M` clause marks. A recipe is a different object, and giving its
blocks clause marks would be the "controlled document" register
Revision 2 dropped. The site nav stays; the rail and search do not.
Consequence: recipes are not searchable until Phase 6 builds the
shelf.

**Why a second recipe.** The bench specimen is all grams in one flat
list, so it exercises neither of this phase's two riskiest paths. The
pickles carry count units (cloves, sprigs), glyph fractions, and
ingredient sub-groups — which had been parsed since Phase 1 and never
once rendered. It also runs a different method, so `acid-live` is
proven as well as `acid-heat`.

**Verified in a real browser**, not just in tests: ×1.5 turns 3 cloves
into 5 **and says** `×1.5 wants 4.5 — rounded to 5 cloves.`; ×1
restores every original verbatim; a missing recipe renders designed
copy with a way back rather than a stack trace.

**One bug the fixture caught.** The build canonicalises count units to
the singular so `cloves` and `clove` are one facet — correct for the
data, and it put "3 clove garlic" on the page. `Scale.unitLabel` now
inflects words (`clove`, `cup`, `bunch`→`bunches`) while leaving
symbols alone, and it applies to the honest note too. No amount of
unit testing would have found this; it needed a recipe with a clove in
it.

### Phase 5 — print templates ✅ done 2026-09-19

The sheet before the shelf. Pure CSS, `@media print`, no JS.

- [x] `src/print.css` — the whole of §09 in one file: greyscale-only
      palette, 11pt body / 14pt step-number floors, the break law,
      physical-unit `@page` margins, and the traceability footer
      fixed to the page box (number · revision · scale · pulled date
      · address).
- [x] `src/Print.elm` — the three forms as a type. `Prep` is
      deliberately *not* a form: it is supplemental and prints
      alongside, so it is a toggle.
- [x] `sheet`, `card` and `booklet`, selected by the recipe's `print:`
      frontmatter and overridable by a picker that sets a class and
      does nothing else.
- [x] The prep card — shopping list, prep tasks, equipment — derived
      entirely from what the recipe already carries. The tasks are
      exactly the ingredients that have a preparation note, so this
      needed no schema change.
- [x] The stale Revision 1 directive in `sheet.css` ("the live site is
      NOT the print surface… generate it with typst") is gone; that
      block now prints the *prose* documents only.
- [x] `scripts/print_test.ts` — 11 tests reading the ink discipline
      out of the stylesheet.

**One serious bug, found by screenshot and not by reading.** A media
query contributes **no specificity**, so the print palette competed
with `theme.css` on selector weight alone — and lost:
`:root:not([data-theme='light'])` scores (0,2,0) against a bare
`:root`'s (0,1,0). **A reader with dark mode on printed a near-black
page.** Every print token override is now `!important`, which is the
only fix that does not depend on which stylesheet the bundler happens
to place last, and a test pins it.

**What is verified, and what is not.** Verified: the palette fix, in a
real browser, as an image; the form classes, prep derivation and
footer contents, against the live DOM; and the ink discipline by
eleven tests that read the real stylesheet. **Not verified: page
counts and laid-out typography.** "A card is one page" and "a booklet
is at most four" are contracts against real paginated output, and no
static read of CSS establishes them. Firefox has no headless
print-to-PDF, so this needs a human with a print preview — which is
also the right way to judge whether a sheet *looks* right on paper.

**To check it by hand:** `deno task dev`, open a recipe, pick a form,
and use the browser's print preview. Toggle the OS to dark mode first
— that is the case that was broken.

### Phase 6 — the shelf (browse, search, filter) ✅ done 2026-09-20

- [x] `src/Shelf.elm` — the index, the four paths, and the filter
      logic as pure functions. `judge` returns a **`Verdict` carrying
      its reasons**, never a filtered list: that type is what makes
      "filters narrow, they never hide" impossible to implement
      wrongly.
- [x] `src/Page/Shelf.elm` — four full-acid tiles, chip trays, the
      active-filter bar, the dense row list, the zero state.
- [x] `src/shelf.css` — the one surface where `--shelf-*` tokens
      belong, and the one place decoration is permitted.
- [x] Recipe search over the index, matching titles **and facets**,
      because "vegan" is a thing people type as readily as click.
- [x] Zero-results copy with the nearest recipe by total time and a
      way out of the filters.
- [x] `tests/ShelfTests.elm` — 21 tests.

**`Page.Home` is deleted.** The shelf replaced it, so the placeholder
was unreachable — and its two `Search.index` entries pointed at
anchors that no longer render. Both removed, and `SearchTests`
repointed at About.

**The front page is no longer in `Search.index`, deliberately.** `/`
is the shelf, and a shelf is not a prose document: no numbered
sections to address, no `Doc` chrome to search from. It carries its
own search over recipes — a different index answering a different
question. The site search now lives only on the two document pages.

**Filters are not in the URL**, the same call as the scale factor.
Mirroring carries a contract that `Main.arrivalMirrors` is the only
record of: a route answering True there **must** issue a
`Nav.replaceUrl` on arrival, or `mirroring` stays set and the next
genuine navigation is mistaken for the shell's own echo. Arriving at
the shelf with no filters has no URL to write, so satisfying that
needs its own pass. Filters reset on navigation meanwhile.

**Verified against the running app:** both recipes listed newest-test
first; selecting SWEET keeps Fridge Pickles on the page struck through
and tagged `Hidden by flavour`; composing a second path empties the
list into designed copy offering Nº 47 at 45 min; clearing recovers
both. The pickles row reads `20min · 2d total` — the twelve-hour-cure
case that §07 calls the most common lie in recipe software, rendering
honestly.

**One bug caught by looking:** the lockout tag read "Hidden by By
flavour", because the tile label ("By flavour") and the prose noun
("flavour") want different words. `Shelf.pathNoun` now supplies the
second.

### Phase 7 — cook mode ✅ done 2026-09-20

- [x] `Route.Cook slug` at `/recipe/<slug>/cook`, its own address so
      it survives a reload mid-cook.
- [x] `src/Cook.elm` — the timer and the wake state, pure.
- [x] `src/Page/Cook.elm` + `src/cook.css` — the arm's-length screen:
      20px-equivalent body, 2.75rem tap targets, the whole step as the
      target, watchpoints kept on screen.
- [x] Step stamping — **stamped, not greyed.** A done step keeps every
      word, because you re-read it to check what you already did.
- [x] Wake lock through a port, reporting what **actually** happened,
      including re-acquisition after the tab is hidden (the spec
      releases the lock then, so without it the lock silently stops
      working the first time you check a message).
- [x] Step timer, the first subscription beyond `sectionSeen` — and
      `Time.every` is subscribed **only while one is running**.
- [x] `tests/CookTests.elm` — 30 tests, 12 of them rendering the
      screen.

**The timer counts to an absolute end, not down a counter.**
`Time.every` is throttled in a background tab, so a decrementing
counter passes every test you would think to write and loses four
minutes the first time you check a message. A test pins the
five-minute-sleep case.

**It makes no sound, and that is a position rather than a gap.** On
expiry it shows the step's own doneness cue: the clock was never the
answer, the tell was (§05). An alarm would be the archive claiming to
know the caramel is done.

**The scale rides in the URL** (`?scale=1.5`), not through
navigation. It is set before you start (§08), so entering cook mode
must not be able to change the quantities — and a half batch becomes
a thing you can bookmark. This is the first use of `Route.withQuery`
and `Route.queryParam`, which had tests but no consumer.

**Build change:** steps now carry `timer` seconds, extracted from the
cue. **A range takes its LOW end** — `6–9 MIN` sets six minutes,
because the timer says when to start *looking*. Anything over an hour
is left alone: a two-day cure is not a thing you stand and watch.

**A wrong diagnosis, recorded because the fix shipped and was
reverted.** Headless screenshots showed every quantity, step number
and cue blank. I read that as JetBrains Mono 700's `font-display:
swap` block period and preloaded the cut — then the symptom persisted
with the preload in place. The real cause is that this headless
browser does not render the data voice at all; the operator's own
screenshot shows `.mono` rendering correctly in a real browser. The
preload was reverted: 22 kB of render-blocking fetch is not worth a
brief FOUT (§12), and it was added on a false premise.

**Verified:** the screen renders, the scale badge reads `SCALED ×1.5`
off the URL, quantities scale, the wake badge reports honestly, a
stamped step keeps its words, a running timer replaces the offer, and
an expired one shows the tell — all through rendered-view tests.
**Not verified interactively:** clicking a step, and the wake lock
against a real device. The browser tooling wedged partway through
this session.

### Phase 8 — cleanup & polish ✅ done 2026-09-20

- [x] **`Page.About` is markdown now**, not retired. The Phase 2
      generator was generalised to a list of documents, so
      `docs/about.md` compiles to `Generated.About` and the page is
      four lines of wiring. **There is no hand-written prose left in
      `src/`.**
- [x] Revision-1 sweep: the last of it was "deep stratum" in
      `theme.css` and `contrast_test.ts`, now "a lit bench" and
      "after dark" per Rev 2 §04. The remaining hits in
      `design-standard.md` are deliberate — they define the absence.
- [x] Motion pass, and `scripts/motion_test.ts` to hold it.
- [x] Payload measured (below).

**The old colophon was lying, which is why this mattered.** It said
"body copy is a system serif" — true when it was written, false since
Phase 3 put Inter in. That is exactly the drift the markdown pipeline
exists to end, and it survived three phases because it was the one
page still hand-written. The new colophon is accurate and generated.

**The motion pass found there was no motion at all.** Zero
transitions, zero keyframes across the whole product, so §10's "zero
ambient motion" held by construction. What was missing was the
*sanctioned* half: the shelf may acknowledge a hand. Added — press
and hover on tiles and chips, under 200 ms, stepped easing — and
authored **inside** `prefers-reduced-motion: no-preference` rather
than overridden outside it, so a reduced-motion reader never has the
transitions defined. `motion_test.ts` fails the build on a transition
outside the guard, on any keyframes, on shelf motion over 200 ms, on
a negative bezier control point (an overshoot), and on a focus
outline hidden behind a motion query.

**A real bug the perf audit surfaced: `/content/*` had no cache
rule.** It is unhashed JSON that changes every time a recipe is
edited, so without a rule it takes Pages' default and an edited
recipe serves stale from the edge — the shelf listing a revision its
document has not caught up to. Now revalidates like HTML, and
`deploy.yml` asserts the rule beside the existing SPA-fallback
guards.

**Payload, measured on a cold visit to `/`:**

| Part | Bytes (compressed) |
|------|-------------------|
| HTML | 1,156 |
| JS | 41,555 |
| CSS | 7,073 |
| Three preloaded faces | 60,012 |
| Shelf index | 790 |
| **Total** | **110,586** |

A recipe adds 2.2 kB. Fonts are 54% of the cold visit, which is the
price of DS-01 §05's four voices and is not negotiable without
dropping one.

**A cost worth naming with its number:** the generated standard is
45.8 kB of Elm source compiled into the bundle, downloaded by every
visitor whether or not they open `/design-standard`. That is the
Phase 2 transport decision, and it stands — fetching it as JSON would
end the `SearchTests` machine-check that was the whole reason for
compiling it in, and Elm has no code splitting to offer instead. Now
recorded with a figure rather than as a shrug.

**Not done:** a Lighthouse run. It needs Chrome, which is not
available here — Firefox is, and has no headless Lighthouse. The
numbers above are measured payload, not field metrics.

### Phase 9 — the bench layout ✅ done 2026-09-20

Four asks, one structure. Equipment-first, a wider page, ingredients
beside steps, and a side nav are not four features — they are the
recipe page splitting on its own natural seam: **what you NEED beside
what you DO.** A sticky left rail carries the equipment and the
ingredients; the right column carries the steps and everything after
them; and the side nav stands apart — real chrome in the viewport's
left margin, outside the centred content, the same geometry as the
document pages' contents rail. The quantities stay in view beside the
step that uses them, which is most of the reason to widen at all.

*(Revised 2026-09-20, against the first mockup: the nav began inside
the rail, above the equipment, and read as part of the ingredients
rather than as navigation. Bench alternatives, then rule from the
bench — DS-01 §13, doing its job.)*

**Provenance:** the CSS and the observer for this are already in the
working tree, uncommitted — 82 lines in `recipe.css` (the 68rem
two-column tier, the sticky rail, the jump-nav styles with the
active-row mark) and 13 in `boot.js` (section tracking extended to
`.recipe section[id]`, skipping zero-height sections so the hidden
prep card cannot pin the rail). None of it is live: no Elm emits
`.recipe-cols`, `.recipe-side`, `.recipe-main` or `.recipe-nav`. This
phase reviews that staging, builds the markup behind it, and makes the
block-order change it implies.

Ruled at this plan:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| Block order | **Equipment moves above Ingredients** in the canonical order — document, print and mobile alike, not only in the rail. Mise-en-place reads gear-first, and at 2–4 lines Equipment does not push the quantities off any fold | Reordering only the wide layout (visual order diverging from document order is two orders to reason about); leaving ingredients first |
| Wide layout | At ≥60rem — the house's one boundary — the page widens to 68rem and splits: 21rem sticky rail + 2.8rem gap + a 44rem reading measure. Below it, everything stacks in document order exactly as today | A wider single column (longer lines, no adjacency win); side-by-side without the sticky rail (loses the quantities-beside-steps payoff) |
| The side nav | **An actual side nav**: an 11rem sticky column in the viewport's left margin, outside the 68rem content, headed by the recipe's number plate — one row per block the recipe actually has, fragment links, the reading-line mark via the existing `sectionSeen` port. Its own width tier at **≥76rem** (nav + gap + the two-column content need the room); between 60 and 76rem the page runs two-column with no nav. **Not `Doc` chrome** — no numbered sections, no clause marks, no search; the Phase 4 ruling that a recipe is not a prose document stands | Inside the rail above the equipment (the first mockup — it read as part of the ingredients, not as navigation); wearing `Doc`; a floating table of contents |

**Is side-by-side too crammed? No, by arithmetic.** 21 + 2.8 + 44 =
67.8rem fits the 68rem page with the steps at the same measure they
read at today. At exactly the 60rem boundary the steps column bottoms
out near 36rem — tighter but comfortably above cramped — and one pixel
below the boundary the whole thing stacks. The rail's ingredient rows
drop their quantity column from 7.5rem to 5.5rem (staged), which is
the cook-mode width and already proven.

**Done. What shipped, and the two things it turned up:**

- [x] DS-01 §06 amended first, as a dated block — Equipment 3rd,
      Ingredients 4th, with the order/presentation distinction stated
      and the bench specimen reordered to match.
- [x] `BLOCKS` swapped; both recipes reordered; `RecipePageTests`
      pins Equipment-before-Ingredients in the **DOM**.
- [x] `Page.Recipe` restructured: `.recipe-nav` as its own region,
      then plate, then `.recipe-cols` → `.recipe-side` (Equipment →
      Ingredients) + `.recipe-main` (everything else).
- [x] Side nav rows derived from non-empty blocks; `Config.active`
      wired from the existing `sectionSeen` tracking.
- [x] CSS rehomed to the ≥76rem outer-margin tier; `scroll-margin-top`
      added so a pasted `#anchor` clears the sticky site nav.
- [x] Print collapses the bench layout explicitly; `print_test.ts`
      holds it.
- [x] `tests/RecipePageTests.elm` — 15 tests.

**The enforcement worked, and exposed its own bug.** Swapping
`BLOCKS` made the build reject both recipes, exactly as intended —
but the message read *"`## Equipment` is out of order — it belongs
**after** Ingredients"*. It belongs before. The check fires precisely
when a block sorts earlier than the one above it, so the block named
is always the one that must move **up**; the wording had been
backwards since Phase 1 and the swap was the first thing that ever
triggered it. Fixed.

**A gap the layout opened.** `Main.jumpTo` measures the sticky chrome
for clicks the shell handles, but the side nav's fragment links can
also be pasted, reloaded on, or reached with the back button — paths
where the browser scrolls, not Elm. `.recipe-block` now carries
`scroll-margin-top`, so a heading never lands under the nav bar
whichever route got it there.

**Verified in a real browser** at 1400px (nav in the left margin,
equipment above ingredients in the rail, steps beside them, History
correctly absent from a Rev 1 recipe) and at 760px (stacked, no nav,
document order). The 60–76rem mid tier is bracketed by those two and
the query is unambiguous, but was not itself screenshotted — the
headless capture kept racing the fetch. **Still wants a human:** that
the rail and nav actually stick while scrolling, and a print preview
confirming the columns collapse.

The work, in order:

- [ ] **The DS-01 §06 amendment first**, per §00's own law: a dated
      amendment block recording the new order (Equipment 4th → 3rd,
      before Ingredients) and why; the blocks table updated to match.
      A sentence distinguishing *order* from *presentation*: the
      two-column tier is layout, and blocks still linearize in
      document order on narrow screens and on paper.
- [ ] `scripts/vocabulary.ts` — swap Equipment above Ingredients in
      `BLOCKS`. The build then rejects both recipes until their
      `## Equipment` sections move up — the enforcement doing its job
      loudly. Reorder both markdown files; add a test pinning the new
      canonical order.
- [ ] `src/Page/Recipe.elm` — the markup the staged CSS is waiting
      for: `.recipe-nav` first (the side nav, its own region in
      `.recipe-layout`), then the recipe — plate full-width, then
      `.recipe-cols` wrapping `.recipe-side` (inner sticky:
      Equipment → Ingredients) and `.recipe-main` (photo → Steps →
      Watchpoints → Rescues → Keeps → Note → History). At ≥76rem
      `.recipe-layout` becomes a two-track grid (11rem nav +
      minmax(0, 68rem) content, centred as a pair); the nav is
      `display: none` below that, so DOM order still linearises
      correctly on narrow screens and paper.
- [ ] The side nav's rows: derived from which blocks are non-empty,
      so it can never offer a dead anchor. The prep card is never
      listed — it is print furniture, not reading matter.
      `Page.Recipe.Config` gains `active : Maybe String`; the shell
      already tracks it (`model.active`, fed by the extended
      observer) and already clears it on navigation. The staged
      `.recipe-nav` CSS in `recipe.css` is rehomed from the in-rail
      form to the outer-margin tier — the mockup carries the exact
      rules.
- [ ] `print.css` — two explicit rules: `.recipe-cols` prints as
      block, `.recipe-nav` does not print. A4 portrait (~49.6rem)
      happens to sit under the 60rem query, but "the paper was
      narrow enough" is not a rule; landscape and legal must not
      print a rail.
- [ ] `print_test.ts` — `.recipe-nav` joins the screen-furniture
      hidden list. Rendered-view tests: nav rows match present
      blocks; the active row wears the mark; Equipment precedes
      Ingredients in the DOM; fragment hrefs resolve to real ids.
- [ ] Verify in a real browser: the rail sticks and scrolls within
      itself past the viewport; jump links land under the sticky
      chrome correctly (`Main.jumpTo` already measures it); the
      active mark follows the scroll; the 60rem collapse; the prep
      card toggle; and a print preview of both recipes, unchanged
      from Phase 5.

**Untouched, deliberately:** cook mode keeps ingredients-then-steps
with no equipment block — "to have out" is the prep card's job, and a
list of pans is not what arm's length is for. The shelf, the
documents and the four print forms are unaffected; the sheet template
simply inherits the new block order.

### Phase 10 — the printed sheet, revision 2 ✅ done 2026-09-21

Phase 5 built the ink discipline — greyscale, the break law, the
traceability footer — and it holds. What it did not build is a page:
the current print is the screen document linearized, and the first
real print run against the recovered source cards showed the gap.
Those cards are the household's proven print grammar (printed, taped
up, cooked from), and this phase carries their four load-bearing
traits into the CSS forms: the gauge strip, the clock-topped step,
the row-aligned ingredient table, and the duplex front/back split.
The screen layout is untouched; this is `@media print` work plus one
schema addition, and the rulings above govern it.

Two bugs ride along because the print run surfaced them:

- **`Scale.unitLabel` pluralizes everything that is not exactly
  `"1"`**, so the sheet reads `¾ cups` and `⅓ cups`. The rule is
  plural only above one: `¾ cup`, `1 cup`, `1½ cups`, and a range
  judges by its high end (`1–2 cups`). The honest-note path inflects
  through the same function and inherits the fix.
- **`print.css` still styles `#history`** on the card form — a block
  that no longer exists. Dead selector, out.

The work, in order:

- [x] **The DS-01 §09 amendment first**, per §00's own law: a dated
      block recording the duplex sheet, the step clock line, the
      ingredient grid, the gauge strip, the chip drop, and the page
      budgets as contract. §06 gains the `gauges:` field beside the
      other frontmatter, marked optional.
- [x] `Scale.unitLabel` — plural iff the amount exceeds one;
      `ScaleTests` pins `¾ cup`, `1 cup`, `1½ cups`, `2 cups`, and a
      scaled note that crosses one in either direction.
- [x] `scripts/recipe.ts` — parse `gauges:`: up to five entries,
      label and value required, note optional, word rules apply
      (a gauge is procedure, not the Note's human voice). One test
      per rule in `recipe_test.ts`; the bench specimen gains a gauge
      strip so every rule is load-bearing.
- [x] `content/recipes/AGENTS.md` — the field documented in the
      schema section and the skeleton; `agents_test.ts` extended if
      the contract states anything the code holds (the entry cap,
      the required halves).
- [x] `src/Recipe.elm` + `src/Page/Recipe.elm` — decode and render
      the strip on the plate, under the facts row: label in the data
      voice, value bold, note dim. Screen and print, one markup.
- [x] `src/print.css`, the forms rebuilt:
      - Ingredients: multicolumn out, the four-track grid in
        (`qty · name · qty · name`), group heads spanning, rules
        aligned because rows are shared. Card keeps a denser variant
        of the same grid, not a third layout.
      - Steps: the cue joins the number line, right-aligned, body
        below — grid placement of existing markup, no Elm change.
      - The sheet form: `#watchpoints { break-before: page }` — the
        duplex split. Booklet keeps its steps-on-their-own-page rule;
        card remains one page and now genuinely fits it.
      - Chips hidden in print; plate padding, block gaps and step
        padding tightened to the budgets; the `#history` selector
        deleted.
- [x] `scripts/print_test.ts` — new pins for everything statically
      readable: no `columns:` in the ingredient rules, the cue's
      print placement, the sheet's break-before, chips hidden, the
      dead selector gone, the existing ink checks untouched.
- [x] `tests/` — rendered-view tests: the gauge strip renders when
      present and is absent when not (never a heading over blank
      space), and the plate carries it on both recipe fixtures.
- [x] Gauges authored for the seventeen real recipes — the numbers
      are already in their prose; this is transcription, not
      invention.
- [x] **Verify from the production build** (`deno task build`, serve
      `dist/`), per the QA ruling: all three forms in print preview,
      OS dark mode on (the Phase 5 regression case), page counts
      against the budgets, and the duplex sheet actually flippable —
      front ends where the back begins.

**Three bugs it turned up, all of them by looking rather than by
reading** — which is the same way Phase 5 found the dark-mode
palette, and the reason this phase's QA rule exists at all:

- **A "COOK THIS" button printed on every sheet.** `.cook-enter` was
  never added to print's screen-furniture list, so under the print
  palette it set as a solid black block with knockout text at the
  foot of the plate. It had been there since Phase 7 and nobody had
  printed a recipe to see it. Now hidden, and the test that lists
  the screen controls names it.
- **Every block carried 31pt of inherited air.** `sheet.css` has a
  bare `section { margin-top: 2.6rem }` for the prose documents, and
  a recipe block is a `<section>` too. Print set `margin-bottom` and
  nothing else, so the element selector governed the top — most of a
  page's worth of dead space across a recipe, while the phase was
  supposedly tightening density. `.recipe-block` now states both
  sides, and a test asserts it states *both*, because setting one is
  exactly how this hid.
- **The gauge strip drew a rule 4pt above the plate's own.** Cosmetic,
  and the kind of thing only a rendering shows: with the chips and
  controls gone, the strip is the plate's last child, so its bottom
  border doubled the plate's. Dropped on paper, kept on screen where
  the controls still follow it.

**What was verified, and how.** Headless Firefox here has no
print-to-PDF (Phase 5 found the same), so the shipped bundle's CSS
was served with its `@media print` blocks rewritten to `@media all`
and rendered against a static fixture carrying the real class
structure — the real rules, the real markup, one media word changed.
That confirms the ingredient rows share baselines across the gutter
when one name wraps, the cue sets beside the step number, a step
with no cue leaves no blank line, the chips are gone, the strip is
ruled and unbroken, and `¾ cup` reads singular beside `2 cups`.
**Still unverified: pagination.** Page counts and where the duplex
break actually lands are contracts against paginated output, and no
amount of rendering a scrolling page establishes them. That needs a
human with a print preview — as it did in Phase 5, and for the same
reason.

**One screen change, after the fact (2026-09-21).** The plate's
controls now sit in a band: the scale and the print form on the
left, **COOK THIS at the right edge**, vertically centred against
the two settings rows. Stacked beneath them the button read as a
third setting, and the right half of the plate sat empty — which the
gauge strip made more obvious by filling that width just above it.
DOM order is unchanged, so the tab order still runs scale → form →
go, and below the wrap the button returns to its own full-width
line. `.recipe-controls` joins the screen furniture that does not
print, as a box rather than only as its children: an emptied flex
row still contributes its gap to the page.

**Otherwise untouched, deliberately:** the bench tiers, the side
nav, the shelf (the user's call: the site reads right, the paper
does not); cook mode; the prep card, which already has its own page
and its own job; and the traceability footer, which was correct from
Phase 5.

**Noted and not carried:** the source cards' cut-here freezer label
strip. Charming, genuinely useful for the casserole set — and
knowing a recipe is a freezer recipe would be inference. If it
comes, it comes as a picker toggle like the prep card: explicit,
never guessed. Logged under Open items.

## Open items

- ~~**Prerendered recipe HTML.**~~ **Closed 2026-09-19, at Phase 5.**
  Revision 1 required reading and printing with JS off; the Rev 2
  rewrite already replaced that with "printing is pure CSS" (§12),
  which the Elm SPA satisfies as written — the print path is an
  `@media print` stylesheet over the rendered document, with no
  print-specific JavaScript in it.

  Ruled explicitly rather than left open: **there will be no second
  renderer.** A TypeScript print renderer beside the Elm one is the
  same failure Phase 2 deleted `design-standard.html` to end — two
  copies with no rule about which wins — and print is where drift
  hurts most, because the sheet outlives the bug. The cost is that
  the site needs JavaScript to render at all, including before a
  print. Accepted.
- **Typst.** If CSS print can't hit the layout quality wanted for
  `booklet` (running headers, precise page control), revisit
  Typst-generated PDFs as a *download* option layered on top. Not a
  replacement for CSS print.
- **Photos at print.** Halftone-at-build (preprocessed asset) vs
  CSS-filter-at-print. Decide on the bench in Phase 5.
- ~~**Example print artifact.**~~ **Closed 2026-09-21, at Phase 10.**
  The reference artifacts were recovered when the corpus was rebuilt
  from them, and the traits worth carrying are now ruled one by one
  in the Phase 10 decision block: the gauge strip, the clock-topped
  step, the row-aligned ingredient table, the duplex front/back
  grammar, and the density that fits a whole casserole on one leaf.
  Not carried: the cut-here freezer label strip (below).
- **The freezer label strip.** The source cards end with a cut-here
  strip — dish name, frozen-on, use-by, reheat line — taped to the
  wrapped pan. Wanting one is a property of the *recipe* (the
  casserole set), and no schema field says so; deriving it from the
  Keeps prose would be inference. If it comes, it is a picker toggle
  like the prep card, and the frozen-on/use-by lines stay blank for
  a pen — a printed date would be the sheet claiming to know when
  you cooked.
- **The results-row storage summary.** DS-01 §07's example row ends
  `KEEPS 14 D` / `FREEZES`, but no frontmatter field carries it and
  the Keeps block is prose. Deliberately left out of the Phase 1
  index rather than invented outside the standard. Phase 6 rules it
  from the bench: either a short `keeps:` field (an amendment to
  §06) or drop the column. The index JSON is regenerated every
  build, so adding it later costs nothing.
- **Ingredient sub-groups.** Parsed (`### For the caramel`) but
  unexercised — the bench specimen has one flat list. The first
  multi-component recipe is the real test, and it will arrive with
  the `booklet` template in Phase 5.
