---
tag: DS-01
kicker: DELISHH DESIGN STANDARD
rev: REV 2
revDate: 2026-09-19
titleLines: [The design, standard]
standfirst: >-
  A personal recipe archive — browse, search, filter, print — built in
  the acid-Y2K idiom. This document owns look, feel and voice. Where a
  mechanic and the aesthetic disagree, we redesign the mechanic's
  presentation, never the aesthetic.
footNote: >-
  This page is generated from docs/design-standard.md, which is the
  prose of record. When build reality contradicts a decided rule, the
  dated amendment is written first and the code changes second.
---

# Design Standard — DS-01

Document DS-01 · Revision 2 · Issued 2026-09-19 · Status: IN FORCE

Revision 2 is a wholesale reframe. Revision 1 borrowed another
project's institutional register; this revision replaces it with
delishh's own premise (§01) and keeps only what earns its place in a
recipe archive: the measurement discipline, the print rigour, and the
honesty rules.

*Everything above the first `##` is the header of the raw file. The
app takes its masthead from the frontmatter, so this preamble is not
rendered — and the two must be kept in step by hand.*

---

## 00. Scope, and where things live
<!-- doc anchor=sec-scope toc="Scope" intent="Which file owns which rule" body=clauses -->

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
<!-- doc anchor=sec-premise toc="Premise" intent="The split every other rule follows from" body=clauses -->

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
speaks as itself: warm, direct, precise. The one structural touch —
every recipe carries a last-batch date — survives because it is
*useful*: it is the archive's working sort order, and it is how a
printed sheet says how old it is. A recipe's identity is its name
and its address, not a serial.

The one human register the design protects: **your note.** Every
recipe ends with a personal note in a serif, in sentence case, in the
first person, unedited. On a page where every number is exact, the
note is the reason the archive is yours.

---

## 02. Design pillars
<!-- doc anchor=sec-pillars toc="Pillars" intent="The six claims, and what each one forbids" body=clauses -->

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
<!-- doc anchor=sec-refs toc="References" intent="What the look is taken from, and what it refuses" body=panel -->

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
<!-- doc anchor=sec-color toc="Colour" intent="Where acid runs loud, and where it narrows" body=clauses -->

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

> **Amendment 2026-09-21 — an action may wear the colour of what it
> opens.** The table above gives volt to "the actionable — the
> primary verb on any surface", and **COOK THIS is now orange**. The
> rule it bends is real, so here is the reasoning in full.
>
> A button can name one of two things: that it is a button, or where
> it goes. Volt names the first, and on a page with exactly one
> primary action that is a fact the reader already has — nothing
> else on a recipe page is a filled block. Orange names the second:
> cook mode is the surface you open when the food goes on the heat,
> and heat is what orange has meant here since Revision 2.
>
> **The hazard reading survives because the two never share a
> screen.** Orange also carries alarm in cook mode — a refused wake
> lock, an expired timer — and an acid that meant "go" and "look
> out" in one place would be worth refusing. It does not: the button
> lives on the recipe page and the alarms live in cook mode, one
> click apart and never together. Both alarms also carry their
> words, which is §04's own guarantee that no meaning rides on a
> colour alone.
>
> **The counting rule is unaffected, and often improved.** On a bake,
> fry, sear or sugar-work recipe the page's dominant acid is already
> heat, so the plate's method word and its button now agree and the
> surface runs on *one* acid. On a cold or live recipe it is a
> dominant plus one cameo. Never three, as before.
>
> Volt keeps every other actionable role — it is still what
> `--accent` means, and nothing else moved. The button takes a named
> role of its own (`--accent-heat`), so this is one deliberate
> exception rather than a loosening of what volt is for.

> **Amendment 2026-09-22 — a third surface: the shopping list.**
> §01 splits the product into a loud shelf and a quiet page, and for
> two revisions that was every surface there was. The list at `/list`
> is neither. It is a working document you carry *out* of the
> kitchen, read standing in an aisle with one hand, and throw away
> when the shopping is done.
>
> **It runs page-quiet.** `--page-*` marks only; no `--shelf-*` fill
> ever lands here. The reasoning is the reasoning of §01: decoration
> is for the surface where you are choosing, and by the time you are
> holding this you have chosen. Volt is its one acid and it lands
> only on the actionable — the control that puts something in the
> cart. Quantities stay ink, as they do everywhere (§04), because a
> shopping list is a page made almost entirely of quantities and the
> rule that makes a dense page trustworthy is needed most here.
>
> **In the cart is a shape, not a colour.** A checked item fills its
> box against the outlined boxes of everything still to buy — the
> same filled-against-outlined glance the cook rail uses for a done
> step (§08), and the same drawn box the printed prep sheet uses
> (§09), because a character checkbox is a font dependency. It also
> says ", in cart" to a screen reader. The line through the name is
> decoration on top of those two carriers and never the only one:
> that is §12's never-colour-alone rule applied to a treatment that
> is not a colour but would fail the same way.
>
> **The one control in the archive that asks twice.** Clearing the
> list is the only irreversible thing a reader can do here: there is
> no undo, and rebuilding one means walking back through every recipe
> that made it. So the first press arms it and the second press does
> it, and what changes in between is the **word** — the button stops
> saying what it is and starts saying what the next press will do.
> Pressing anything else disarms it, and so does leaving the page.
>
> This is a deliberate exception, not a new habit. Everywhere else a
> press does what it says on it, and a product that asks "are you
> sure" out of caution teaches people to stop reading the question.
> The test for the exception is the one met here and nowhere else
> yet: irreversible, and read one-handed in a shop. A reader who
> wants only one recipe gone takes that recipe off its own row, and
> that needs no confirming because it is a press away from being
> undone.
>
> **Checked items sink; they do not vanish.** The cart group sits at
> the bottom of the list, struck but fully legible. This is the
> shelf's lockout rule (§07) rather than cook mode's stamp: on the
> shelf an excluded recipe stays on the page wearing the reason, and
> here you want to be able to look down and see that you did already
> get the butter. Nothing animates on the way down — the motion
> register is still zero (§10) and a list that rearranged itself
> under your thumb in a shop would be actively hostile.
>
> **The recipe page's second button is outlined, never filled.** The
> amendment above stakes COOK THIS on there being exactly one filled
> block on a recipe page, and that premise is preserved rather than
> quietly spent. ADD TO LIST stands beside it, outlined.
>
> They stand together because the controls row is split on *what each
> thing changes*, not on how important it is. The scale and the print
> form change the document in front of you, and they sit on the left
> wearing their key words. These two send something somewhere else —
> one to a shop, one to the heat — and neither is a setting you would
> think to read back. Putting the list button with the settings made
> it a third row of options nobody was choosing between; putting it
> with the action makes the pair what it is.
>
> **The fill is what separates them**, and it is now doing real work
> rather than merely being unique: of two adjacent actions, one is
> the page's primary verb and one is not. Outlined first, filled
> last, which is also the tab order — you reach past the quieter one
> to get to the loud one.

### Themes

Light and dark are the viewer's choice (System/Light/Dark, already
wired through `boot.js`). Light is a lit bench: near-white field, ink
text, acid as fills-with-ink-text. Dark is the same system at night:
near-black field, acid at full strength. Same tokens, same swap
mechanism, both themes verified independently.

---

## 05. Type, and the measurement ladder
<!-- doc anchor=sec-type toc="Type" intent="The four voices, and how a quantity is set" body=clauses -->

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

## 06. The recipe document — one markdown file, nine blocks
<!-- doc anchor=sec-document toc="The document" intent="One markdown file, and the ten blocks in it" body=clauses -->

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
title: Salted Caramel
tested: 2026-03-11         # last date it was cooked as written
yield: { amount: 340, unit: g, servings: 8 }
time: { active: 15m, total: 45m }   # total includes every hold — no lying
keeps: fridge 14d          # optional; how long it keeps and where — counter | fridge | freezer, h | d | mo
slot: [dessert]            # breakfast | lunch | dinner | snack | dessert
course: sauce              # main | side | sauce | drink | bake | component
flavor: [sweet 3, salty]   # word, or word 1–3 — sweet | savory | spicy | tangy | umami | bitter | salty
method: sugar-work         # primary technique, one value from the method list
effort: focused            # relaxed | focused | project
dietary: [vegetarian, gluten-free]   # verified flags only — absence means unverified
cuisine: []                # optional tags; empty is honest
print: sheet               # sheet | card | booklet — default template (§09)
photo: salted-caramel.avif # optional; omitted means no photo, never a placeholder
gauges:                    # optional; up to five operating numbers (§09)
  - { label: Pan, value: 20 cm, note: pale interior }
  - { label: Take it to, value: 175–180 °C, note: deep amber }
---
```

The facet lists (`slot`, `flavor`, `method`, `effort`, `dietary`) are
**closed vocabularies** defined in one place in the build script.
Adding a value is a deliberate act, not a typo surviving review.

> **Amendment 2026-09-21 — a flavour may state how loudly it
> speaks.** `spicy 2` is the word and an authored level: `1`
> background · `2` present · `3` defining. Three levels for the same
> reason `effort` has three — a finer scale is one nobody applies
> consistently to their own cooking. A bare word is **unstated**,
> never zero, and the page draws a meter only for a stated level:
> nothing is ever inferred, least of all what dinner tastes like.
> On the chips the level renders as filled cells beside the word and
> the word's own stencil mark — shape carrying what colour never
> carries alone (§04). Facet chips still do not print (§09).

> **Amendment 2026-09-21 — a keeping life states its place.**
> `keeps:` is how long the finished thing is good for, and it does
> not travel without the *where*: `fridge 14d`, `freezer 3mo`,
> `counter 4d`. The archive is mostly make-ahead food whose Keeps
> block states a freezer life and no fridge one, and a bare duration
> at the end of a shelf row reads as a claim about the dish in a
> fridge — the one misreading here that can put somebody in hospital,
> which is a different order of wrong from a page that looks untidy.
> Absent means **not stated**, never "does not keep": the same
> contract as an unverified dietary flag, and a dish that genuinely
> does not keep says so in its Keeps block, in words. The number is
> authored beside that block and never read out of it — picking which
> of a paragraph's durations is the one you bet on is a judgement,
> exactly as a gauge is (§12).

### The body blocks

> **Amendment 2026-09-20 — Equipment precedes Ingredients.**
> Blocks 3 and 4 are swapped from the order issued in Revision 2.
> Mise en place reads gear-first: you cannot weigh into a bowl you
> have not got out, and the pan's diameter changes the recipe before
> a single quantity does. At two to four lines, Equipment costs the
> quantities nothing — the rule beneath this, that ingredients sit
> above the fold, survives intact and is simply measured from one
> short block lower.
>
> **This is an order, not a layout.** Blocks linearise in exactly
> this sequence in the document, on the printed sheet, and on a
> narrow screen. Where a wide screen sets Equipment and Ingredients
> in a column beside the steps, that is presentation, and it presents
> them in this order too.

> **Amendment 2026-09-21 — the number is retired.**
> `number:` leaves the schema. Its honest job was traceability, and
> the slug does that better everywhere the number appeared: it is the
> filename, the address, and already on every printed footer inside
> the URL. What remained was a collector's-plate fiction — an
> insertion-order serial that tells a reader nothing about the food.
> Its slot on the plate now carries **the method**, the one fact that
> already colours the whole page (§04): the mark and its word
> together, which "information is never colour-only" always wanted.
> The printed footer carries the recipe's name instead, so every page
> of a booklet says what it belongs to.

> **Amendment 2026-09-21 — no revisions, no History block.**
> The `revision` counter and the History block (formerly block 10)
> are retired. The change log is git's job: the archive is a
> repository, every edit is already recorded there with a date and a
> reason, and a reader does not need it. The counter had a deeper
> fault than redundancy — nothing forced it to move, so `REV 3` on a
> printed sheet was a hand-maintained claim about content, not a
> fact, which is exactly the lying metadata this standard refuses
> everywhere else. Staleness on paper is now read from the
> **LAST BATCH** date — the lot-code idiom from §03's own reference
> table: the sheet's date against the site's, no arithmetic. The story of
> how a recipe got here belongs in the note, which was always the
> better home for it.

> **Amendment 2026-09-21 — the gauge strip.**
> The frontmatter gains one optional field, `gauges:` — at most five
> entries, each a label and a value with an optional note. These are
> the recipe's **operating numbers**: the pan, the oven, the
> temperature a thing is done at, the life of the thing in a freezer.
> They ride on the header plate (block 1) and print at the top of
> every form (§09).
>
> **They are authored, never derived, and that is the whole
> decision.** Every one of these numbers is already somewhere in the
> document — in an equipment line, inside a step's cue, in the middle
> of a Keeps paragraph. Lifting them out mechanically would mean
> guessing which of a recipe's numbers is the one you check with your
> hands full, and §12's rule is that nothing is ever inferred. So the
> cook names them, and the cost is borne where every other line of
> this document bears it: a gauge is read at the bench, and a wrong
> one fails the cook the same way a wrong step does. That is a
> different thing from `revision:`, which nothing ever checked —
> the reason this field is allowed and that counter was not.
>
> Optional, and empty is the honest answer. Not every recipe has an
> operating number worth the plate: a Frosty is blended until it is
> smooth, and no temperature will tell you more than that.

| # | Block | Carries |
|---|-------|---------|
| 1 | Header plate | Rendered from frontmatter: name, method mark, last-batch date, yield, times, and the gauge strip if the recipe has one |
| 2 | Photo | One photograph. One. Absent if none — never a grey box |
| 3 | Equipment | Named with the dimensions and materials that change the result |
| 4 | Ingredients | Grouped by sub-preparation, mass-first, scalable |
| 5 | Steps | Numbered, each with its own temperature/time/tell inline |
| 6 | Watchpoints | The critical limits — the temperatures and states that decide success |
| 7 | Rescues | What goes wrong, what causes it, whether it can be saved |
| 8 | Keeps | Storage, freezing, reheating |
| 9 | The note | Yours. Serif, sentence case, first person, unedited |

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
SUGAR WORK · LAST BATCH 2026-03-11
SALTED CARAMEL                                      [SUGAR WORK]
YIELD 340 g · 8 SERVINGS   ACTIVE 15 MIN   TOTAL 45 MIN
SWEET · SALTY · DESSERT · FOCUSED

EQUIPMENT
  Heavy 20 cm saucepan, pale interior · probe thermometer · spatula

INGREDIENTS
  200 g  caster sugar
   90 g  unsalted butter, cubed, cold
  120 g  double cream, held at 40 °C
    6 g  flaky salt

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
  late. The third go is that sentence, in numbers. The first two
  were too pale.
```

### The photograph

One per document, treated as a record of what you actually made.
Clamp it toward the neutral family or render it as a coarse halftone
— halftone is already in the graphic vocabulary, it keeps the payload
tiny, and it's the only form a photo survives printing in (§09). No
photo means the block is absent. Never a placeholder.

> **Amendment 2026-09-22 — an ingredient knows what aisle it is
> bought in, and a person decided that.** Every ingredient the build
> emits carries `shop: {aisle, buyAs}` so the list at `/list` can
> group a shop by where you will be standing. Neither half is read
> out of the ingredient line.
>
> **The aisle is a join, not a guess.** A central table maps the
> exact item string to one of a closed list of aisles, and the build
> fails on an item the table has never heard of. The alternative — a
> rule that sees "potatoes" and reasons its way to produce — is the
> move §06 has already refused for a gauge, for a keeping life and
> for a flavour level, and it fails in the same direction: quietly,
> plausibly, and only in the shop. A new ingredient costs one line in
> a table. That friction is the point, exactly as it is for a facet.
>
> **`buyAs` is what goes in the trolley**, and it is the name two
> recipes merge on. The corpus says "yellow onion" in one file and
> "yellow onions" in another; it says "cilantro" and "cilantro — at
> serving only". Those are one purchase, and collapsing them by
> stemming the strings would be inference wearing a tidier hat. The
> table states the purchase name, the recipes keep their own words,
> and neither has to bend.
>
> **A bullet that is not a purchase says so out loud.** One
> ingredient line in this archive reads "or nothing at all; it is
> excellent plain". The table marks it omitted, by hand. An unmapped
> item and a deliberate non-purchase must never look the same to the
> build, or the check stops meaning anything the first time somebody
> silences it.
>
> **Merging never converts between kinds.** Mass sums with mass,
> volume with volume, a count with the same count unit. Flour asked
> for in grams by one recipe and cups by another is *one line
> carrying both* — `500 g + 2 cups` — because a cup of flour weighs
> what it weighs on the day, and a shopping list that made that
> number up would be wrong in the only place it is ever read. A
> compound item is never split for the same reason: nothing here
> knows how much of "Monterey Jack and sharp cheddar" is the cheddar.
>
> **Where it rounds, it rounds up.** Half an egg is not a thing to
> buy, and the honest answer for a shop is *enough*. This is the one
> place the measurement ladder (§05) deliberately reads differently
> from the recipe page, which still states what the arithmetic
> actually wanted.
>
> **A "pick one" group contributes all of its options.** The list
> does not carry sub-preparation headings, so a recipe offering
> chocolate chips *or* pepitas puts both on it. Over-inclusive is
> recoverable at the shelf edge; under-inclusive sends you home
> without dinner.

---

## 07. Browse — choose your own path
<!-- doc anchor=sec-browse toc="Browse" intent="Four ways in, and filters that never hide" body=clauses -->

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
QUERY ▸ caram_

│ SUGAR WORK · SALTED CARAMEL     SWEET·SALTY   15 MIN   KEEPS 14 D · FRIDGE
│ SAUTÉ · CARAMELIZED ONIONS      SAVORY        55 MIN   KEEPS 5 D · FRIDGE
│ CHILL · CARAMEL ICE CREAM BASE  SWEET         25 MIN   KEEPS 3 MO · FREEZER
│ FERMENT · Caramel miso ferment  HIDDEN BY [TOTAL ≤ 60 MIN]

[TOTAL ≤ 60 MIN ✕] [SWEET ✕] [+ EFFORT] [+ DIETARY]
```

- **Filters narrow; they never silently hide.** An excluded recipe
  stays on the page, tagged with the filter that excluded it. A
  silently-vanished result teaches you to distrust your own archive.
- **Active time and total time are different facets and both are
  shown.** A twelve-hour cure is not a twenty-minute recipe;
  collapsing the two is the most common lie in recipe software.
- **The query wears its own label and marks where it landed.** The
  field is `QUERY ▸`, not a box with a magnifier in it, and the
  letters it matched are marked in the rows that stayed — the same
  courtesy the lockout tag pays the rows that went. A row is on the
  page for a reason, and the reason should be visible in it.
- **How long it keeps is the last thing in the row**, with the place
  it keeps in (§06). Absent when the recipe has never said: nothing
  stands in for an unstated life, because a hedge in that slot is the
  archive filling a silence it has no right to fill.
- **Default sort is last tested.** The archive's own working order
  beats the dictionary's.
- **Zero results is designed copy with an action:**
  `NOTHING MATCHES. CLOSEST BY TIME ▸`. A dead end is a design
  failure, not an edge case.

---

## 08. Cook mode — the arm's-length constraint
<!-- doc anchor=sec-cook toc="Cook mode" intent="Wet hands, bad light, a pan on the heat" body=clauses -->

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
- **Rescues are on this screen, last.** Watchpoints are the limits you
  hold to while it is going right; a rescue is for the moment it has
  not, and nobody leaves cook mode to find the document with a pan
  smoking. Last because you scroll to it when you need it and never
  otherwise. Keeps and the Note stay on the document: one is for after
  the cooking and the other is for reading.
- **Air between steps.** At two to three feet the thing that loses you
  your place is two steps reading as one block of text, and the fix is
  space rather than another rule.
- **A rail, on a screen wide enough to have a side.** Its rows are the
  blocks, the named ingredient groups, and the steps — the steps as
  their numbers, because twelve step sentences in a rail is the
  document again, and the document is what you came here to stop
  reading. A done step fills its chip: filled against outlined is a
  shape, and this is the glance that says how far in you are (§04).
  Below 64rem there is no side, and the rail is gone rather than
  stacked above the ingredients.

---

## 09. Print — black and white, by design
<!-- doc anchor=sec-print toc="Print" intent="Black ink, four templates, a footer that knows itself" body=clauses -->

> The web page is rich, colorful, and alive. The printed sheet is
> none of those things, on purpose: it is black ink on white paper,
> built for a home laser, designed to live on a counter, get ruined,
> and be reprinted. These are two renderings of the same markdown
> file — the screen never pretends to be paper and the paper never
> apologizes for not being the screen.

> **Amendment 2026-09-21 — the sheet is a page, not a printout.**
> Everything below this block was written before there was anything
> to print. It described ink, margins and breaks correctly, and the
> first real print run — seventeen recipes, cooked from — showed what
> it had left out: a *page*. What came off the printer was the screen
> document linearised, carrying the screen's whitespace and the
> screen's furniture, and spending four pages on two pages of
> content. Five rules follow, and they are what the rest of this
> section is now read through.
>
> **The gauge strip prints at the top of every form.** Up to five
> operating numbers from the frontmatter (§06), set as a rule of
> label-over-value in the data voice, directly beneath the plate.
> This is the first thing the eye lands on from a metre away and the
> thing you re-check with your hands full — the pan, the oven, the
> temperature it is done at. It is ink well spent because it answers
> questions the bench actually asks.
>
> **Facet chips do not print.** Not flavour, not slot, not effort,
> not cuisine — and not dietary. Facets exist so you can *find* a
> recipe (§07), and a sheet in your hand has been found. The strip
> above replaces them in the same band of the page, which is the
> honest trade: the ink goes to the numbers you cook by instead of
> the words you searched by. (Dietary was argued for and lost: the
> ingredients are on the same sheet, and a lone chip row that
> answers one facet of four invites the reader to think the others
> were checked.)
>
> **The cue rides on the step's number line.** On screen a cue sits
> beneath its step, where you read down. On paper it sets to the
> right of the step number, on the same line — clock and tell
> together, at the left edge where a standing reader scans for their
> place. The step's prose sits below it. Nothing is re-authored; the
> sheet sets the same words in a different order, which is what two
> renderings of one file means.
>
> **Ingredients set as a table, not as columns.** Two columns of
> quantities are right (§09 has always said the held half of the page
> should not be wasted), but flowed columns are wrong: a flowed
> column balances by height, so the two stacks drift out of step and
> the rule under each line stops at the gutter. It reads as a broken
> table because it is a list pretending to be one. The sheet sets a
> real grid — quantity, name, quantity, name — so rows share a
> baseline and every rule runs the width it appears to.
>
> **The sheet breaks before Watchpoints, and that makes it duplex.**
> The block order already splits on the bench seam: Equipment,
> Ingredients and Steps are what you do; Watchpoints, Rescues, Keeps
> and the Note are what you consult when it goes wrong or when it is
> over. One page break at that seam turns the default form into a
> two-sided leaf — procedure on the front, recovery on the back —
> which is how a working recipe card has always been laid out. The
> break is in the form, not in the content: the same nine blocks, in
> the same order, folded where they already divided.

### Four templates

The print system is CSS (`@media print`), selected per recipe by the
`print` frontmatter field and overridable by the reader at print
time. All templates share the ink discipline and the footer.

| Template | Pages | For | Shape |
|----------|-------|-----|-------|
| `sheet` | 2, one duplex leaf | The default workhorse | Front: the gauge strip, equipment, the ingredient table, the numbered steps with their cues on the number line. Back: watchpoints, rescues, keeps, the note, and the footer |
| `card` | 1 | Simple recipes cooked from memory-plus-a-glance | Dense single page, larger type, abbreviated steps; fits a card box or the fridge door |
| `booklet` | ≤4 | Multi-component or multi-day recipes | Page 1 is the overview: component map, full timeline, combined ingredient list. Then one section per component, never split across a page break |
| `prep` | ½–1 | The day before | Supplemental, printable alongside any of the above: shopping list with quantities, plus prep tasks (cuts, pre-measures, holds) as a checklist |

**Four pages is the ceiling, not a target.** If a recipe won't fit
the booklet, that's a signal about the recipe.

**The page counts in that table are a contract, not an aspiration.**
A card that runs to two pages is a bug in the card, and a booklet
that fills four pages with air is the same bug wearing a different
name. The body floor below is not where the space comes from — it is
the one measurement protecting a reader who is standing up. It comes
from everything the floor does not protect: the padding around the
plate, the gaps between blocks, the air around a step.

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

Every printed page carries: the recipe's name, its last-batch date,
the scale factor it was printed at, the date it was pulled, and the
short URL. **A sheet found in a drawer in three years should be able to
tell you what it is and how out of date it is.** Reprinting is the
intended lifecycle — which is exactly why the sheet must be cheap in
ink, small in pages, and traceable to the archive's current copy.

---

## 10. Motion — playful hands, still pages
<!-- doc anchor=sec-motion toc="Motion" intent="Playful on the shelf, still on the page" body=clauses -->

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
<!-- doc anchor=sec-voice toc="Voice" intent="Warm where it sells nothing, exact where it counts" body=clauses -->

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
<!-- doc anchor=sec-constraints toc="Hard constraints" intent="The bars that are never waived" body=panel -->

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
- **Nothing about a reader leaves their browser.** Two things are
  stored, both local and both named in the colophon: the lighting
  they chose, and the shopping list they built. Either may fail to
  save — a full or blocked store degrades to the choice holding for
  the session, never to a surface that will not render. State that
  cannot be read back is discarded and the reader starts empty.

---

## 13. Governance, and the first five things to build
<!-- doc anchor=sec-governance toc="Governance" intent="Dated amendments, and where to start" body=clauses -->

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
2. **One real recipe, end to end** — the salted caramel above. A hard one, with
   genuine watchpoints and rescues. It is the bench specimen forever.
3. **The `sheet` print template** — before the browse page, not
   after. If the sheet is right, the screen has very little left to
   get wrong.
4. **The token refresh.** Both themes, all four acids, every text
   variant, with measured contrast ratios in a comment beside each
   pair.
5. **The browse paths**, once there are at least a handful of recipes
   to walk them with.
