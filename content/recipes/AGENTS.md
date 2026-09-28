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
keeps: fridge 14d         # optional; how long the finished thing
                          # keeps, and where — see below
slot: [dessert]
course: sauce
flavor: [sweet 3, salty]
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
- **`keeps` is optional, and absent means *not stated*** — never
  "does not keep". See below.
- **A misspelled key** gets a "did you mean" from the build; a
  misspelled *value* gets the vocabulary list.

### The keeping life — optional

`keeps: fridge 14d` is **how long the finished thing is good for,
and where**. It is the last thing on a shelf row and a fact on the
plate, so it is the number a reader browses on when they are deciding
what to make on a Sunday for a week.

The grammar is one string — the place, one space, the number and its
unit. A string rather than a `{ }` map for the same reason `flavor`
is one: a colon turns the entry into a YAML map and the error then
names a key you never wrote.

- `keeps.where` — exactly one of: `counter` · `fridge` · `freezer`
- `keeps.unit` — exactly one of: `h` · `d` · `mo`

- **The place is not optional, and this is the rule that matters.**
  Most of this archive is make-ahead food whose Keeps block states a
  *freezer* life and no fridge one. `keeps: 3mo` on a shelf row, with
  no place on it, reads as a claim about the dish in a fridge — the
  one misreading here that can make somebody ill. So the build will
  not take a bare duration.
- **Absent means *not stated*, never "does not keep".** The same
  contract as a dietary flag: if you have not established a life,
  leave the field out. A shelf life nobody measured is precisely the
  number that hurts somebody, and the build will not invent one for
  you (DS-01 §12). A dish that genuinely does not keep says so in the
  block, in its own words — "make it, eat it" is a sentence, not a
  number.
- **Pick the life the recipe actually leans on**, the one you would
  bet on for the dish as a whole. Per-component lives ("the sauce
  alone holds 3 days") belong in the block, not here.
- **No minutes.** Nothing keeps for minutes, and a field that took
  them would collect a `45m` meant for `time`.
- **A `keeps:` requires a Keeps block.** Enforced. The number is what
  a reader browses on; the block is what they do with it — jar warm,
  cap cold, under a film of oil — and half of that pair is a promise
  nobody can keep. The reverse does not hold: a Keeps block with no
  `keeps:` is a recipe that has not established a life, which is
  allowed and honest.
- **It is not derived from the block.** "Fridge at 4 °C, keeps 14
  days" is prose, and picking which of a paragraph's numbers is the
  one you bet on is a judgement, the same as a gauge.

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

### Flavour levels

A flavour entry may carry how loudly it speaks: the word, one space,
a level — `spicy 2`. **Enforced.** The levels are `1` background ·
`2` present · `3` defining, and there is deliberately no finer scale:
three is what you can apply consistently to your own cooking, the
same reasoning as `effort`. A bare word means **unstated**, never
zero — the page draws a meter only for what you have actually
judged. Write `spicy 2`, not `spicy: 2`: the colon turns the entry
into a YAML map and the build will tell you so.

### Deciding a facet — the constraints

The build holds these words to the vocabulary and stops. Which word,
which level, which tier and which flag is a judgement, and the rules
for making it the same way every time are in `agents/refs/` — one
file per judged facet group: `flavour.md`, `effort.md`, `needs.md`
(digest: `docs/facet-constraints.md`). Read the one for the facet
you are setting before you set it. Three rules from there that
matter most, so you have seen them before you look:

- **Every listed flavour carries a level**, and an optional
  ingredient never moves one; in doubt go lower, except `spicy`,
  where you go higher.
- **Effort counts windows, not minutes**: `relaxed` can be left,
  `focused` has a window you must watch, `project` wants the day or
  more than one session. In doubt go higher.
- **A dietary flag is verified against every ingredient line,
  optional and `or` included**, and a known carrier (soy sauce,
  malt, hoisin, mole paste, hard cheese) states its constraint in
  the line or the flag stays off. Absent is *not verified*, never
  *not suitable*, so off is always safe.

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

### Every ingredient must be in the pantry table

You do not write this in the recipe, but the build will stop you if
it is missing. `scripts/pantry.ts` maps **the exact item string** —
what is left after the amount, the unit and the comma-note are taken
off — to the aisle it is bought in and the name it goes on a shopping
list under. A recipe naming an item no other recipe has named yet
fails the build until the table gains a line:

```
"yellow onions":  { aisle: "produce", buyAs: "yellow onions" },
"yellow onion":   { aisle: "produce", buyAs: "yellow onions" },
"cilantro — at serving only": { aisle: "produce", buyAs: "cilantro" },
"or nothing at all; it is excellent plain": { omit: true },
```

Three things that trip people:

- **`buyAs` is the name two recipes merge on**, so it is written as
  the thing you put in the trolley — plural, no preparation, no
  aside. That is how "yellow onion" and "yellow onions" become one
  line, and why the table is the only place that knows they are the
  same purchase. Leave it out and the key itself is used.
- **`omit: true` is for a bullet that is not a purchase** — a line
  offering to add nothing at all. It must be stated, never detected:
  an item nobody has mapped and an item deliberately not bought have
  to look different to the build.
- **An `or` picks one; an `and` does not.** `corn oil or neutral oil`
  is written `buyAs: "neutral oil"` — the recipe offered a choice and
  the table makes it once, so the line joins the six others wanting
  neutral oil. `Monterey Jack and sharp cheddar` keeps its own name,
  because nothing here knows how much of the 200 g is the cheddar and
  a list that split it would be making the number up.

- **The table also refuses a dietary flag it knows is wrong.** An
  item may carry `breaks`, the flags it defeats on every shelf
  (`"ground beef": { aisle: "meat", breaks: FLESH }`), and the build
  fails a recipe that sets one of them. It never adds a flag, and it
  says nothing about a carrier that varies by brand — that is what
  the note on your ingredient line is for (`agents/refs/needs.md`,
  N2).

- `aisle` — exactly one of: `produce` · `meat` · `dairy` · `bakery` · `dry-goods` · `canned` · `spices` · `baking` · `condiments` · `frozen`

The order of that list is the order the shopping list renders in, and
it is a walk through a shop — perimeter first, freezer last so it is
not sitting in the trolley the whole time.

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

A bullet list: storage, freezing, reheating, and for how long. The
prose lives here; the one number a reader browses on goes in
frontmatter as `keeps:` (above), and stating one without this block
fails the build.

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
# keeps: fridge 5d       # optional — uncomment once you have
                          # established a life; absent is *not stated*
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
