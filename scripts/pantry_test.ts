/**
 * The pantry table — the checks that keep it from lying.
 *
 * The table is the one place in the build where a human judgement is
 * recorded rather than a rule enforced: which aisle a thing is in, and
 * what two recipes both mean by it. That makes it the one place a
 * wrong answer is invisible, because nothing downstream can tell a
 * considered "dairy" from a careless one.
 *
 * So these hold the shapes that *are* checkable. The completeness of
 * the table against the corpus is checked by `build-content.ts` on
 * every build — `deno task test` runs `content` first, so an unmapped
 * ingredient fails the suite before it reaches here.
 */

import { assert, assertEquals } from "@std/assert";
import { AISLE_LABELS, AISLES, DIETARY } from "./vocabulary.ts";
import { PANTRY, shopFor, violations } from "./pantry.ts";

const entries = Object.entries(PANTRY);

Deno.test("every aisle named in the table is one the vocabulary knows", () => {
  for (const [item, purchase] of entries) {
    if ("omit" in purchase) continue;
    assert(
      (AISLES as readonly string[]).includes(purchase.aisle),
      `\`${item}\` is shelved in "${purchase.aisle}", which is not an aisle`,
    );
  }
});

Deno.test("every aisle is somewhere in the table", () => {
  const used = new Set(
    entries.flatMap(([, p]) => "omit" in p ? [] : [p.aisle]),
  );
  for (const aisle of AISLES) {
    assert(
      used.has(aisle),
      `nothing is bought in "${aisle}". An aisle no item uses is a ` +
        `heading that never renders — drop it, or shelve something there.`,
    );
  }
});

Deno.test("every aisle has words to print above its items", () => {
  assertEquals(
    Object.keys(AISLE_LABELS).sort(),
    [...AISLES].sort(),
    "AISLE_LABELS and AISLES disagree",
  );
  for (const [aisle, label] of Object.entries(AISLE_LABELS)) {
    assert(label.trim().length > 0, `"${aisle}" has no label`);
  }
});

Deno.test("a purchase name is never blank", () => {
  for (const [item, purchase] of entries) {
    if ("omit" in purchase) continue;
    if (purchase.buyAs === undefined) continue;
    assert(
      purchase.buyAs.trim().length > 0,
      `\`${item}\` has an empty \`buyAs\`. Leave it out to use the item ` +
        `itself; a blank one merges every silent line onto one.`,
    );
  }
});

Deno.test("an omitted item claims nothing else", () => {
  for (const [item, purchase] of entries) {
    if (!("omit" in purchase)) continue;
    assertEquals(
      Object.keys(purchase).sort(),
      ["omit"],
      `\`${item}\` is both omitted and shelved. It is one or the other.`,
    );
  }
});

Deno.test("an item with no entry is unknown, not omitted", () => {
  // The distinction the whole gate rests on. `undefined` fails the
  // build; `null` is an authored non-purchase and passes quietly. A
  // table that conflated them would let a typo pass as a decision.
  assertEquals(shopFor("a thing nobody has ever cooked with"), undefined);
  assertEquals(shopFor("warm water"), null);
});

Deno.test("buyAs defaults to the item, and overrides it when given", () => {
  assertEquals(shopFor("carrots"), { aisle: "produce", buyAs: "carrots" });
  assertEquals(shopFor("yellow onion"), {
    aisle: "produce",
    buyAs: "yellow onions",
  });
});

Deno.test("the merges the corpus actually depends on", () => {
  // Each of these is two or more ways the corpus writes one purchase.
  // They are the reason the table has a `buyAs` at all, and a
  // regression here is a shopping list with the same thing on it
  // twice — which is the failure the feature exists to prevent.
  const sameThing = [
    ["yellow onion", "yellow onions"],
    ["large egg", "large eggs", "eggs", "egg yolk"],
    ["butter", "melted butter", "unsalted butter"],
    ["cilantro", "cilantro — at serving only"],
    ["flour", "all-purpose flour"],
    ["sugar", "granulated sugar"],
    ["chipotle in adobo", "chipotles in adobo", "adobo sauce"],
    ["neutral oil", "corn oil or neutral oil", "lard or neutral oil"],
    ["sourdough", "day-old sourdough"],
    ["milk", "whole milk", "whole milk or cream"],
  ];
  for (const group of sameThing) {
    const names = group.map((item) => {
      const shop = shopFor(item);
      assert(shop, `\`${item}\` is not a purchase`);
      return shop.buyAs;
    });
    assertEquals(
      new Set(names).size,
      1,
      `${group.join(" / ")} should be one purchase, and are: ${
        names.join(" / ")
      }`,
    );
  }
});

Deno.test("a compound is never resolved to one of its halves", () => {
  // An `or` may pick a side — the shopper decides once, in the table.
  // An `and` may not: nothing here knows how much of the 200 g is the
  // cheddar, so the pair stays one line under its own name (DS-01 §06).
  for (const [item, purchase] of entries) {
    if ("omit" in purchase || purchase.buyAs === undefined) continue;
    if (!/ and /.test(item)) continue;
    assert(
      / and /.test(purchase.buyAs),
      `\`${item}\` is bought as "${purchase.buyAs}", which drops half of ` +
        `it. A compound keeps both names.`,
    );
  }
});

// ---------------------------------------------------------------------------
// `breaks` — the flags an item defeats, and the build's refusal
// ---------------------------------------------------------------------------

Deno.test("every flag an item breaks is one the vocabulary has", () => {
  // A `breaks` naming a flag nobody can set is a refusal that can
  // never fire, which is a comment pretending to be a check.
  for (const [item, purchase] of entries) {
    if ("omit" in purchase || !purchase.breaks) continue;
    for (const flag of purchase.breaks) {
      assert(
        (DIETARY as readonly string[]).includes(flag),
        `\`${item}\` breaks "${flag}", which is not a dietary flag`,
      );
    }
    assert(purchase.breaks.length > 0, `\`${item}\` has an empty breaks list`);
  }
});

Deno.test("an item bought as another breaks at least what that one breaks", () => {
  // "flour" is bought as "all-purpose flour"; if the second breaks
  // gluten-free, the first cannot say nothing, or a recipe could dodge
  // the refusal by writing the shorter name.
  for (const [item, purchase] of entries) {
    if ("omit" in purchase || !purchase.buyAs) continue;
    const bought = PANTRY[purchase.buyAs];
    if (!bought || "omit" in bought || !bought.breaks) continue;
    for (const flag of bought.breaks) {
      assert(
        purchase.breaks?.includes(flag),
        `\`${item}\` is bought as \`${purchase.buyAs}\`, which breaks ` +
          `"${flag}", but the row says nothing about it`,
      );
    }
  }
});

Deno.test("the refusal names the flag and the item, and nothing else", () => {
  // The fixture is the Frosty's list with a flag it cannot carry: the
  // malt is wheat. The other flag is fine and must not be named.
  const items = ["vanilla ice cream", "milk", "chocolate syrup", "malted milk powder", "cocoa powder"];
  assertEquals(
    violations(["vegetarian", "gluten-free"], items),
    [{ flag: "gluten-free", item: "malted milk powder" }],
  );
});

Deno.test("the refusal never fires on a flag nothing in the table breaks", () => {
  // The table only says no. An empty answer is "nothing contradicts
  // this", never "this is verified" — and a recipe of tap water and
  // an unmapped item gets the same empty answer as a clean one.
  assertEquals(violations(["vegan", "nut-free"], ["warm water", "not in the table"]), []);
  assertEquals(violations([], ["ground beef"]), []);
});

Deno.test("an `or` breaks what either branch breaks", () => {
  // N0 verifies both branches of an `or`. "lard or neutral oil" is
  // bought as neutral oil and still breaks vegetarian, because the
  // author offered lard.
  assertEquals(
    violations(["vegetarian"], ["lard or neutral oil"]),
    [{ flag: "vegetarian", item: "lard or neutral oil" }],
  );
});

Deno.test("the table marks only what is true of every bottle", () => {
  // The three named in the type's comment as brand-dependent must
  // stay silent on the flag that varies. If one of these starts
  // breaking, the bar has moved and the comment is lying.
  const silent: [string, string][] = [
    ["vanilla ice cream", "vegetarian"], // gelatin, sometimes
    ["hoisin sauce", "gluten-free"], // wheat, often
    ["Gruyère", "vegetarian"], // animal rennet, often
    ["neutral oil", "nut-free"], // peanut, sometimes
    ["mole paste", "nut-free"], // nearly every jar, not every jar
  ];
  for (const [item, flag] of silent) {
    const entry = PANTRY[item];
    assert(entry && !("omit" in entry), `fixture drift: \`${item}\` is not in the table`);
    assert(
      !entry.breaks?.includes(flag as never),
      `\`${item}\` breaks "${flag}", but that varies by brand — the line's note decides it`,
    );
  }
});
