/**
 * The prose generator's tests.
 *
 * DS-01 itself is the fixture, for the same reason the bench recipe is
 * the fixture in `recipe_test.ts`: these fail the day the real
 * document stops building, which is exactly when you want to know.
 *
 * The guards that matter here are the ones protecting cross-references
 * — a section whose written number drifts from its position silently
 * repoints every `§NN` in the standard, and that is a class of bug no
 * one notices until it is in print.
 */

import { assert, assertEquals, assertStringIncludes } from "@std/assert";
import { buildDoc } from "./build-docs.ts";
import { parseBlocks, parseSpans } from "./markdown.ts";

const good = await Deno.readTextFile("docs/design-standard.md");

function rejects(source: string, expect: string) {
  const { elm, problems } = buildDoc(source);
  assertEquals(elm, null, "expected the document to be rejected");
  const all = problems.map((p) => p.message).join("\n");
  assertStringIncludes(all.toLowerCase(), expect.toLowerCase());
}

function swap(source: string, find: string, replace: string): string {
  assert(source.includes(find), `fixture drift: ${JSON.stringify(find)} not found`);
  return source.replace(find, replace);
}

// ---------------------------------------------------------------------------

Deno.test("DS-01 builds", () => {
  const { elm, problems } = buildDoc(good);
  assertEquals(problems, []);
  assert(elm);
  assertStringIncludes(elm, "module Generated.DesignStandard exposing");
  // 14 sections, §00 through §13.
  assertEquals(elm.match(/\{ anchor = /g)?.length, 14);
});

Deno.test("every section carries an anchor, a toc label and an intent", () => {
  const { elm } = buildDoc(good);
  assert(elm);
  assertEquals(elm.match(/anchor = ""/g), null);
  assertEquals(elm.match(/tocLabel = ""/g), null);
  assertEquals(elm.match(/intent = ""/g), null);
});

Deno.test("a heading numbered against its position is rejected", () => {
  // The bug this exists for: the prose says "see §09" and §09 has
  // quietly become §10.
  rejects(
    swap(good, "## 07. Browse", "## 08. Browse"),
    "in-prose §08 reference now disagree",
  );
});

Deno.test("a section with no doc directive is rejected", () => {
  rejects(
    swap(good, '<!-- doc anchor=sec-cook toc="Cook mode"', "<!-- nope"),
    "has no `<!-- doc ... -->` line",
  );
});

Deno.test("a directive missing its anchor is rejected", () => {
  rejects(swap(good, "anchor=sec-print ", ""), "missing `anchor`");
});

Deno.test("two sections may not claim one anchor", () => {
  rejects(swap(good, "anchor=sec-motion", "anchor=sec-print"), "claim the anchor");
});

Deno.test("an unknown body kind is rejected", () => {
  rejects(swap(good, "body=panel", "body=slab"), "`clauses`");
});

Deno.test("a document with no frontmatter is rejected", () => {
  rejects("# Title\n\n## 00. Thing\n", "no YAML frontmatter");
});

Deno.test("a missing masthead field is rejected", () => {
  rejects(swap(good, "kicker: DELISHH DESIGN STANDARD\n", ""), "missing `kicker`");
});

// --- the markdown subset ---------------------------------------------------

Deno.test("inline marks parse to their voices", () => {
  assertEquals(parseSpans("a **b** c *d* `e`"), [
    { t: "text", v: "a " },
    { t: "strong", v: "b" },
    { t: "text", v: " c " },
    { t: "em", v: "d" },
    { t: "text", v: " " },
    { t: "mono", v: "e" },
  ]);
});

Deno.test("a hard-wrapped paragraph joins into one block", () => {
  const { blocks } = parseBlocks(["one two", "three four", "", "next"], 1);
  assertEquals(blocks.length, 2);
  assertEquals(blocks[0], { t: "para", spans: [{ t: "text", v: "one two three four" }] });
});

Deno.test("a table of any width parses, header separate from body", () => {
  const { blocks, problems } = parseBlocks(
    ["| A | B | C |", "|---|---|---|", "| 1 | 2 | 3 |"],
    1,
  );
  assertEquals(problems, []);
  assertEquals(blocks.length, 1);
  assert(blocks[0].t === "grid");
  assertEquals(blocks[0].headers, ["A", "B", "C"]);
  assertEquals(blocks[0].rows.length, 1);
  assertEquals(blocks[0].rows[0].length, 3);
});

Deno.test("a ragged table row is rejected, not silently padded", () => {
  const { problems } = parseBlocks(
    ["| A | B | C |", "|---|---|---|", "| 1 | 2 |"],
    1,
  );
  assert(problems.length > 0);
  assertStringIncludes(problems[0].message, "2 cells but the header has 3");
});

Deno.test("a fenced block keeps its shape exactly", () => {
  const { blocks } = parseBlocks(["```", "  a   b", "   c", "```"], 1);
  assertEquals(blocks, [{ t: "pre", v: "  a   b\n   c" }]);
});

Deno.test("an unclosed fence is rejected", () => {
  const { problems } = parseBlocks(["```", "body"], 1);
  assertStringIncludes(problems[0].message, "unclosed");
});

Deno.test("a blank line inside a blockquote splits it into two asides", () => {
  const { blocks } = parseBlocks(["> one", ">", "> two"], 1);
  assertEquals(blocks.length, 2);
  assertEquals(blocks[0].t, "why");
  assertEquals(blocks[1].t, "why");
});

Deno.test("a list item hard-wraps onto its continuation line", () => {
  const { blocks } = parseBlocks(["- one two", "  three", "- next"], 1);
  assert(blocks[0].t === "bullets");
  assertEquals(blocks[0].items.length, 2);
  assertEquals(blocks[0].items[0], [{ t: "text", v: "one two three" }]);
});

Deno.test("an ordered list is distinguished from a bulleted one", () => {
  const { blocks } = parseBlocks(["1. one", "2. two"], 1);
  assert(blocks[0].t === "numbered");
  assertEquals(blocks[0].items.length, 2);
});

Deno.test("a heading above ### inside a section is rejected", () => {
  const { problems } = parseBlocks(["## Nested"], 1);
  assertStringIncludes(problems[0].message, "a heading above `###`");
});

Deno.test("Elm string escapes survive emission", () => {
  const { elm } = buildDoc(
    good.replace(
      "This standard covers a single-operator recipe archive",
      'A "quoted" back\\slash covers a single-operator recipe archive',
    ),
  );
  assert(elm);
  assertStringIncludes(elm, '\\"quoted\\"');
  assertStringIncludes(elm, "back\\\\slash");
});
