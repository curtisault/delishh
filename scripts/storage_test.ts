/**
 * What this browser keeps about a reader, held to what the documents
 * say it keeps.
 *
 * DS-01 §12 and the colophon both make a promise with a number in it:
 * *three things are stored*, each named. The number is a claim about
 * `boot.js`, and nothing else would notice a fourth key arriving
 * unnamed — the page renders, the key is written, and the colophon's
 * "Nothing is kept about you" quietly acquires an exception. A privacy
 * statement that lags the code is worse than none, because it is the
 * one a reader believes.
 *
 * So this counts `localStorage` keys declared in `boot.js` and reads
 * the count out of both documents' prose.
 */

import { assert, assertEquals } from "@std/assert";

const boot = await Deno.readTextFile("src/boot.js");
const about = await Deno.readTextFile("docs/about.md");
const standard = await Deno.readTextFile("docs/design-standard.md");

const WORDS: Record<string, number> = {
  one: 1,
  two: 2,
  three: 3,
  four: 4,
  five: 5,
};

/** Every `const X_KEY = 'delishh-…'` in boot.js. */
function declaredKeys(): string[] {
  return [...boot.matchAll(/const\s+\w+_KEY\s*=\s*['"](delishh-[\w-]+)['"]/g)]
    .map((m) => m[1]);
}

/** The number in "<Word> things are stored", wherever it wraps. */
function claimedCount(doc: string, name: string): number {
  const m = doc.replace(/\s+/g, " ").match(
    /\b(\w+) things are\s+stored/i,
  );
  assert(m, `${name} no longer says how many things are stored`);
  const n = WORDS[m[1].toLowerCase()];
  assert(n !== undefined, `${name} says "${m[1]} things"; teach this test the word`);
  return n;
}

Deno.test("every key boot.js keeps is a delishh- key, declared once", () => {
  const keys = declaredKeys();
  assert(keys.length > 0, "boot.js declares no storage keys");
  assertEquals(new Set(keys).size, keys.length, "a storage key is declared twice");
});

Deno.test("boot.js touches storage only through a declared key", () => {
  // A literal key passed straight to getItem/setItem would dodge the
  // count above.
  const literal = boot.match(/localStorage\.\w+\(\s*['"`]/);
  assertEquals(literal, null, "boot.js calls localStorage with a literal key");
});

Deno.test("the colophon names as many stored things as boot.js keeps", () => {
  assertEquals(
    claimedCount(about, "docs/about.md"),
    declaredKeys().length,
    "docs/about.md and src/boot.js disagree on how many keys are stored",
  );
});

Deno.test("DS-01 §12 names as many stored things as boot.js keeps", () => {
  assertEquals(
    claimedCount(standard, "docs/design-standard.md"),
    declaredKeys().length,
    "docs/design-standard.md §12 and src/boot.js disagree on how many keys are stored",
  );
});

/** The service worker's one cache. Not a `localStorage` key and not
 * about the reader, but bytes on their device all the same — so it is
 * named, and held named, the way the keys are. */
Deno.test("the offline copy is one cache, and both documents name it", async () => {
  const worker = await Deno.readTextFile("src/sw.js");
  const names = [...worker.matchAll(/`(delishh-[\w-]+?)-\$\{BUILD\}`/g)].map((m) => m[1]);
  assertEquals(names, ["delishh-archive"], "src/sw.js keeps a cache the documents do not name");
  for (const [name, doc] of [["docs/about.md", about], ["docs/design-standard.md", standard]]) {
    assert(
      /\bcopy of the archive\b/i.test(doc.replace(/\s+/g, " ")),
      `${name} no longer says a copy of the archive is kept`,
    );
  }
});
