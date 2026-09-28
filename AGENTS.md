# delishh

A personal recipe archive — browse, search, filter, print — built in
the acid-Y2K idiom: loud shelf, quiet page, black-and-white sheet. Elm + Vite, no Node. The design
language is set out in full in `docs/design-standard.md`; that doc is
the authority on how this looks and why.

## Doc map

| Doc | Owns |
|-----|------|
| `content/recipes/AGENTS.md` | The authoring contract for recipes — schema, vocabularies, block grammar, banned words. **Machine-held**: `agents_test.ts` fails the build if its lists drift from `vocabulary.ts` |
| `docs/about.md` | The colophon — what this is, what it is built from, what is never kept about a reader. Rendered at `/about` |
| `docs/design-standard.md` | DS-01 — look, feel, voice, type, colour, the recipe document, browse, cook mode, print, the word rules, hard constraints. **The prose of record.** |
| `docs/decisions.md` | **The decision record** — every ruling in force, dated, with what was rejected and why, from the Revision 2 reframe through the planner, the install and the facet constraints. Ends with *Open*: what is deferred, and what is outstanding by hand (the install and the planner's picture both still want a pass on a phone). A new ruling is a dated block appended here; the four implementation plans it replaced were dropped 2026-09-28 |
| `docs/decisions-archive.md` | Rulings that were overturned, **as they were made**, with the date and the ruling that replaced them. Never edited; a row moves here from `decisions.md` in the commit that overturns it |
| `docs/facet-constraints.md` | The **digest** of the facet doctrine — how a flavour level, an effort tier, a dietary flag and a cuisine are *decided*, as numbered requirements a review cites. The meal path has none: the only requirement for a meal is food |
| `docs/recipe-review-<date>.md` | One file per review of the corpus against the constraints: what was found, changed and left for the cook, recipe by recipe, citing requirements by number. Appended, never edited; the first is 2026-09-28 |
| `agents/refs/{flavour,effort,needs}.md` | The **verbose** copies of that doctrine, one per judged facet group: every threshold, false friend, hidden carrier and worked case. Read the one for the facet you are setting. **Machine-held**: `doctrine_test.ts` holds their lists to `vocabulary.ts` and the corpus to their mechanical rules |
| `src/sw.js` | The service worker: **`public/_headers`' cache policy, carried onto the device.** Cache-first exactly where `_headers` says immutable; `/content/*` never |
| `src/Prose.elm` | Markdown blocks → the house chrome. **Every styling decision for generated prose lives here**, in hand-written Elm; the generator emits data and knows no class name |
| `src/Page/DesignStandard.elm` | Four lines of wiring: `Generated.DesignStandard` through `Prose` through `Doc`. There is no second copy of the standard anywhere |
| `src/Scale.elm` | The measurement ladder (DS-01 §05) as a pure module. **Where a recipe archive would otherwise lie to you** — see below |
| `src/Page/Recipe.elm` | The nine blocks of DS-01 §06. Deliberately does **not** wear `Doc` |
| `src/print.css` | **All of DS-01 §09.** The four printed forms, the ink discipline, the break law, the traceability footer |
| `src/Shelf.elm` | The four browse paths and the filter logic (DS-01 §07), pure. `judge` returns a verdict **with its reasons** |
| `src/Cook.elm` | The step timer and the wake state (DS-01 §08, §10). The timer counts to an **absolute end**, never down a counter |
| `src/Plan.elm` | The week, pure. **The shape is private**: pages go through its API so the expansion lands here, not in the shell |
| `src/Liner.elm` | The backing paper and the leaf (DS-01 §04 as amended 2026-09-23). `on` is the one place that says which routes get the liner (every one but cook mode); `leafKey` is what makes a navigation a new sheet |

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

- `deno task content` — recipes → JSON, prose → generated Elm, both validated; the manifest from `theme.css`, the worker from `src/sw.js`
- `deno task dev` — content, then the Vite dev server
- `deno task build` — content, then production build to `dist/`
- `deno task test` — content, the validator's tests, then elm-test-rs
- `deno task test:content` — the validator's tests alone
- `deno task deploy` — build, then `wrangler pages deploy dist`
- `deno task icons` — the home-screen PNGs from `public/icons/icon.svg`. Needs `resvg` on PATH; the PNGs are committed, so only a redrawn icon needs it

`content` runs first in `dev`, `build` and `test` alike. That is
deliberate: `test` is the one gate both CI workflows share, so content
that violates DS-01 fails the pull request rather than surfacing as an
empty page in production. It is also a hard dependency — `src/Generated/`
must exist before `elm make` runs.

## The content pipeline

Markdown is the source of record for both recipes and prose.
`deno task content` parses and validates it into two generated,
gitignored trees that are never edited by hand:

| Source | Generated | Transport |
|--------|-----------|-----------|
| `content/recipes/*.md` | `public/content/*.json` | Fetched at runtime — a growing corpus does not belong in the bundle |
| `docs/*.md` (the standard, the colophon) | `src/Generated/*.elm` | Compiled in — see below |
| `src/theme.css` | `public/manifest.webmanifest` | Its two colours are hexes, and `theme.css` is the only place one may live |
| `src/sw.js` | `public/sw.js` | A build stamp substituted in: a new worker, and a new cache name, every build |

**Why prose compiles in and recipes do not.** A document that ships
*with* the app is not a corpus. Generating Elm keeps
`Page.DesignStandard.view` a pure function of chrome, which is what
lets `tests/SearchTests.elm` keep holding every search term to the
rendered page — the machine-check that has stopped the hand-written
index rotting. It also avoids `elm/http` and a loading state on a page
whose only job is to be read.

- `scripts/vocabulary.ts` — **data only.** Every closed facet list
  (slot, course, flavor, method, effort, dietary, cuisine), the units
  and their kinds, the fixed block order, and the word rules. A new
  flavour is one line here and nowhere else; that friction is the
  point, because it is what stops a filter chip being backed by a
  typo. A recipe's identity is its **slug** — filename, URL, and the
  name on the printed footer; there is no serial number and no
  revision counter (both retired 2026-09-21: hand-maintained metadata
  nothing forces to move is metadata that can lie, and git is the
  change log).
- `scripts/recipe.ts` — `parseRecipe`, a pure function. **This module
  decides what a recipe is**, and everything downstream is a view of
  what it returns. Frontmatter is the schema (facets, times, yield);
  the body is the nine blocks of DS-01 §06 in fixed order.
  Frontmatter also carries the optional **gauge strip** — up to five
  hand-authored operating numbers (the pan, the oven, the temperature
  it is done at) that head the plate and the printed sheet. They are
  *authored, never derived*: every one is already somewhere in the
  prose, and picking which number matters is a judgement, not an
  inference. That is what separates them from `revision:`, which was
  retired for being metadata nothing ever checked — a wrong gauge
  fails the cook the same way a wrong step does. Frontmatter also
  carries the optional **keeping life** — `keeps: freezer 3mo`, a
  place and a duration, never one without the other. The place is
  mandatory because most of this corpus states a freezer life and no
  fridge one, and a bare `3mo` at the end of a shelf row reads as a
  claim about the dish in a fridge; absent means *not stated*, never
  *does not keep*. It is authored beside the Keeps block, never read
  out of it, and the build rejects a life with no block to act on.
- `scripts/build-content.ts` — walks the corpus, runs the checks that
  need every file at once (photos exist on disk), refuses a dietary
  flag that an item's `breaks` in `scripts/pantry.ts` defeats — the
  table only ever says no; it never adds a flag — and
  writes the JSON. **Collects every problem before exiting**; writes
  nothing on failure. A validator that stops at the first fault
  trains you to distrust its "all clear".
- `scripts/recipe_test.ts` — one test per rule, over the bench
  specimen as fixture. The rules are regexes, and a regex without a
  test stops being enforced the first time someone edits it.
- `scripts/markdown.ts` — a parser for **exactly the subset DS-01
  uses**, and it should never become a general markdown
  implementation. It rejects what it does not understand rather than
  dropping it, because a silently-dropped construct is missing prose
  on a published page.
- `scripts/build-docs.ts` — every prose document → a module under
  `src/Generated/`. The list is the `DOCUMENTS` const at the top;
  adding a page is a line there and a markdown file. **There is no
  hand-written prose page left in `src/`**, which is the point: a
  page you can edit in two places disagrees with itself eventually —
  the old About colophon claimed the body voice was a system serif
  for three phases after it stopped being one. The masthead rides in
  the document's frontmatter; each section's anchor, rail label,
  intent and body kind ride in a `<!-- doc ... -->` comment beneath
  its heading, which markdown renders as nothing.
- `scripts/docs_test.ts` — the generator's guards, over DS-01 itself.
- `scripts/agents_test.ts` — holds `content/recipes/AGENTS.md` to the
  code, both directions: every vocabulary list, the block order, the
  skeleton's order, the unit kinds, and that every banned word it
  names actually trips a rule — a warning about nothing teaches
  authors the contract exaggerates. It also asserts the build skips
  AGENTS.md, which would otherwise be parsed as a recipe and fail the
  slug check.
- `scripts/contrast_test.ts` — reads the real hexes out of
  `theme.css` and recomputes every foreground/background pair in both
  themes. **It also holds each ratio written in a comment to the hex
  beside it**, because those numbers are how the next person decides
  whether they have headroom to darken something, and a comment that
  lies is worse than none. Adding a colour role means adding its pair
  here; a role with no pair is a colour nobody has checked.
- `scripts/motion_test.ts` — the motion register (DS-01 §10). Fails
  on any keyframes, on a transition authored **outside**
  `prefers-reduced-motion: no-preference`, on shelf motion over
  200 ms, on a negative bezier control point (an overshoot), and on a
  focus outline hidden behind a motion query.
- `scripts/storage_test.ts` — counts the `localStorage` keys
  `boot.js` declares and holds the colophon's and DS-01 §12's "N
  things are stored" to it. A fourth key cannot arrive unnamed. It
  also holds the worker to **one** cache, `delishh-archive`, which
  both documents name as *a copy of the archive* — not a key, and not
  about the reader, but bytes on their device all the same.
- `scripts/pwa_test.ts` — the install: the manifest's scope and
  colours, every icon on disk at its claimed size, the head's links,
  the theme-color metas held to `--stencil-bg`, the revalidate rules,
  and the worker's cache-first list held to `_headers`' immutable
  paths — so `/content/*` can never be served stale by the device.
- `scripts/plan_slots_test.ts` — the planner's labels held to the
  recipes' `SLOTS`, and its five-a-day cap held to their count.
- `scripts/share_test.ts` — the meal plan's picture, which is the
  one place colour and type are drawn from JavaScript: no raw hex, no
  family spelled, every token it reads declared, every pair it draws
  checked, and share and copy kept inside the press.
- `scripts/fonts_test.ts` — the font wiring. Misspell a family between
  `@font-face` and its `--font-*` token and nothing breaks: the stack
  falls through to a system face, the page renders, and DS-01's type
  casting is silently void.
- `scripts/doctrine_test.ts` — the facet constraints
  (`docs/facet-constraints.md` and `agents/refs/*.md`) held to
  `vocabulary.ts`, the same way `agents_test.ts` holds the authoring
  contract, and the corpus held to the doctrine's *mechanical* rules:
  every flavour carries a level, at most four words and two at `3`,
  the three effort anchors carry the tiers they anchor, at most two
  cuisines. The judgements themselves — a level, a window count, a
  verified flag — are a person's, at the tested cook, and are not
  here. Needs N3 (a `vegetarian` recipe also carries `pescatarian`)
  is held over the corpus too, since the first review (2026-09-28).

Five rules that are easy to break without noticing:

- **Motion is authored inside the guard, never overridden outside
  it.** `@media (prefers-reduced-motion: no-preference)` wraps the
  transition; there is no un-guarded transition that a media query
  then cancels. The difference is invisible until someone adds a
  property to a transition list and forgets the override — at which
  point a reader who asked for stillness gets exactly one thing
  moving. Focus outlines are the opposite: always unconditional,
  because they are not decoration.


- **Section numbers start at 00 and are positional.** `Doc.sectionNum`
  renders `i`, DS-01's headings are written `## 00.` onward, and
  `build-docs.ts` fails the build if the two disagree. Clause marks
  derive from the same `i`, so §04's first clause is §4.1 — numbering
  the header and the clauses from different bases is a bug that has
  already happened once.

- **Acid tokens are named by layer, and the name is the rule.**
  `--shelf-*` are fills for browse surfaces, where decoration is
  allowed; `--page-*` are marks for recipe surfaces, where it is not.
  A `--shelf-*` token inside a recipe page is a bug, and so is a
  `--page-*` token used as a background — that is the entire reason
  they are not one set of four (DS-01 §04). `--accent` is the
  actionable role and aliases `--shelf-act`.

- **The side nav's rows are derived, never listed.** They come from
  which blocks are non-empty, so the nav cannot offer an anchor that
  resolves to nothing — the corpus contains both shapes (a Rev 1
  recipe has no History). The prep card is never a row: it is
  furniture for paper.

- **Nothing is ever inferred.** An absent dietary flag means "not
  verified", never "not suitable"; an absent photo means the block is
  gone, never a placeholder. Guessing on the reader's behalf is how a
  recipe archive becomes untrustworthy.
- **The Note block is exempt from the word rules, unconditionally.**
  The checker does not read it. Sanding down the one human voice on
  the page to match the machine would destroy the thing the design
  exists to frame (DS-01 §01, §11).

All four voices of DS-01 §05 ship self-hosted. Swapping a face means
four places, and `fonts_test.ts` fails if you miss one: the `.woff2`
under a **new** filename (`/fonts/*` is cached immutably), its OFL
text beside it, the `@font-face` in `fonts.css`, the `--font-*` token
in `theme.css` — plus a `<link rel=preload>` in `index.html` only if
it is above the fold, and `public/404.html` if that page uses it.

`scripts/fixtures/bench.md` is the **bench specimen** — the one
document every parser rule is load-bearing on, and the fixture the
validator's tests mutate. It lives with the tests, not in the
corpus: the corpus is the cook's and its recipes come and go; the
fixture must never drift under the suite. Keep it parsing.

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
  from that list, so they cannot disagree with it. For DS-01 the
  generator also checks each `## NN.` heading against its position, so
  a reordered section fails the build instead of silently repointing
  every in-prose `§`.
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
- `src/Recipe.elm` / `src/Page/Recipe.elm` — a recipe, fetched and
  rendered. **The bench layout** (DS-01 §06 as amended 2026-09-20):
  Equipment precedes Ingredients *in the document*, not merely on a
  wide screen — an order that exists only in CSS is two orders to
  reason about. Three tiers: ≥76rem puts the side nav in the
  viewport's left margin outside the content and splits the recipe
  into a sticky what-you-NEED rail beside what-you-DO; 60–76rem keeps
  the split without the nav; below 60rem everything stacks in
  document order, which is also what paper gets. **The page does not wear `Doc`**: `Doc` frames prose
  documents with numbered sections and citable `§N.M` clause marks,
  and a recipe is a different object — its nine blocks are a fixed
  form, not a specification. Giving them clause marks would be the
  "controlled document" register Revision 2 dropped. An empty block
  is absent, never a heading over blank space.
- `src/Scale.elm` — **the one place the product could quietly be
  wrong.** Multiply 3 eggs by 1.5 and the arithmetic says 4.5, which
  is not a thing you can put in a bowl. Rounding it to 5 is right;
  rounding it *silently* is the bug. Every indivisible count that
  gets rounded carries a note saying what the arithmetic actually
  wanted. Two more rules that look like rounding and are not:
  **×1 is identity** (the original text verbatim, so a recipe nobody
  asked to scale is never quietly re-rounded), and **nothing ever
  rounds to zero** (an ingredient that vanishes on a half batch still
  leaves a page that looks correct).
- `src/print.css` — **the whole of print, in one file.** The forms
  are classes on the recipe wrapper set by a picker that does nothing
  else; there is no print-specific JavaScript anywhere, and
  `print_test.ts` fails the build if `boot.js` grows a `beforeprint`
  hook. Four rules that are not obvious:
  - **Every print token override is `!important`.** A media query
    contributes no specificity, so the print palette competes with
    `theme.css` on selector weight alone and loses —
    `:root:not([data-theme='light'])` is (0,2,0) against a bare
    `:root`'s (0,1,0). Without it, a reader in dark mode prints a
    near-black page. Matching the dark selector's shape instead
    would work only while `print.css` stays last in the bundle.
  - **`.form-sheet` carries exactly one rule: the duplex break**
    (`#watchpoints { break-before: page }`, added 2026-09-21).
    Everything else in the file *is* the sheet; that one rule is
    what makes it a two-sided leaf — procedure on the front,
    recovery on the back — and the card and booklet both opt out
    explicitly.
  - **Ingredients are a grid on paper, never `columns:`.** A flowed
    column balances by height, so one wrapped name drifts the two
    stacks apart and every hairline stops at the gutter. `.ing-list`
    sets two equal tracks and the rows share a baseline, which is
    the only reason to draw the rules at all. A test forbids
    `columns:` coming back.
  - **A print rule must state every side of a box it cares about.**
    `sheet.css` carries a bare `section { margin-top: 2.6rem }` for
    the prose documents, and a recipe block is a `<section>` too. A
    class beats that element selector only for properties it
    actually names — setting `margin-bottom` alone silently left
    ≈31pt above every block on the sheet.
- `src/Shelf.elm` / `src/Page/Shelf.elm` — the front page. **The
  loudest surface in the product**, and the only one where
  `--shelf-*` tokens and decoration belong. Two things worth knowing:
  - **`judge` returns `Verdict`, not a filtered list.** DS-01 §07
    says filters narrow but never hide: an excluded recipe stays on
    the page wearing the filter that excluded it, because a
    silently-vanished result means you cannot tell "nothing matches"
    from "I mis-set something three clicks ago". Returning the
    reasons is what makes that impossible to implement wrongly.
  - **`pathLabel` and `pathNoun` are different words on purpose.**
    The tile says "By flavour"; a lockout tag says "Hidden by
    flavour". Using one for both reads "Hidden by By flavour".
  - **`marks` and `matchesQuery` read the same `needles`.** The
    highlight in a row is a view of the judgement, not a second
    opinion about it — a mark derived from its own notion of
    "matches" would fill letters the filter never acted on, which is
    the view lying about the reader's own query. It also refuses to
    mark anything when case-folding changes a string's length: the
    wrong letters filled is worse than none.
- `src/Cook.elm` / `src/Page/Cook.elm` — cook mode, at
  `/recipe/<slug>/cook`. Four things that look like details and are
  not:
  - **The timer counts to an absolute end**, not down a decrementing
    counter. `Time.every` is throttled in a background tab, so a
    counter passes every test you would think to write and loses four
    minutes the first time the reader checks a message.
  - **`Time.every` is subscribed only while a timer runs.** The rule
    this shell has carried since the start — a subscription only when
    something genuinely changes on its own — and a running duration
    is DS-01 §10's *one* sanctioned piece of motion.
  - **The wake badge reports what actually happened.** boot.js sends
    back `held` / `unsupported` / `refused` / `off`, and each reaches
    the reader as its own sentence. "Screen held" on a browser that
    refused is how you find out with your hands covered in flour.
    The lock is also re-taken on `visibilitychange`, because the spec
    releases it whenever the document hides.
  - **The scale rides in the URL**, not through navigation. It is set
    before you start, so entering cook mode cannot silently change
    the quantities — and a half batch is bookmarkable.
  - **The rail's rows are derived, like the recipe page's**, and its
    steps are numbers rather than sentences — a rail that repeated
    twelve step texts would be the document again. Done fills the
    chip: *filled against outlined* is a shape, not a colour, and the
    chip also says ", done" to a screen reader. `boot.js` matches
    `.cook-layout li[id]` as well as `section[id]`, because the
    finest thing to be inside here is a step and a step is a list
    item. **`Main.stickyChromeHeight` measures `#cook-head`** — it is
    the tallest sticky chrome in the product, and an anchor that
    ignored it would land every step underneath the scale badge.
  - **Rescues are on this screen, last.** Watchpoints are the limits
    you hold to while it is going right; a rescue is for after it has
    not, and nobody exits cook mode to find the document with a pan
    smoking. Keeps and the Note stay on the document — one is for
    after the cooking, the other is for reading.
- `src/Search.elm` — the site index. Hand-written, machine-checked:
  `terms` must appear in the section they claim, `aliases` must not.
  The query lives in the model, never the URL, and any real
  navigation clears it. **The front page is not in this index**: `/`
  is the shelf, which is not a prose document and wears no `Doc`
  chrome. It carries its own search, over recipes rather than
  sections. `Doc` takes a `Chrome` (active section +
  query + handler); a non-empty query replaces the sheet's sections
  with results.
- `src/Plan.elm` / `src/Page/Plan.elm` — the week at `/plan`.
  Three things that are easy to undo:
  - **`savePlan` needs a caller the compiler can see.** Elm drops an
    unused port, and `boot.js` subscribing to a port that is not
    there throws at boot — the whole site. `Main.readPlan` discarding
    an unreadable store is a real caller; do not remove it without
    another.
  - **Enter never picks a match.** The entry field is a form so
    Enter keeps the typed words; a match is always its own press.
    Typing a recipe's name never becomes that recipe by itself.
  - **The picker's rule is `Plan.placeRecipe`**, tested there: a day
    with this recipe gives it up, any other day takes it at the end,
    a full day refuses with `DayFull`. Nothing replaces any more.
    After placing, a label row offers the five slot words and None;
    the recipe's own slots are marked, and **none is preselected**.
  - **A day is a list of up to five entries** (the expansion, done
    2026-09-27). The pages and the picture read `entries` and write
    `add`, `remove`, `label` and `moveEntry`. The one-meal `get` /
    `set` / `move` survive only as test fixtures' shorthand; no page
    calls them, and new code should not. Label marks show only on a
    day of two or more, or on a meal that already has one.
  - **A week of one meal a day draws the first planner's picture,
    pixel for pixel.** The height budget (one phone screen, then two
    type steps, then taller) never triggers for it. If you touch the
    drawing's geometry, re-run the pixel comparison recorded in docs/decisions.md
    before claiming the one-meal picture is unchanged. Labels are the recipes'
    `SLOTS`, held by `scripts/plan_slots_test.ts`.
  - **The shared picture is drawn by `boot.js`, from tokens.** No hex
    and no font family is written there; `share_test.ts` holds it,
    and holds every text pair it draws to `contrast_test.ts`. A draw
    carries a generation number, and `boot.js` discards any draw that
    is not the one wanted. Share and copy must be called before
    anything is awaited, or Safari refuses them outside the press.
- `src/sw.js` / `src/Reach.elm` / `src/Install.elm` — the install (`docs/decisions.md`).
  Three things that are easy to undo:
  - **Test offline by stopping the server**, never with DevTools'
    offline switch: it does not reach the worker's own fetches, and
    `vite preview` answers a missing path with `index.html` at 200,
    which Cloudflare never does. The two together fake a failure
    production cannot have.
  - **A failed fetch says why.** `Reach.fromHttp` turns the error
    into Missing / Unkept / Unreachable / Broken, and each page has a
    sentence per reason. *No such recipe* for a kitchen with no
    signal is the page guessing. The worker's `503` is what makes
    *Unkept* knowable; a static host never sends one.
  - **Registration is production-only.** In dev a worker would cache
    Vite's unhashed modules and fight HMR.
  - **The install press is drawn from capabilities.** `Install.elm`
    has three answers — the browser's dialog, Safari's share sheet,
    nothing — and `boot.js` finds them from `beforeinstallprompt` and
    `navigator.standalone`, never the user agent (`pwa_test.ts`). It
    never appears in dev: Chrome offers only with a worker. `prompt()`
    is called before anything is awaited, or it is refused.
- Two ports exist: `saveTheme` (out) and `sectionSeen` (in). The
  second is a port because `elm/browser` has no scroll subscription;
  boot.js reads the active section on scroll, resize and DOM
  mutation, rAF-throttled. The active style must never affect layout,
  or marking a section could move it.
- `src/Liner.elm` / `sheet.css` — the backing paper. Every route but
  cook mode is a **leaf** (a `--surface` sheet with a `--rule-soft`
  edge, class `leaf` on each page's column) laid on a **liner** fixed
  to the viewport. Four things that are easy to undo without noticing:
  - **`body` has no background.** `html` is the canvas and the liner
    sits at z-index −1 between it and every in-flow block; a body fill
    paints straight over the paper and nothing fails.
  - **The liner drifts, and it is the only thing that does.** The one
    keyframes block in the product rides the liner's rows, so it
    reaches exactly the routes `Liner.on` names and never cook mode.
    The leaf holds still; the margin is not the page. `motion_test.ts`
    holds the drift to that one block, inside the guard, at 45 s a
    cycle or slower.
  - **The leaf lands as a `box-shadow`, never a transform.**
    `Main.jumpTo` measures the anchor in the frame the page renders,
    so a leaf that arrived translated would put every deep link a few
    pixels low. `Main.view` keys the page on `Liner.leafKey`, which is
    what lets `@starting-style` see a fresh leaf.
  - **Neither prints**, and `print_test.ts` holds it: a fixed element
    prints on every page.
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
  live, and since 2026-09-27 electric blue = time, lilac = gentle heat,
  yellow = work. The three new ones map to **no method yet**; that
  is a separate decision per method. One acid dominates per surface,
  a second may cameo, never three — except the recipe page's action
  row, which holds exactly three faces (list, plan, cook). **Acid never lands on a quantity**, and **information is
  never colour-only** — a thermal class carries its word as well as
  its mark, which is the same rule that makes the black-and-white
  printout work.
- Four type voices, strictly cast (DS-01 §05): Archivo Expanded 700
  display, Inter 500 procedure, JetBrains Mono data, Instrument Serif
  human. The human voice is never used for procedure.
- Wide content (reference tables, grids) scrolls inside its own
  `.doc-scroller`; **the page body never scrolls sideways.**
- `public/404.html` must exist and `public/_redirects` must stay free
  of a **root-level** wildcard: together they keep Cloudflare Pages'
  SPA fallback off. Deleting either serves `index.html` as
  `text/html` for missing hashed assets, and `public/_headers` then
  caches that mistake for a year. CI fails the build if you break it.
  The one permitted wildcard is `/recipe/*`, because a recipe's slug
  is *content* and adding a recipe must not mean editing a redirect
  file. It is safe for the reason the bare `/*` is not: hashed assets
  live under `/assets/`, and nothing but a recipe address can ever
  fall into `/recipe/`.
- `public/_headers` gives `/content/*` a **revalidate** rule, the
  mirror of `/assets/*`'s immutable one: hashed things may be
  immutable *because* their name changes with their content, and the
  generated JSON cannot. Without it an edited recipe serves stale
  from the edge and the shelf lists a revision its document has not
  caught up to. CI asserts the rule.
- `public/404.html` inlines a subset of `theme.css`'s tokens by hand
  — it cannot link the hashed bundle. Change a colour in one, change
  it in the other.

## Not yet in force

- **Step stamps do not survive a reload.** They live in the model, so
  a refresh mid-cook loses which steps are done. Persisting them
  needs a port and a storage key; the wake lock means you should not
  be reloading, which is why it has not been built.
- **The shelf flashes a loading state.** The index is fetched like
  any recipe, so the front page shows "Opening the archive…" for one
  round trip. Instant locally; worth revisiting if the corpus grows
  enough that the index does too.
- **Printed page counts.** "A card is one page", "a booklet is at
  most four" are contracts against real paginated output, and no
  static read of the CSS establishes them. `print_test.ts` checks
  everything that *can* be read out of the stylesheet and says so in
  its header; the rest needs a human with a print preview.

