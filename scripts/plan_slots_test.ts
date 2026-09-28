/**
 * The planner's labels are the recipes' slot vocabulary, in two
 * languages, and this is what stops them drifting.
 *
 * `scripts/vocabulary.ts` owns `SLOTS`; `src/Plan.elm` carries a copy
 * because the plan page labels a meal without fetching the index, and
 * a label list that needed the network would be a list you cannot use
 * on a plan you already made. A deliberate duplication, held the way
 * `aisles_test.ts` holds the aisles: spelling and order. A word added
 * to one and not the other is a label the other cannot read — and the
 * decoder refuses a stored week holding a label it does not know.
 */

import { assert, assertEquals } from "@std/assert";
import { SLOTS } from "./vocabulary.ts";

const elm = await Deno.readTextFile("src/Plan.elm");

Deno.test("Plan.slots matches the vocabulary's SLOTS, in order", () => {
  const start = elm.indexOf("slots =");
  assert(start !== -1, "Plan.elm has no `slots` list");
  const body = elm.slice(start, elm.indexOf("]", start) + 1);
  assertEquals(
    [...body.matchAll(/"([^"]+)"/g)].map((m) => m[1]),
    [...SLOTS],
    "src/Plan.elm's slots disagree with scripts/vocabulary.ts",
  );
});

Deno.test("the cap is the size of the vocabulary", () => {
  // The expansion's ruling: five a day, because five is how many
  // things a day can be labelled. A sixth slot word without a sixth
  // place is a vocabulary the planner cannot fill.
  const cap = elm.match(/\ncap =\s*\n\s*(\d+)/);
  assert(cap, "Plan.elm has no `cap`");
  assertEquals(Number(cap![1]), SLOTS.length);
});
