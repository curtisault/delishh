# Design Standard — DS-01

> **delishh** · a personal recipe archive — browse, search, filter, print
> Document DS-01 · Revision 2 · Issued 2026-09-19 · Status: IN FORCE
>
> The aesthetic contract for delishh. This doc owns *look, feel, and
> voice*. Where a mechanic and the aesthetic disagree, we redesign the
> mechanic's presentation — never the aesthetic.
>
> Revision 2 is a wholesale reframe. Revision 1 borrowed another
> project's institutional register; this revision replaces it with
> delishh's own premise (§01) and keeps only what earns its place in a
> recipe archive: the measurement discipline, the print rigor, and the
> honesty rules.

---

## 00. Scope, and where things live

This standard covers a single-operator recipe archive: a place to keep
recipes, find them again, and print them. The idiom is **acid-Y2K** —
flat, printed-looking vector graphics, acid color on clean neutrals,
total confidence, zero irony — applied toward *fun*: the site should
feel like something you enjoy opening, not something you consult.

| File | Owns |
|------|------|
| `docs/design-standard.md` (this doc) | Look, feel, voice, color, type, the recipe document, browse, cook mode, print, hard constraints. **The prose of record — rendered in-app; there is no separate frozen HTML copy.** |
| `docs/delishh-redesign.md` | The implementation plan for this revision, with its dated decision log |
| `content/recipes/*.md` | The recipes themselves — one markdown file per recipe, frontmatter as the schema of record (§06) |
| `scripts/` (build) | Enforcement: schema validation and the word rules run at build time, in CI |

One governing rule: **if build reality contradicts a decided rule, you
write the dated amendment first and change the code second.** Never
diverge silently.

---

## 01. The premise — loud shelf, quiet page

**The one-line vibe:** a shelf of recipes that looks like a sticker
sheet and reads like a lab notebook — loud where you're choosing,
quiet where you're cooking, pure ink where you're printing.

delishh runs on one deliberate split, and every rule below is a
consequence of it:

- **The shelf is loud.** Browsing, searching, and choosing what to
  cook is the fun part, and the interface treats it that way: acid
  color used generously, chunky type, flavor chips like stickers,
  category tiles you *want* to press. This is where the Y2K energy
  lives.
- **The page is quiet.** Once you've opened a recipe, the chrome
  calms down. Quantities, temperatures, and times are the loudest
  things on a recipe page, and they are set in ink-dark mono on a
  calm field so nothing competes with the data you cook from.
- **The sheet is ink.** The printed recipe is black and white, built
  for a home laser, legible at arm's length on a counter, and
  designed to be destroyed and reprinted (§09).

There is no in-fiction company and no institutional voice. delishh
speaks as itself: warm, direct, precise. Structural touches — every
recipe carries a number, a tested-on date, and a revision history —
survive because they're *useful* (they make search, traceability, and
the printed footer work), not because a fiction requires them. A
recipe number is a collector's plate, not a compliance artifact.

The one human register the design protects: **your note.** Every
recipe ends with a personal note in a serif, in sentence case, in the
first person, unedited. On a page where every number is exact, the
note is the reason the archive is yours.

---

## 02. Design pillars

### 2.1 Printed, not simulated

Every graphic element reads as a **flat printed artifact**: a sticker,
a label, a chip, a plate, a tab. Flat color, hard edges, no bevels, no
soft shadows, no gloss. Depth comes from layering and overlap, never
from lighting. If it couldn't be silk-screened, it doesn't ship.

### 2.2 Loud shelf, quiet page

Color budget follows the split from §01. Browse surfaces may run
loud — tiles, chips, and plates in full acid. Recipe reading surfaces
run calm: neutral field, acid as accent marks only, and **acid never
lands on a quantity** (§04). Print surfaces are black and white, full
stop.

### 2.3 Precise where it counts

The playfulness never touches the data. Quantities are exact,
mass-first, and scalable (§05). Temperatures are dual-unit. Every
duration carries its doneness cue. Total time never hides an
overnight hold. Fun is a register, not an excuse.

### 2.4 The recipe is the hero

A recipe is a document with a fixed structure (§06), not a blog post
with a story on top. Ingredients above the fold. No SEO preamble, no
"jump to recipe" button apologizing for a layout that shouldn't
exist. The personal note lives at the bottom, where it's a reward.

### 2.5 Everything states its own use

A step states its own temperature and its own doneness cue on its own
line. A filter chip states what it excludes. A pan is named with its
diameter and material because those change the result. If an element
needs external explanation, its design has failed.

### 2.6 Designed, never broken

The interface is immaculate by intent. No simulated coffee rings,
torn-paper edges, or distressed "vintage recipe card" textures —
that's nostalgia cosplay. The screen never ages. The printed sheet
does — in your kitchen, honestly, and then you reprint it.

---

## 03. Reference points, and the anti-references

| Source | What to take |
|--------|--------------|
| Y2K software & hardware | Candy-bright UI chrome, chunky progress bars, installer-density layouts, translucent-plastic color as *reference only* |
| Sticker sheets & fruit labels | Die-cut shapes, saturated flat color, small-format type discipline, the joy of a good chip |
| The Designers Republic / Wipeout | Aggressive grotesk typography, graphic systems applied with total confidence |
| Nutrition panels & spice-jar labels | Dense typographic tables that are legally obliged to be legible; a whole taxonomy on 40 mm |
| Test-kitchen documentation | Stated tolerances, doneness cues, published failure modes — a recipe as a tested procedure, not an anecdote |

**Explicitly not:**

- **Not a food blog.** No origin story above the fold, no marketing
  copy, no engagement bait.
- **Not rustic farmhouse.** No kraft paper, twine, chalkboard,
  reclaimed wood, or handwriting fonts. Warmth comes from the content
  and the color, not the texture.
- **Not dark-moody restaurant photography.** The photograph is a
  record of what you made, not a seduction.
- **Not minimal-Scandinavian.** delishh is dense and colorful on
  purpose. Spareness shows up only where the data needs quiet.
- **Not vaporwave, and never ironic.** The color is loud because food
  is fun, not as a joke about the year 2000.

---

## 04. Color — two layers, one honesty rule

The palette is four acids on a cold-neutral field, in light and dark
themes. What changed in Revision 2 is *where* acid is allowed, split
by the two layers from §01.

| Token | Hex | Reads as |
|-------|-----|----------|
| `--acid-volt` | `#B9EE00` | The actionable — the primary verb on any surface |
| `--acid-cyan` | `#00C8DC` | Cold — chill, freeze, set, raw, fresh |
| `--acid-orange` | `#FF6A00` | Heat — fry, sear, sugar work, anything that burns |
| `--acid-mag` | `#FF2E88` | Live & sweet — ferment, proof, culture; the dessert end of the shelf |

### The browse layer — decoration allowed

On shelf surfaces (home, browse paths, search results), acid is
generous and *may* be decorative: flavor chips, meal-slot tiles,
category plates all take full color. Rules that still hold:

- **Every colored chip carries its word.** A magenta chip that says
  nothing is confetti; a magenta chip that says SWEET is navigation.
  Information is never color-only — on any surface, ever.
- **Contrast is measured, not assumed.** Acid fills take ink text;
  colored text uses the darkened text variants (`--volt-tx` `#3E5200`,
  `--cyan-tx` `#05555F`, `--orange-tx` `#8C3200`, `--mag-tx`
  `#9C0B4A`), every pair verified at 4.5:1 in both themes.

### The procedure layer — color means physical state

Inside a recipe's ingredients, steps, watchpoints, and storage
blocks, color narrows to function. An acid appearing in procedure
marks a **physical state of the food**: orange = heat/hazard, cyan =
cold chain, magenta = live culture, volt = the action to take now.

- **Acid never lands on a quantity.** Amounts, temperatures, and
  times are set in ink — the color lives in labels and structure,
  never in the data. This is the rule that makes a dense page
  trustworthy.
- **One acid dominates a recipe page; a second may cameo; never
  three.** The shelf can be a riot; the page cannot.

### Themes

Light and dark are the viewer's choice (System/Light/Dark, already
wired through `boot.js`). Light is a lit bench: near-white field, ink
text, acid as fills-with-ink-text. Dark is the same system at night:
near-black field, acid at full strength. Same tokens, same swap
mechanism, both themes verified independently.

---

## 05. Type, and the measurement ladder

Four voices, strictly cast. A glyph's typeface tells you what *kind*
of information it is, every time.

| Voice | Typeface | Used for |
|-------|----------|----------|
| **Display** | Archivo Expanded 700 | Titles, plates, tiles, section marks |
| **Body** | Inter 500 | Every word you read while cooking |
| **Data** | JetBrains Mono 400/700 | Every number that means something |
| **Human** | Instrument Serif 400 | Your notes, and nothing else |

The human voice is never used for procedure; the data voice is never
used for prose. A fifth voice is a cost delishh doesn't pay.

> Repo note: `public/fonts/` currently ships Archivo Expanded and
> JetBrains Mono only. Inter and Instrument Serif must be added, with
> their OFL files, before §05 is fully in force.

### The measurement ladder

Quantities get as much specification as color does. Ruled once,
enforced in the build:

- **Mass is authoritative; volume is a convenience**, printed second,
  dimmed. Grams as integers; no `142.5 g`.
- **Fractions are glyphs** (¾ tsp), never decimals, for volume.
  Decimals are for mass and temperature only.
- **Scaling rounds per unit** — to 5 g above 100 g, to ¼ tsp, to
  whole grinds — and **never produces a fractional egg, can, or
  clove.** When it would, the system emits a note instead:
  `SCALED ×1.5 — USE 2 EGGS, HOLD BACK 20 g OF THE WHITE.` An honest
  note beats a false number.
- **Temperatures are dual and consistently ordered** (180 °C /
  356 °F), authoritative unit first.
- **The clock is never alone.** Every duration carries its tell:
  `6–9 MIN · UNTIL THE EDGES RUN CLEAR`. Time is the least reliable
  variable in any kitchen; a recipe that gives only a number is
  withholding the thing you actually need.
- **Tabular numerals everywhere**, and a running timer must never
  shift layout by a pixel as it counts.

---

## 06. The recipe document — one markdown file, ten blocks

Every recipe is **one markdown file** in `content/recipes/`. The
frontmatter is the schema of record — it drives search, filtering,
the browse paths (§07), and the print template choice (§09). The body
carries the blocks in a fixed order, so you learn where to look
exactly once. Blocks may be empty; they may not be reordered.

### The frontmatter schema

Required fields, validated at build time — a recipe that fails
validation fails CI:

```yaml
---
number: 47                 # the collector's plate; unique, never reused
title: Salted Caramel
tested: 2026-03-11         # last date this revision was cooked as written
revision: 3
yield: { amount: 340, unit: g, servings: 8 }
time: { active: 15m, total: 45m }   # total includes every hold — no lying
slot: [dessert]            # breakfast | lunch | dinner | snack | dessert
course: sauce              # main | side | sauce | drink | bake | component
flavor: [sweet, salty]     # sweet | savory | spicy | tangy | umami | bitter | salty
method: sugar-work         # primary technique, one value from the method list
effort: focused            # relaxed | focused | project
dietary: [vegetarian, gluten-free]   # verified flags only — absence means unverified
cuisine: []                # optional tags; empty is honest
print: sheet               # sheet | card | booklet — default template (§09)
photo: salted-caramel.avif # optional; omitted means no photo, never a placeholder
---
```

The facet lists (`slot`, `flavor`, `method`, `effort`, `dietary`) are
**closed vocabularies** defined in one place in the build script.
Adding a value is a deliberate act, not a typo surviving review.

### The body blocks

| # | Block | Carries |
|---|-------|---------|
| 1 | Header plate | Rendered from frontmatter: name, number, revision, tested date, yield, times, method mark |
| 2 | Photo | One photograph. One. Absent if none — never a grey box |
| 3 | Ingredients | Grouped by sub-preparation, mass-first, scalable |
| 4 | Equipment | Named with the dimensions and materials that change the result |
| 5 | Steps | Numbered, each with its own temperature/time/tell inline |
| 6 | Watchpoints | The critical limits — the temperatures and states that decide success |
| 7 | Rescues | What goes wrong, what causes it, whether it can be saved |
| 8 | Keeps | Storage, freezing, reheating |
| 9 | The note | Yours. Serif, sentence case, first person, unedited |
| 10 | History | What changed and when |

**Ingredients sit above the fold.** A returning cook needs
quantities; a first-time cook needs a shopping list; neither needs a
paragraph first.

Blocks 6 and 7 are the ones conventional recipe sites omit, and
they're the reason to build this at all. A published rescue is the
most generous sentence a recipe can contain.

### The bench specimen

One real recipe, built first and kept forever, on which every rule
above is load-bearing:

```
Nº 47 · REV 3 · TESTED 2026-03-11
SALTED CARAMEL                                      [SUGAR WORK]
YIELD 340 g · 8 SERVINGS   ACTIVE 15 MIN   TOTAL 45 MIN
SWEET · SALTY · DESSERT · FOCUSED

INGREDIENTS
  200 g  caster sugar
   90 g  unsalted butter, cubed, cold
  120 g  double cream, held at 40 °C
    6 g  flaky salt

EQUIPMENT
  Heavy 20 cm saucepan, pale interior · probe thermometer · spatula

STEPS
  01  Warm the cream and hold it there. Cold cream into hot sugar
      is the single cause of seizing.        40 °C · HOLD
  02  Sugar into the dry pan in one even layer. No water. No
      stirring — swirl the pan instead.      MEDIUM HEAT
  03  Melt until the edges run clear and the pool turns straw.
                              6–9 MIN · UNTIL THE EDGES RUN CLEAR
  04  Take it to deep amber and the first thread of smoke, then
      off the heat. The colour is the tell, not the clock.
                                       175–180 °C · DEEP AMBER
  05  Butter in, all at once. It will foam to the rim. Beat it flat.
  06  Cream in a thin stream, beating throughout. Salt last.

RESCUES
  GRAINY / CRYSTALLIZED   A sugar crystal fell back into the pool.
                          Add 30 g water, return to the heat,
                          re-take it to 180 °C.
  SEIZED INTO A LUMP      The cream was cold. Low heat, keep
                          beating. It comes back.
  BITTER                  Past 190 °C. It does not come back.

KEEPS
  Jar warm, cap cold. Fridge at 4 °C, keeps 14 days.
  Do not freeze — it separates on thaw.

NOTE
  Mum's pan was aluminium and she went by smell, not temperature —
  she'd say it's ready when it smells like it's about to be too
  late. Revision three is that sentence, in numbers. The first two
  were too pale.
```

### The photograph

One per document, treated as a record of what you actually made.
Clamp it toward the neutral family or render it as a coarse halftone
— halftone is already in the graphic vocabulary, it keeps the payload
tiny, and it's the only form a photo survives printing in (§09). No
photo means the block is absent. Never a placeholder.

---

## 07. Browse — choose your own path

The shelf is the fun half of the product, and its job is to let you
choose *how* you want to choose. Four browse paths, one per required
facet group, each a first-class entry point on the home surface:

| Path | Facets | The question it answers |
|------|--------|------------------------|
| **By meal** | `slot` + `course` | "What's for dinner?" |
| **By flavor** | `flavor` (combinable) | "I want something sweet and spicy" |
| **By effort** | `method` + `effort` + `time` | "What am I up for tonight?" |
| **By needs** | `dietary` + `cuisine` | "Gluten-free, and make it Thai" |

Paths are presented as full-acid tiles — this is the loudest surface
in the product. Selecting within a path composes with the others:
start from SWEET, then narrow to `effort: relaxed`. The facets all
come from frontmatter (§06), which is why the schema is the thing to
build first.

### Results

Results render as a dense, scannable list — the flavor chips supply
the color; the rows supply the information:

```
SEARCH ▸ caram_

│ Nº 47 · SALTED CARAMEL          SWEET·SALTY   15 MIN   KEEPS 14 D
│ Nº 112 · CARAMELIZED ONIONS     SAVORY        55 MIN   KEEPS 5 D
│ Nº 88 · CARAMEL ICE CREAM BASE  SWEET         25 MIN   FREEZES
│ Nº 203 · Caramel miso ferment   HIDDEN BY [TOTAL ≤ 60 MIN]

[TOTAL ≤ 60 MIN ✕] [SWEET ✕] [+ EFFORT] [+ DIETARY]
```

- **Filters narrow; they never silently hide.** An excluded recipe
  stays on the page, tagged with the filter that excluded it. A
  silently-vanished result teaches you to distrust your own archive.
- **Active time and total time are different facets and both are
  shown.** A twelve-hour cure is not a twenty-minute recipe;
  collapsing the two is the most common lie in recipe software.
- **Default sort is last tested.** The archive's own working order
  beats the dictionary's.
- **Zero results is designed copy with an action:**
  `NOTHING MATCHES. CLOSEST BY TIME ▸`. A dead end is a design
  failure, not an edge case.

---

## 08. Cook mode — the arm's-length constraint

Reading a recipe while cooking imposes constraints no other screen
has: you're two to three feet away, your hands are wet or full, the
light is bad, and something is on the heat.

- **Body type at 20px equivalent or larger**, the step number larger
  again. The one place the type scale steps up.
- **No hover-only information, anywhere.** There may be no pointer at
  all. Everything a step needs is printed on the step.
- **Completed steps stamp; they never grey out.** You will re-read a
  done step to check what you already did. Tagged, not disabled.
- **Tap targets at 2.75rem minimum, scaling with text.**
- **Hold the screen awake** while cook mode is open, and say so on
  screen.
- **Scaling is set before you start and displayed permanently** in
  the header. A scaled recipe that doesn't say it's scaled is
  dangerous.

---

## 09. Print — black and white, by design

> The web page is rich, colorful, and alive. The printed sheet is
> none of those things, on purpose: it is black ink on white paper,
> built for a home laser, designed to live on a counter, get ruined,
> and be reprinted. These are two renderings of the same markdown
> file — the screen never pretends to be paper and the paper never
> apologizes for not being the screen.

### Four templates

The print system is CSS (`@media print`), selected per recipe by the
`print` frontmatter field and overridable by the reader at print
time. All templates share the ink discipline and the footer.

| Template | Pages | For | Shape |
|----------|-------|-----|-------|
| `sheet` | 1–2 | The default workhorse | Ingredients in two columns up top; numbered steps with temps/times/tells inline; watchpoints and rescues boxed; note and footer at the bottom |
| `card` | 1 | Simple recipes cooked from memory-plus-a-glance | Dense single page, larger type, abbreviated steps; fits a card box or the fridge door |
| `booklet` | ≤4 | Multi-component or multi-day recipes | Page 1 is the overview: component map, full timeline, combined ingredient list. Then one section per component, never split across a page break |
| `prep` | ½–1 | The day before | Supplemental, printable alongside any of the above: shopping list with quantities, plus prep tasks (cuts, pre-measures, holds) as a checklist |

**Four pages is the ceiling, not a target.** If a recipe won't fit
the booklet, that's a signal about the recipe.

### The ink discipline

- **Black plus one screen tint. That's the whole budget.** Acid
  doesn't survive a monochrome laser. A volt fill becomes a solid
  black block with knockout text; a flavor chip prints as an outlined
  capsule with its word; heat warnings become 45° hatching.
- **No reversed body type.** Knockout survives on a heading and
  smears at 9pt after one photocopy.
- **Body at 11pt minimum, step numbers at 14pt** — larger than the
  screen, because the sheet sits on a counter and you're standing.
  Print body is Inter; quantities stay in the mono voice; the title
  stays in the display voice.
- **The photograph prints as a coarse halftone or not at all.**
- **Break law:** never between a heading and its table, never inside
  a step, never orphan the rescues.
- **Margins in physical units**, sized for the sheet to be handled at
  the edge and held by a clip.

### The footer — every sheet knows what it is

Every printed page carries: the recipe number, the revision, the
scale factor it was printed at, the date it was pulled, and the short
URL. **A sheet found in a drawer in three years should be able to
tell you what it is and how out of date it is.** Reprinting is the
intended lifecycle — which is exactly why the sheet must be cheap in
ink, small in pages, and traceable to its current revision.

---

## 10. Motion — playful hands, still pages

Revision 2 relaxes the total-stillness rule, but only on the shelf,
and never ambiently.

- **Zero ambient motion, everywhere.** Nothing loops, drifts,
  breathes, or pulses on its own. Motion is always a response to the
  user's hand.
- **The shelf may respond playfully.** Tiles, chips, and buttons may
  acknowledge press and hover — under 200 ms, stepped or snappy
  easing, no springs that overshoot more than they travel. Think
  machinery with good detents, not jelly.
- **Recipe pages hold still.** Reading surfaces get state transitions
  under 150 ms and nothing else. Cook mode is the stillest surface in
  the product.
- **Sanctioned exception — the step timer.** A running duration is
  functional readout: tabular numerals, zero layout shift.
- **`prefers-reduced-motion` implies calm.** New motion is authored
  inside `@media (prefers-reduced-motion: no-preference)`, so
  reduced-motion users never have motion defined at all rather than
  merely overridden.

---

## 11. Voice — warm, direct, precise

delishh speaks like a friend who cooks seriously: enthusiastic about
the food, exact about the numbers. Two registers, split on the same
line as everything else:

- **Shelf copy may have personality.** Warmth, first person, the
  occasional exclamation mark. It still never sells — banned outright:
  *game-changer, crowd-pleaser, the best ___ ever, foolproof*, and
  any sentence whose job is engagement rather than information.
- **Procedure is calm and exact.** Inside steps, watchpoints, and
  storage: no *simply, just, easy* (they minimize a difficulty the
  reader is currently having), no vague verbs (*toss, whip up, throw
  together*) where the procedure needs a real one, no exclamation
  marks, no emoji. Real verbs with defined meanings: fold, beat,
  swirl, render, slake.
- **The note is exempt entirely.** First person, feeling, digression
  — all permitted, none edited toward house style. The word rules do
  not read it.
- **delishh never lies about status.** "Ready in 20 minutes" on a
  recipe with an overnight cure is a lie even when every individual
  number is true. Total time always includes holds. Fun is not
  dishonest.

The banned-word check runs in the build, not in a review checklist —
copy is written in a hurry and nobody reviews a tooltip.

---

## 12. Hard constraints — never waived

- **Dense but never broken.** No overlapping text, no clipped
  quantities, no unreadable state, at any density.
- **WCAG AA for all functional text**, measured on its actual
  background, in both themes. Bold is not legible; contrast is.
- **Information is never carried by color alone**, on screen or on
  paper.
- **≤ 3 Hz flashing; `prefers-reduced-motion` respected** (§10).
- **User text scaling respected** — no px font sizes, breakpoints in
  rem, and the never-broken bar holds at 200% zoom *and* at a raised
  browser default font. Two different mechanisms; both must work.
- **Printing is pure CSS.** The print templates are `@media print`
  stylesheets over the rendered document — no print-specific
  JavaScript, no server round-trip to produce a sheet.
- **Fast on a phone in a kitchen.** The acid layer is CSS and SVG,
  never image payloads; at most one photograph per recipe, lazily
  loaded.
- **Self-hosted assets only.** No font CDNs, no third-party analytics
  on a document you may want to read in ten years.

---

## 13. Governance, and the first five things to build

- **Amendments are dated blocks, not rewrites.** A new ruling is
  appended with its date and overrides the prose beneath it. The
  superseded reasoning stays readable, because "why did we stop doing
  it that way" is the question you'll actually have.
- **Bench alternatives, then rule from the bench.** Build candidate
  treatments side by side on identical content, look at them, pick
  one, and record what the rejected ones were.
- **Constants live in one file** — tokens in `theme.css`, vocabularies
  and validation in one build module. Retune there and nowhere else.
- **The word check and the schema check run in CI**, not in a review
  checklist.

### The first five things to build

1. **The recipe schema and the build script.** Frontmatter
   vocabularies, validation, markdown → JSON. Everything else in the
   product is a view of this.
2. **One real recipe, end to end** — Nº 47 above. A hard one, with
   genuine watchpoints and rescues. It is the bench specimen forever.
3. **The `sheet` print template** — before the browse page, not
   after. If the sheet is right, the screen has very little left to
   get wrong.
4. **The token refresh.** Both themes, all four acids, every text
   variant, with measured contrast ratios in a comment beside each
   pair.
5. **The browse paths**, once there are at least a handful of recipes
   to walk them with.
