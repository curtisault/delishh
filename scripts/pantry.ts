/**
 * The pantry table — what each ingredient is, as a purchase.
 *
 * **Data only.** The join runs in `build-content.ts`; the shopping
 * list's arithmetic lives in `src/GroceryList.elm`.
 *
 * Two questions this answers that an ingredient line cannot:
 *
 *  - **Which part of a shop is it in.** One of `AISLES`, chosen by a
 *    person. Reading "potatoes" and reasoning your way to produce is
 *    the inference DS-01 §06 refuses for a gauge, a keeping life and
 *    a flavour level, and it fails the same way: quietly, plausibly,
 *    and only once you are standing in the wrong aisle.
 *  - **What it is called in the trolley** (`buyAs`, defaulting to the
 *    key). This is the name two recipes merge on. The corpus writes
 *    "yellow onion" in one file and "yellow onions" in another, and
 *    "cilantro" beside "cilantro — at serving only"; those are one
 *    purchase. Collapsing them by stemming the strings would be the
 *    same guess in a tidier hat, so the table states the answer.
 *
 * Three conventions, because the table is only as good as its
 * consistency:
 *
 *  - **`buyAs` is written as the thing on the shelf** — plural where
 *    you buy more than one, no preparation, no aside. "melted butter"
 *    is butter; "ribs celery" is celery.
 *  - **An `or` resolves to the one you would actually buy.** The
 *    author offered a choice; the shopper makes it once, here, and
 *    "corn oil or neutral oil" joins the six other lines wanting
 *    neutral oil instead of starting a seventh.
 *  - **An `and` does not.** "Monterey Jack and sharp cheddar" stays
 *    one line under its own name, because nothing here knows how much
 *    of the 200 g is the cheddar, and a list that split it would be
 *    making the number up.
 *
 * `omit: true` is for a bullet that is not a purchase at all — tap
 * water, or an option to add nothing. It is stated rather than
 * detected on purpose: an item nobody has mapped and an item
 * deliberately not bought must never look the same to the build.
 */

import { type Aisle, AISLES, type Dietary } from "./vocabulary.ts";

/** What the table says about one item. Either where to buy it, or
 * that it is not bought.
 *
 * `breaks` is the dietary flags this item **defeats on every shelf**:
 * beef is never vegetarian, flour is never gluten-free. The build
 * refuses a recipe that sets a flag one of its items breaks — the one
 * direction of dietary error a machine can catch without guessing
 * (agents/refs/needs.md, N0). Absent means *says nothing*, the same
 * contract as an absent flag; it is never "safe for". The bar for
 * listing a flag here is that it is true of every bottle, so a brand
 * that varies — the gelatin in an ice cream, the wheat in a hoisin,
 * the rennet in a Gruyère — stays off, and the ingredient line's own
 * note (N2) remains the only way that flag is set. The table never
 * adds a flag. */
export type Purchase =
  | { aisle: Aisle; buyAs?: string; breaks?: readonly Dietary[] }
  | { omit: true };

/** The sets a `breaks` draws from, named so a row reads as a fact
 * ("this is flesh") rather than a list someone typed. */
export const FLESH: readonly Dietary[] = ["vegetarian", "vegan", "pescatarian"];
export const DAIRY: readonly Dietary[] = ["vegan", "dairy-free"];
export const EGG: readonly Dietary[] = ["vegan", "egg-free"];
export const GLUTEN: readonly Dietary[] = ["gluten-free"];
export const NUT: readonly Dietary[] = ["nut-free"];
export const ANIMAL: readonly Dietary[] = ["vegan"];

/** What the build attaches to an ingredient it could place. */
export type Shop = { aisle: Aisle; buyAs: string };

/**
 * Every distinct ingredient string in the corpus, and what it is as a
 * purchase. Keyed on the **exact** `item` the parser produces — the
 * line with its amount, unit and comma-note removed, em-dash asides
 * and all.
 *
 * Grouped by aisle for reading, but the grouping carries no meaning:
 * the `aisle` field is what the build reads.
 */
export const PANTRY: Record<string, Purchase> = {
  // --- produce -------------------------------------------------------------
  "carrots": { aisle: "produce" },
  "carrot": { aisle: "produce", buyAs: "carrots" },
  "ribs celery": { aisle: "produce", buyAs: "celery" },
  "chopped parsley": { aisle: "produce", buyAs: "parsley" },
  "cilantro": { aisle: "produce" },
  "cilantro — at serving only": { aisle: "produce", buyAs: "cilantro" },
  "corn kernels": { aisle: "produce" },
  "cremini mushrooms": { aisle: "produce" },
  "mushrooms": { aisle: "produce" },
  "garlic": { aisle: "produce" },
  "garlic clove": { aisle: "produce", buyAs: "garlic" },
  "fresh ginger": { aisle: "produce" },
  "Napa cabbage": { aisle: "produce" },
  "green bell pepper": { aisle: "produce", buyAs: "green bell peppers" },
  "red bell pepper": { aisle: "produce", buyAs: "red bell peppers" },
  "jalapeños": { aisle: "produce" },
  "jalapeño": { aisle: "produce", buyAs: "jalapeños" },
  "lemon": { aisle: "produce", buyAs: "lemons" },
  "lemon juice": { aisle: "produce", buyAs: "lemons" },
  "lime": { aisle: "produce", buyAs: "limes" },
  "limes": { aisle: "produce" },
  "lime juice": { aisle: "produce", buyAs: "limes" },
  "roasted green chiles": { aisle: "produce" },
  "Roma tomatoes": { aisle: "produce" },
  "scallions": { aisle: "produce" },
  "thyme": { aisle: "produce", buyAs: "fresh thyme" },
  "very ripe bananas — 1¼ cups mashed": { aisle: "produce", buyAs: "bananas" },
  "white onion": { aisle: "produce", buyAs: "white onions" },
  "yellow onion": { aisle: "produce", buyAs: "yellow onions" },
  "yellow onions": { aisle: "produce" },

  // --- meat ----------------------------------------------------------------
  "beef chuck": { aisle: "meat", breaks: FLESH },
  "skin-on pork belly": { aisle: "meat", breaks: FLESH },
  "ground beef": { aisle: "meat", breaks: FLESH },
  "skirt steak": { aisle: "meat", breaks: FLESH },
  "bacon": { aisle: "meat", breaks: FLESH },
  "boneless chicken thighs": { aisle: "meat", breaks: FLESH },
  "chicken thighs": { aisle: "meat", breaks: FLESH },
  // One bird answers all four. What differs between them is how it is
  // torn up after it is cooked, which is not a thing you buy.
  "cooked chicken": { aisle: "meat", breaks: FLESH },
  "shredded chicken": { aisle: "meat", buyAs: "cooked chicken", breaks: FLESH },
  "shredded chicken thigh": { aisle: "meat", buyAs: "cooked chicken", breaks: FLESH },
  "shredded rotisserie chicken": { aisle: "meat", buyAs: "cooked chicken", breaks: FLESH },
  "breakfast sausage": { aisle: "meat", buyAs: "bulk breakfast sausage", breaks: FLESH },
  "bulk breakfast sausage": { aisle: "meat", breaks: FLESH },
  "bulk Italian sausage": { aisle: "meat", breaks: FLESH },
  "sausage or bacon drippings": { aisle: "meat", breaks: FLESH },

  // --- dairy & eggs --------------------------------------------------------
  "butter": { aisle: "dairy", buyAs: "unsalted butter", breaks: DAIRY },
  "melted butter": { aisle: "dairy", buyAs: "unsalted butter", breaks: DAIRY },
  "unsalted butter": { aisle: "dairy", breaks: DAIRY },
  "buttermilk": { aisle: "dairy", breaks: DAIRY },
  "heavy cream": { aisle: "dairy", breaks: DAIRY },
  "milk": { aisle: "dairy", buyAs: "whole milk", breaks: DAIRY },
  "whole milk": { aisle: "dairy", breaks: DAIRY },
  "whole milk or cream": { aisle: "dairy", buyAs: "whole milk", breaks: DAIRY },
  "cream cheese": { aisle: "dairy", breaks: DAIRY },
  "sour cream": { aisle: "dairy", buyAs: "full-fat sour cream", breaks: DAIRY },
  "full-fat sour cream — no substitutes": {
    aisle: "dairy",
    buyAs: "full-fat sour cream",
    breaks: DAIRY,
  },
  "sour cream or full-fat Greek yogurt": {
    aisle: "dairy",
    buyAs: "full-fat sour cream",
    breaks: DAIRY,
  },
  "crema and lime wedges": { aisle: "dairy", breaks: DAIRY },
  "eggs": { aisle: "dairy", buyAs: "large eggs", breaks: EGG },
  "large egg": { aisle: "dairy", buyAs: "large eggs", breaks: EGG },
  "large eggs": { aisle: "dairy", breaks: EGG },
  // A yolk is bought as a whole egg; counting it with them is what
  // stops the list asking for six eggs and one mystery.
  "egg yolk": { aisle: "dairy", buyAs: "large eggs", breaks: EGG },
  "Gruyère": { aisle: "dairy", breaks: DAIRY },
  "Gruyère or Swiss": { aisle: "dairy", buyAs: "Gruyère", breaks: DAIRY },
  "Monterey Jack": { aisle: "dairy", breaks: DAIRY },
  "sharp cheddar": { aisle: "dairy", breaks: DAIRY },
  "Monterey Jack and sharp cheddar": { aisle: "dairy", breaks: DAIRY },
  "cheddar and Monterey Jack": {
    aisle: "dairy",
    buyAs: "Monterey Jack and sharp cheddar",
    breaks: DAIRY,
  },
  "grated parmesan": { aisle: "dairy", buyAs: "parmesan", breaks: DAIRY },
  "parmesan or pecorino": { aisle: "dairy", buyAs: "parmesan", breaks: DAIRY },
  "low-moisture mozzarella": {
    aisle: "dairy",
    buyAs: "whole-milk low-moisture mozzarella",
    breaks: DAIRY,
  },
  "whole-milk low-moisture mozzarella": { aisle: "dairy", breaks: DAIRY },
  "whole-milk ricotta — whole-milk only; see Watchpoints": {
    aisle: "dairy",
    buyAs: "whole-milk ricotta",
    breaks: DAIRY,
  },
  "queso fresco or cotija": { aisle: "dairy", buyAs: "queso fresco", breaks: DAIRY },
  "white American cheese": { aisle: "dairy", breaks: DAIRY },

  // --- bakery --------------------------------------------------------------
  "sourdough": { aisle: "bakery", breaks: GLUTEN },
  "day-old sourdough": { aisle: "bakery", buyAs: "sourdough", breaks: GLUTEN },
  "corn tortillas": { aisle: "bakery" },
  "corn tortillas — corn": { aisle: "bakery", buyAs: "corn tortillas" },
  "fresh flour tortillas": { aisle: "bakery", buyAs: "flour tortillas", breaks: GLUTEN },
  "flour tortillas": { aisle: "bakery", breaks: GLUTEN },
  "small flour tortillas": { aisle: "bakery", buyAs: "flour tortillas", breaks: GLUTEN },

  // --- dry goods -----------------------------------------------------------
  "lasagna noodles": { aisle: "dry-goods", breaks: GLUTEN },
  "long-grain white rice — white only; see Watchpoints": {
    aisle: "dry-goods",
    buyAs: "long-grain white rice",
  },
  "wild rice blend": { aisle: "dry-goods" },
  "panko": { aisle: "dry-goods", breaks: GLUTEN },
  "toasted pepitas — seeds": { aisle: "dry-goods", buyAs: "pepitas" },

  // --- canned & jarred -----------------------------------------------------
  "beef broth": { aisle: "canned", breaks: FLESH },
  "chicken broth": { aisle: "canned", breaks: FLESH },
  "evaporated milk": { aisle: "canned", breaks: DAIRY },
  "tomato paste": { aisle: "canned" },
  "black beans": { aisle: "canned", buyAs: "canned black beans" },
  "can black beans": { aisle: "canned", buyAs: "canned black beans" },
  "great northern beans": {
    aisle: "canned",
    buyAs: "canned great northern beans",
  },
  "pinto or kidney beans": { aisle: "canned", buyAs: "canned pinto beans" },
  "pinto beans": { aisle: "canned", buyAs: "canned pinto beans" },
  "can crushed tomatoes": { aisle: "canned", buyAs: "canned crushed tomatoes" },
  "can whole peeled tomatoes": {
    aisle: "canned",
    buyAs: "canned whole peeled tomatoes",
  },
  "can tomato sauce": { aisle: "canned", buyAs: "canned tomato sauce" },
  "can diced green chiles": {
    aisle: "canned",
    buyAs: "canned diced green chiles",
  },
  "can Ro-Tel": { aisle: "canned", buyAs: "Ro-Tel" },
  "chipotles in adobo": { aisle: "canned" },
  "chipotle in adobo": { aisle: "canned", buyAs: "chipotles in adobo" },
  // The sauce is what is left in the tin the chipotles came in.
  "adobo sauce": { aisle: "canned", buyAs: "chipotles in adobo" },

  // --- spices --------------------------------------------------------------
  "salt": { aisle: "spices" },
  "fine salt": { aisle: "spices" },
  "kosher salt": { aisle: "spices" },
  "flaky salt": { aisle: "spices" },
  "salt and brown sugar": { aisle: "spices" },
  "black pepper": { aisle: "spices" },
  "cayenne": { aisle: "spices" },
  "chili powder": { aisle: "spices" },
  "cumin": { aisle: "spices" },
  "dried basil": { aisle: "spices" },
  "dried oregano": { aisle: "spices" },
  "dried thyme": { aisle: "spices" },
  "dry mustard": { aisle: "spices" },
  "fennel seed": { aisle: "spices" },
  "garlic powder": { aisle: "spices" },
  "ground coriander": { aisle: "spices" },
  "cinnamon": { aisle: "spices", buyAs: "ground cinnamon" },
  "ground cinnamon": { aisle: "spices" },
  "nutmeg": { aisle: "spices" },
  "red pepper flakes": { aisle: "spices" },
  "smoked paprika": { aisle: "spices" },
  "sesame seeds": { aisle: "spices" },

  // --- baking --------------------------------------------------------------
  "flour": { aisle: "baking", buyAs: "all-purpose flour", breaks: GLUTEN },
  "all-purpose flour": { aisle: "baking", breaks: GLUTEN },
  "cornmeal": { aisle: "baking" },
  "fine yellow cornmeal — for the snap": {
    aisle: "baking",
    buyAs: "fine yellow cornmeal",
  },
  "masa harina or fine cornmeal": { aisle: "baking", buyAs: "masa harina" },
  "sugar": { aisle: "baking", buyAs: "granulated sugar" },
  "granulated sugar": { aisle: "baking" },
  "brown sugar": { aisle: "baking" },
  "dark brown sugar": { aisle: "baking" },
  "powdered sugar": { aisle: "baking" },
  "turbinado or demerara sugar": { aisle: "baking", buyAs: "turbinado sugar" },
  "baking powder": { aisle: "baking" },
  "baking soda": { aisle: "baking" },
  "instant yeast": { aisle: "baking" },
  "cocoa powder": { aisle: "baking" },
  "chocolate chips": { aisle: "baking" },
  "Mexican chocolate": { aisle: "baking" },
  "malted milk powder": { aisle: "baking", breaks: [...DAIRY, ...GLUTEN] },
  "vanilla": { aisle: "baking", buyAs: "vanilla extract" },
  "vanilla extract": { aisle: "baking" },
  "freeze-dried blueberries": { aisle: "baking" },

  // --- oils & condiments ---------------------------------------------------
  "neutral oil": { aisle: "condiments" },
  "corn oil or neutral oil": { aisle: "condiments", buyAs: "neutral oil" },
  "lard or neutral oil": { aisle: "condiments", buyAs: "neutral oil", breaks: FLESH },
  "corn oil plus butter": { aisle: "condiments", breaks: DAIRY },
  "olive oil": { aisle: "condiments" },
  "avocado oil": { aisle: "condiments" },
  "sesame oil": { aisle: "condiments", buyAs: "toasted sesame oil" },
  "soy sauce": { aisle: "condiments", breaks: GLUTEN },
  "hoisin sauce": { aisle: "condiments" },
  // The author offered a choice; the shopper makes it once.
  "doenjang or white miso": { aisle: "condiments", buyAs: "doenjang" },
  "mirin": { aisle: "condiments" },
  "rice vinegar": { aisle: "condiments" },
  "honey": { aisle: "condiments", breaks: ANIMAL },
  "Kewpie mayonnaise": { aisle: "condiments", breaks: EGG },
  "mayonnaise": { aisle: "condiments", breaks: EGG },
  "Dijon": { aisle: "condiments", buyAs: "Dijon mustard" },
  "cider vinegar": { aisle: "condiments" },
  "sherry vinegar": { aisle: "condiments" },
  "sherry": { aisle: "condiments", buyAs: "dry sherry" },
  "dry sherry or white wine": { aisle: "condiments", buyAs: "dry sherry" },
  "dash hot sauce": { aisle: "condiments", buyAs: "hot sauce" },
  "chocolate syrup": { aisle: "condiments" },
  "peanut butter or almond butter": {
    aisle: "condiments",
    buyAs: "peanut butter",
    breaks: NUT,
  },
  "mole paste": { aisle: "condiments" },

  // --- frozen --------------------------------------------------------------
  "frozen peas": { aisle: "frozen" },
  "frozen wild blueberries": { aisle: "frozen" },
  "vanilla ice cream": { aisle: "frozen", breaks: DAIRY },
  "puff pastry": { aisle: "frozen", breaks: GLUTEN },

  // --- not a purchase ------------------------------------------------------
  // It comes out of a tap.
  "warm water": { omit: true },
  "water": { omit: true },
  // The third option in "Instead of the walnuts — optional, pick one",
  // which is to add nothing.
  "or nothing at all; it is excellent plain": { omit: true },
};

/**
 * What to do with one ingredient string: a `Shop` to attach, `null`
 * for an authored non-purchase, `undefined` for an item the table has
 * never heard of — which is a build failure, not a default.
 */
export function shopFor(item: string): Shop | null | undefined {
  const entry = PANTRY[item];
  if (entry === undefined) return undefined;
  if ("omit" in entry) return null;
  return { aisle: entry.aisle, buyAs: entry.buyAs ?? item };
}

/**
 * The dietary flags a recipe sets that one of its items breaks — the
 * build's refusal, as a pure function so it can be tested on a
 * fixture. Empty means nothing in the table contradicts the flags,
 * which is **not** the same as the flags being right: the table only
 * ever says no.
 */
export function violations(
  dietary: readonly string[],
  items: readonly string[],
): { flag: string; item: string }[] {
  const out: { flag: string; item: string }[] = [];
  for (const flag of dietary) {
    for (const item of items) {
      const entry = PANTRY[item];
      if (entry && !("omit" in entry) && entry.breaks?.includes(flag as Dietary)) {
        out.push({ flag, item });
      }
    }
  }
  return out;
}

/** The aisles, in walk order, as an index — so a renderer can sort by
 * position without re-stating the order and getting it wrong. */
export const AISLE_ORDER: Record<string, number> = Object.fromEntries(
  AISLES.map((a, i) => [a, i]),
);
