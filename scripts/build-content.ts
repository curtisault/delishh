/**
 * The content build — markdown in, JSON out, nothing silent.
 *
 * Reads every recipe in `content/recipes/`, validates it against
 * DS-01 §06 (see `recipe.ts`), and writes what the app consumes:
 *
 *   public/content/index.json          the facet index — browse, search
 *   public/content/recipes/<slug>.json one document, fully parsed
 *
 * **`public/content/` is generated and gitignored.** It is rebuilt by
 * `deno task content`, which `dev`, `build` and `test` all run first,
 * so a bad recipe fails the pull request rather than surfacing as an
 * empty page in production.
 *
 * Errors are collected, not thrown on the first one. Fixing six
 * problems in one pass beats six rebuilds, and a validator that stops
 * at the first fault trains you to distrust its "all clear".
 */

import { parseRecipe, type Problem, type Recipe } from "./recipe.ts";
import { AISLES } from "./vocabulary.ts";
import { shopFor } from "./pantry.ts";
import {
  COURSES,
  CUISINES,
  DIETARY,
  EFFORTS,
  FLAVORS,
  METHODS,
  PRINT_TEMPLATES,
  SLOTS,
} from "./vocabulary.ts";

const RECIPES_IN = "content/recipes";
const OUT = "public/content";
const PHOTOS = "public/photos";

// ---------------------------------------------------------------------------
// Reporting
// ---------------------------------------------------------------------------

const color = !Deno.noColor;
const red = (s: string) => (color ? `\x1b[31m${s}\x1b[0m` : s);
const dim = (s: string) => (color ? `\x1b[2m${s}\x1b[0m` : s);
const bold = (s: string) => (color ? `\x1b[1m${s}\x1b[0m` : s);

/** Wrap at 76 columns with a hanging indent. A validation message that
 * explains *why* is only useful if it is readable in a terminal. */
function wrap(text: string, indent: string): string {
  const out: string[] = [];
  let line = "";
  for (const word of text.split(/\s+/)) {
    if (line && line.length + word.length + 1 > 76) {
      out.push(line);
      line = word;
    } else {
      line = line ? `${line} ${word}` : word;
    }
  }
  if (line) out.push(line);
  return out.map((l, i) => (i === 0 ? l : indent + l)).join("\n");
}

function report(file: string, problems: Problem[]) {
  console.error(`\n${red("✕")} ${bold(file)}`);
  for (const p of problems) {
    const at = p.line === undefined ? "" : dim(`:${p.line}`);
    console.error(`  ${at ? `${at} ` : ""}${dim(p.where)}`);
    console.error(`     ${wrap(p.message, "     ")}`);
  }
}

// ---------------------------------------------------------------------------
// Build
// ---------------------------------------------------------------------------

async function main() {
  const recipes: Recipe[] = [];
  let failed = 0;

  const files: string[] = [];
  try {
    for await (const entry of Deno.readDir(RECIPES_IN)) {
      // AGENTS.md is the authoring contract that lives beside the
      // recipes, not a recipe — without this skip it would be parsed
      // as one and fail the slug check. Held to `vocabulary.ts` by
      // `agents_test.ts`, so it cannot drift into lying either way.
      if (entry.name === "AGENTS.md" || entry.name === "README.md") continue;
      if (entry.isFile && entry.name.endsWith(".md")) files.push(entry.name);
    }
  } catch (e) {
    if (!(e instanceof Deno.errors.NotFound)) throw e;
    console.error(
      `${red("✕")} ${RECIPES_IN}/ does not exist. Recipes live there, one ` +
        `markdown file each.`,
    );
    Deno.exit(1);
  }
  files.sort();

  for (const name of files) {
    const slug = name.replace(/\.md$/, "");
    if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) {
      report(`${RECIPES_IN}/${name}`, [{
        where: "filename",
        message:
          "the filename is the recipe's URL. Lowercase, digits and single " +
          "hyphens only — `salted-caramel.md`.",
      }]);
      failed++;
      continue;
    }

    const source = await Deno.readTextFile(`${RECIPES_IN}/${name}`);
    const { recipe, problems } = parseRecipe(slug, source);
    if (problems.length || !recipe) {
      report(`${RECIPES_IN}/${name}`, problems);
      failed++;
      continue;
    }
    recipes.push(recipe);
  }

  // --- checks that need the whole corpus -----------------------------------
  // (Identity is the slug, which the filesystem already keeps unique;
  // the photo check below is the one that still needs the set.)

  // A photo named in frontmatter but absent on disk renders as a
  // broken image — exactly the placeholder DS-01 §06 forbids.
  for (const r of recipes.filter((x) => x.photo)) {
    try {
      await Deno.stat(`${PHOTOS}/${r.photo}`);
    } catch {
      report(`${RECIPES_IN}/${r.slug}.md`, [{
        where: "frontmatter.photo",
        message:
          `\`${r.photo}\` is not in ${PHOTOS}/. Add the file, or drop the ` +
          `field — a recipe with no photograph has no photo block at all.`,
      }]);
      failed++;
    }
  }

  // Every ingredient must be placeable in a shop, and a person must
  // have placed it. The shopping list groups by aisle and merges on
  // the purchase name, and both come out of `pantry.ts` — an item the
  // table has never heard of fails here rather than turning up
  // unsorted at the bottom of somebody's list (DS-01 §06).
  for (const r of recipes) {
    const unplaced: Problem[] = [];
    for (const group of r.ingredients) {
      for (const ing of group.items) {
        const shop = shopFor(ing.item);
        if (shop === undefined) {
          unplaced.push({
            where: "ingredients",
            message:
              `\`${ing.item}\` is not in scripts/pantry.ts. Add it — the ` +
              `aisle it is bought in (${AISLES.join(", ")}), and \`buyAs\` ` +
              `if two recipes should merge onto one line. A bullet that ` +
              `is not a purchase at all takes \`{ omit: true }\`, because ` +
              `an item nobody mapped and an item deliberately not bought ` +
              `must not look the same to this check.`,
          });
        } else if (shop !== null) {
          ing.shop = shop;
        }
      }
    }
    if (unplaced.length) {
      report(`${RECIPES_IN}/${r.slug}.md`, unplaced);
      failed++;
    }
  }

  if (failed) {
    console.error(
      `\n${red(bold(`${failed} file${failed === 1 ? "" : "s"} failed validation.`))} ` +
        `Nothing was written.\n`,
    );
    Deno.exit(1);
  }

  // --- write ---------------------------------------------------------------

  await Deno.mkdir(`${OUT}/recipes`, { recursive: true });

  for (const r of recipes) {
    await Deno.writeTextFile(
      `${OUT}/recipes/${r.slug}.json`,
      JSON.stringify(r, null, 2) + "\n",
    );
  }

  // The index carries the facets and nothing a recipe page would need,
  // so the shelf loads one small file rather than the whole corpus.
  // Default order is last tested — the archive's own working order
  // beats the dictionary's (DS-01 §07).
  const index = {
    vocabulary: {
      slot: SLOTS,
      course: COURSES,
      flavor: FLAVORS,
      method: METHODS,
      effort: EFFORTS,
      dietary: DIETARY,
      cuisine: CUISINES,
      print: PRINT_TEMPLATES,
    },
    recipes: [...recipes]
      .sort((a, b) => (a.tested < b.tested ? 1 : a.tested > b.tested ? -1 : a.slug.localeCompare(b.slug)))
      .map((r) => ({
        slug: r.slug,
        title: r.title,
        tested: r.tested,
        yield: r.yield,
        time: r.time,
        slot: r.slot,
        course: r.course,
        flavor: r.flavor,
        method: r.method,
        effort: r.effort,
        dietary: r.dietary,
        cuisine: r.cuisine,
        print: r.print,
        photo: r.photo,
        // The shelf's last column. Null is "not stated" all the way
        // through — the row draws nothing rather than a hedge.
        keepsFor: r.keepsFor,
      })),
  };

  await Deno.writeTextFile(
    `${OUT}/index.json`,
    JSON.stringify(index, null, 2) + "\n",
  );

  const plural = recipes.length === 1 ? "recipe" : "recipes";
  console.log(`content: ${recipes.length} ${plural} → ${OUT}/`);
}

await main();
