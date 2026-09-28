# Needs — the constraints

> One of three references under `agents/refs/`, one per facet group
> that carries a *judgement*: flavour, effort, needs. The digest of
> all three is `docs/facet-constraints.md`. This file is the verbose
> copy — every flag's definition and its hidden carriers, and the
> cuisine test — so that "verified" means the same thing to every
> author. Created 2026-09-28. The lists in it are held to
> `scripts/vocabulary.ts` by `scripts/doctrine_test.ts`; the
> reasoning is held by whoever edits it.

## What this facet group is for

The fourth browse path of DS-01 §07 is **By needs**: `dietary` and
`cuisine`, "gluten-free, and make it Thai". The two halves are not
alike. A cuisine is a *want*, and a wrong one is merely wrong. A
dietary flag is a *need*: a reader cooking for someone with coeliac
disease, a nut allergy, or a conviction is relying on it, and it is
the only facet in the archive whose error can hurt a person. Every
rule below is stricter for that reason, and the strictness costs
nothing — because of the one rule that governs the whole facet:

**An absent flag means *not verified*, never *not suitable*.**
(`vocabulary.ts`, DS-01 §06, §12.) Leaving a flag off is always
safe. Putting one on is a claim.

- `dietary` — zero or more of: `vegetarian` · `vegan` · `gluten-free` · `dairy-free` · `nut-free` · `egg-free` · `pescatarian`
- `cuisine` — zero or more of: `british` · `french` · `italian` · `spanish` · `greek` · `middle-eastern` · `north-african` · `west-african` · `indian` · `thai` · `vietnamese` · `chinese` · `japanese` · `korean` · `mexican` · `american` · `caribbean`

## Dietary — the requirements

**N0** is the rule the others descend from.

### N0. A flag is a verified claim about the dish as written, every ingredient included

Verified means a person has read **every** ingredient line — every
sub-preparation, every "to serve", every "optional", every "or" —
against the flag's definition below and its list of hidden carriers,
and the flag held for all of them. Not "it looks vegetarian". Not
"I would assume the stock is fine". The build infers nothing here on
purpose (DS-01 §12); the person is the check, and this section is
what the check consists of.

Two consequences:

- **Optional ingredients count against a flag.** The recipe as
  written *offers* the malted milk powder; a reader who takes the
  offer is still cooking the recipe. If an optional item would break
  a flag, either the item goes or the flag does. (Contrast flavour,
  where an optional item does *not* move the facet — there the
  reader who adds it knows what they added; here the reader who
  adds it may not know what it carries.)
- **An `or` is verified for both branches.** "Sausage or bacon
  drippings, butter if you have none" — every one of the three must
  hold, or the flag does not.

### N1. Substitutions do not count

"Use gluten-free flour if needed" does not make a recipe
`gluten-free`. The flag describes the file as written, not the
variant a reader might make. If the free version is the one worth
finding, write the recipe that way round — or as a second file.

### N2. A processed ingredient that is a known carrier must state its constraint in the ingredient line

This is the rule that makes the flag *actionable* rather than
merely true. A recipe cannot be `gluten-free` on "2 tbsp soy sauce",
because the shopper will buy soy sauce, and soy sauce is wheat. It
can be `gluten-free` on "2 tbsp tamari, not soy sauce". The
constraint travels with the ingredient onto the shopping list, which
is the only place it can protect anyone.

The carriers are listed per flag below. A recipe naming one of them
bare — no constraint in the line — does not get the flag, however
the author shops.

### N3. Every flag that holds is listed, including the ones another flag implies

The shelf reads flags as words. A reader who selects `dairy-free`
sees the recipes carrying that word — and nothing infers that a
`vegan` recipe is one of them. So the author states it:

| If the dish is verified | It also carries |
|-------------------------|-----------------|
| `vegan` | `vegetarian`, `pescatarian`, `dairy-free`, `egg-free` |
| `vegetarian` | `pescatarian` |

`pescatarian` on its own is for a dish that contains fish or
seafood and no other flesh. A vegetarian dish carries it too, by
this rule, because a pescatarian reader selecting one chip must
find both.

### N4. Kitchen contamination is out of scope, and the archive says so

Every flag is a claim about the *ingredients as written*. It says
nothing about the surfaces, the fryer oil, the shared toaster, or a
"may contain" label on a packet — those are the reader's kitchen and
the reader's packet, and the archive cannot see either. A reader
with an allergy severe enough that traces matter reads the
ingredient lines, and the flag has done its job by getting them to
the right recipe, not by promising what it cannot.

### N5. The flag is verified at `tested:`, and re-verified on any change to Ingredients

A change to the Ingredients block — a new item, a swapped brand, an
`or` added — re-reads every flag against N0 through N3. The review's
rule is mechanical: **if the diff touches Ingredients, the diff
re-verifies `dietary`**, and says so.

### N6. The list stays short, and a new flag is defined here before it exists

The seven flags are the ones the archive verifies. Soy, sesame,
shellfish, sulphites, alliums, nightshades, low-FODMAP, halal,
kosher — none is verified anywhere, and a reader with any of those
needs reads the ingredients, which are on every page and every
print.

A new flag needs, in this order: a real recipe verified against it;
a reader who would browse by it; its definition and carrier list in
this document; and *then* the word in `vocabulary.ts` and
`content/recipes/AGENTS.md`. A flag with no definition is a flag two
authors set differently, and on this facet that is the failure that
hurts.

## The seven flags — definitions and hidden carriers

Each flag: what it means in this archive, then the ingredients that
carry the thing without saying so. The carrier lists are why this
file is the verbose copy. They are not exhaustive — nothing could
be — but every one has caught a real recipe somewhere.

### `vegetarian`

No flesh, and nothing that requires an animal's death. Eggs and
dairy are allowed. Fish is flesh.

Hidden carriers — the ones that look vegetarian and are not:

- **Animal rennet** in hard and aged cheese: Parmigiano-Reggiano,
  Grana Padano, Pecorino Romano, Manchego, many Gruyère, many
  Emmental, some cheddars. The flag needs the line to say
  "vegetarian rennet" or name a cheese that is always so
  (mozzarella, ricotta, paneer, most fresh cheeses, most
  supermarket cheddar in the UK — check the packet, and name it).
- **Gelatin**: marshmallows, gummy sweets, some yoghurts, some
  ice creams, jelly, some cream cheeses, many "mousse" desserts,
  capsules.
- **Lard, tallow, dripping, schmaltz**: pastry, refried beans (the
  traditional and many canned), tortillas from some makers, some
  biscuit and pie recipes, frying fat.
- **Stock and bouillon**: chicken or beef stock in a "vegetable"
  soup or a rice; bouillon powder; many gravy granules.
- **Fish in disguise**: Worcestershire sauce (anchovy), Caesar
  dressing (anchovy), fish sauce, oyster sauce, dashi (bonito),
  some curry pastes (shrimp paste), some kimchi (fish sauce,
  salted shrimp), XO sauce, many "Thai" and "Vietnamese" sauces.
- **Isinglass**: some beers and wines (fining).
- **Cochineal / carmine (E120)** in red colourings.

### `vegan`

`vegetarian`, and no animal product at all: no eggs, dairy, honey,
or anything derived from them.

Hidden carriers, in addition to everything under `vegetarian`:

- **Dairy in disguise**: whey and casein in "non-dairy" creamers and
  many processed foods; milk powder in breads, crackers, sausages,
  crisps, some dark chocolate; butter in pastry, in "vegetable"
  stock cubes, in many breads; ghee.
- **Egg in disguise**: mayonnaise and Kewpie; egg wash on pastry
  and bread; fresh pasta; many noodles; brioche, challah, most
  enriched doughs; meringue, marshmallow fluff, royal icing;
  hollandaise; some glazes.
- **Honey**, in granola, glazes, dressings, some breads.
- **Bone char** in some refined sugars is not on any label and is
  out of the archive's scope — stated here so no author invents a
  rule about it.

### `gluten-free`

No wheat (including spelt, durum, semolina, kamut, farro, bulgur,
couscous), barley, rye, or oats not stated gluten-free. The flag is
about ingredients, not the kitchen (N4).

Hidden carriers — this flag has the most, and most of them are
sauces:

- **Soy sauce** (wheat) — tamari is the substitute, and the line
  must say so. **Hoisin** (often wheat). **Oyster sauce** (often
  wheat). **Teriyaki**, **ponzu**, many **miso** (barley miso;
  rice miso is fine, name it). **Doenjang** (often wheat or
  barley).
- **Malt in any form**: malted milk powder, malt vinegar, malt
  extract, many breakfast cereals, most beer.
- **Thickeners**: a roux, a flour-thickened gravy, condensed soup,
  gravy granules, many stock cubes, some baking powders, some
  spice blends (flour as an anti-caking agent), some icing sugars.
- **Bread in disguise**: breadcrumbs, panko, croutons, stuffing,
  flour tortillas, most wraps, "corn" tortillas that are a
  corn–wheat blend (the line says "100% corn"), some corn chips.
- **Meat in disguise**: sausages and burgers with rusk or
  breadcrumb, some processed ham, imitation crab (surimi), some
  meatballs, breaded anything.
- **Oats** not labelled gluten-free (cross-grown and cross-milled).
- **Seitan**, obviously, and "wheat meat".
- **Some ice cream and frozen desserts** — cookie pieces, brownie
  swirls, malt.

### `dairy-free`

No milk from any mammal or anything made from it: butter, cream,
cheese, yoghurt, buttermilk, sour cream, crème fraîche, ghee, ice
cream, whey, casein, lactose, milk chocolate.

**Eggs are not dairy.** This is the commonest confusion on the
flag, in both directions: an omelette can be `dairy-free`; a
custard cannot be `egg-free`.

Hidden carriers:

- **Whey and casein** in processed foods, "non-dairy" creamers,
  protein powders, some margarines, some crisps and crackers.
- **Milk powder** in breads, sausages, some dark chocolate, some
  spice blends, instant mashes.
- **Butter** in pastry, stock cubes, many breads, brioche, most
  biscuits, ghee.
- **Lactose** in some medicines and sweeteners.
- **Cream-based sauces** described only by name: alfredo,
  béchamel, a "white" gravy.

### `nut-free`

No tree nuts — almond, brazil, cashew, chestnut, hazelnut,
macadamia, pecan, pine nut, pistachio, walnut — and **no peanut**,
which is a legume and is grouped here because the reader with the
need groups it here.

Two rulings, so authors do not each make their own:

- **Coconut is not a nut for this flag.** A reader with a coconut
  allergy reads the ingredients.
- **Nutmeg, butternut, water chestnut** are not nuts.

Hidden carriers:

- **Nut oils**: almond, walnut, hazelnut, groundnut/peanut oil
  (some frying oils are peanut).
- **Nut pastes and butters**: marzipan, frangipane, praline,
  pesto (pine nut), satay, romesco (almond), many curry pastes
  (peanut, cashew), **mole** (almond, peanut, or both — nearly
  every jarred paste).
- **Extracts**: almond extract; some "natural flavourings".
- **Nut milks and creams**: almond milk, cashew cream, many vegan
  cheeses.
- **Toppings and mix-ins**: granola, many breakfast cereals,
  pralines on a dessert, chopped nuts in a bread.
- **Some chocolates**, some biscuits, baklava and most pastries of
  the eastern Mediterranean.

### `egg-free`

No egg of any bird, in any form: whole, white, yolk, powdered, wash.

Hidden carriers:

- **Mayonnaise, Kewpie, aioli, Caesar dressing, hollandaise,
  béarnaise, tartare.**
- **Fresh pasta, egg noodles, many ramen noodles.**
- **Enriched doughs**: brioche, challah, most cake, many breads,
  many pastries, an egg wash on almost any pie or roll.
- **Meringue, marshmallow fluff, royal icing, macarons, custard,
  crème anglaise, custard-based ice cream, some sorbets (egg
  white), mousse.**
- **Binders**: meatballs, burgers, crab cakes, some veggie burgers,
  breaded anything (egg in the coating).
- **Some wines** (fining with albumen).

### `pescatarian`

`vegetarian` with fish and seafood allowed. On its own it marks a
dish that contains fish or seafood and no other flesh; by N3 every
`vegetarian` dish carries it too.

Hidden carriers: everything under `vegetarian` **except** the fish
ones — fish sauce, anchovy, Worcestershire, oyster sauce, dashi and
shrimp paste are all allowed here. What is not: chicken or beef
stock in a fish soup, lard in the pastry of a fish pie, pancetta in
a seafood pasta, gelatin, animal rennet.

## Cuisine — the requirements

### C0. The test is recognition, from inside the tradition

A cuisine is listed when **a cook from that tradition would
recognise the dish as one of theirs, or as an adaptation of one of
theirs.** Not when an ingredient came from there; not when the
dish's name borrows the word. Tomatoes do not make a dish Italian
and a tortilla does not make it Mexican. The reader asking for Thai
(§07) wants something a Thai cook would put on a Thai table, or
would nod at as a version of one.

### C1. `american` is broad on purpose

For this archive `american` means American home cooking including
its regional traditions — Southern, Tex-Mex, New Mexican, Cajun and
Creole, Midwestern casserole, diner, drive-through. A dish that is
Tex-Mex is `american` on this definition, and is `mexican` as well
only if C0 holds for it independently: a Mexican cook would
recognise it as an adaptation of theirs. Enchiladas in a pan pass;
a chili con carne does not; a "King Ranch" casserole is a judgement
the review makes by C0 and not by the tortillas in it.

If the review finds it keeps wanting a word the vocabulary lacks
(`tex-mex`, `southern`, `cajun`), that is the case for widening the
list under `vocabulary.ts`'s own rule — a real recipe needs it and
a reader would browse for it — and not a reason to stretch
`mexican`.

### C2. Order and count

Primary first: the tradition the dish most belongs to. **At most
two.** A genuine hybrid lists both, primary first (a Korean-glazed
belly in a flour tortilla is `[korean, mexican]`; a lasagna as an
American kitchen makes it is `[italian, american]`). Three is a
dish that belongs to none of them.

### C3. Empty is honest, and the doubt resolves to fewer

`cuisine: []` is the right answer for a caramel, a milkshake, a
plain quick bread. When a second cuisine is in doubt, leave it off:
a cuisine is a browse promise, and a reader who selected `mexican`
and found a casserole from Texas has been given something they did
not ask for. (The same direction as a dietary flag, for a different
reason: there the absent flag protects; here the absent word
avoids a false promise.)

### C4. Named cuisines are traditions, not flags

A cuisine says nothing about suitability. `indian` does not mean
`vegetarian`; `japanese` does not mean `dairy-free`. The dietary
flags are the only suitability claims the archive makes.

## Worked cases

| Dish, as written | `dietary` | `cuisine` | Why |
|------|-----------|-----------|-----|
| A milkshake of ice cream, milk, chocolate syrup and optional malted milk powder | `[vegetarian, pescatarian]` | `[american]` | The malt is wheat, and optional counts (N0) — no `gluten-free`. Ice cream may carry gelatin: the flag holds only if the line names an ice cream without it, or the author verified the one bought. Vegetarian implies pescatarian (N3). The drive-through is American (C1) |
| A quick bread with buttermilk and eggs | `[vegetarian, pescatarian]` | `[american]` | Buttermilk rules out `dairy-free`; eggs rule out `egg-free`; flour rules out `gluten-free`; nothing rules out `nut-free` — but the flag is set only if verified, not because nothing was noticed |
| A belly marinated in soy, glazed with hoisin and doenjang, in flour tortillas, with Kewpie | `[]` | `[korean, mexican]` | Pork rules out the first three; soy, hoisin, doenjang and the tortillas each rule out `gluten-free` (N2); Kewpie rules out `egg-free`. Nothing verified, nothing listed — which is honest, not a failure |
| Enchiladas built on a jarred mole paste | `[]` | `[mexican]` | Nearly every mole paste carries almond or peanut, so `nut-free` is off unless the line names a nut-free paste (N2) |
| A gravy of drippings, flour, whole milk | `[]` | `[american]` | The `or` (drippings or butter) is verified for both branches (N0); butter would pass vegetarian, drippings do not, so the flag is off |
| A chili with beef, beans, chipotle, masa | `[]` | `[american]` | C1: chili con carne is American; a Mexican cook would not claim it (C0), however Mexican its pantry |
| A Thai green curry made with a named vegetarian paste and coconut milk | `[vegetarian, pescatarian, dairy-free, nut-free]` | `[thai]` | Coconut is not a nut (ruling); the paste is named as shrimp-free (N2); coconut milk is not dairy. Not `vegan` unless the line also rules out fish sauce and the sugar is not honey |

## How this is checked

- `scripts/doctrine_test.ts` holds the two lists above to
  `vocabulary.ts`, holds the implication table in N3 as data (every
  flag it names is in the vocabulary) **and holds the corpus to it**
  — a `vegetarian` recipe without `pescatarian` fails the build —
  and holds the corpus to C2 (at most two cuisines). The corpus
  check was held back until the first recipe review had ruled on
  the three files that failed it, and switched on the same day
  (2026-09-28).
- Everything else is a person reading every ingredient line
  against the carrier lists, at `tested:`, and again whenever
  Ingredients changes.
