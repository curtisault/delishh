/**
 * The closed vocabularies — DS-01 §06.
 *
 * Every facet a recipe can carry is enumerated here and nowhere else.
 * This is the file that makes `flavour: [sweet]` a build failure
 * instead of a recipe that quietly never appears under SWEET.
 *
 * **Adding a value is a deliberate act.** That is the entire point of
 * a closed vocabulary: the cost of a new flavour is one line in a
 * reviewed diff, and the benefit is that no filter chip is ever
 * backed by a typo. Widen a list only when a real recipe needs it —
 * never pre-emptively, because an unused facet value is a filter that
 * always returns nothing.
 *
 * Data only. Parsing lives in `recipe.ts`, walking and writing in
 * `build-content.ts`.
 */

// ---------------------------------------------------------------------------
// Facets — the four browse paths of DS-01 §07
// ---------------------------------------------------------------------------

/** By meal, half one: when you would eat it. Multi-valued. */
export const SLOTS = [
  "breakfast",
  "lunch",
  "dinner",
  "snack",
  "dessert",
] as const;

/** By meal, half two: what role it plays in the meal. Single-valued. */
export const COURSES = [
  "main",
  "side",
  "sauce",
  "drink",
  "bake",
  "component",
] as const;

/** By flavour. Multi-valued and combinable — "sweet and spicy" is the
 * browse path this exists for, so a recipe claiming every flavour is
 * as useless as one claiming none. */
export const FLAVORS = [
  "sweet",
  "savory",
  "spicy",
  "tangy",
  "umami",
  "bitter",
  "salty",
] as const;

/** By effort, half one: the primary technique. Single-valued — a
 * recipe that sears *and* braises is a braise, and the facet answers
 * "what am I doing for most of this", not "what happens at any point". */
export const METHODS = [
  "bake",
  "roast",
  "sear",
  "fry",
  "deep-fry",
  "grill",
  "braise",
  "stew",
  "steam",
  "boil",
  "poach",
  "simmer",
  "sauté",
  "sugar-work",
  "ferment",
  "cure",
  "pickle",
  "smoke",
  "confit",
  "sous-vide",
  "dough",
  "blend",
  "toast",
  "chill",
  "freeze",
  "no-cook",
] as const;

/** By effort, half two: how much of you it wants. Deliberately three
 * values — a five-point difficulty scale is a scale nobody can apply
 * consistently to their own cooking. */
export const EFFORTS = ["relaxed", "focused", "project"] as const;

/** By needs, half one. **Verified flags only.** An absent flag means
 * "not verified", never "not suitable" — which is why this list stays
 * short and why nothing here is ever inferred from the ingredients. */
export const DIETARY = [
  "vegetarian",
  "vegan",
  "gluten-free",
  "dairy-free",
  "nut-free",
  "egg-free",
  "pescatarian",
] as const;

/** By needs, half two. Optional on any recipe — an empty list is the
 * honest answer for a caramel, and far better than a guess. */
export const CUISINES = [
  "british",
  "french",
  "italian",
  "spanish",
  "greek",
  "middle-eastern",
  "north-african",
  "west-african",
  "indian",
  "thai",
  "vietnamese",
  "chinese",
  "japanese",
  "korean",
  "mexican",
  "american",
  "caribbean",
] as const;

// ---------------------------------------------------------------------------
// Print — DS-01 §09
// ---------------------------------------------------------------------------

/** The template a recipe defaults to. `prep` is absent on purpose: it
 * is supplemental and prints *alongside* any of these, so it is never
 * a recipe's default. */
export const PRINT_TEMPLATES = ["sheet", "card", "booklet"] as const;

/** How many gauges a recipe may carry (DS-01 §06 amendment,
 * 2026-09-21).
 *
 * The cap is the feature. A gauge strip is what you read from a metre
 * away with your hands full, and a sixth entry is the one that turns
 * a glance into a search — at which point the numbers would be better
 * off back in the prose they came from. Five is also what fits the
 * plate's width at the data voice's size without wrapping, on paper
 * and on a narrow screen alike. */
export const GAUGE_MAX = 5;

// ---------------------------------------------------------------------------
// Units — the measurement ladder of DS-01 §05
// ---------------------------------------------------------------------------

/**
 * A unit's `kind` is what the ladder rules key off:
 *
 *  - `mass` is authoritative and prints first; amounts must be whole
 *    grams (no `142.5 g`).
 *  - `volume` is a convenience, prints second and dimmed; amounts are
 *    whole numbers or fraction glyphs, never decimals.
 *  - `count` is indivisible. Scaling may not produce two-thirds of an
 *    egg, so the scaler emits an honest note instead of a false
 *    number (DS-01 §05).
 */
export type UnitKind = "mass" | "volume" | "count";

export const UNITS: Record<string, { kind: UnitKind; canonical: string }> = {
  g: { kind: "mass", canonical: "g" },
  kg: { kind: "mass", canonical: "kg" },

  ml: { kind: "volume", canonical: "ml" },
  l: { kind: "volume", canonical: "l" },
  tsp: { kind: "volume", canonical: "tsp" },
  tbsp: { kind: "volume", canonical: "tbsp" },
  cup: { kind: "volume", canonical: "cup" },
  cups: { kind: "volume", canonical: "cup" },

  clove: { kind: "count", canonical: "clove" },
  cloves: { kind: "count", canonical: "clove" },
  can: { kind: "count", canonical: "can" },
  cans: { kind: "count", canonical: "can" },
  sprig: { kind: "count", canonical: "sprig" },
  sprigs: { kind: "count", canonical: "sprig" },
  head: { kind: "count", canonical: "head" },
  heads: { kind: "count", canonical: "head" },
  stick: { kind: "count", canonical: "stick" },
  sticks: { kind: "count", canonical: "stick" },
  sheet: { kind: "count", canonical: "sheet" },
  sheets: { kind: "count", canonical: "sheet" },
  bunch: { kind: "count", canonical: "bunch" },
  bunches: { kind: "count", canonical: "bunch" },
  slice: { kind: "count", canonical: "slice" },
  slices: { kind: "count", canonical: "slice" },
};

/** What a `yield:` may be measured in. Narrower than `UNITS` because a
 * yield of "¾ tsp" is a mistake, not a recipe. */
export const YIELD_UNITS = ["g", "kg", "ml", "l", "pieces"] as const;

/** Vulgar fraction glyphs and their values. DS-01 §05: volume
 * fractions are glyphs, never decimals — so these are the only legal
 * way to write a part of a spoon. */
export const FRACTIONS: Record<string, number> = {
  "½": 0.5,
  "⅓": 1 / 3,
  "⅔": 2 / 3,
  "¼": 0.25,
  "¾": 0.75,
  "⅕": 0.2,
  "⅖": 0.4,
  "⅗": 0.6,
  "⅘": 0.8,
  "⅙": 1 / 6,
  "⅚": 5 / 6,
  "⅛": 0.125,
  "⅜": 0.375,
  "⅝": 0.625,
  "⅞": 0.875,
};

// ---------------------------------------------------------------------------
// The body blocks — DS-01 §06
// ---------------------------------------------------------------------------

/**
 * The block headings a recipe body may carry, **in the order they must
 * appear**. Blocks 1 (header plate) and 2 (photo) are rendered from
 * frontmatter and so are absent here.
 *
 * `required: true` means the block must be present and non-empty.
 * Ingredients and Steps because there is no recipe without them; Note
 * because it is the one human voice on the page and the reason this
 * archive is yours rather than a database (DS-01 §01).
 *
 * **Equipment precedes Ingredients** (DS-01 §06, amended 2026-09-20).
 * Mise en place reads gear-first: you cannot weigh into a bowl you
 * have not got out. Changing this order is a change to every recipe
 * in the corpus, which is why the build refuses one that disagrees
 * rather than reordering it silently.
 */
export const BLOCKS = [
  { heading: "Equipment", key: "equipment", required: false },
  { heading: "Ingredients", key: "ingredients", required: true },
  { heading: "Steps", key: "steps", required: true },
  { heading: "Watchpoints", key: "watchpoints", required: false },
  { heading: "Rescues", key: "rescues", required: false },
  { heading: "Keeps", key: "keeps", required: false },
  { heading: "Note", key: "note", required: true },
] as const;

/** Blocks the reader follows with a pan on the heat. The procedure
 * word rules (below) apply to exactly these. */
export const PROCEDURE_BLOCKS = [
  "ingredients",
  "equipment",
  "steps",
  "watchpoints",
  "rescues",
  "keeps",
] as const;

// ---------------------------------------------------------------------------
// The word rules — DS-01 §11
// ---------------------------------------------------------------------------

/**
 * `scope` decides where a rule bites:
 *
 *  - `everywhere` — every block except the note.
 *  - `procedure` — the blocks in `PROCEDURE_BLOCKS` only, where the
 *    register is calm and exact. Shelf copy is allowed personality.
 *
 * **The note is exempt from all of it, unconditionally.** Sanding the
 * one human voice on the page down to match the machine would destroy
 * the thing the design exists to frame, so the checker never reads it.
 */
export type WordRule = {
  pattern: RegExp;
  scope: "everywhere" | "procedure";
  because: string;
};

export const WORD_RULES: WordRule[] = [
  {
    pattern: /\b(simply|just)\b/giu,
    scope: "procedure",
    because:
      "it minimises a difficulty the reader is currently having. Cut the word; the sentence is already true without it.",
  },
  {
    pattern: /\b(easy|effortless)\b/giu,
    scope: "procedure",
    because:
      "difficulty is the reader's to judge. Say what the step needs instead — a temperature, a cue, a warning.",
  },
  {
    pattern: /\bfoolproof\b/giu,
    scope: "everywhere",
    because:
      "nothing is, and the claim is what the Rescues block exists to replace.",
  },
  {
    pattern: /\b(toss|whip up|throw together)\b/giu,
    scope: "procedure",
    because:
      "a vague verb where the procedure needs a real one. Name the motion: fold, beat, swirl, render, slake.",
  },
  {
    pattern: /\b(game[- ]?changer|crowd[- ]?pleaser)\b/giu,
    scope: "everywhere",
    because: "marketing register. delishh never sells.",
  },
  {
    pattern: /\bthe best\b[^.!?]{0,40}\bever\b/giu,
    scope: "everywhere",
    because: "marketing register. delishh never sells.",
  },
  {
    pattern: /!/gu,
    scope: "procedure",
    because:
      "procedure is calm and exact. Enthusiasm belongs on the shelf and in the note, not in a step.",
  },
  {
    pattern: /\p{Extended_Pictographic}/gu,
    scope: "procedure",
    because: "wrong register, and it breaks the type casting (DS-01 §05).",
  },
];

// ---------------------------------------------------------------------------
// Types derived from the lists above
// ---------------------------------------------------------------------------

export type Slot = (typeof SLOTS)[number];
export type Course = (typeof COURSES)[number];
export type Flavor = (typeof FLAVORS)[number];
export type Method = (typeof METHODS)[number];
export type Effort = (typeof EFFORTS)[number];
export type Dietary = (typeof DIETARY)[number];
export type Cuisine = (typeof CUISINES)[number];
export type PrintTemplate = (typeof PRINT_TEMPLATES)[number];
export type BlockKey = (typeof BLOCKS)[number]["key"];
