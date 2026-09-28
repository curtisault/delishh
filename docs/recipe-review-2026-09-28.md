# Recipe review — 2026-09-28, the first pass against the constraints

> Every recipe in `content/recipes/` read against `docs/facet-constraints.md`
> and the three references under `agents/refs/`, one requirement at a
> time, the day the constraints were written. Twelve of eighteen files
> changed. The rulings that will recur are dated in `docs/decisions.md`
> under *Ruled 2026-09-28, at the first recipe review*; this is the
> file-by-file record of what was found, what was changed, and what was
> left for a person. A later review appends its own dated file beside
> this one rather than editing it.

## How to read it

Each entry names the requirement applied by its number (F for
flavour, E for effort, N for dietary, C for cuisine). *Changed* is
what the frontmatter now says; *held* is what was read and left;
*flagged* is what the reviewer could not settle from the file and
hands to the cook.

Two things the review did not do, on purpose. It set no `nut-free`
anywhere: every recipe with no nut in it also has a bare processed
carrier (`neutral oil`, which the donuts offer as peanut; chili
powder; chocolate chips; broth; sausage), and N2 will not take the
flag until the ingredient line states its constraint. And it changed
one time and no effort tier: times are the tested cook's numbers, and
the doctrine does not invent one it did not measure.

## The recipes

### beef-bean-chili-bake

- **Changed** `flavor: [savory 3, spicy 2]` → `[savory 3, spicy 1, sweet 1]`. Three tablespoons of chili powder and a teaspoon of smoked paprika, no chile, is warmth you would not warn a child about (F3, the `spicy` anchors). The corn kernels and sugar in the cornbread lid are the ref's own example of `sweet 1`.
- **Held** `effort: project`: one window (the browning, spices and paste, about twenty minutes) and a session break, since the chili is cooled completely and wrapped before the batter is mixed on baking day (E2, rule 3). `method: bake` — the ninety-minute two-stage bake is where the time and the risk are (E5). `cuisine: [american]`.
- **Flagged** nothing.

### blueberry-cake-donuts

- **Changed** `dietary: [vegetarian]` → `[vegetarian, pescatarian]` (N3).
- **Held** `flavor: [sweet 3, tangy 1]`: the buttermilk, the lemon and the freeze-dried berries are the ref's own `tangy 1`. `effort: project` — the corpus anchor (E3). `method: deep-fry`.
- **Flagged** `nut-free` is impossible as written: the oil line reads *canola or peanut*, and N0 verifies both branches of an `or`.

### breakfast-strata

- **Changed** nothing.
- **Held** `flavor: [savory 3]`: three cups of cheddar and the sausage are nameable, but the plate reads eggy and bready first, and the doubt goes lower (F3). `effort: focused` — no window, one session break for the soak.
- **Found** a flaw in the doctrine, not the recipe: E2 as first written sent any two-session recipe to `project`, which made this a project for soaking overnight. Corrected in `agents/refs/effort.md` and the digest: a session break alone is `focused`; a session break *and* a window, a window over thirty minutes, or components each with a window, is `project`. No recipe's tier moved.

### brown-sugar-banana-bread

- **Changed** `dietary: [vegetarian]` → `[vegetarian, pescatarian]` (N3).
- **Held** `flavor: [sweet 3]`: cinnamon is spiced, not spicy (F7); the sour cream is below `tangy 1`. `effort: relaxed` — the corpus anchor.
- **Flagged** one line-edit from `nut-free`: the note says *no nuts is a position*, and the only carrier is the optional chocolate chips, which would need to say *nut-free* on the line (N2). The cook's call, since it is the flag that can hurt.

### chicago-deep-dish

- **Changed** `cuisine: [american, italian]` → `[american]`. An Italian cook would not recognise a Chicago pie as theirs or as an adaptation they would own (C0); `american` covers Italian-American by C1, and a second cuisine in doubt comes off (C3).
- **Held** `flavor: [savory 3, umami 2]`: the parmesan, the tomato and the sausage fond are nameable sources (F6). The quarter-teaspoon of pepper flakes in the sausage is below `spicy 1`. `effort: project` — a rise, a lamination, a chill, a press and a bake want the day.
- **Flagged** nothing.

### chicken-enchilada-casserole

- **Changed** `flavor: [savory 3, spicy 2]` → `[savory 3, spicy 1]`. The Watchpoints say *the sauce is mild by design* and route real heat to chipotles the recipe does not include. The higher-when-in-doubt rule for heat is for doubt, not for overriding the author's own word (F3).
- **Held** `cuisine: [mexican, american]`: enchiladas in a pan are an adaptation a Mexican cook recognises (C0). `effort: focused` — one short window where the spices can go past toasty.
- **Flagged** nothing.

### chicken-pot-pie-casserole

- **Changed** nothing.
- **Held** `flavor: [savory 3]`: the mushrooms and broth are a `umami 1` at most, and the doubt goes lower. `effort: focused` — one window of about twenty minutes (vegetables to dry, roux, simmer) and the rest can be left.
- **Flagged** the total. `1h25m` is the active time plus the pastry stage and the rest, and omits the covered heat-through before the pastry goes on, which the recipe's own gauge puts at 65 minutes from frozen. The tested cook may have baked it fresh from a warm filling; left as the author's number for the cook to correct (E4).

### chicken-wild-rice-casserole

- **Changed** nothing.
- **Held** `flavor: [savory 3, umami 2]`: browned mushrooms, Gruyère, parmesan and chicken broth are named sources at a quantity that shapes the dish (F6). `effort: focused`.
- **Flagged** one line-edit from `nut-free`, on the same terms as the banana bread: the carriers are the broth and the panko, neither of which states a constraint.

### chipotle-beef-black-bean-chili

- **Changed** `cuisine: [american, mexican]` → `[american]`. Chili con carne is Texan; a Mexican cook would not claim it, however Mexican its pantry (C0, C1).
- **Held** `flavor: [savory 3, spicy 2, umami 2]`: three chipotles and their adobo through a pot is the ref's anchor for `spicy 2`; the tomato paste, tomatoes and beef fond are the umami. The teaspoon of brown sugar is balance and is not listed. `effort: project` — nearly thirty minutes of continuous window at the start and an afternoon at the stove. `method: stew` — cubed chuck tenderised in liquid, which is what separates it from `simmer` (E5).
- **Flagged** nothing.

### classic-lasagna

- **Changed** nothing.
- **Held** everything. `italian` stays: a ricotta-and-mozzarella lasagna is an adaptation an Italian cook recognises as theirs (C0). `effort: project` — a ragù with a browning window, a ricotta layer and an assembly.
- **Flagged** nothing.

### french-onion-grilled-cheese

- **Changed** nothing.
- **Held** `flavor: [savory 3, umami 2, sweet 2]` — the ref's own worked case. `salty` was considered for the Gruyère and the broth dip and left off: doubt goes lower. `french` stays: onions, Gruyère, bread and a beef broth are the soup rearranged, which a French cook would nod at (C0). `effort: project` on the 45-minute onion window alone (E2, a window over thirty minutes). `method: sauté` — the onions carry the time and the risk (E5).
- **Flagged** nothing.

### green-chile-chicken-rice

- **Changed** `flavor: [savory 3, spicy 2]` → `[savory 3, spicy 1, tangy 1]`; `cuisine: [american, mexican]` → `[american]`. The Watchpoints say *mild as written*, and roasted green chile in a casserole is the ref's own `spicy 1`. A cup of full-fat sour cream folded through, with lime at the finish, is its `tangy 1`. New Mexican cooking is `american` by C1.
- **Held** `effort: focused`. `method: bake`, on the tie-break that the reader would say they are making a casserole (E5); the stovetop rice and the bake share the time.
- **Flagged** nothing.

### king-ranch-chicken

- **Changed** `cuisine: [american, mexican]` → `[american]`. The note calls it *the Texas classic*, and it is (C0, C1).
- **Held** `flavor: [savory 3, spicy 1]`: two teaspoons of chili powder and half a teaspoon of cayenne, which the Watchpoints call *a warm background*. `effort: focused`.
- **Flagged** nothing.

### korean-pork-belly-tacos

- **Changed** `flavor: [sweet 3, savory 2, umami 2]` → `[sweet 3, salty 2, umami 2, savory 2]`; `time.total: 19h` → `21h`. A belly marinated in soy and glazed with hoisin and doenjang is the ref's own example of `salty 2`, and the glaze cue says *sweet first, salt second*. Four words is F4's ceiling; the slaw's tablespoon of rice vinegar was considered for `tangy 1` and left off. The total: an eight-hour bath, the ice bath, an overnight that E4 counts at twelve hours, and fifty active minutes is 21 h, not 19.
- **Held** `savory 2` on a main. The ref's `savory` definition was widened to say so: a main whose defining quality is something else carries savoury at `2` under it. `effort: project` — three sessions across two days, and the sear and glaze are both windows. `method: sous-vide`. `cuisine: [korean, mexican]` — the genuine hybrid C2 allows.
- **Flagged** nothing.

### mole-enchiladas

- **Changed** `flavor: [savory 3, spicy 2, sweet 1]` → `[savory 3, spicy 2, sweet 1, bitter 1]`. The note calls the sauce *dense and sweet-bitter*; chocolate and a chile paste are the ref's `bitter 1`.
- **Held** `spicy 2`: a chile-forward paste and a chipotle, and heat's doubt goes higher (F3). `effort: project` — a queso with a window, a mole with a window, a two-hour chill. `cuisine: [mexican]` — enchiladas de mole, recognisably.
- **Flagged** never `nut-free`: the peanut or almond butter, and nearly every jarred paste.

### southern-white-gravy

- **Changed** nothing.
- **Held** `flavor: [savory 3, spicy 1]`: coarse-cracked pepper *plus more, then more* is pepper as the point, which is `spicy 1`; the optional cayenne does not move a flavour (F0). `effort: focused` — the corpus anchor. `dietary: []` — the fat line's `or` includes drippings, so the vegetarian branch fails (N0).
- **Flagged** nothing.

### wendys-style-frosty

- **Changed** `flavor: [sweet 2]` → `[sweet 3]`; `dietary: [vegetarian]` → `[vegetarian, pescatarian]`; the ice cream line now reads *softened slightly — one without gelatin in it*. A dessert at `sweet 2` is a claim the note must back up, and it did not (F3). Ice cream is a gelatin carrier, so the existing `vegetarian` flag needed the line to say so (N2); the item string is unchanged, so the pantry table is too.
- **Held** the cocoa and syrup are the milk-chocolate register, not `bitter` (F7's false friend). `effort: relaxed`; `method: blend`.
- **Flagged** `gluten-free` is impossible as written: the malted milk powder is optional, and optional counts against a flag (N0). `egg-free` is unverified: ice cream may be custard-based.

### white-chicken-chili

- **Changed** `cuisine: [american, mexican]` → `[american]` (C0, C1).
- **Held** `flavor: [savory 3, spicy 1]`: two seeded jalapeños, which the Watchpoints call *mild*, and roasted green chile. The lime and sour cream are at the bowl and were left below `tangy 1`. `effort: focused`. `method: simmer` — nothing is being tenderised.
- **Flagged** nothing.

## What the review changed in the doctrine

Two corrections the corpus forced, both recorded in `docs/decisions.md`:

- **E2, the session rule.** A session break alone is `focused`, not `project`. The strata exposed it.
- **The `savory` definition.** A main led by another flavour carries savoury at `2`. The belly taco exposed it.

And one rule switched on: the N3 corpus check in `scripts/doctrine_test.ts`, once the three vegetarian recipes carried `pescatarian`.

## Left for the cook

- The two `nut-free` candidates (banana bread, wild rice casserole), each one ingredient-line edit away.
- The pot pie's total.
- Whether the six cuisine drops feel too thin on the shelf. If so, the answer logged under *Open* is a `tex-mex` value, not `mexican` restored.
