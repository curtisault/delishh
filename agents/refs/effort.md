# Effort — the constraints

> One of three references under `agents/refs/`, one per facet group
> that carries a *judgement*: flavour, effort, needs. The digest of
> all three is `docs/facet-constraints.md`. This file is the verbose
> copy. Created 2026-09-28. The lists in it are held to
> `scripts/vocabulary.ts` by `scripts/doctrine_test.ts`; the
> reasoning is held by whoever edits it.

## What this facet group is for

The third browse path of DS-01 §07 is **By effort**, and it reads
three fields together: `method`, `effort` and `time`. The question
it answers is "what am I up for tonight?" — which is not one
question but three. *What will I be doing* (method), *how much of me
does it want* (effort), and *when will we eat* (time). A reader who
has a free Sunday and a reader who has forty minutes before a
meeting both use this path, and both are relying on the answer. A
recipe that says `relaxed` and then wants twenty minutes of you at a
hot pan has lied to the second reader at the worst possible moment.

The build checks the words, the duration grammar, and that total is
never less than active. It cannot know whether a step can be walked
away from. That is what this document is for.

- `method` — exactly one of: `bake` · `roast` · `sear` · `fry` · `deep-fry` · `grill` · `braise` · `stew` · `steam` · `boil` · `poach` · `simmer` · `sauté` · `sugar-work` · `ferment` · `cure` · `pickle` · `smoke` · `confit` · `sous-vide` · `dough` · `blend` · `toast` · `chill` · `freeze` · `no-cook`
- `effort` — exactly one of: `relaxed` · `focused` · `project`

## The requirements

**E0** is the rule the others descend from.

### E0. Effort measures attention, not time and not skill

The three values answer one question: *how much of you does the
recipe need, and when.* Not how long it takes — that is `time`, and
the shelf shows it separately for exactly this reason. Not how hard
the technique is — a difficult thing that takes five minutes is
`focused`, not `project`, and the difficulty belongs in Watchpoints
and Rescues where it can be acted on.

A nineteen-hour sous-vide is mostly waiting. A twenty-five-minute
gravy is all attention. The facet has to be able to say that the
second one wants more of you than the first, and it can only say
that if it never reads the clock.

### E1. The three values, defined by what you can do while it cooks

| Value | The test | What you can do meanwhile |
|-------|----------|---------------------------|
| `relaxed` | No step where a minute's inattention costs the dish. Interruptible at any point: a phone call, a child, the door | Something else entirely. Read; leave the room |
| `focused` | At least one **window** where you must be present and watching — a roux, an emulsion, a sear, a fry, a caramel — but the windows are bounded and the rest can be left | Talk. Not read |
| `project` | The recipe wants the day, or more than one session, or continuous attention over a long stretch, or several components each with its own focused window | Plan the day around it |

A **window** is a stretch of a step whose cue is a *state you must
catch* — "until the edges run clear", an oil temperature held, "do
not move it", "the moment it thickens" — as opposed to a state that
arrives and waits for you (a bake reaching 96 °C, a chill reaching
cold, a soak reaching four hours).

### E2. The decision procedure

Walk the Steps block and count the windows. Then:

1. **No windows, one session** → `relaxed`. Mix and bake, blend and
   pour, stew that simmers with a lid on.
2. **Either of the following** → `focused`:
   - one or two windows, each under about fifteen minutes, and the
     rest can be left;
   - no window, but a **session** break the recipe makes you respect
     — a hold on the order of hours or a night between two active
     stretches (assemble, soak four hours, bake). You must come back,
     which is more than `relaxed` asks, and it is all it asks.
3. **Any of the following** → `project`:
   - three or more windows;
   - any single window longer than about thirty minutes of
     continuous attention (holding a frying temperature through
     four batches; forty-five minutes at a pan of onions);
   - more than one session **and** at least one window (chill two
     hours minimum, then fry at a held temperature; brown a chili,
     freeze it, bake it under a fresh batter);
   - more than one component that each carries its own window (a
     ragù *and* a béchamel *and* an assembly).

Components alone do not make a project; components each with a
window do. A casserole with a sauce, a filling and an assembly, where
only the sauce has a window, is `focused`. A session break alone
does not either: a strata is not a project because it soaks
overnight, and the rule that said so was corrected at the first
recipe review (2026-09-28).

The thresholds are stated in minutes so that two authors land on the
same side of them, and they are approximate because a kitchen is.
When the count sits on a line, take the **higher** value: a reader
who planned for `focused` and got `relaxed` has lost nothing; the
reverse has lost their evening.

### E3. The archive's anchors

Three recipes in the corpus define the three values by example, and
every new recipe is placed *relative to them*, not against an
imagined scale:

| Value | Anchor | Why it is the anchor |
|-------|--------|----------------------|
| `relaxed` | `brown-sugar-banana-bread` | Mash, mix, pour, bake to a temperature. Nothing in it can be missed by a minute |
| `focused` | `southern-white-gravy` | One window — the roux, then the eight-minute simmer that must be stirred — and nothing else. Twenty-five minutes, every one of them at the pan |
| `project` | `blueberry-cake-donuts` | Two sessions (a chill of two hours minimum, then the fry), and the fry is a held temperature through batches: a long window *and* a session break |

If an anchor is ever re-tiered, this table moves with it, and the
recipes placed against it are re-read.

### E4. Time — the two numbers, and what each includes

`time: { active, total }`. Both are honest clocks, and they measure
different things:

- **`active`** is the minutes you are *doing something* — hands on,
  or standing in a window. It **includes** every wait you cannot
  leave (frying at a held temperature, stirring a simmer) and
  **excludes** every wait you can (a bake, a chill, a soak, an
  overnight, a bath).
- **`total`** is first step to plate, **every hold included**. An
  overnight is at least twelve hours. "Start two days before" is at
  least a day and a half. A hold stated as a *minimum* ("chill 2 h
  minimum, or overnight") is counted at the minimum, and the gauge
  or the note says longer is better.

Three rules the build does not hold:

- **Round as coarsely as honesty allows.** Active to the nearest
  five minutes. Total to five minutes under an hour, to fifteen
  under four hours, to the hour above that, to the half-day above a
  day. `time: { active: 47m, total: 1h23m }` is a precision nobody
  cooked to.
- **`total` never quietly drops a hold.** The single commonest lie
  on a recipe site is a total that stops at the oven door. If the
  Keeps block or a gauge says "overnight is better", the total says
  what the recipe *requires*, and the note says what is better.
- **Reheating is not in either number.** The facets describe making
  the dish; a from-frozen bake time is a gauge, not a `total`.

### E5. Method — the dominant physical process

`content/recipes/AGENTS.md` already says the method answers "what am
I doing for *most* of this", not "what happens at any point", and
that a recipe that sears and then braises is a braise. Two
tie-breakers for when two processes share the time:

1. **The process that carries the risk wins** — the one the
   Watchpoints are about, the one with the window. Forty-five
   minutes of onions at a pan and five minutes of griddling a
   sandwich is a `sauté`.
2. **The process the reader would name wins.** Ask what they would
   say they were doing. "I'm making a casserole" is `bake`; "I'm
   doing a belly in the bath" is `sous-vide`.

Distinctions that have already needed drawing:

- **`stew` against `simmer`.** A stew tenderises something in
  liquid over a long time — cubed beef, dried beans from raw. A
  simmer cooks a liquid at a simmer with nothing being tenderised —
  a gravy, a soup of already-cooked chicken, a sauce reducing.
- **`bake` against `roast`.** Roast is dry heat on a whole thing
  (a bird, a tray of vegetables) that browns; bake is an oven doing
  the cooking of an assembled thing (a casserole, a bread, a pie).
- **`fry` against `sauté` against `sear`.** Sear is brief, high,
  for a crust and then something else happens; sauté is a pan
  cooking through with movement; fry is shallow oil doing the
  cooking; `deep-fry` is submerged.
- **`toast` against `bake`.** Toast is browning a surface, dry —
  nuts, spices, bread; a griddled sandwich whose point is the
  browned bread could be `toast` if nothing else in the recipe
  outweighs it.
- **`no-cook`** is for a dish with no heat at all; `chill` and
  `freeze` are for dishes where the cold *is* the cooking (a
  set custard, a granita). A blended milkshake is `blend`, not
  `no-cook`: the process is the blending.

The method also colours the page (DS-01 §04: an acid names a
physical process), so a wrong method is a wrong accent on every
surface the recipe appears on. That is a second reason to get it
right and not a reason to pick the prettier one.

### E6. Authored from the tested cook

The `tested:` date is the cook that produced these three fields. An
effort authored from reading the source — "it looks focused" — is
the inference §12 bans, wearing a person's name. Every recipe in the
archive has been cooked as written; if one has not, it does not have
a `tested:` and is not in the archive.

When the Steps block changes, the count in E2 is re-run. A step
gaining a window is the commonest way a `relaxed` becomes a
`focused` without anyone noticing.

### E7. Equipment counts, and the facet is authored for the equipment listed

A thermometer turns "watch for the moment" into "wait for 96 °C". A
bath turns eight hours of attention into eight hours of none. The
facet describes the recipe *with the Equipment block honoured*: a
sous-vide belly is `relaxed` during the bath and a `project` only
because of the sessions around it. A reader without the gear reads
the Equipment block, which is why it comes first.

### E8. Skill is not a facet, and neither is mess

A recipe that needs practice (lamination, a tempered chocolate) is
tiered by its windows and sessions like any other. The practice it
needs is said in Watchpoints, and what happens when the practice is
missing is said in Rescues. A recipe that dirties every pan in the
kitchen is tiered the same way; washing up is nobody's window.

## Worked cases

| Dish, as written | Windows | Sessions | `effort` | Why |
|------|---------|----------|----------|-----|
| A quick bread, mixed and baked to a temperature | 0 | 1 | `relaxed` | Nothing can be missed by a minute |
| A milkshake, blended | 0 | 1 | `relaxed` | Five minutes, none of them a window |
| A roux gravy with a stirred simmer | 1 (the roux and the simmer, continuous) | 1 | `focused` | One window, the whole recipe; still one window |
| A casserole: a roux-based sauce, then assembly, then a bake | 1 | 1 | `focused` | The sauce has the window; the assembly and the bake do not |
| A strata: assemble, soak four hours, bake | 0 | 2 | `focused` | No window, but the soak is a session break the recipe makes you respect (E2, rule 2) |
| Cake donuts: mix, chill two hours, fry at a held temperature in batches | 1 long | 2 | `project` | A window over thirty minutes *and* a session break |
| A lasagna: ragù, béchamel, assembly, bake | 2 (the ragù's browning, the béchamel) | 1 | `project` | Two components each with a window, plus the assembly; and the ragù's simmer is long enough to make it a day |
| A belly: bath eight hours, ice bath, chill overnight, sear, glaze | 2 (the sear, the glaze) | 3 | `project` | Three sessions across two days. The bath itself is `relaxed`; the recipe is not |
| A chili with a cornbread top: brown and simmer, cool and freeze, then batter and bake | 1 (the browning) | 2 | `project` | A window *and* a session break — the chili is made, cooled completely and wrapped, and the batter is mixed on the baking day (E2, rule 3) |

## How this is checked

- `scripts/doctrine_test.ts` holds the method and effort lists above
  to `vocabulary.ts`, and holds the three anchors in E3 to the
  corpus: each anchor file exists and carries the effort it anchors.
  An anchor that drifts is a scale with no zero.
- The build already refuses a `total` less than `active`
  (`scripts/recipe.ts`).
- The window count, the sessions, the rounding and the method
  tie-breaks are a person's judgement, applied at the tested cook
  and re-run whenever the Steps or Equipment block changes.
