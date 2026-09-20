/**
 * The four voices are actually wired — DS-01 §05.
 *
 * **The failure this exists for is silent.** Misspell a family between
 * `@font-face` and its `--font-*` token and nothing breaks: the stack
 * falls through to the system face named after it, the page still
 * renders, and the type casting that the whole design rests on is
 * quietly void. Nobody notices, because "a sans-serif appeared" looks
 * exactly like success.
 *
 * Same for a `.woff2` that was never committed, and for a licence file
 * the OFL requires to ship beside the font it covers.
 */

import { assert, assertEquals } from "@std/assert";

const fonts = await Deno.readTextFile("src/fonts.css");
const theme = await Deno.readTextFile("src/theme.css");
const index = await Deno.readTextFile("index.html");
const notFound = await Deno.readTextFile("public/404.html");

/** Every family declared by an `@font-face`, and the files it names. */
const faces = [...fonts.matchAll(/@font-face\s*\{([\s\S]*?)\}/g)].map((m) => ({
  family: m[1].match(/font-family:\s*'([^']+)'/)?.[1] ?? "",
  weight: m[1].match(/font-weight:\s*(\d+)/)?.[1] ?? "",
  file: m[1].match(/url\('([^']+)'\)/)?.[1] ?? "",
  range: m[1].match(/unicode-range:\s*([\s\S]*?);/)?.[1].replace(/\s+/g, " ").trim() ?? "",
}));

/** The first family in each `--font-*` stack — the one that actually
 * gets used when it loads. */
const stacks = Object.fromEntries(
  [...theme.matchAll(/--font-([a-z]+):\s*'([^']+)'/g)].map((m) => [m[1], m[2]]),
);

const exists = async (path: string) => {
  try {
    await Deno.stat(path);
    return true;
  } catch {
    return false;
  }
};

// ---------------------------------------------------------------------------

Deno.test("all four voices are cast, one family each", () => {
  assertEquals(Object.keys(stacks).sort(), ["body", "data", "display", "human"]);
});

Deno.test("every cast family has an @font-face", () => {
  const declared = new Set(faces.map((f) => f.family));
  const missing = Object.entries(stacks)
    .filter(([, family]) => !declared.has(family))
    .map(([voice, family]) => `--font-${voice} leads with "${family}", which has no @font-face`);
  assertEquals(missing, []);
});

Deno.test("every @font-face family is cast to a voice", () => {
  // An unreferenced face is bytes shipped for nothing — and usually
  // means a token was renamed and its face was not.
  const cast = new Set(Object.values(stacks));
  const orphans = [...new Set(faces.map((f) => f.family))].filter((f) => !cast.has(f));
  assertEquals(orphans, []);
});

Deno.test("every .woff2 an @font-face names is committed", async () => {
  const missing: string[] = [];
  for (const face of faces) {
    assert(face.file.startsWith("/fonts/"), `${face.family}: ${face.file} is not under /fonts/`);
    if (!(await exists(`public${face.file}`))) missing.push(face.file);
  }
  assertEquals(missing, []);
});

Deno.test("every family ships its OFL licence beside it", async () => {
  // Required by the licence, and the thing most likely to be forgotten
  // when a face is swapped in a hurry.
  const licences: Record<string, string> = {
    "Archivo Expanded": "Archivo-OFL.txt",
    "Inter": "Inter-OFL.txt",
    "JetBrains Mono": "JetBrainsMono-OFL.txt",
    "Instrument Serif": "InstrumentSerif-OFL.txt",
  };
  const missing: string[] = [];
  for (const family of new Set(faces.map((f) => f.family))) {
    const file = licences[family];
    if (!file) {
      missing.push(`${family} has no licence file recorded in this test`);
    } else if (!(await exists(`public/fonts/${file}`))) {
      missing.push(`${family}: public/fonts/${file} is absent`);
    }
  }
  assertEquals(missing, []);
});

Deno.test("every family carries both subsets, on identical ranges", () => {
  // The latin and latin-ext cuts must agree across families or a glyph
  // falls between two definitions and silently swaps face mid-word.
  const byRange = new Map<string, Set<string>>();
  for (const f of faces) {
    if (!byRange.has(f.range)) byRange.set(f.range, new Set());
    byRange.get(f.range)!.add(`${f.family} ${f.weight}`);
  }
  assertEquals(byRange.size, 2, "expected exactly two unicode-ranges: latin and latin-ext");

  const cuts = [...byRange.values()].map((s) => [...s].sort());
  assertEquals(cuts[0], cuts[1], "a cut is missing one of its two subsets");
});

Deno.test("every preloaded font is one this project ships", async () => {
  const preloads = [...index.matchAll(/href="(\/fonts\/[^"]+)"/g)].map((m) => m[1]);
  assert(preloads.length > 0, "no font preloads in index.html");

  const declared = new Set(faces.map((f) => f.file));
  for (const href of preloads) {
    assert(declared.has(href), `${href} is preloaded but has no @font-face`);
    assert(await exists(`public${href}`), `${href} is preloaded but absent`);
  }
});

Deno.test("the human voice is not preloaded", () => {
  // It appears in asides and at the foot of a recipe, never above the
  // fold. Preloading it buys 21 kB of nothing on a phone (DS-01 §12).
  const preloads = index.match(/href="\/fonts\/[^"]+"/g) ?? [];
  assertEquals(preloads.filter((p) => p.includes("instrument-serif")), []);
});

Deno.test("404.html declares every face it uses", async () => {
  // It cannot link the hashed bundle, so it carries its own @font-face
  // blocks — and they drift from fonts.css without anything noticing.
  const used = [...notFound.matchAll(/font-family:\s*'([^']+)'/g)].map((m) => m[1]);
  const declaredThere = new Set(
    [...notFound.matchAll(/@font-face\s*\{[\s\S]*?font-family:\s*'([^']+)'[\s\S]*?\}/g)]
      .map((m) => m[1]),
  );
  const shipped = new Set(faces.map((f) => f.family));

  const missing = [...new Set(used)]
    .filter((f) => shipped.has(f) && !declaredThere.has(f));
  assertEquals(missing, [], "404.html names a shipped face it does not declare");

  for (const file of [...notFound.matchAll(/url\('(\/fonts\/[^']+)'\)/g)].map((m) => m[1])) {
    assert(await exists(`public${file}`), `404.html references ${file}, which is absent`);
  }
});
