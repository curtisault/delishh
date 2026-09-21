/**
 * The authoring contract is held to the code — content/recipes/AGENTS.md.
 *
 * AGENTS.md is what an agent (or a person) reads before writing a
 * recipe, and it necessarily repeats things the code owns: the closed
 * vocabularies, the block order, the unit lists, the banned words. A
 * hand-maintained copy of a machine-enforced list lies the first time
 * the list changes — and a contract that lies is worse than none,
 * because it is *trusted*.
 *
 * So, the same pattern as the contrast ratios and the font wiring:
 * the prose is hand-written, the facts in it are recomputed here from
 * `vocabulary.ts` on every test run. Add a flavour without touching
 * AGENTS.md and the build fails, naming the drift.
 */

import { assert, assertEquals } from "@std/assert";
import {
  BLOCKS,
  COURSES,
  CUISINES,
  DIETARY,
  EFFORTS,
  FLAVORS,
  METHODS,
  PRINT_TEMPLATES,
  SLOTS,
  UNITS,
  WORD_RULES,
  YIELD_UNITS,
} from "./vocabulary.ts";

const doc = await Deno.readTextFile("content/recipes/AGENTS.md");
const lines = doc.split("\n");

/** The backticked tokens of the single line that opens with
 * `` - `name` `` — the format every checkable list in AGENTS.md uses.
 * The first token is the name itself and is dropped. */
function listedOn(prefix: string): string[] {
  const line = lines.find((l) => l.trim().startsWith(`- \`${prefix}\``));
  assert(line, `AGENTS.md has no \`${prefix}\` list line`);
  return [...line.matchAll(/`([^`]+)`/g)].map((m) => m[1]).slice(1);
}

function sorted(values: readonly string[]): string[] {
  return [...values].sort();
}

// ---------------------------------------------------------------------------

Deno.test("every facet list matches the vocabulary, exactly", () => {
  const facets: [string, readonly string[]][] = [
    ["slot", SLOTS],
    ["course", COURSES],
    ["flavor", FLAVORS],
    ["method", METHODS],
    ["effort", EFFORTS],
    ["dietary", DIETARY],
    ["cuisine", CUISINES],
    ["print", PRINT_TEMPLATES],
  ];
  for (const [facet, vocabulary] of facets) {
    assertEquals(
      sorted(listedOn(facet)),
      sorted(vocabulary),
      `AGENTS.md's \`${facet}\` list disagrees with vocabulary.ts`,
    );
  }
});

Deno.test("the block order is stated, and matches BLOCKS", () => {
  // The arrow line is prose a reader follows and a build enforces;
  // one string, present verbatim, derived here from the same array
  // the parser walks.
  const order = BLOCKS.map((b) => b.heading).join(" → ");
  assert(
    doc.includes(order),
    `AGENTS.md does not state the block order as \`${order}\``,
  );
});

Deno.test("the required blocks match BLOCKS", () => {
  const line = lines.find((l) => l.includes("Required blocks:"));
  assert(line, "AGENTS.md names no required blocks");
  const listed = [...line.matchAll(/`([^`]+)`/g)].map((m) => m[1]);
  const required = BLOCKS.filter((b) => b.required).map((b) => b.heading);
  assertEquals(sorted(listed), sorted(required));
});

Deno.test("the skeleton's blocks are in canonical order", () => {
  // The arrow line pins the rule; this pins the template people
  // actually copy. A skeleton in the wrong order hands every new
  // recipe a build failure as its first experience.
  const skeleton = doc.slice(doc.indexOf("## The skeleton"));
  const positions = BLOCKS
    .map((b) => skeleton.indexOf(`## ${b.heading}`))
    .filter((at) => at !== -1);
  assert(positions.length >= 2, "the skeleton shows no blocks");
  assertEquals(
    positions,
    [...positions].sort((a, b) => a - b),
    "the skeleton's blocks are not in canonical order",
  );
});

Deno.test("the unit lists match UNITS, kind by kind", () => {
  for (const kind of ["mass", "volume", "count"] as const) {
    const canonical = new Set(
      Object.values(UNITS)
        .filter((u) => u.kind === kind)
        .map((u) => u.canonical),
    );
    assertEquals(
      sorted(listedOn(kind)),
      sorted([...canonical]),
      `AGENTS.md's ${kind} units disagree with vocabulary.ts`,
    );
  }
});

Deno.test("the yield units match YIELD_UNITS", () => {
  const line = lines.find((l) => l.includes("`yield.unit`"));
  assert(line, "AGENTS.md does not list the yield units");
  const listed = [...line.matchAll(/`([^`]+)`/g)]
    .map((m) => m[1])
    .filter((t) => t !== "yield.unit");
  assertEquals(sorted(listed), sorted(YIELD_UNITS));
});

Deno.test("every banned word AGENTS.md names actually trips a rule", () => {
  // The other direction of drift: a word listed here that no rule
  // matches is a warning about nothing, and teaches authors the
  // contract exaggerates.
  const section = doc.slice(
    doc.indexOf("## Words the build rejects"),
    doc.indexOf("## The skeleton"),
  );
  const words = [...section.matchAll(/`([^`]+)`/g)].map((m) => m[1]);
  assert(words.length >= 8, "the banned-words section lists almost nothing");

  for (const word of words) {
    // The one templated entry needs a concrete phrase to test with.
    const sample = word === "the best ___ ever" ? "the best caramel ever" : word;
    const tripped = WORD_RULES.some((rule) => {
      rule.pattern.lastIndex = 0;
      return rule.pattern.test(sample);
    });
    assert(tripped, `AGENTS.md bans "${word}" but no word rule matches it`);
  }
});

Deno.test("the build never parses AGENTS.md as a recipe", async () => {
  // build-content.ts walks this directory for *.md; without an
  // explicit skip, the contract itself fails the slug check and takes
  // the corpus down with it.
  const build = await Deno.readTextFile("scripts/build-content.ts");
  assert(
    build.includes('"AGENTS.md"'),
    "build-content.ts no longer skips AGENTS.md",
  );
});
