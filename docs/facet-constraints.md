# delishh facet constraints — flavour, effort, needs

> Companion to `docs/design-standard.md` (DS-01 Revision 2) and
> `content/recipes/AGENTS.md`. Created 2026-09-28. This doc is the
> **digest** of three references under `agents/refs/` — `flavour.md`,
> `effort.md`, `needs.md` — which are the verbose copies: every
> threshold, every hidden carrier, every worked case. This one holds
> the principles and the numbered requirements so a review can cite
> them; the refs hold the detail so two authors apply them the same
> way. Where a ref and this digest disagree, one of them is stale,
> and `scripts/doctrine_test.ts` holds the lists in all four to
> `scripts/vocabulary.ts`. DS-01 governs both.

## Why these three, and not the fourth

DS-01 §07 gives the shelf four browse paths. **By meal** (`slot` +
`course`) needs no doctrine: the only requirement for a meal is
food, and whether a strata is breakfast is not a claim anyone is
relying on. The other three carry a *judgement* a reader acts on:

| Path | Fields | What the reader is relying on |
|------|--------|-------------------------------|
| By flavour | `flavor` (word + level) | That the dish tastes the way the chip says |
| By effort | `method` + `effort` + `time` | That the evening will go the way the row says |
| By needs | `dietary` + `cuisine` | That the dish is safe for the person they are cooking for, and is the food they asked for |

The build holds each of these to a closed vocabulary and stops
there. It cannot taste, cannot know whether a step can be walked
away from, and refuses on principle to read an ingredient list and
decide it is vegetarian (§12: nothing is ever inferred). So the
accuracy of these facets rests on the person who authors them, and
these constraints are what makes that judgement *repeatable*: the
requirement is that two authors, cooking the same dish from the same
file, write the same line.

**The idea, in one sentence:** these are requirements for more
accurate recipes, codified so the accuracy does not depend on who
was cooking.

## The principle every rule descends from

**Every doubt resolves toward the reader who is relying on the
answer.** It cuts differently on each facet, which is why each has
its own list:

- A flavour level in doubt goes **lower** — except `spicy`, which
  goes **higher**, because heat is a need as well as a want.
- An effort tier in doubt goes **higher**: a reader who planned for
  `focused` and got `relaxed` lost nothing.
- A dietary flag in doubt is **left off**: absent means *not
  verified*, never *not suitable*, so leaving it off is always safe
  and putting it on is a claim.
- A cuisine in doubt is **left off**: it is a browse promise, and
  `[]` is honest.

And one rule shared by all three: **the facet is authored from the
cook recorded in `tested:`, for the dish as written, at ×1.** Not
from reading the source, not for a variant, not for a reheat.

## Flavour

Verbose copy: `agents/refs/flavour.md`.

- `flavor` — one or more of: `sweet` · `savory` · `spicy` · `tangy` · `umami` · `bitter` · `salty`
- Levels: `1` background · `2` present · `3` defining. A bare word
  is unstated, never zero.

| # | Requirement |
|---|-------------|
| F0 | The facet describes the finished dish on the plate, as written, as tested. A component's flavour is not the dish's; an **optional ingredient does not move it**; a variant is not the recipe |
| F1 | A word is listed only when it passes both directions of the filter: a reader who wants it would be satisfied, **and** a reader who avoids it would be right to steer clear |
| F2 | Every listed word carries a level. The build allows a bare word; the doctrine does not |
| F3 | `3`: the first word you would use, and a reader who dislikes it declines. `2`: tasted in every bite, put there on purpose. `1`: you would notice its absence before its presence. In doubt, lower — except `spicy`, higher |
| F4 | At least one word, at most four, at most two at `3` |
| F5 | Lead with the defining word; the chips render in the order written |
| F6 | A `2` or `3` names its source: the reviewer can point to the line or step that puts it there |
| F7 | Flavour is taste only. No word for texture, richness, temperature, aroma or spicing — and **spiced is not spicy** |

The word that carries the most error is `spicy` (cinnamon is not
heat; pepper as seasoning is not `spicy 1`; pepper as the point is).
The word that carries the least information is `savory` (nearly
every main is a `3`); its neighbour `umami` is the one that says
something on a main, and it requires a **nameable source** — the
parmesan, the tomato paste, the doenjang — or it is `savory` twice.

## Effort

Verbose copy: `agents/refs/effort.md`.

- `method` — exactly one of: `bake` · `roast` · `sear` · `fry` · `deep-fry` · `grill` · `braise` · `stew` · `steam` · `boil` · `poach` · `simmer` · `sauté` · `sugar-work` · `ferment` · `cure` · `pickle` · `smoke` · `confit` · `sous-vide` · `dough` · `blend` · `toast` · `chill` · `freeze` · `no-cook`
- `effort` — exactly one of: `relaxed` · `focused` · `project`

| # | Requirement |
|---|-------------|
| E0 | Effort measures **attention**, not time and not skill. Time is its own field and the shelf shows it; skill belongs in Watchpoints and Rescues |
| E1 | `relaxed`: no step a minute's inattention costs; you can leave the room. `focused`: at least one bounded **window** you must watch; you can talk, not read. `project`: the day, or more than one session, or a long window, or several components each with a window |
| E2 | Count the windows. None → `relaxed`. One or two under ~15 min, or no window but a session break the recipe makes you respect → `focused`. Three or more, or one over ~30 min, or more than one session with a window, or components each with a window → `project`. On a line, take the higher |
| E3 | Three corpus anchors define the tiers by example — `brown-sugar-banana-bread` (relaxed), `southern-white-gravy` (focused), `blueberry-cake-donuts` (project) — and every recipe is placed relative to them |
| E4 | `active` is the minutes you are doing something, including waits you cannot leave; `total` is first step to plate with **every hold included**, an overnight at least twelve hours, a minimum counted at the minimum. Round as coarsely as honesty allows. Reheating is in neither |
| E5 | `method` is the dominant physical process; where two share the time, the one that carries the risk wins, then the one the reader would name. Stew tenderises, simmer does not; roast browns a whole thing, bake cooks an assembled one; blend is not no-cook |
| E6 | Authored from the tested cook, and re-counted whenever Steps changes |
| E7 | The facet is authored for the equipment listed: a bath makes eight hours `relaxed`; a thermometer turns a window into a wait |
| E8 | Skill is not a facet, and neither is washing up |

## Needs

Verbose copy: `agents/refs/needs.md`.

- `dietary` — zero or more of: `vegetarian` · `vegan` · `gluten-free` · `dairy-free` · `nut-free` · `egg-free` · `pescatarian`
- `cuisine` — zero or more of: `british` · `french` · `italian` · `spanish` · `greek` · `middle-eastern` · `north-african` · `west-african` · `indian` · `thai` · `vietnamese` · `chinese` · `japanese` · `korean` · `mexican` · `american` · `caribbean`

Dietary is the only facet whose error can hurt a person, and every
rule is stricter for it. The strictness costs nothing, because an
absent flag is *not verified*, never *not suitable*.

| # | Requirement |
|---|-------------|
| N0 | A flag is a verified claim about the dish as written, **every ingredient included** — every sub-preparation, every "to serve", every "optional", both branches of every "or". Optional ingredients count *against* a flag (the reverse of flavour, because here the reader may not know what they added) |
| N1 | Substitutions do not count. "Use GF flour if needed" is not `gluten-free` |
| N2 | A processed ingredient that is a known carrier states its constraint **in the ingredient line** — "tamari, not soy sauce", "corn tortillas, 100% corn" — or the flag is not set. The constraint has to reach the shopping list to protect anyone |
| N3 | Every flag that holds is listed, including the implied ones: `vegan` also carries `vegetarian`, `pescatarian`, `dairy-free`, `egg-free`; `vegetarian` also carries `pescatarian`. The shelf reads words and infers nothing |
| N4 | Kitchen contamination is out of scope and the archive says so: the flag is about ingredients, not surfaces, oil or "may contain" |
| N5 | Verified at `tested:`, and **any diff to Ingredients re-verifies every flag** and says so |
| N6 | The list stays short. A new flag needs a real recipe, a reader who would browse by it, and its definition and carrier list in the ref **before** the word enters the vocabulary |

The definitions, in brief — the ref carries each flag's hidden
carriers, which is where the verification actually happens:

- `vegetarian` — no flesh and nothing requiring an animal's death: watch animal rennet in hard cheese, gelatin, lard, stock, Worcestershire, fish sauce.
- `vegan` — vegetarian and no animal product: watch whey and casein, milk powder, egg wash, mayonnaise, honey.
- `gluten-free` — no wheat, barley, rye, or oats not stated so: watch soy sauce, hoisin, malt, roux, panko, flour tortillas, sausage rusk.
- `dairy-free` — no milk or anything from it. **Eggs are not dairy.** Watch whey, milk powder, butter in pastry and stock cubes.
- `nut-free` — no tree nut and no peanut; **coconut is not a nut** for this flag. Watch nut oils, pesto, satay, mole paste, almond extract.
- `egg-free` — no egg in any form: watch mayonnaise and Kewpie, fresh pasta, enriched dough, egg wash, meringue, custard.
- `pescatarian` — vegetarian with fish allowed; on its own it marks a dish that contains fish and no other flesh.

| # | Requirement |
|---|-------------|
| C0 | A cuisine is listed when **a cook from that tradition would recognise the dish as theirs, or as an adaptation of theirs**. Not because an ingredient came from there |
| C1 | `american` is broad on purpose — Southern, Tex-Mex, New Mexican, Cajun, casserole, diner. A Tex-Mex dish is `american`, and `mexican` too only if C0 holds independently |
| C2 | Primary first; at most two |
| C3 | `[]` is honest; a second cuisine in doubt is left off |
| C4 | A cuisine is a tradition, never a suitability claim |

## What is checked, and what is not

`scripts/doctrine_test.ts`:

- holds every list above, and in each ref, to `vocabulary.ts` — the
  same pattern as `agents_test.ts`, for the same reason: a
  hand-maintained copy of a machine-held list lies the first time
  the list changes;
- holds the corpus to the rules that are mechanical: every flavour
  carries a level (F2); at most four words and two at `3` (F4);
  the three effort anchors exist and carry their tiers (E3); at
  most two cuisines (C2);
- holds the implication table in N3 to the vocabulary, and the
  corpus to it (a `vegetarian` recipe without `pescatarian` fails the
  build) — held back until the first recipe review had ruled on the
  three files that failed it, and switched on the same day.

`scripts/pantry.ts` (from 2026-09-28) carries a `breaks` list on
the items that defeat a dietary flag on every shelf, and the build
refuses a recipe that sets a flag one of its items breaks. It never
adds a flag; brand-dependent carriers stay silent there and are the
ingredient line's job (N2).

Everything else — the level, the window count, the verification —
is a person, at the tested cook, citing the requirement by number.

## The rulings

The decisions behind this doctrine — where it lives, the direction
of doubt, optional ingredients, implied flags, why the corpus check
for N3 waits, why it is not rendered in-app — are dated in
`docs/decisions.md` under *Ruled 2026-09-28, at the facet
constraints*. This document carries the requirements; that one
carries the reasoning and what was rejected.
