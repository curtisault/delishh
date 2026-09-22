# Adding a recipe

One markdown file in this directory is one recipe, and this file is
the authoring contract for writing it. The build enforces everything
below marked **enforced** — a recipe that violates it fails
`deno task content` with a file-and-line error, and nothing ships.
This document itself is machine-checked: `scripts/agents_test.ts`
holds every list in it to `scripts/vocabulary.ts`, so if you are
reading it, it is current.

The design authority behind these rules is DS-01
(`docs/design-standard.md`), §05 and §06. This file tells you *what*
to write; the standard says *why*.

## The workflow

1. Copy the skeleton at the bottom of this file to
   `<slug>.md` — lowercase, digits and single hyphens only
   (`salted-caramel.md`). **The filename is the recipe's identity**:
   its URL, and the name on its printed footer. There is no serial
   number (DS-01 §06, amended 2026-09-21).
2. Write the frontmatter and the blocks, in the order below.
3. Run `deno task content`. Fix what it names; it reports every
   problem at once, with line numbers, and writes nothing until the
   corpus is clean.
4. `deno task test` before committing — the recipe tests run against
   the real corpus.

## Frontmatter — the schema of record

Every field below is required unless marked optional. **Enforced.**

```yaml
---
title: Salted Caramel
tested: 2026-03-11        # ISO date it was last cooked as written;
                          # never in the future
yield: { amount: 340, unit: g, servings: 8 }   # servings optional
time: { active: 15m, total: 45m }
slot: [dessert]
course: sauce
flavor: [sweet, salty]
method: sugar-work
effort: focused
dietary: [vegetarian, gluten-free]
cuisine: []               # empty is honest
print: sheet
photo: salted-caramel.avif   # optional; the file must exist in
                             # public/photos — omit the field if
                             # there is no photograph
gauges:                      # optional; at most 5 — see below
  - { label: Pan, value: 20 cm, note: pale interior }
  - { label: Take it to, value: 175–180 °C, note: deep amber }
---
```

Rules that trip people:

- **Durations** are `15m`, `1h30m`, `2d`, `1d12h` — never a bare
  number, because 45 of *what* is exactly the thing readers get
  wrong. `total` includes **every** hold: an overnight cure makes the
  total overnight. delishh never lies about status.
- **`dietary` lists only what you have verified.** An absent flag
  means "not verified", never "not suitable". Nothing is inferred
  from the ingredients.
- **`yield.unit`** is one of: `g` · `kg` · `ml` · `l` · `pieces`
- **A misspelled key** gets a "did you mean" from the build; a
  misspelled *value* gets the vocabulary list.

### The gauge strip — optional, at most 5

The recipe's **operating numbers**: the pan, the oven, the
temperature it is done at, how long it lives in a freezer. They print
at the top of every form and sit on the plate on screen, which makes
them the thing you re-read from a metre away with your hands full.

- Each entry is `{ label, value }` with an optional `note`. All three
  are free text — they are *your* numbers, not a vocabulary.
- **Five is the ceiling, and the cap is the point.** A sixth is the
  one that turns a glance into a search, and a number nobody glances
  at is better off in the prose it came from.
- **Author them; never derive them.** Every gauge already exists
  somewhere in the document. Copy it up deliberately — picking which
  number matters is a judgement the build must not make for you
  (DS-01 §12: nothing is ever inferred).
- **The word rules apply**, exactly as they do to a step. A gauge is
  procedure, not the note's human voice.
- **A comma inside a `{ }` entry must be quoted** — YAML reads a bare
  comma as the next key, so `note: "bitter, and it does not come
  back"` needs its quotes. The build rejects the unquoted form, but
  the error names a key you never wrote, so it is worth knowing why.
- **Omit the field when the recipe has no number worth the plate.** A
  drink blended until it is smooth is blended until it is smooth, and
  no temperature will tell you more than that.

### The closed vocabularies

These are the only legal values. **Enforced.** Adding one is a
deliberate act: edit `scripts/vocabulary.ts` *and* the matching line
here — the test fails the build if the two disagree.

- `slot` — one or more of: `breakfast` · `lunch` · `dinner` · `snack` · `dessert`
- `course` — exactly one of: `main` · `side` · `sauce` · `drink` · `bake` · `component`
- `flavor` — one or more of: `sweet` · `savory` · `spicy` · `tangy` · `umami` · `bitter` · `salty`
- `method` — exactly one of: `bake` · `roast` · `sear` · `fry` · `deep-fry` · `grill` · `braise` · `stew` · `steam` · `boil` · `poach` · `simmer` · `sauté` · `sugar-work` · `ferment` · `cure` · `pickle` · `smoke` · `confit` · `sous-vide` · `dough` · `blend` · `toast` · `chill` · `freeze` · `no-cook`
- `effort` — exactly one of: `relaxed` · `focused` · `project`
- `dietary` — zero or more of: `vegetarian` · `vegan` · `gluten-free` · `dairy-free` · `nut-free` · `egg-free` · `pescatarian`
- `cuisine` — zero or more of: `british` · `french` · `italian` · `spanish` · `greek` · `middle-eastern` · `north-african` · `west-african` · `indian` · `thai` · `vietnamese` · `chinese` · `japanese` · `korean` · `mexican` · `american` · `caribbean`
- `print` — exactly one of: `sheet` · `card` · `booklet`

The `method` answers "what am I doing for *most* of this", not "what
happens at any point" — a recipe that sears and then braises is a
braise. It also picks the page's accent colour, so choose the one
that names the recipe's defining physical process.

## The blocks — fixed order, `##` headings

**Enforced.** The order is:

Equipment → Ingredients → Steps → Watchpoints → Rescues → Keeps → Note

Required blocks: `Ingredients` · `Steps` · `Note`

Blocks may be absent (an absent block simply does not render — never
a heading over nothing); they may **not** be reordered or repeated.
No `#` headings in the body, and no text outside a block. Equipment
precedes Ingredients as of the 2026-09-20 amendment to DS-01 §06:
mise en place reads gear-first.

### Equipment

A bullet list. Name the dimensions and materials that change the
result — "Heavy 20 cm saucepan, pale interior", not "a saucepan",
because the diameter changes the recipe and a dark pan hides the one
tell that matters.

### Ingredients

A bullet list, optionally grouped by `### sub-preparation` headings
("### The brine"). Each line is:

```
- 200 g caster sugar
- 90 g unsalted butter, cubed, cold
- 2–3 cloves garlic, peeled
- 2 eggs
- flaky salt, to finish
```

The grammar, **enforced** where marked:

- Amount, then unit, then the item; everything after the first comma
  is the preparation note.
- **Grams are whole numbers** — no `142.5 g`. Decimals are legal only
  for mass in `kg`.
- **Volume fractions are glyphs** — `¾ tsp`, never `0.75 tsp`.
- Known units, by kind (anything else becomes part of the item name,
  which is how `2 eggs` works):
  - `mass` — `g` · `kg`
  - `volume` — `ml` · `l` · `tsp` · `tbsp` · `cup`
  - `count` — `clove` · `can` · `sprig` · `head` · `stick` · `sheet` · `bunch` · `slice`
- Count units and bare counts are **indivisible**: the scaler will
  never render half an egg — it rounds and prints an honest note
  saying what the arithmetic wanted. Write plurals naturally
  (`3 cloves`); the build canonicalises them.

### Steps

A numbered list. Each step may carry one `cue:` continuation line —
its temperature, duration and doneness tell, printed on the step:

```
1. Melt undisturbed until the edges run clear and the pool turns
   straw. Swirl once to even it out, then leave it alone again.
   cue: 6–9 MIN · UNTIL THE EDGES RUN CLEAR
```

- **The clock is never alone** (enforced): a cue that is *only* a
  duration is rejected. Say what done looks like — time is the least
  reliable variable in any kitchen.
- A cue's first duration of an hour or less becomes a countdown in
  cook mode, and **a range takes its low end** — `6–9 MIN` counts
  six minutes, because the timer says when to start looking, not
  when to stop. Longer holds ("2 D MINIMUM") are left alone.
- House style the build does not catch: temperatures dual and
  authoritative-unit first (`175–180 °C`), cues in the flat
  imperative register of the examples.

### Watchpoints

A bullet list: the critical limits — the temperatures and states that
decide success. One sentence each.

### Rescues

The block most recipe sites omit, and the reason this archive exists.
Each entry is:

```
- **Grainy, or crystallized to sand** — A sugar crystal fell back in.
  Add 30 g water, return to the heat, re-take it to 180 °C.
- **Bitter** [terminal] — Past 190 °C. It does not come back.
```

**Enforced** shape: bold symptom, an em dash, then cause and what to
do. Mark `[terminal]` when it cannot be saved — saying so plainly is
the most generous sentence a recipe can carry, and it renders with
its own warning treatment.

### Keeps

A bullet list: storage, freezing, reheating, and for how long.

### Note

**Yours, and required.** Free prose in the first person — why this
recipe, what its history is, what your mother did differently. It
renders in the serif at the foot of the page, and **the word rules
never read it**. Do not write it in the procedure register; it is the
one human voice on the page.

There is no change-log block — the change log is git, and the story
of how a recipe got to its current form belongs here, in your own
words ("the first two goes were too pale"), if it belongs anywhere.

## Words the build rejects

**Enforced** in every block except the Note. In procedure
(Equipment through Keeps), also no exclamation marks and no emoji.

- `simply` · `just` — they minimise a difficulty the reader is
  currently having
- `easy` · `effortless` · `foolproof` — difficulty is the reader's to
  judge, and Rescues exists because nothing is foolproof
- `toss` · `whip up` · `throw together` — vague verbs where procedure
  needs a real one: fold, beat, swirl, render, slake
- `game-changer` · `crowd-pleaser` · `the best ___ ever` — marketing
  register; delishh never sells

## The skeleton

```markdown
---
title: Name
tested: YYYY-MM-DD
yield: { amount: 0, unit: g, servings: 0 }
time: { active: 0m, total: 0m }
slot: []
course: main
flavor: []
method: bake
effort: relaxed
dietary: []
cuisine: []
print: sheet
gauges: []
---

## Equipment

- 

## Ingredients

- 

## Steps

1. 
   cue: 

## Watchpoints

- 

## Rescues

- **Symptom** — Cause, and what to do.

## Keeps

- 

## Note

Why this recipe is yours.
```
