# Flavour — the constraints

> One of three references under `agents/refs/`, one per facet group
> that carries a *judgement*: flavour, effort, needs. The digest of
> all three is `docs/facet-constraints.md`. This file is the verbose
> copy: every threshold, every false friend, every worked case, so
> that two authors reading it set the same facet on the same dish.
> Created 2026-09-28. The lists in it are held to
> `scripts/vocabulary.ts` by `scripts/doctrine_test.ts`; the
> reasoning is held by whoever edits it.

## What this facet is for

`flavor:` is the second browse path of DS-01 §07 — "I want something
sweet and spicy" — and the meter on every chip. A reader arrives at
the shelf with a want in mind, and the facet is the archive's promise
that the dish answers it. Filters narrow and never hide, so a recipe
this facet excludes stays on the page wearing the word that excluded
it: a wrong flavour is not invisible, it is *visibly* wrong, on the
front page, every time that reader looks.

The build cannot taste. It holds the words to the vocabulary and the
levels to `1`–`3` and stops there, because inferring what dinner
tastes like from an ingredient list is the guess DS-01 §12 bans. So
the accuracy of this facet rests entirely on the person authoring it,
and these are the rules that person applies. They exist so the
judgement is *repeatable* — so a second author, cooking the same dish
from the same file, would write the same line.

- `flavor` — one or more of: `sweet` · `savory` · `spicy` · `tangy` · `umami` · `bitter` · `salty`

The levels: `1` background · `2` present · `3` defining. A bare word
is *unstated*, never zero.

## The requirements

Numbered so a review can cite them. **F0** is the rule the others
descend from.

### F0. The facet describes the finished dish, on the plate, as written, as tested

Not an ingredient, not a component, not a variation, not the dish a
different cook might make from the same file. The line is authored
from the cook recorded in `tested:`, tasting what came out, at the
scale written (×1 — the scaler never moves a facet).

Three consequences that trip people:

- **A component's flavour is not the dish's flavour.** Sugar in a
  marinade that is then seared off is not sweetness on the plate.
  The two tablespoons of brown sugar in a chili are balance, not a
  flavour; the glaze on a pork belly, laid on in the last sixty
  seconds and tasted in every bite, is.
- **An optional ingredient does not move the facet.** `cayenne, a
  pinch, optional` does not make a gravy spicier than the version
  without it. Author the facet for the dish with every optional
  item *left out*, because that is the dish the file promises; a
  reader who adds the pinch knows what they added.
- **A variant is not the recipe.** A sub-preparation offered as
  "the version worth making" is still a variant. If the variant is
  the dish you would actually serve, the recipe should be written
  that way round; the facet is not where that decision is made.

### F1. A word is listed only when it passes both directions of the filter

Every flavour word is read two ways on the shelf: a reader who
*selects* it wants dishes that deliver it, and a reader who selects
something else sees this dish tagged "hidden by flavour". So a word
earns its place only when:

1. a reader who came to the shelf for that quality would be
   satisfied by this dish, **and**
2. a reader who avoids that quality would be right to steer clear.

A word that passes one test and fails the other is a word at the
wrong level or a word that does not belong. A pinch of pepper passes
neither; a Scotch bonnet passes both.

### F2. Every listed word carries a level

The build allows a bare word; this doctrine does not. The chip draws
a meter only for a stated level, so an unstated word sits beside its
stated neighbours looking like a lesser judgement — which it is.
Every recipe in the corpus states every level, and a review holds
new recipes to that.

The one exception is a recipe imported and not yet cooked, which has
no `tested:` and is not in the archive anyway (F0).

### F3. The levels, operationalised

The words `background`, `present`, `defining` are the meter's
labels. These are the tests behind them:

| Level | The test | If you removed it |
|-------|----------|-------------------|
| `3` defining | The first word you would use describing the dish to someone who has not eaten it. A reader who dislikes this quality declines the dish | It is a different dish, or a failed one |
| `2` present | You taste it in every bite and the recipe put it there on purpose. A reader who dislikes it notices and minds | The dish is flatter but still itself |
| `1` background | You would notice its absence before its presence — a seasoning that has crossed into being tasted. A reader who dislikes it would probably not object | Nobody but the cook would know |

Two calibration rules:

- **When two levels seem right, take the lower — except for
  `spicy`, where you take the higher.** Under-stating sweetness or
  tang disappoints nobody; under-stating heat is the one flavour
  misreading that hurts, because heat is a need as well as a want
  (some readers cannot eat it), and a reader relying on `spicy 1`
  who gets a 2 has been lied to about their dinner. Every doubt in
  this doctrine resolves toward the reader who is relying on the
  answer.
- **A level is authored against the archive, not against the
  world.** `spicy 3` means the hottest register *this archive*
  carries, not the hottest food that exists. The anchors below are
  what "3" is measured from.

### F4. At least one word, at most four, and at most two at level 3

A dish with no flavour is not food, and a dish claiming five is an
ingredient list wearing a facet — `vocabulary.ts` says so in its
own words: a recipe claiming every flavour is as useless as one
claiming none.

Two defining flavours is a real thing (salted caramel; sweet and
sour). Three is a sign that one of them is a `2`.

### F5. Lead with the defining word

The chips render in the order written, so the line reads in
descending level: `[savory 3, spicy 2, umami 2]`. Ties go in the
order you would say them.

### F6. A level of 2 or 3 names its source

For every word at `2` or above, the reviewer can point to the
ingredient line or step that puts it there. A defining quality
usually also surfaces in the title, a gauge, or the note; a `3` that
the document never otherwise mentions is a `3` to question. A `1`
need not be traceable — background is, by definition, the level at
which you stop being able to point.

### F7. Flavour is taste, and nothing else

There are no words here for texture (crisp, creamy), richness (fat),
temperature (cold), aroma (smoky, herbal) or spicing (cinnamon,
cumin). Do not stretch a word to cover one: `savory` is not
"creamy", `sweet` is not "rich", `spicy` is not "spiced" (below).
If a real recipe carries a quality no word covers *and* a reader
would browse for it, the cost is one line in `vocabulary.ts`, one in
`content/recipes/AGENTS.md`, and a definition here **first** — a
word with no threshold is a word two authors set differently.

## The seven words

Each with its definition for this archive, the threshold for each
level, and its false friends — the things that look like the
flavour and are not.

### `sweet`

Sugar, honey, syrup, ripe fruit, caramelisation, or reduction
*tasted as sweetness* on the plate.

- `3` — the dish is a sweet thing: a dessert, a sweet bake, a glaze
  that is the point. Nearly every dessert and sweet bake is a `3`;
  a dessert at `2` is a claim ("not very sweet") and should be one
  the note backs up.
- `2` — a savoury dish with a deliberate sweet element you taste in
  every bite: jammy onions in a sandwich, a hoisin glaze, a
  sweet-and-sour sauce.
- `1` — sweetness you would miss if it went: the corn in a
  cornbread topping, the carrot in a long-cooked sauce.

False friends: sugar used for browning or balance (a teaspoon in a
tomato sauce, a tablespoon in a chili) — not listed. "Rich" — not
this word. Fruit cooked until its sugar has gone to acid (tomato) —
see `tangy`.

### `savory`

The register of a meal: salt, fat, cooked protein, aromatics, and
browned things, tasted together. It is the default of a main course
and says almost nothing on one — nearly every main in the archive is
`savory 3`, which is honest and also why it is a weak filter. Its
information is in where it is *absent* (a dessert) and where it
appears *unexpectedly* (a cheese scone, a savoury oatmeal).

- `3` — a main, a side, a sauce for a main.
- `2` — a dish that is not a meal but leans that way: a savoury
  snack, a bread with cheese or herbs in it.
- `1` — a sweet thing with a deliberate savoury edge: brown butter,
  a miso caramel, a bacon in a dessert.

False friends: "creamy", "hearty", "comforting" — none of these is
a flavour. Salt tasted as itself — see `salty`. Depth from a named
glutamate source — see `umami`, which is the word that carries
information on a main.

### `spicy`

Heat — capsaicin (chilli in any form), piperine (black pepper in
quantity), allyl isothiocyanate (mustard, horseradish, wasabi), or
gingerol (fresh ginger in quantity), *felt* as heat.

- `3` — the dish is about heat. A heat-averse reader declines.
  Anchor: a dish built on whole fresh chillies or a chilli paste
  with nothing to soften it.
- `2` — you would warn a heat-averse guest, and they would be right
  to ask. Anchor: chipotle in adobo through a pot, a chilli-forward
  enchilada sauce, a curry paste at its stated quantity.
- `1` — warmth you would not warn a child about. Anchor: canned
  green chile in a casserole, a pepper-forward gravy, one dried
  chilli in a large braise.

**Take the higher level when in doubt** (F3).

False friends — this word has the most, and every one is a real
error waiting to happen:

- **Spiced is not spicy.** Cinnamon, cumin, coriander, clove,
  allspice, nutmeg, paprika (sweet or smoked), turmeric: aromatic,
  and not heat. A chai, a tagine, a pumpkin bread are not `spicy`.
- **Ginger in a marinade** that is seared or braised away is not
  heat on the plate. Fresh ginger grated into a dressing is.
- **Black pepper as seasoning** is not `spicy 1`. Black pepper as
  the *point* — cracked coarse, added "then more" — is.
- **"Mild" chilli powder or "mild" salsa** as a listed ingredient is
  still heat; author at `1`, not zero, and say so.

### `tangy`

Acid tasted as brightness or sourness: citrus, vinegar, buttermilk,
sour cream or yoghurt in quantity, fermented things, tomato where
it stays sharp.

- `3` — sour-first: a pickle, a ceviche, a lemon curd, a vinegar
  barbecue sauce.
- `2` — a deliberate acid you would name when describing the dish:
  the lime through a taco, the vinegar in a slaw, the buttermilk in
  a dressing.
- `1` — acid you would miss before you could name it: the
  buttermilk in a cake batter, the sour cream folded through a
  casserole, a squeeze of lemon at the end.

False friends: acid used only to balance (a teaspoon of vinegar in
a pot of chili) — not listed. Tomato cooked long with sugar and fat
until it reads sweet and deep — that is `umami`, sometimes `sweet
1`, not `tangy`. Fruit that is sweet on the plate (ripe banana,
blueberries in a batter) — `sweet`, not `tangy`, unless the fruit's
acid is what you taste.

### `umami`

Glutamate and nucleotide depth from a **named source**: aged or hard
cheese (parmesan, pecorino, aged cheddar, gruyère), tomato paste or
long-cooked tomato, soy, miso, doenjang, fish sauce, anchovy,
Worcestershire, dried or cooked-down mushroom, seaweed, long-cooked
meat stock or a browned braise, cured meat.

**The test is that you can name the ingredient supplying it.** "Meat
is umami" is not a source; "the parmesan, the tomato paste and the
ragù cooked two hours" is. A recipe at `umami 2` with no nameable
source is describing `savory` twice.

- `3` — the depth is what the dish is: a miso soup, a mushroom ragù,
  a dashi, an anchovy-built sauce.
- `2` — one or more named sources at a quantity that shapes the
  dish: a lasagna's parmesan and cooked-down tomato, a chili's
  tomato paste and chipotle, a deep-dish pie's cheese and sauce, a
  belly glazed with hoisin and doenjang.
- `1` — a named source present as seasoning: a spoon of tomato
  paste in a soup, a dash of soy in a dressing, parmesan finishing
  a plate.

False friends: `savory` (above — umami is the *specific* depth,
savory the general register). Salt from soy or fish sauce — that is
also `salty`, and a dish built on soy may list both.

### `bitter`

Designed-in bitterness: char, coffee, cocoa and dark chocolate, dark
leafy greens, radicchio and chicory, hops and dark beer, burnt or
very dark caramel, citrus pith and zest in quantity, walnut skins,
certain spices at quantity (fenugreek, turmeric).

- `3` — the bitterness is the point: a Campari thing, a radicchio
  salad, a burnt-caramel dessert, an espresso granita.
- `2` — a deliberate bitter line you taste through: a dark beer in
  a braise, unsweetened cocoa in a mole, charred greens.
- `1` — a bitter edge you would miss: the cocoa in a chilli, the
  zest in a glaze, the char on a griddled sandwich.

False friends: milk chocolate, cocoa syrup, hot chocolate — sweet,
not bitter. A fault (scorched, over-reduced) is never authored as a
flavour; it goes in Rescues.

### `salty`

Salt **tasted as itself**, not salt as seasoning. Every dish in the
archive is seasoned; this word is for a named salty element the
reader will taste: a flaky-salt finish, a cure or brine, a
salted-caramel, soy or fish sauce as a base, anchovy, feta,
halloumi, bacon or ham where they lead, olives, capers, pickles.

- `3` — salt is a lead flavour: salted caramel, a cured thing eaten
  as cured, a brined and finished pork.
- `2` — a salty element you taste in every bite: a soy-glazed
  belly, a feta salad, a bacon-forward dish.
- `1` — a salty accent: parmesan on top, a few capers, a salted
  rim.

False friends: seasoning to taste — never listed. "Well-seasoned" —
not this word. Cheese in general — most cheese is `umami` first and
`salty` only when it is the sharp, salty kind and it leads.

## Worked cases

Hypothetical or drawn from the bench fixture; the corpus's own lines
are the review's business, not this document's.

| Dish | Line | Why |
|------|------|-----|
| Salted caramel sauce | `[sweet 3, salty 2]` | A sweet thing (`3`); the salt is named in the title and tasted in every spoon (`2`), not the lead (`3` would be a salt caramel, which is a different sauce). The bench fixture writes the bare `salty`, which the build allows and F2 does not |
| A cheese scone | `[savory 2, salty 1]` | Not a meal, so `savory` is at `2` and is carrying information; cheddar tasted as sharp and salty at the edge |
| A pumpkin bread with cinnamon, nutmeg and clove | `[sweet 3]` | Spiced, not spicy (F7). The spicing has no word and needs none |
| A red curry at the paste's stated quantity | `[spicy 2, savory 3, umami 1]` | Warn a guest (`2`); a main (`savory 3`); fish sauce present as seasoning (`umami 1`) |
| Jammy-onion grilled cheese | `[savory 3, umami 2, sweet 2]` | The onions are a deliberate sweet line tasted in every bite; the gruyère and the long-cooked onion supply nameable depth |
| Lemon curd | `[sweet 3, tangy 3]` | Two defining flavours, both true, both named in any description of it. The one shape F4 allows two `3`s for |
| A pot of chili with a tablespoon of sugar and a teaspoon of vinegar | `[savory 3, spicy 2, umami 2]` | The sugar and vinegar are balance, and neither is tasted as itself; the chipotle is a `2` because a guest would ask |

## How this is checked

- `scripts/doctrine_test.ts` holds the word list and the level words
  above to `vocabulary.ts`, and holds the corpus to the two rules
  the build does not enforce and a script can: every listed flavour
  carries a level (F2); at most four words and at most two at `3`
  (F4).
- Everything else — the level itself, the source, the false
  friends — is a person's judgement, applied at the cook recorded in
  `tested:` and re-applied whenever the Ingredients or Steps block
  changes. A review cites the requirement it is applying by number.
