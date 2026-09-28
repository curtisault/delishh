/**
 * The facet constraints are held to the code — `agents/refs/*.md` and
 * `docs/facet-constraints.md`.
 *
 * The same pattern as `agents_test.ts`, for the same reason. The
 * doctrine is hand-written prose about *how to decide* a facet, and
 * it necessarily repeats the closed vocabularies it is deciding
 * within. A hand-maintained copy of a machine-held list lies the
 * first time the list changes, and a doctrine that lies is worse
 * than none — it is what a reviewer cites.
 *
 * Two kinds of test here:
 *
 *  - The lists in every doctrine document match `vocabulary.ts`,
 *    exactly, in both the verbose refs and the digest.
 *  - The corpus meets the doctrine's *mechanical* rules — the ones a
 *    script can read off the frontmatter. The judgements (a level, a
 *    window count, a verification) are a person's, and are not here.
 *
 * Needs N3 — that a `vegetarian` recipe also carries `pescatarian`,
 * and a `vegan` one the four flags it implies — was held back until
 * the first recipe review had ruled on the files that failed it, and
 * switched on the same day (2026-09-28). The implication table itself
 * is held to the vocabulary below, so the rule can never instruct an
 * author to write a flag the build rejects.
 */

import { assert, assertEquals } from "@std/assert";
import {
  CUISINES,
  DIETARY,
  EFFORTS,
  FLAVOR_LEVELS,
  FLAVORS,
  METHODS,
} from "./vocabulary.ts";
import { parseRecipe, type Recipe } from "./recipe.ts";

const DIGEST = "docs/facet-constraints.md";
const REFS = {
  flavour: "agents/refs/flavour.md",
  effort: "agents/refs/effort.md",
  needs: "agents/refs/needs.md",
};

const digest = await Deno.readTextFile(DIGEST);
const refs = {
  flavour: await Deno.readTextFile(REFS.flavour),
  effort: await Deno.readTextFile(REFS.effort),
  needs: await Deno.readTextFile(REFS.needs),
};

/** The backticked tokens of the single line in `doc` that opens with
 * `` - `name` `` — the same list format `agents_test.ts` reads. The
 * first token is the name itself and is dropped. */
function listedOn(doc: string, prefix: string, name: string): string[] {
  const line = doc.split("\n").find((l) => l.trim().startsWith(`- \`${prefix}\``));
  assert(line, `${name} has no \`${prefix}\` list line`);
  return [...line.matchAll(/`([^`]+)`/g)].map((m) => m[1]).slice(1);
}

function sorted(values: readonly string[]): string[] {
  return [...values].sort();
}

// ---------------------------------------------------------------------------
// The lists
// ---------------------------------------------------------------------------

Deno.test("every list in every doctrine document matches the vocabulary", () => {
  const holds: [string, string, string, readonly string[]][] = [
    // [document name, its text, the list prefix, the vocabulary]
    [REFS.flavour, refs.flavour, "flavor", FLAVORS],
    [REFS.effort, refs.effort, "method", METHODS],
    [REFS.effort, refs.effort, "effort", EFFORTS],
    [REFS.needs, refs.needs, "dietary", DIETARY],
    [REFS.needs, refs.needs, "cuisine", CUISINES],
    [DIGEST, digest, "flavor", FLAVORS],
    [DIGEST, digest, "method", METHODS],
    [DIGEST, digest, "effort", EFFORTS],
    [DIGEST, digest, "dietary", DIETARY],
    [DIGEST, digest, "cuisine", CUISINES],
  ];
  for (const [name, doc, prefix, vocabulary] of holds) {
    assertEquals(
      sorted(listedOn(doc, prefix, name)),
      sorted(vocabulary),
      `${name}'s \`${prefix}\` list disagrees with vocabulary.ts`,
    );
  }
});

Deno.test("the flavour levels the doctrine teaches are the ones the build accepts", () => {
  // Both the ref and the digest name each level with its word, the
  // way AGENTS.md does. A level the doctrine calls something else is
  // a meter that means two things.
  for (const [name, doc] of [[REFS.flavour, refs.flavour], [DIGEST, digest]]) {
    for (const [n, word] of Object.entries(FLAVOR_LEVELS)) {
      assert(
        doc.includes(`\`${n}\` ${word}`),
        `${name} should teach \`${n}\` as "${word}"`,
      );
    }
  }
});

Deno.test("the digest names each ref, and each ref names the digest", () => {
  // The two copies exist so one can be verbose and the other citable;
  // that only works while each says where the other is.
  for (const path of Object.values(REFS)) {
    assert(digest.includes(path), `the digest never points at ${path}`);
  }
  for (const [key, doc] of Object.entries(refs)) {
    assert(doc.includes(DIGEST), `${REFS[key as keyof typeof REFS]} never points at the digest`);
  }
});

Deno.test("the implication table (needs N3) names only flags the vocabulary has", () => {
  // The rule is stated as data in the ref: a table of "if verified X,
  // also carries Y…". Every word in it must be a real flag, or the
  // rule instructs authors to write something the build rejects.
  const section = refs.needs.slice(
    refs.needs.indexOf("### N3."),
    refs.needs.indexOf("### N4."),
  );
  assert(section.length > 0, "needs.md has no N3 section");
  const words = [...section.matchAll(/`([a-z-]+)`/g)].map((m) => m[1]);
  assert(words.length >= 6, "the implication table lists almost nothing");
  for (const w of words) {
    assert(
      (DIETARY as readonly string[]).includes(w),
      `needs N3 names \`${w}\`, which is not a dietary flag`,
    );
  }
});

// ---------------------------------------------------------------------------
// The corpus, against the mechanical rules
// ---------------------------------------------------------------------------

async function corpus(): Promise<Recipe[]> {
  const out: Recipe[] = [];
  for await (const entry of Deno.readDir("content/recipes")) {
    if (!entry.isFile || !entry.name.endsWith(".md") || entry.name === "AGENTS.md") continue;
    const slug = entry.name.slice(0, -3);
    const source = await Deno.readTextFile(`content/recipes/${entry.name}`);
    const { recipe, problems } = parseRecipe(slug, source);
    assert(recipe && problems.length === 0, `${entry.name} does not parse; the build will say why`);
    out.push(recipe);
  }
  assert(out.length > 0, "the corpus is empty");
  return out;
}

Deno.test("flavour F2: every listed flavour carries a level", async () => {
  for (const r of await corpus()) {
    for (const f of r.flavor) {
      assert(
        f.level !== null,
        `${r.slug}: \`${f.name}\` has no level. The build allows a bare word; the doctrine does not (agents/refs/flavour.md, F2)`,
      );
    }
  }
});

Deno.test("flavour F4: at least one word, at most four, at most two at 3", async () => {
  for (const r of await corpus()) {
    assert(r.flavor.length >= 1, `${r.slug}: no flavour at all`);
    assert(
      r.flavor.length <= 4,
      `${r.slug}: ${r.flavor.length} flavours — an ingredient list wearing a facet (flavour.md, F4)`,
    );
    const defining = r.flavor.filter((f) => f.level === 3).length;
    assert(
      defining <= 2,
      `${r.slug}: ${defining} flavours at level 3 — one of them is a 2 (flavour.md, F4)`,
    );
  }
});

Deno.test("effort E3: the three anchors exist and carry the tier they anchor", async () => {
  // The anchors are how "focused" is calibrated: every recipe is
  // placed relative to them. An anchor re-tiered without the table
  // moving is a scale with no zero.
  const section = refs.effort.slice(
    refs.effort.indexOf("### E3."),
    refs.effort.indexOf("### E4."),
  );
  const anchors = new Map<string, string>();
  for (const m of section.matchAll(/^\| `(\w+)` \| `([a-z0-9-]+)` \|/gmu)) {
    anchors.set(m[2], m[1]);
  }
  assertEquals(
    sorted([...anchors.values()]),
    sorted(EFFORTS),
    "effort.md's anchor table should name exactly one recipe per tier",
  );
  const bySlug = new Map((await corpus()).map((r) => [r.slug, r]));
  for (const [slug, tier] of anchors) {
    const r = bySlug.get(slug);
    assert(r, `effort.md anchors \`${tier}\` to ${slug}, which is not in the corpus`);
    assertEquals(
      r.effort,
      tier,
      `${slug} anchors \`${tier}\` in effort.md but is \`${r.effort}\` in its frontmatter`,
    );
  }
});

Deno.test("needs N3: every flag another flag implies is stated", async () => {
  // The shelf ORs selections within a path and infers nothing, so a
  // reader who selects `pescatarian` finds a vegetarian dish only if
  // the word is on it. Switched on at the first recipe review
  // (2026-09-28), once the corpus met it.
  const implies: Record<string, string[]> = {
    vegan: ["vegetarian", "pescatarian", "dairy-free", "egg-free"],
    vegetarian: ["pescatarian"],
  };
  for (const r of await corpus()) {
    for (const [flag, implied] of Object.entries(implies)) {
      if (!r.dietary.includes(flag)) continue;
      for (const want of implied) {
        assert(
          r.dietary.includes(want),
          `${r.slug}: \`${flag}\` implies \`${want}\`, and the shelf will not infer it (needs.md, N3)`,
        );
      }
    }
  }
});

Deno.test("cuisine C2: at most two cuisines", async () => {
  for (const r of await corpus()) {
    assert(
      r.cuisine.length <= 2,
      `${r.slug}: ${r.cuisine.length} cuisines — a dish that belongs to none of them (needs.md, C2)`,
    );
  }
});
