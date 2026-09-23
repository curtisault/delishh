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

import { type Aisle, AISLES } from "./vocabulary.ts";

/** What the table says about one item. Either where to buy it, or
 * that it is not bought. */
export type Purchase =
  | { aisle: Aisle; buyAs?: string }
  | { omit: true };

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
  "ribs celery": { aisle: "produce", buyAs: "celery" },
  "chopped parsley": { aisle: "produce", buyAs: "parsley" },
  "cilantro": { aisle: "produce" },
  "cilantro — at serving only": { aisle: "produce", buyAs: "cilantro" },
  "corn kernels": { aisle: "produce" },
  "cremini mushrooms": { aisle: "produce" },
  "mushrooms": { aisle: "produce" },
  "garlic": { aisle: "produce" },
  "garlic clove": { aisle: "produce", buyAs: "garlic" },
  "green bell pepper": { aisle: "produce", buyAs: "green bell peppers" },
  "red bell pepper": { aisle: "produce", buyAs: "red bell peppers" },
  "jalapeños": { aisle: "produce" },
  "lemon": { aisle: "produce", buyAs: "lemons" },
  "lemon juice": { aisle: "produce", buyAs: "lemons" },
  "lime": { aisle: "produce", buyAs: "limes" },
  "roasted green chiles": { aisle: "produce" },
  "scallions": { aisle: "produce" },
  "thyme": { aisle: "produce", buyAs: "fresh thyme" },
  "very ripe bananas — 1¼ cups mashed": { aisle: "produce", buyAs: "bananas" },
  "white onion": { aisle: "produce", buyAs: "white onions" },
  "yellow onion": { aisle: "produce", buyAs: "yellow onions" },
  "yellow onions": { aisle: "produce" },

  // --- meat ----------------------------------------------------------------
  "beef chuck": { aisle: "meat" },
  "ground beef": { aisle: "meat" },
  "boneless chicken thighs": { aisle: "meat" },
  "chicken thighs": { aisle: "meat" },
  // One bird answers all four. What differs between them is how it is
  // torn up after it is cooked, which is not a thing you buy.
  "cooked chicken": { aisle: "meat" },
  "shredded chicken": { aisle: "meat", buyAs: "cooked chicken" },
  "shredded chicken thigh": { aisle: "meat", buyAs: "cooked chicken" },
  "shredded rotisserie chicken": { aisle: "meat", buyAs: "cooked chicken" },
  "breakfast sausage": { aisle: "meat", buyAs: "bulk breakfast sausage" },
  "bulk breakfast sausage": { aisle: "meat" },
  "bulk Italian sausage": { aisle: "meat" },
  "sausage or bacon drippings": { aisle: "meat" },

  // --- dairy & eggs --------------------------------------------------------
  "butter": { aisle: "dairy", buyAs: "unsalted butter" },
  "melted butter": { aisle: "dairy", buyAs: "unsalted butter" },
  "unsalted butter": { aisle: "dairy" },
  "buttermilk": { aisle: "dairy" },
  "heavy cream": { aisle: "dairy" },
  "milk": { aisle: "dairy", buyAs: "whole milk" },
  "whole milk": { aisle: "dairy" },
  "whole milk or cream": { aisle: "dairy", buyAs: "whole milk" },
  "cream cheese": { aisle: "dairy" },
  "sour cream": { aisle: "dairy", buyAs: "full-fat sour cream" },
  "full-fat sour cream — no substitutes": {
    aisle: "dairy",
    buyAs: "full-fat sour cream",
  },
  "sour cream or full-fat Greek yogurt": {
    aisle: "dairy",
    buyAs: "full-fat sour cream",
  },
  "crema and lime wedges": { aisle: "dairy" },
  "eggs": { aisle: "dairy", buyAs: "large eggs" },
  "large egg": { aisle: "dairy", buyAs: "large eggs" },
  "large eggs": { aisle: "dairy" },
  // A yolk is bought as a whole egg; counting it with them is what
  // stops the list asking for six eggs and one mystery.
  "egg yolk": { aisle: "dairy", buyAs: "large eggs" },
  "Gruyère": { aisle: "dairy" },
  "Gruyère or Swiss": { aisle: "dairy", buyAs: "Gruyère" },
  "Monterey Jack": { aisle: "dairy" },
  "sharp cheddar": { aisle: "dairy" },
  "Monterey Jack and sharp cheddar": { aisle: "dairy" },
  "cheddar and Monterey Jack": {
    aisle: "dairy",
    buyAs: "Monterey Jack and sharp cheddar",
  },
  "grated parmesan": { aisle: "dairy", buyAs: "parmesan" },
  "parmesan or pecorino": { aisle: "dairy", buyAs: "parmesan" },
  "low-moisture mozzarella": {
    aisle: "dairy",
    buyAs: "whole-milk low-moisture mozzarella",
  },
  "whole-milk low-moisture mozzarella": { aisle: "dairy" },
  "whole-milk ricotta — whole-milk only; see Watchpoints": {
    aisle: "dairy",
    buyAs: "whole-milk ricotta",
  },
  "queso fresco or cotija": { aisle: "dairy", buyAs: "queso fresco" },
  "white American cheese": { aisle: "dairy" },

  // --- bakery --------------------------------------------------------------
  "sourdough": { aisle: "bakery" },
  "day-old sourdough": { aisle: "bakery", buyAs: "sourdough" },
  "corn tortillas": { aisle: "bakery" },
  "corn tortillas — corn": { aisle: "bakery", buyAs: "corn tortillas" },
  "fresh flour tortillas": { aisle: "bakery", buyAs: "flour tortillas" },

  // --- dry goods -----------------------------------------------------------
  "lasagna noodles": { aisle: "dry-goods" },
  "long-grain white rice — white only; see Watchpoints": {
    aisle: "dry-goods",
    buyAs: "long-grain white rice",
  },
  "wild rice blend": { aisle: "dry-goods" },
  "panko": { aisle: "dry-goods" },
  "toasted pepitas — seeds": { aisle: "dry-goods", buyAs: "pepitas" },

  // --- canned & jarred -----------------------------------------------------
  "beef broth": { aisle: "canned" },
  "chicken broth": { aisle: "canned" },
  "evaporated milk": { aisle: "canned" },
  "tomato paste": { aisle: "canned" },
  "black beans": { aisle: "canned", buyAs: "canned black beans" },
  "can black beans": { aisle: "canned", buyAs: "canned black beans" },
  "great northern beans": {
    aisle: "canned",
    buyAs: "canned great northern beans",
  },
  "pinto or kidney beans": { aisle: "canned", buyAs: "canned pinto beans" },
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

  // --- baking --------------------------------------------------------------
  "flour": { aisle: "baking", buyAs: "all-purpose flour" },
  "all-purpose flour": { aisle: "baking" },
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
  "malted milk powder": { aisle: "baking" },
  "vanilla": { aisle: "baking", buyAs: "vanilla extract" },
  "vanilla extract": { aisle: "baking" },
  "freeze-dried blueberries": { aisle: "baking" },

  // --- oils & condiments ---------------------------------------------------
  "neutral oil": { aisle: "condiments" },
  "corn oil or neutral oil": { aisle: "condiments", buyAs: "neutral oil" },
  "lard or neutral oil": { aisle: "condiments", buyAs: "neutral oil" },
  "corn oil plus butter": { aisle: "condiments" },
  "olive oil": { aisle: "condiments" },
  "mayonnaise": { aisle: "condiments" },
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
  },
  "mole paste": { aisle: "condiments" },

  // --- frozen --------------------------------------------------------------
  "frozen peas": { aisle: "frozen" },
  "frozen wild blueberries": { aisle: "frozen" },
  "vanilla ice cream": { aisle: "frozen" },
  "puff pastry": { aisle: "frozen" },

  // --- not a purchase ------------------------------------------------------
  // It comes out of a tap.
  "warm water": { omit: true },
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

/** The aisles, in walk order, as an index — so a renderer can sort by
 * position without re-stating the order and getting it wrong. */
export const AISLE_ORDER: Record<string, number> = Object.fromEntries(
  AISLES.map((a, i) => [a, i]),
);
