/**
 * The aisles exist in two languages, and this is what stops them
 * drifting.
 *
 * `scripts/vocabulary.ts` owns the list; `src/GroceryList.elm` carries
 * a copy because the shopping list page fetches nothing — it is read
 * standing in a shop, off a snapshot, and a page that needed the index
 * to know what "produce" is called would be a page that needs a
 * network to render a list you already made.
 *
 * That is a deliberate duplication, so it gets the treatment every
 * other deliberate duplication in this build gets — `contrast_test.ts`
 * recomputes the ratios written in comments, `fonts_test.ts` holds a
 * family name to its token, and this holds the Elm list to the
 * TypeScript one. Tokens, labels, and **order**: the order is the walk
 * through the shop, and a scrambled walk is the whole value of the
 * grouping gone.
 */

import { assert, assertEquals } from "@std/assert";
import { AISLE_LABELS, AISLES } from "./vocabulary.ts";

const elm = await Deno.readTextFile("src/GroceryList.elm");

/** The `aisles` list out of `GroceryList.elm`, in source order, as
 * (token, label) pairs. */
function aislesInElm(): [string, string][] {
  const start = elm.indexOf("aisles =");
  assert(start !== -1, "GroceryList.elm has no `aisles` list");
  const body = elm.slice(start, elm.indexOf("\n\n\n", start));
  return [...body.matchAll(/\(\s*"([^"]+)"\s*,\s*"([^"]+)"\s*\)/g)]
    .map((m) => [m[1], m[2]]);
}

Deno.test("the Elm aisle list matches the vocabulary, in order", () => {
  assertEquals(
    aislesInElm().map(([token]) => token),
    [...AISLES],
    "src/GroceryList.elm's aisles disagree with scripts/vocabulary.ts",
  );
});

Deno.test("the Elm aisle labels match the vocabulary's", () => {
  assertEquals(
    Object.fromEntries(aislesInElm()),
    AISLE_LABELS,
    "src/GroceryList.elm's aisle labels disagree with scripts/vocabulary.ts",
  );
});

Deno.test("the shopping list never converts between kinds", () => {
  // The one arithmetic rule in `GroceryList.elm` that no Elm test can
  // catch going missing, because removing it makes the module simpler
  // and every existing test still passes: a factor from a volume to a
  // mass. A cup of flour weighs what it weighs on the day, and the
  // list is read in the one place being wrong about it costs a shop.
  const table = elm.slice(
    elm.indexOf("toBase : String -> String -> Float -> Float"),
    elm.indexOf("-- ROUNDING, ALWAYS UPWARD"),
  );
  assert(table.length > 0, "GroceryList.elm has no `toBase` conversion table");
  for (const [kind, unit] of [...table.matchAll(/\(\s*"(\w+)",\s*"(\w+)"\s*\)/g)]
    .map((m) => [m[1], m[2]])) {
    const legal = kind === "mass"
      ? ["g", "kg"]
      : kind === "volume"
      ? ["ml", "l", "tsp", "tbsp", "cup"]
      : [];
    assert(
      legal.includes(unit),
      `\`${unit}\` is converted as ${kind}, which it is not. Within a kind ` +
        `a spoon IS five millilitres; across one, the factor is a property ` +
        `of the food and nothing here knows it.`,
    );
  }
});
