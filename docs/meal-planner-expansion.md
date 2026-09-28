# delishh meal planner, expansion — several meals a day

> Companion to `docs/meal-planner.md` (the first planner) and
> `docs/design-standard.md` (DS-01 Revision 2). Created 2026-09-27,
> **not yet scheduled.** The first planner ships and is used for some
> weeks before this is built; the section *When to start* says what
> that use has to show. This doc owns the expansion's *sequence and
> scope*; DS-01 owns look, feel and voice.

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

### Phase 1 — the data

- [ ] `Plan` reshaped: entries, labels, `add` with its refusal,
      `remove`, `label`, `move` with the two targets, `slots`.
- [ ] The two-shape decoder, with the first planner's stored value
      as a permanent fixture.
- [ ] `tests/PlanTests.elm` extended: the cap, the refusal reason,
      label set/unset, non-unique labels, both move targets, both
      stored shapes.
- [ ] `scripts/plan_slots_test.ts` — `Plan.slots` held to
      `vocabulary.ts`, order and spelling.

### Phase 2 — the pages

- [ ] ADD under a held day; the full-day sentence in its place at
      five.
- [ ] The label mark and its six presses, on the plan page and after
      the recipe page's day picker, declared slots marked and none
      preselected.
- [ ] REMOVE per entry; PLANNED · DAY, DAY on the recipe page with a
      remove per day.
- [ ] Pick-and-place's entry target; the refusal on a full day
      leaves the entry lifted.
- [ ] `tests/PlanPageTests.elm` extended: a seven-dinner week renders
      identically to before (a snapshot of the first planner's
      markup, held), the sixth ADD is a sentence, a label reads in
      the data voice, the recipe page marks declared slots and
      preselects nothing.

### Phase 3 — the picture

- [ ] The drawing over the new shape: day headers, entry rows, the
      label mark, the one-meal day drawn on one line as before.
- [ ] The height budget and the two type steps; growth past them.
- [ ] A first-planner week rendered through the expansion's drawing
      and compared pixel-for-pixel to the first planner's output,
      recorded here. That comparison is the test that the expansion
      cost nobody anything.

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
