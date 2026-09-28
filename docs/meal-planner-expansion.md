# delishh meal planner, expansion — several meals a day

> Companion to `docs/meal-planner.md` (the first planner) and
> `docs/design-standard.md` (DS-01 Revision 2). Created 2026-09-27,
> **started and finished the same day, early** — see the decision
> log. The section
> *When to start* is kept as the questions this was meant to wait
> for. This doc owns the expansion's *sequence and scope*; DS-01 owns
> look, feel and voice.

## What it is

The same week, with room. A day holds up to five meals instead of
one, each optionally labelled — breakfast, lunch, dinner, snack,
dessert — from the vocabulary the recipes already use. Nothing is
turned on: a day grows when a second meal is added to it, and a
reader who plans seven dinners sees the first planner exactly, with
the same picture.

It is for the hyper-organised, and it is built so that they pay for
it and nobody else does. Every ruling below is read against that:
if a change would make the one-meal week say or show one more thing,
the ruling is wrong.

## Decision log

Ruled 2026-09-27, at the expansion's framing:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| A day is a list | **A day holds an ordered list of entries, one to five, in the order they were added.** The first planner's *one meal or nothing* is the case of a list of one. There is no mode, no toggle, no preference: the ADD press on a held day is the whole expansion's surface, and it appears only once a day has something to add to | A FULL WEEK toggle (a preference to store, name in the colophon, and keep two views agreeing over); a day that is always five rows (a 35-cell week for a person planning seven dinners) |
| Labels | **An entry may carry a label from `SLOTS` in `scripts/vocabulary.ts`, or none.** Optional, because a one-meal day should never be made to say *dinner* (the first plan's ruling, kept). The five words are the recipe vocabulary's own, duplicated into `Plan.slots` and held to `vocabulary.ts` by a test, the way `GroceryList.aisles` is held by `aisles_test.ts`. Labels are **not unique** within a day — two snacks is a real day — and a label never reorders anything | A planner-specific label set (a second vocabulary for the same five words); labels required once a day has two (the second meal forcing a word onto the first); auto-sorting a day by label (the week rearranging itself under a thumb — §10's zero register on this surface) |
| The cap | **Five entries a day, the size of the slot vocabulary.** A count, not a slot check: five unlabelled entries is a full day too. At five the ADD press is **replaced by a sentence** — *Five is a full day* — so the limit is stated where the press was, never a control that silently vanished | No cap (the picture's height budget becomes the only limit, and it is soft); hiding ADD at five (a control that vanishes without saying why) |
| Adding to a held day | **ADD opens the same entry field the empty day opens**, under the day's last meal, and appends. One field, the same two outcomes — a match press sets a recipe, Enter keeps the words. The label is set afterwards, on the entry, never asked for at entry time: typing *eggs* should not stall on *which meal* | A label picker inside the entry field (two questions where the first planner asks one); a per-slot entry field (five fields on every held day) |
| Setting a label | **A press on the entry's label mark** — reading *NO LABEL* in the data voice when unset — opens the five words and NONE as presses. On the recipe page's ADD TO PLAN the same six presses follow the day picker, **with none preselected**: the slots the recipe *declares* are marked the way the shelf marks them, because that is declared data shown, but choosing one is the reader's, because a recipe tagged *breakfast* placed as breakfast by default is a guess made on their behalf (§06, nothing is inferred) | Preselecting the recipe's first declared slot (inference); no label from the recipe page (a second trip to the plan page for the one fact the recipe page already knows) |
| Moving, with lists | **Pick up and place, extended by one rule.** Placing a lifted entry on a **day** appends to that day; placing it on an **entry** swaps the two, whether they share a day or not. So reordering within a day is a swap with a neighbour, and every target is a press that already exists. A full day refuses a placed entry with the same sentence the ADD press gives, and the entry stays lifted | Insert-before on placing over an entry (a second gesture to teach, and a full day then needs a different refusal); move arrows within a day (a third mechanism beside pick-and-place) |
| The stored shape | **One shape, versioned by its form, not a number.** The first planner stores a day as one object; the expansion stores a day as an array of entries. The expansion's decoder reads both — an object becomes a list of one unlabelled entry — and writes only the array. No `version:` field: a hand-maintained number that nothing forces to move is the counter the archive retired in 2026-09-21, and the shape already says which it is | A one-off migration on boot that rewrites the key (a write nobody asked for, on a store that may be full); a version field (see the revision counter's retirement) |
| The picture, with lists | **The same portrait card.** Each held day heads its entries; each entry's meal in the procedure voice, its label in the data voice at the right where the first planner's ARCHIVE mark sits (`LUNCH · ARCHIVE`, or one, or neither). A one-meal day draws exactly as before — the day and the meal on one line — so a picture of a seven-dinner week is byte-for-byte the first planner's. **A height budget of one phone screen** (1080 × 1920 logical): past it the type steps down one size, then a second; past that the card grows taller, because a meal cut off a picture is a broken picture (§12), and a taller card is only a scroll | A 7-column landscape grid once any day has two (arrives as a thumbnail in every chat client — the compact promise lost for exactly the people this is for); one card per day past the budget (seven files, and the week no longer one thing) |
| What the nav counts | **Still days.** The link's count says how much of the week is covered, and five meals on Monday covers Monday once. The page itself says the meal count | Counting entries (a number that grows without the week being any more planned) |

Ruled 2026-09-27, at the start:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| Starting early | **Started the day the first planner shipped, at the user's call**, twice asked. The plan's own advice was to wait for real weeks of use and the three questions under *When to start*. Recorded so the next reader knows those questions were not answered first, and that the first planner's real-device share pass (its Phase 3) was still outstanding | Waiting, as this doc advised |
| Phase 1 keeps the pages running | **The storage reshapes; the page API does not, yet.** `get`, `set`, `move` and `placeRecipe` keep their exact one-meal behaviour over the new lists — `get` is a day's first meal, `set` makes the day that one meal — so the first planner's pages run unchanged until Phase 2's presses replace them. The list API (`entries`, `add`, `remove`, `label`, `moveEntry`) sits beside them | Rewriting the pages in the same phase (a phase that cannot be tested on its own); a flag to switch shapes (two planners to keep in agreement) |

## What changes from the first planner

Everything the first planner rules stands, except where the ruling
above supersedes it. The concrete diff, so that the first
implementation can be built with these seams in place at no cost:

- **`src/Plan.elm`.** `Plan` becomes `Day -> List Entry` with
  `Entry = { meal : Meal, label : Maybe Slot }`. `set` becomes `add`
  (refuses at five, returning the plan unchanged and a reason, the
  way `Shelf.judge` returns a verdict). `clear day` empties the list;
  `remove day index` takes one. `move` gains the day-versus-entry
  target. `label day index (Maybe Slot)` is new. `toShare` emits
  days holding entry lists. **The first planner keeps every one of
  these behind `Plan`'s API**, so `Page.Plan`, `Page.Recipe` and the
  shell never learn the shape and the expansion touches pages only
  where new presses appear.
- **The decoder.** The first planner's decoder is already total
  (malformed → empty week). The expansion's reads the first
  planner's object shape as a list of one, and `PlanTests` keeps a
  first-planner fixture as a stored-value test forever, because the
  browser that still holds one is real.
- **`Page.Plan`.** ADD under a held day; the label mark on each
  entry and its six presses; the full-day sentence; REMOVE per
  entry rather than per day. The empty day, the entry field, CLEAR
  THE WEEK, and pick-and-place are unchanged in look.
- **`Page.Recipe`.** ADD TO PLAN's day picker gains the label row
  after the day. PLANNED · WED becomes PLANNED · WED, FRI when a
  recipe is on several days, and pressing it offers a remove per
  day.
- **The shell.** `lifted` becomes `Maybe ( Day, Int )`. Nothing
  else: no new port, no new key, no new flag.
- **`boot.js`.** The drawing reads the new `toShare` shape and
  gains the height budget and the two type steps. The port names
  and the share flow are unchanged.
- **`docs/about.md` and DS-01 §12.** Unchanged. The key is the same
  key and the sentence *the week they planned* still describes it.
  DS-01 §06 gains a one-line note that the slot vocabulary is also
  read by the planner, and `scripts/plan_slots_test.ts` holds
  `Plan.slots` to `SLOTS`.

## Phases

### Phase 1 — the data ✅ done 2026-09-27

- [x] `Plan` reshaped: entries, labels, `add` with its refusal
      (`Err DayFull`), `remove`, `label`, `moveEntry` with the two
      targets (`OntoDay`, `OntoEntry`), `slots`, `cap`.
- [x] The two-shape decoder: a first-planner object reads as a list of
      one, unlabelled, and both shapes may sit in one stored week.
      Arrays only are written; a label only when there is one.
- [x] `tests/PlanTests.elm` — 25 more: the cap and its reason, five
      unlabelled as full, remove, label set/unset, non-unique labels,
      a word outside the vocabulary refused, both move targets
      including a swap into a full day, both stored shapes, and the
      refusals (empty array, six entries, unknown or non-word label).
      The first planner's stored value stays as a fixture.
- [x] `scripts/plan_slots_test.ts` — `Plan.slots` held to `SLOTS`,
      spelling and order, and `cap` held to the vocabulary's size. A
      misspelled slot was tried and fails it.
- [x] DS-01 §06: one sentence saying the planner reads the slot list.

**Two things a Phase 1 build does, to know before Phase 2 lands.**
It writes the array shape on the next save of any plan, so a browser
that loads this build and then an older one loses its week; deploys
only move forward. And nothing in it can make a second entry, but a
hand-made store could hold one: the page would show and share only
each day's first meal until Phases 2 and 3.

### Phase 2 — the pages ✅ done 2026-09-27

- [x] ADD under a held day; the full-day sentence in its place at
      five.
- [x] The label mark and its six presses on the plan page; after the
      recipe page's day picker, the same six, declared slots marked
      and none preselected.
- [x] REMOVE per entry. PLANNED · DAY, DAY on the recipe page, where
      pressing a planned day takes the recipe off that day.
- [x] Pick-and-place's entry target. A full day's end is a sentence
      rather than a press, so a placed meal cannot be refused by
      surprise; the shell still keeps it lifted if a refusal arrives.
- [x] `tests/PlanPageTests.elm` — 13 more for days of several, and
      the lifted-state tests re-cut for lists; `RecipePageTests` — 7
      for the picker's add, full and label row.

**Where the build differs from this plan, and why:**

- **A one-meal week does not render identically to the first
  planner's**, and could not: this plan also puts ADD on every held
  day. What holds instead is that a day of one never shows a label
  mark or the words NO LABEL, and ADD is a quiet word like REMOVE, not
  a slab. The snapshot test the plan asked for became tests of those
  two facts.
- **Label marks show on a day of two or more, or on a meal already
  labelled.** A single labelled meal keeps its mark, so a label set
  from the recipe page is visible on a day of one.
- **The picker no longer replaces.** The first planner armed a held
  day and replaced it on the second press. With room for five, a held
  day takes the recipe at the end, and a full day refuses in words
  under the picker. `Plan.placeRecipe` now returns `Result Refusal`.
  DS-01 §04's fourth-surface amendment is re-cut to say clearing the
  week is the plan's one control that asks twice.
- **Lifted, the targets are the meals and each day's end.** Every
  other meal is a swap; each held day ends in a SET HERE press, or the
  full-day sentence; an empty day is still one row press. The lifted
  meal's own day has no end press: setting it at the end of its own
  day is not a move the model makes, and PUT BACK is on the meal.
- **Day names sit level with a day's first meal.** Centred on the
  stack, THURSDAY floated beside its third meal; found in the browser.

**Verified in a real browser** against `deno task build`: a stored
week mixing both shapes read correctly; labelling, adding with Enter,
a swap across days, and a labelled meal moved to an empty day with its
label; REMOVE gone while a meal was held; the stored week matching at
each step; and on the recipe page, a day of two taking the recipe at
the end, the recipe's own slots marked, only None seated until the
reader chose.

### Phase 3 — the picture ✅ done 2026-09-27

- [x] The drawing over the new shape. `Plan.toShare` now sends each
      day's meals in order, each with its source and label. A meal's
      mark is `LUNCH · ARCHIVE`, or one, or neither, right-aligned
      on its first line. The day's name sits on its first meal's
      line. Meals on one day are 22 pixels apart, and the rule
      between days is unchanged.
- [x] The height budget of 1920 pixels and the two type steps, ×0.85
      then ×0.72 on the meals' type and the gap between them. A week
      still too tall after both grows taller rather than cutting.
- [x] The alt text says every meal with its label and source, and
      keeps the first planner's wording for a day of one.
- [x] **The pixel comparison.** The picture code from the first
      planner's commit (`3d58c30`) and from this phase were loaded
      into the same page and drew the same one-meal week:

      | Week | First planner | Expansion | Differing pixels |
      |---|---|---|---|
      | Six meals, one three-line, lit | 1080 × 1273 | 1080 × 1273 | 0 |
      | The same, dark | 1080 × 1273 | 1080 × 1273 | 0 |
      | Empty | 1080 × 1158 | 1080 × 1158 | 0 |

      The expansion cost a one-meal week nothing. The harness was a
      throwaway: both drawing blocks cut out of `boot.js` at `const
      PICTURE` and `async function sharePicture`, wrapped as modules,
      decoded to `ImageData` and compared channel by channel.

**Seen, not only measured.** A mixed week of eight meals, some
labelled, drew at 1080 × 1500, inside one screen. A full week, 35
meals with every label, stepped down twice and still grew to
1080 × 3162. That is the ruling working, but it is worth knowing: a
maxed-out week is three screens tall, and the wide `LUNCH · ARCHIVE`
marks narrow the meal column enough that long names wrap to two lines.

## When to start

Not before the first planner has been used for real weeks, and not
until that use has answered, in either direction:

- **Did a day want a second meal?** If the entry field was ever used
  to type *lunch: soup* into a day already holding dinner, yes. If
  own meals stayed single names, the expansion may be solving a
  problem nobody had.
- **Did the picture get shared, and read?** The expansion's whole
  risk sits in the picture; if the first one is not being sent, the
  height budget has nothing to protect.
- **Was the cap of one ever hit and resented?** A recipe page's ADD
  TO PLAN replacing a held day is the first planner's only lossy
  press. If it never bit, five is generous; if it bit weekly, this
  starts.

## Open items

- **The week onto the list, with lists.** Carried from the first
  plan. With several recipes a day it is more attractive and no
  better defined: *this week's recipes* is now a bigger set, and
  whether the list wants all of them or those not yet bought for is
  still only answerable by use.
- **A label the vocabulary lacks.** *Brunch*, *tea*. The rule is the
  vocabulary's rule: a new word is one line in `vocabulary.ts`, a
  line in `Plan.slots`, and a test that fails if only one moves.
  Widened only when a real week wants it, never in advance.
- **Two-line meals in a five-entry day.** The height budget's worst
  case: thirty-five wrapped entries. The type steps assume names of
  a few words; if own meals turn out to be sentences, the drawing
  wants a per-entry line cap before it wants a third type step.
