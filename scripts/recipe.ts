/**
 * Parse and validate one recipe markdown file — DS-01 §06.
 *
 * **This module decides what a recipe *is*.** Everything downstream —
 * the browse facets, the search index, the four print templates, the
 * scaler — is a view of what comes out of here, which is why the
 * validation is strict and the errors are long. A recipe that parses
 * is a recipe every later phase can render without defensive code.
 *
 * The contract, in one line: **frontmatter is the schema, the body is
 * the document.** Frontmatter carries everything a filter or a search
 * needs (and is therefore a closed vocabulary — see `vocabulary.ts`);
 * the body carries the blocks in their fixed order and nothing
 * else.
 *
 * Nothing here is inferred. A dietary flag that is not written down is
 * "not verified", never "not suitable"; a missing photo is an absent
 * block, never a placeholder. Guessing on a reader's behalf is how a
 * recipe archive becomes untrustworthy.
 */

import { parse as parseYaml } from "@std/yaml";
import {
  BLOCKS,
  type BlockKey,
  COURSES,
  CUISINES,
  DIETARY,
  EFFORTS,
  FLAVORS,
  FRACTIONS,
  GAUGE_MAX,
  METHODS,
  PRINT_TEMPLATES,
  PROCEDURE_BLOCKS,
  SLOTS,
  type UnitKind,
  UNITS,
  WORD_RULES,
  YIELD_UNITS,
} from "./vocabulary.ts";

// ---------------------------------------------------------------------------
// What comes out
// ---------------------------------------------------------------------------

/** One thing wrong with one recipe. `line` is 1-based in the source
 * file when we know it — the whole value of a build-time check is that
 * it tells you where to stand. */
export type Problem = { line?: number; where: string; message: string };

export type Amount = {
  /** The parsed value, for scaling. A range carries its low end here. */
  value: number;
  /** The high end of a range (`2–3 cloves`), absent otherwise. */
  max?: number;
  /** Exactly as written, for display. Fraction glyphs survive. */
  text: string;
};

export type Ingredient = {
  amount: Amount | null;
  unit: string | null;
  unitKind: UnitKind | null;
  /** True when scaling may not produce a fraction of this (DS-01 §05):
   * every count unit, and every bare count. Eggs, cans, cloves. */
  indivisible: boolean;
  item: string;
  /** The preparation after the first comma — "cubed, cold". */
  note: string | null;
};

export type IngredientGroup = { name: string | null; items: Ingredient[] };

export type Step = {
  n: number;
  text: string;
  /** The step's own temperature / duration / doneness tell, printed on
   * its own line. Never a tooltip (DS-01 §2.5). */
  cue: string | null;
  /** Seconds, when the cue names a duration cook mode can count down.
   *
   * **A range takes its LOW end.** `6–9 MIN` sets six minutes, because
   * the timer's job is to say when to start looking, not when to stop:
   * the colour is the tell, not the clock (DS-01 §05). Ringing at nine
   * would be the archive telling you the caramel is done when it might
   * already be bitter. */
  timer: number | null;
};

export type Rescue = {
  symptom: string;
  /** False when it cannot be saved — "Past 190 °C. It does not come
   * back." The honest half of the block, and a different treatment. */
  recoverable: boolean;
  text: string;
};

/** One operating number from the plate (DS-01 §06 amendment,
 * 2026-09-21): the pan, the oven, the temperature it is done at.
 *
 * **Authored, never derived.** Every one of these is already
 * somewhere in the document — in an equipment line, inside a cue, in
 * the middle of a Keeps paragraph — and lifting them out
 * mechanically would mean guessing which of a recipe's numbers is the
 * one you check with your hands full. Nothing is ever inferred
 * (DS-01 §12). */
export type Gauge = { label: string; value: string; note: string | null };

export type Recipe = {
  slug: string;
  title: string;
  tested: string;
  yield: { amount: number; unit: string; servings?: number };
  /** Minutes. Formatting is the renderer's job, in one place. */
  time: { active: number; total: number };
  slot: string[];
  course: string;
  flavor: string[];
  method: string;
  effort: string;
  dietary: string[];
  cuisine: string[];
  print: string;
  photo: string | null;
  /** Empty when the recipe has none, which is the honest answer for a
   * drink blended until it is smooth. Never a placeholder row. */
  gauges: Gauge[];
  ingredients: IngredientGroup[];
  equipment: string[];
  steps: Step[];
  watchpoints: string[];
  rescues: Rescue[];
  keeps: string[];
  note: string[];
};

// ---------------------------------------------------------------------------
// Small parsers
// ---------------------------------------------------------------------------

const FRACTION_GLYPHS = Object.keys(FRACTIONS).join("");
const FRAC = `[${FRACTION_GLYPHS}]`;

/** `15m`, `45m`, `1h30m`, `12h`, `2d`, `1d12h` → minutes.
 *
 * Deliberately no bare-number form: `total: 45` reads as 45 of
 * something, and the something is exactly what a reader gets wrong. */
function parseDuration(raw: unknown): number | null {
  if (typeof raw !== "string") return null;
  const m = raw.trim().match(/^(?:(\d+)d)?(?:(\d+)h)?(?:(\d+)m)?$/i);
  if (!m || (!m[1] && !m[2] && !m[3])) return null;
  return (
    Number(m[1] ?? 0) * 1440 + Number(m[2] ?? 0) * 60 + Number(m[3] ?? 0)
  );
}

/** A quantity as written: `200`, `¾`, `1½`, `2–3`. Returns null when
 * the text is not a quantity at all, which is how an ingredient line
 * with no amount ("flaky salt, to finish") is recognised. */
function parseAmount(text: string): Amount | null {
  const one = (t: string): number | null => {
    const m = t.match(new RegExp(`^(\\d+(?:\\.\\d+)?)?(${FRAC})?$`, "u"));
    if (!m || (!m[1] && !m[2])) return null;
    return Number(m[1] ?? 0) + (m[2] ? FRACTIONS[m[2]] : 0);
  };

  const range = text.split(/\s*[–—-]\s*/);
  if (range.length === 2) {
    const lo = one(range[0]);
    const hi = one(range[1]);
    if (lo === null || hi === null) return null;
    return { value: lo, max: hi, text };
  }

  const value = one(text);
  return value === null ? null : { value, text };
}

/**
 * `200 g caster sugar` → 200 · g · caster sugar
 * `90 g unsalted butter, cubed, cold` → … item "unsalted butter",
 *   note "cubed, cold"
 * `2 eggs` → 2 · (no unit) · eggs, and indivisible
 *
 * The unit is whatever the second token is *if the vocabulary knows
 * it*; otherwise there is no unit and the token belongs to the item.
 * That is what keeps `2 eggs` and `1 clove garlic` both correct
 * without a special case for either.
 */
function parseIngredient(line: string): { ok: Ingredient } | { err: string } {
  const words = line.trim().split(/\s+/);

  let amount: Amount | null = null;
  let rest = words;

  // A leading quantity may be one token (`200`, `¾`, `1½`) or three
  // when a range was typed with spaces (`2 – 3`).
  for (const take of [3, 1]) {
    if (words.length <= take) continue;
    const candidate = parseAmount(words.slice(0, take).join(take === 1 ? "" : " "));
    if (candidate) {
      amount = candidate;
      rest = words.slice(take);
      break;
    }
  }

  let unit: string | null = null;
  let unitKind: UnitKind | null = null;
  if (amount && rest.length > 1) {
    const known = UNITS[rest[0].toLowerCase()];
    if (known) {
      unit = known.canonical;
      unitKind = known.kind;
      rest = rest.slice(1);
    }
  }

  if (rest.length === 0) return { err: "no ingredient named, only a quantity" };

  // DS-01 §05, the measurement ladder. Grams are whole; anything
  // smaller than a unit is a glyph, never a decimal.
  if (amount?.text.includes(".")) {
    if (unit === "g") {
      return { err: `"${amount.text} g" — grams are whole numbers (DS-01 §05)` };
    }
    if (unitKind !== "mass") {
      return {
        err:
          `"${amount.text}" — fractions are glyphs (¾), never decimals, ` +
          `outside mass and temperature (DS-01 §05)`,
      };
    }
  }

  const [item, ...noteParts] = rest.join(" ").split(/,\s*/);
  return {
    ok: {
      amount,
      unit,
      unitKind,
      indivisible: unitKind === "count" || (amount !== null && unit === null),
      item,
      note: noteParts.length ? noteParts.join(", ") : null,
    },
  };
}

/** Does this cue name a duration? Used to enforce "the clock is never
 * alone" — temperatures are not durations and must not trip it — and
 * to hand cook mode something to count down. */
const DURATION_IN_CUE =
  /(\d+)\s*(?:[–—-]\s*(\d+)\s*)?(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours|d|day|days)\b/giu;

const PER_UNIT: Record<string, number> = {
  s: 1,
  m: 60,
  h: 3600,
  d: 86400,
};

/**
 * The first duration in a cue, in seconds — what cook mode counts
 * down (DS-01 §10's one sanctioned piece of motion).
 *
 * A range takes its low end, and anything past an hour is left alone:
 * a two-day cure is a thing you put in the fridge, not a thing you
 * stand and watch, and offering to count it down would be the
 * interface misunderstanding the recipe.
 */
function timerFor(cue: string | null): number | null {
  if (!cue) return null;
  DURATION_IN_CUE.lastIndex = 0;
  const m = DURATION_IN_CUE.exec(cue);
  if (!m) return null;

  const seconds = Number(m[1]) * PER_UNIT[m[3][0].toLowerCase()];
  return seconds > 0 && seconds <= 3600 ? seconds : null;
}

// ---------------------------------------------------------------------------
// Frontmatter
// ---------------------------------------------------------------------------

const ALLOWED_KEYS = [
  "title",
  "tested",
  "yield",
  "time",
  "slot",
  "course",
  "flavor",
  "method",
  "effort",
  "dietary",
  "cuisine",
  "print",
  "photo",
  "gauges",
];

type Frontmatter = Record<string, unknown>;

/** Where a frontmatter key sits in the file, so an error can point at
 * a line rather than at a name. Best-effort: nested keys report their
 * top-level parent, which is close enough to stand on. */
function keyLine(raw: string, key: string, offset: number): number | undefined {
  const idx = raw.split("\n").findIndex((l) => l.startsWith(`${key}:`));
  return idx === -1 ? undefined : idx + offset;
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

type RawBlock = { key: BlockKey; heading: string; line: number; lines: string[] };

/** A markdown list item plus its indented continuation lines, kept
 * together with the line it started on. */
type Item = { line: number; text: string; continuations: string[] };

function collectItems(lines: string[], startLine: number, ordered: boolean): Item[] {
  const marker = ordered ? /^\s*\d+\.\s+(.*)$/ : /^\s*[-*]\s+(.*)$/;
  const items: Item[] = [];
  lines.forEach((raw, i) => {
    const m = raw.match(marker);
    if (m) {
      items.push({ line: startLine + i, text: m[1].trim(), continuations: [] });
    } else if (raw.trim() && items.length && /^\s+/.test(raw)) {
      items[items.length - 1].continuations.push(raw.trim());
    }
  });
  return items;
}

// ---------------------------------------------------------------------------
// The entry point
// ---------------------------------------------------------------------------

export function parseRecipe(
  slug: string,
  source: string,
): { recipe: Recipe | null; problems: Problem[] } {
  const problems: Problem[] = [];
  const fail = (where: string, message: string, line?: number) => {
    problems.push({ where, message, line });
  };

  // --- split frontmatter ---------------------------------------------------

  const split = source.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
  if (!split) {
    fail(
      "frontmatter",
      "no YAML frontmatter. Every recipe opens with a `---` block carrying " +
        "the schema of DS-01 §06 — it is what makes the recipe findable.",
      1,
    );
    return { recipe: null, problems };
  }
  const [, rawYaml, rawBody] = split;
  const bodyStartLine = rawYaml.split("\n").length + 3;

  let fm: Frontmatter;
  try {
    fm = (parseYaml(rawYaml) ?? {}) as Frontmatter;
  } catch (e) {
    fail("frontmatter", `YAML will not parse: ${(e as Error).message}`, 2);
    return { recipe: null, problems };
  }

  const at = (key: string) => keyLine(rawYaml, key, 2);

  // --- frontmatter validation ---------------------------------------------

  for (const key of Object.keys(fm)) {
    if (!ALLOWED_KEYS.includes(key)) {
      const near = ALLOWED_KEYS.find(
        (k) => k.startsWith(key.slice(0, 3)) || key.startsWith(k.slice(0, 3)),
      );
      fail(
        `frontmatter.${key}`,
        `not a field in the schema${near ? ` — did you mean \`${near}\`?` : ""}. ` +
          `Allowed: ${ALLOWED_KEYS.join(", ")}.`,
        at(key),
      );
    }
  }

  const oneOf = (key: string, allowed: readonly string[]): string => {
    const v = fm[key];
    if (typeof v !== "string" || !allowed.includes(v)) {
      fail(
        `frontmatter.${key}`,
        `${v === undefined ? "missing" : `\`${String(v)}\` is not in the vocabulary`}. ` +
          `One of: ${allowed.join(", ")}. Widening the list is a deliberate ` +
          `edit to scripts/vocabulary.ts, not a thing to do in passing.`,
        at(key),
      );
      return "";
    }
    return v;
  };

  const manyOf = (
    key: string,
    allowed: readonly string[],
    mayBeEmpty: boolean,
  ): string[] => {
    const v = fm[key];
    if (!Array.isArray(v)) {
      fail(
        `frontmatter.${key}`,
        `${v === undefined ? "missing" : "must be a list"} — write \`${key}: []\` ` +
          `if there is genuinely nothing to declare.`,
        at(key),
      );
      return [];
    }
    if (!mayBeEmpty && v.length === 0) {
      fail(`frontmatter.${key}`, `may not be empty — every recipe has at least one.`, at(key));
    }
    const bad = v.filter((x) => typeof x !== "string" || !allowed.includes(x));
    if (bad.length) {
      fail(
        `frontmatter.${key}`,
        `${bad.map((b) => `\`${String(b)}\``).join(", ")} not in the vocabulary. ` +
          `Allowed: ${allowed.join(", ")}.`,
        at(key),
      );
    }
    return v.filter((x): x is string => typeof x === "string" && allowed.includes(x));
  };

  const title = typeof fm.title === "string" ? fm.title.trim() : "";
  if (!title) fail("frontmatter.title", "missing.", at("title"));

  const tested = typeof fm.tested === "string"
    ? fm.tested
    : fm.tested instanceof Date
    ? fm.tested.toISOString().slice(0, 10)
    : "";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(tested)) {
    fail(
      "frontmatter.tested",
      "missing or not an ISO date (YYYY-MM-DD). This is the date the recipe " +
        "was last cooked as written, and it is the archive's default sort order.",
      at("tested"),
    );
  } else if (tested > new Date().toISOString().slice(0, 10)) {
    fail(
      "frontmatter.tested",
      `${tested} is in the future. delishh never lies about status (DS-01 §11).`,
      at("tested"),
    );
  }


  // yield
  const y = (fm.yield ?? {}) as Record<string, unknown>;
  if (typeof y.amount !== "number" || y.amount <= 0) {
    fail("frontmatter.yield.amount", "missing or not a positive number.", at("yield"));
  }
  if (typeof y.unit !== "string" || !YIELD_UNITS.includes(y.unit as never)) {
    fail(
      "frontmatter.yield.unit",
      `must be one of: ${YIELD_UNITS.join(", ")}.`,
      at("yield"),
    );
  }
  if (y.servings !== undefined && (!Number.isInteger(y.servings) || (y.servings as number) < 1)) {
    fail("frontmatter.yield.servings", "must be a positive whole number when present.", at("yield"));
  }

  // time
  const t = (fm.time ?? {}) as Record<string, unknown>;
  const active = parseDuration(t.active);
  const total = parseDuration(t.total);
  if (active === null) {
    fail("frontmatter.time.active", "missing or unparseable. Use `15m`, `1h30m`, `2d`.", at("time"));
  }
  if (total === null) {
    fail("frontmatter.time.total", "missing or unparseable. Use `15m`, `1h30m`, `2d`.", at("time"));
  }
  if (active !== null && total !== null && total < active) {
    fail(
      "frontmatter.time",
      `total (${total} min) is less than active (${active} min). Total elapsed ` +
        `always includes every hold — that is the rule that keeps "ready in 20 ` +
        `minutes" off an overnight cure (DS-01 §11).`,
      at("time"),
    );
  }

  const slot = manyOf("slot", SLOTS, false);
  const course = oneOf("course", COURSES);
  const flavor = manyOf("flavor", FLAVORS, false);
  const method = oneOf("method", METHODS);
  const effort = oneOf("effort", EFFORTS);
  const dietary = manyOf("dietary", DIETARY, true);
  const cuisine = manyOf("cuisine", CUISINES, true);
  const print = oneOf("print", PRINT_TEMPLATES);

  let photo: string | null = null;
  if (fm.photo !== undefined) {
    if (typeof fm.photo !== "string" || !fm.photo.trim()) {
      fail(
        "frontmatter.photo",
        "must be a filename, or absent. A recipe with no photograph has no " +
          "photo block at all — never a placeholder, never a grey box (DS-01 §06).",
        at("photo"),
      );
    } else {
      photo = fm.photo.trim();
    }
  }

  // --- gauges: the operating numbers (DS-01 §06, amended 2026-09-21) -------
  //
  // Optional, and an absent strip is the honest answer for a recipe
  // whose tell is not a number. What this validates is shape only: a
  // gauge's *content* is the cook's, the same way a step's is.

  const gauges: Gauge[] = [];
  if (fm.gauges !== undefined) {
    if (!Array.isArray(fm.gauges)) {
      fail(
        "frontmatter.gauges",
        "must be a list of `{ label, value }` entries, or absent — the " +
          "operating numbers you check with your hands full (DS-01 §06).",
        at("gauges"),
      );
    } else if (fm.gauges.length > GAUGE_MAX) {
      fail(
        "frontmatter.gauges",
        `${fm.gauges.length} gauges, and ${GAUGE_MAX} is the ceiling. The cap ` +
          `is the feature: a strip you cannot take in at a glance is prose ` +
          `wearing a table's clothes, and prose belongs in the blocks.`,
        at("gauges"),
      );
    } else {
      fm.gauges.forEach((raw, i) => {
        const where = `frontmatter.gauges[${i}]`;
        if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
          fail(
            where,
            "is not a `{ label, value }` entry. A bare string cannot say " +
              "which half of it is the number.",
            at("gauges"),
          );
          return;
        }
        const entry = raw as Record<string, unknown>;
        for (const key of Object.keys(entry)) {
          if (!["label", "value", "note"].includes(key)) {
            fail(
              `${where}.${key}`,
              "is not part of a gauge. A gauge is `label`, `value`, and an " +
                "optional `note` — three fields, because a fourth would be a " +
                "sentence.",
              at("gauges"),
            );
          }
        }
        const text = (key: "label" | "value"): string | null => {
          const v = entry[key];
          if (typeof v !== "string" || !v.trim()) {
            fail(
              `${where}.${key}`,
              `missing. A gauge without a ${key} is half a fact: ` +
                `\`{ label: Oven, value: 190 °C }\` reads at a metre, and ` +
                `either half alone reads as nothing.`,
              at("gauges"),
            );
            return null;
          }
          return v.trim();
        };
        const label = text("label");
        const value = text("value");
        if (entry.note !== undefined && typeof entry.note !== "string") {
          fail(
            `${where}.note`,
            "must be a string, or absent. The note is the aside after the " +
              "number — `covered`, `center`, `flat bags` — never a list.",
            at("gauges"),
          );
        }
        if (label !== null && value !== null) {
          const note =
            typeof entry.note === "string" && entry.note.trim()
              ? entry.note.trim()
              : null;
          gauges.push({ label, value, note });
        }
      });
    }
  }

  // --- body: split into blocks --------------------------------------------

  const bodyLines = rawBody.split("\n");
  const blocks: RawBlock[] = [];
  const seen = new Set<BlockKey>();

  bodyLines.forEach((line, i) => {
    const lineNo = bodyStartLine + i;
    if (/^#\s/.test(line)) {
      fail(
        "body",
        "an `#` heading in the body. The title comes from frontmatter; the " +
          "body carries `##` blocks only.",
        lineNo,
      );
      return;
    }
    const m = line.match(/^##\s+(.*?)\s*$/);
    if (!m) {
      if (blocks.length) blocks[blocks.length - 1].lines.push(line);
      else if (line.trim()) {
        fail(
          "body",
          "text before the first `## ` block. Everything in the body belongs " +
            "to one of the blocks of DS-01 §06.",
          lineNo,
        );
      }
      return;
    }
    const known = BLOCKS.find((b) => b.heading.toLowerCase() === m[1].toLowerCase());
    if (!known) {
      fail(
        "body",
        `\`## ${m[1]}\` is not a block. The body carries exactly these, in ` +
          `this order: ${BLOCKS.map((b) => b.heading).join(", ")}.`,
        lineNo,
      );
      return;
    }
    if (seen.has(known.key)) {
      fail("body", `\`## ${known.heading}\` appears twice.`, lineNo);
      return;
    }
    seen.add(known.key);
    blocks.push({ key: known.key, heading: known.heading, line: lineNo, lines: [] });
  });

  // Order is the whole point of a fixed form: you learn where to look
  // exactly once (DS-01 §06). Blocks may be absent; they may not move.
  const order = BLOCKS.map((b) => b.key);
  blocks.reduce((prev, b) => {
    if (order.indexOf(b.key) < order.indexOf(prev)) {
      fail(
        "body",
        // BEFORE, not after: this fires precisely when `b` sorts
        // earlier than the block above it, so `b` is the one that
        // needs to move up. The message said "after" from Phase 1
        // until the 2026-09-20 block-order swap became the first
        // thing that ever triggered it.
        `\`## ${b.heading}\` is out of order — it belongs before ` +
          `${BLOCKS.find((x) => x.key === prev)!.heading}. The block order is ` +
          `fixed: ${BLOCKS.map((x) => x.heading).join(" → ")}.`,
        b.line,
      );
    }
    return b.key;
  }, order[0]);

  for (const b of BLOCKS) {
    if (b.required && !seen.has(b.key)) {
      fail(
        "body",
        `\`## ${b.heading}\` is required and absent.` +
          (b.key === "note"
            ? " The note is the one human voice on the page and the reason this " +
              "archive is yours rather than a database (DS-01 §01). Serif, " +
              "sentence case, first person, and nothing checks its words."
            : ""),
        bodyStartLine,
      );
    }
  }

  const block = (key: BlockKey): RawBlock | undefined => blocks.find((b) => b.key === key);
  const linesOf = (key: BlockKey) => block(key)?.lines ?? [];
  const lineOf = (key: BlockKey) => (block(key)?.line ?? bodyStartLine) + 1;

  // --- body: parse each block ---------------------------------------------

  // Ingredients, optionally grouped by `### sub-preparation`.
  const ingredients: IngredientGroup[] = [];
  {
    const raw = linesOf("ingredients");
    let group: IngredientGroup = { name: null, items: [] };
    raw.forEach((line, i) => {
      const lineNo = lineOf("ingredients") + i;
      const head = line.match(/^###\s+(.*?)\s*$/);
      if (head) {
        if (group.items.length || group.name) ingredients.push(group);
        group = { name: head[1], items: [] };
        return;
      }
      const item = line.match(/^\s*[-*]\s+(.*)$/);
      if (!item) return;
      const parsed = parseIngredient(item[1]);
      if ("err" in parsed) fail("ingredients", parsed.err, lineNo);
      else group.items.push(parsed.ok);
    });
    if (group.items.length || group.name) ingredients.push(group);

    if (seen.has("ingredients") && ingredients.every((g) => g.items.length === 0)) {
      fail(
        "ingredients",
        "the block is empty. Ingredients sit above the fold because a " +
          "returning cook needs quantities and a first-time cook needs a " +
          "shopping list (DS-01 §06).",
        lineOf("ingredients"),
      );
    }
  }

  const equipment = collectItems(linesOf("equipment"), lineOf("equipment"), false)
    .map((i) => i.text);

  // Steps: an ordered list, each item optionally closing with a
  // `cue:` continuation carrying its temperature, duration and tell.
  const steps: Step[] = [];
  {
    const items = collectItems(linesOf("steps"), lineOf("steps"), true);
    items.forEach((item, i) => {
      const cueLines = item.continuations.filter((c) => /^cue:/i.test(c));
      const prose = item.continuations.filter((c) => !/^cue:/i.test(c));
      if (cueLines.length > 1) {
        fail("steps", `step ${i + 1} carries two \`cue:\` lines; it gets one.`, item.line);
      }
      const cue = cueLines.length ? cueLines[0].replace(/^cue:\s*/i, "").trim() : null;

      // DS-01 §05: the clock is never alone. A cue that is only a
      // duration is withholding the thing the reader actually needs.
      if (cue) {
        const withoutDurations = cue.replace(DURATION_IN_CUE, "");
        if (
          withoutDurations !== cue &&
          !/[a-z]/i.test(withoutDurations.replace(/[·•,\/\s–—-]/g, ""))
        ) {
          fail(
            "steps",
            `step ${i + 1}'s cue is \`${cue}\` — a duration with no tell. Time is ` +
              `the least reliable variable in any kitchen; say what it looks ` +
              `like when it is done: \`6–9 MIN · UNTIL THE EDGES RUN CLEAR\` ` +
              `(DS-01 §05).`,
            item.line,
          );
        }
      }

      steps.push({
        n: i + 1,
        text: [item.text, ...prose].join(" ").replace(/\s+/g, " ").trim(),
        cue,
        timer: timerFor(cue),
      });
    });
    if (seen.has("steps") && steps.length === 0) {
      fail("steps", "the block is empty. Steps are a numbered list (`1.`).", lineOf("steps"));
    }
  }

  const watchpoints = collectItems(linesOf("watchpoints"), lineOf("watchpoints"), false)
    .map((i) => [i.text, ...i.continuations].join(" "));

  const rescues: Rescue[] = [];
  for (const item of collectItems(linesOf("rescues"), lineOf("rescues"), false)) {
    const whole = [item.text, ...item.continuations].join(" ");
    const m = whole.match(/^\*\*(.+?)\*\*\s*(\[terminal\])?\s*[—–-]?\s*(.*)$/u);
    if (!m) {
      fail(
        "rescues",
        "a rescue reads `- **Symptom** — what caused it, and what to do`. Add " +
          "`[terminal]` after the symptom when it cannot be saved — saying so " +
          "plainly is the most generous sentence a recipe can carry (DS-01 §06).",
        item.line,
      );
      continue;
    }
    rescues.push({
      symptom: m[1].trim(),
      recoverable: !m[2],
      text: m[3].trim(),
    });
  }

  const keeps = collectItems(linesOf("keeps"), lineOf("keeps"), false)
    .map((i) => [i.text, ...i.continuations].join(" "));

  // The note: free prose, in paragraphs. Nothing below reads it.
  const note = linesOf("note")
    .join("\n")
    .split(/\n\s*\n/)
    .map((p) => p.trim().replace(/\s*\n\s*/g, " "))
    .filter(Boolean);
  if (seen.has("note") && note.length === 0) {
    fail(
      "note",
      "the block is present but empty. An empty note is worse than no recipe — " +
        "write the sentence you would say out loud about this dish.",
      lineOf("note"),
    );
  }

  // --- the word rules ------------------------------------------------------

  const procedure = new Set<string>(PROCEDURE_BLOCKS);
  for (const b of blocks) {
    if (b.key === "note") continue; // exempt, unconditionally (DS-01 §11)
    const text = b.lines.join("\n");
    for (const rule of WORD_RULES) {
      if (rule.scope === "procedure" && !procedure.has(b.key)) continue;
      rule.pattern.lastIndex = 0;
      let hit: RegExpExecArray | null;
      while ((hit = rule.pattern.exec(text)) !== null) {
        const line = b.line + 1 + text.slice(0, hit.index).split("\n").length - 1;
        fail("words", `"${hit[0]}" in ${b.heading} — ${rule.because}`, line);
        if (hit[0].length === 0) rule.pattern.lastIndex++;
      }
    }
  }

  // A gauge is procedure, not the note's human voice: it is read at
  // the bench, in the same register as a step, so it answers to the
  // same words. The Note's exemption is the *one* exemption (§11).
  for (const g of gauges) {
    const text = [g.label, g.value, g.note].filter(Boolean).join(" · ");
    for (const rule of WORD_RULES) {
      rule.pattern.lastIndex = 0;
      let hit: RegExpExecArray | null;
      while ((hit = rule.pattern.exec(text)) !== null) {
        fail("words", `"${hit[0]}" in a gauge — ${rule.because}`, at("gauges"));
        if (hit[0].length === 0) rule.pattern.lastIndex++;
      }
    }
  }

  if (problems.length) return { recipe: null, problems };

  return {
    recipe: {
      slug,
      title,
      tested,
      yield: {
        amount: y.amount as number,
        unit: y.unit as string,
        ...(y.servings === undefined ? {} : { servings: y.servings as number }),
      },
      time: { active: active as number, total: total as number },
      slot,
      course,
      flavor,
      method,
      effort,
      dietary,
      cuisine,
      print,
      photo,
      gauges,
      ingredients,
      equipment,
      steps,
      watchpoints,
      rescues,
      keeps,
      note,
    },
    problems,
  };
}
