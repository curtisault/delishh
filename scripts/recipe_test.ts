/**
 * The validator's own tests — `deno task test:content`.
 *
 * `parseRecipe` is a pure function, so every rule in DS-01 §06 can be
 * tested by mutating one known-good recipe and asserting the mutation
 * is caught. **The bench specimen is the fixture**: these tests fail
 * the day Nº 47 stops parsing, which is exactly when you want to know.
 *
 * A rule without a test here is a rule that silently stops being
 * enforced the next time someone touches a regex.
 */

import { assert, assertEquals, assertStringIncludes } from "@std/assert";
import { parseRecipe } from "./recipe.ts";

const BENCH = "content/recipes/salted-caramel.md";
const good = await Deno.readTextFile(BENCH);

/** Assert a mutation of the bench specimen is rejected, and that the
 * complaint mentions `expect` — so a test cannot pass because some
 * *other* rule happened to fire. */
function rejects(source: string, expect: string) {
  const { recipe, problems } = parseRecipe("test", source);
  assertEquals(recipe, null, "expected the recipe to be rejected");
  assert(problems.length > 0, "expected at least one problem");
  const all = problems.map((p) => `${p.where}: ${p.message}`).join("\n");
  assertStringIncludes(all.toLowerCase(), expect.toLowerCase());
}

/** Replace once, and fail loudly if the anchor text was not there —
 * otherwise a stale fixture turns every test below into a no-op that
 * passes. */
function swap(source: string, find: string, replace: string): string {
  assert(source.includes(find), `fixture drift: ${JSON.stringify(find)} not found`);
  return source.replace(find, replace);
}

// ---------------------------------------------------------------------------

Deno.test("the bench specimen parses", () => {
  const { recipe, problems } = parseRecipe("salted-caramel", good);
  assertEquals(problems, []);
  assert(recipe);
  assertEquals(recipe.time, { active: 15, total: 45 });
  assertEquals(recipe.steps.length, 6);
  assertEquals(recipe.photo, null, "no photo field means an absent block, not a placeholder");
});

Deno.test("every step carries its own cue", () => {
  const { recipe } = parseRecipe("salted-caramel", good);
  assert(recipe);
  for (const step of recipe.steps) {
    assert(step.cue, `step ${step.n} has no cue — DS-01 §2.5`);
  }
});

Deno.test("mass ingredients parse amount, unit and preparation note", () => {
  const { recipe } = parseRecipe("salted-caramel", good);
  assert(recipe);
  const butter = recipe.ingredients[0].items.find((i) => i.item === "unsalted butter");
  assert(butter);
  assertEquals(butter.amount?.value, 90);
  assertEquals(butter.unit, "g");
  assertEquals(butter.unitKind, "mass");
  assertEquals(butter.note, "cubed, cold");
  assertEquals(butter.indivisible, false);
});

Deno.test("a rescue that cannot be saved is marked, not softened", () => {
  const { recipe } = parseRecipe("salted-caramel", good);
  assert(recipe);
  const bitter = recipe.rescues.find((r) => r.symptom === "Bitter");
  assert(bitter);
  assertEquals(bitter.recoverable, false);
  assert(recipe.rescues.filter((r) => r.recoverable).length >= 3);
});

// --- the closed vocabularies -----------------------------------------------

Deno.test("a flavour outside the vocabulary is rejected", () => {
  rejects(swap(good, "flavor: [sweet, salty]", "flavor: [sweet, savoury]"), "not in the vocabulary");
});

Deno.test("a misspelled frontmatter key is rejected, with a suggestion", () => {
  rejects(swap(good, "flavor:", "flavour:"), "did you mean `flavor`");
});

Deno.test("an empty required facet is rejected", () => {
  rejects(swap(good, "slot: [dessert]", "slot: []"), "may not be empty");
});

Deno.test("cuisine may be empty — an honest blank beats a guess", () => {
  const { problems } = parseRecipe("test", good);
  assertEquals(problems, []);
});

// --- the measurement ladder, DS-01 §05 -------------------------------------

Deno.test("grams are whole numbers", () => {
  rejects(swap(good, "- 90 g unsalted butter", "- 90.5 g unsalted butter"), "whole numbers");
});

Deno.test("volume fractions are glyphs, never decimals", () => {
  rejects(swap(good, "- 6 g flaky salt", "- 0.75 tsp vanilla extract"), "glyphs");
});

Deno.test("a glyph fraction parses to its value", () => {
  const { recipe, problems } = parseRecipe(
    "test",
    swap(good, "- 6 g flaky salt", "- ¾ tsp vanilla extract"),
  );
  assertEquals(problems, []);
  assert(recipe);
  const vanilla = recipe.ingredients[0].items.find((i) => i.item === "vanilla extract");
  assertEquals(vanilla?.amount?.value, 0.75);
  assertEquals(vanilla?.unit, "tsp");
});

Deno.test("a bare count is indivisible — scaling may not halve an egg", () => {
  const { recipe, problems } = parseRecipe(
    "test",
    swap(good, "- 6 g flaky salt", "- 2 eggs, at room temperature"),
  );
  assertEquals(problems, []);
  assert(recipe);
  const eggs = recipe.ingredients[0].items.find((i) => i.item === "eggs");
  assertEquals(eggs?.indivisible, true);
  assertEquals(eggs?.unit, null);
  assertEquals(eggs?.note, "at room temperature");
});

Deno.test("a count unit is indivisible and canonicalised", () => {
  const { recipe, problems } = parseRecipe(
    "test",
    swap(good, "- 6 g flaky salt", "- 2 cloves garlic, crushed"),
  );
  assertEquals(problems, []);
  assert(recipe);
  const garlic = recipe.ingredients[0].items.find((i) => i.item === "garlic");
  assertEquals(garlic?.unit, "clove");
  assertEquals(garlic?.indivisible, true);
});

Deno.test("the clock is never alone", () => {
  rejects(
    swap(good, "cue: 6–9 MIN · UNTIL THE EDGES RUN CLEAR", "cue: 6–9 MIN"),
    "a duration with no tell",
  );
});

Deno.test("a temperature-only cue is fine — it is not a clock", () => {
  const { problems } = parseRecipe(
    "test",
    swap(good, "cue: 6–9 MIN · UNTIL THE EDGES RUN CLEAR", "cue: 175 °C · DEEP AMBER"),
  );
  assertEquals(problems, []);
});

Deno.test("total time may not be less than active time", () => {
  rejects(swap(good, "total: 45m", "total: 10m"), "includes every hold");
});

Deno.test("a tested date in the future is rejected", () => {
  rejects(swap(good, "tested: 2026-03-11", "tested: 2099-01-01"), "in the future");
});

// --- the word rules, DS-01 §11 ---------------------------------------------

Deno.test("'simply' in a step is rejected", () => {
  rejects(
    swap(good, "Sugar into the dry pan", "Simply tip the sugar into the dry pan"),
    "minimises a difficulty",
  );
});

Deno.test("an exclamation mark in a step is rejected", () => {
  rejects(swap(good, "Beat it\n   flat", "Beat it flat!"), "calm and exact");
});

Deno.test("a vague verb in a step is rejected", () => {
  rejects(swap(good, "Salt last, off the", "Toss the salt in last, off the"), "vague verb");
});

Deno.test("the note is exempt from every word rule", () => {
  // The bench note already says "pale caramel is just sweet" — the
  // checker must not read it. Pile on more and it still must not.
  const loud = swap(
    good,
    "The third go is that sentence, in numbers.",
    "The third go is that sentence, in numbers. It is simply the best caramel ever! Easy, honestly 🎉",
  );
  const { problems } = parseRecipe("test", loud);
  assertEquals(problems, [], "the note must never be linted");
});

Deno.test("banned marketing copy is caught outside the note", () => {
  rejects(swap(good, "- Fridge at 4 °C", "- A foolproof keeper. Fridge at 4 °C"), "nothing is");
});

// --- the fixed block form, DS-01 §06 ---------------------------------------

Deno.test("blocks may not be reordered", () => {
  const scrambled = good
    .replace("## Watchpoints", "## @@")
    .replace("## Steps", "## Watchpoints")
    .replace("## @@", "## Steps");
  rejects(scrambled, "out of order");
});

Deno.test("an unknown block heading is rejected", () => {
  rejects(swap(good, "## Keeps", "## Storage"), "is not a block");
});

Deno.test("the note block is required", () => {
  // To the end of the file: Note is the last block now that History
  // is retired (DS-01 §06, amended 2026-09-21).
  rejects(good.replace(/## Note[\s\S]*$/, ""), "required and absent");
});




Deno.test("History is no longer a block — the change log is git's job", () => {
  // DS-01 §06, amended 2026-09-21. The old `## History` grammar is
  // rejected as an unknown block rather than parsed, so a recipe
  // carried over from before the amendment fails loudly with the
  // current block list instead of silently dropping its entries.
  rejects(
    good.replace("## Note", "## History\n\n- **2026-01-01** — Changed things.\n\n## Note"),
    "is not a block",
  );
});

Deno.test("a malformed rescue is rejected", () => {
  rejects(swap(good, "- **Bitter** [terminal] —", "- Bitter:"), "a rescue reads");
});

Deno.test("a file with no frontmatter is rejected", () => {
  rejects("## Steps\n\n1. Do the thing.\n", "no YAML frontmatter");
});
