/**
 * Contrast, measured from `src/theme.css` itself — DS-01 §12.
 *
 * "WCAG AA for all functional text, measured on its actual background,
 * in both themes" is a hard constraint, and until now it was a hard
 * constraint nobody could check. These tests read the real token
 * values out of the stylesheet and recompute every pair.
 *
 * **Two things fail here, and the second is the useful one.**
 *
 *  1. A pair that drops below its threshold — someone retuned a hex
 *     and took a colour under the bar with it.
 *  2. A ratio *written in a comment* that no longer matches the hex
 *     beside it. Those comments are how the next person decides
 *     whether they have headroom to darken something, and a comment
 *     that lies is worse than no comment at all.
 *
 * Both themes are checked independently, because a token that passes
 * on the lit bench can fail after dark, and this file is the
 * only place the two are written down together.
 */

import { assert, assertEquals } from "@std/assert";

const css = await Deno.readTextFile("src/theme.css");

// ---------------------------------------------------------------------------
// WCAG 2.1 relative luminance and contrast
// ---------------------------------------------------------------------------

function luminance(hex: string): number {
  const channels = [1, 3, 5]
    .map((i) => parseInt(hex.slice(i, i + 2), 16) / 255)
    .map((v) => (v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)));
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}

export function contrast(fg: string, bg: string): number {
  const a = luminance(fg);
  const b = luminance(bg);
  return (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
}

// ---------------------------------------------------------------------------
// Reading the stylesheet
// ---------------------------------------------------------------------------

/**
 * The three blocks of the three-state contract. `[data-theme='dark']`
 * is checked rather than the media query because the two carry
 * identical values by design — and the test below proves that, so
 * checking one covers both.
 */
function block(selector: string): string {
  const at = css.indexOf(selector);
  assert(at !== -1, `no ${selector} block in theme.css`);
  const open = css.indexOf("{", at);
  const close = css.indexOf("\n}", open);
  return css.slice(open, close);
}

const LIGHT = block(":root {");
const DARK = block(":root[data-theme='dark']");
const DARK_MEDIA = block(":root:not([data-theme='light'])");

/** Resolve a token to a hex, following one level of `var(--other)`. */
function token(name: string, theme: string): string {
  const read = (where: string) =>
    where.match(new RegExp(`--${name}:\\s*([^;]+);`))?.[1].trim();

  // A theme block only overrides what changes; anything else falls
  // through to the complete light set on bare :root.
  let value = read(theme) ?? read(LIGHT);
  assert(value, `token --${name} is not defined`);

  const indirect = value.match(/^var\(--([a-z-]+)\)$/);
  if (indirect) value = token(indirect[1], theme);

  assert(/^#[0-9a-f]{6}$/i.test(value), `--${name} is ${value}, not a 6-digit hex`);
  return value;
}

// ---------------------------------------------------------------------------
// The pairs
// ---------------------------------------------------------------------------

/**
 * Every foreground/background pair the design actually draws.
 *
 * `min` is 4.5 — AA for body text — everywhere except where the token
 * is only ever a large-format or non-text mark, and each of those
 * says why in place. Adding a colour role to theme.css means adding
 * its pair here; a role with no pair is a colour nobody has checked.
 */
const PAIRS: { fg: string; bg: string; min: number; note?: string }[] = [
  { fg: "tx", bg: "surface", min: 4.5 },
  { fg: "tx-dim", bg: "surface", min: 4.5 },
  { fg: "mark", bg: "surface", min: 4.5 },
  { fg: "here", bg: "surface", min: 4.5 },
  { fg: "tx", bg: "panel", min: 4.5 },
  { fg: "tx", bg: "tint", min: 4.5 },
  { fg: "stencil-tx", bg: "stencil-bg", min: 4.5 },
  { fg: "stencil-mark", bg: "stencil-bg", min: 4.5 },
  { fg: "block-tx", bg: "block-bg", min: 4.5 },
  { fg: "data-accent", bg: "surface", min: 4.5 },

  // The page layer: acid as a word. Body text, so full AA.
  { fg: "page-act", bg: "surface", min: 4.5 },
  { fg: "page-cold", bg: "surface", min: 4.5 },
  { fg: "page-heat", bg: "surface", min: 4.5 },
  { fg: "page-live", bg: "surface", min: 4.5 },

  // The shelf layer: acid as a fill, with ink on it. The chip's word
  // is what carries the meaning (information is never colour-only),
  // so it is text and gets the text bar.
  { fg: "shelf-tx", bg: "shelf-act", min: 4.5 },
  { fg: "shelf-tx", bg: "shelf-cold", min: 4.5 },
  { fg: "shelf-tx", bg: "shelf-heat", min: 4.5 },
  { fg: "shelf-tx", bg: "shelf-live", min: 4.5 },

  // Structural rules are lines, not glyphs: AA's non-text bar.
  { fg: "rule", bg: "surface", min: 3 },
  { fg: "rule-soft", bg: "surface", min: 1.5, note: "divides without structuring" },
  { fg: "hairline", bg: "surface", min: 1.2, note: "non-structural separator" },
];

// ---------------------------------------------------------------------------

for (const theme of ["light", "dark"] as const) {
  const block_ = theme === "light" ? LIGHT : DARK;
  for (const { fg, bg, min, note } of PAIRS) {
    Deno.test(`${theme}: --${fg} on --${bg}${note ? ` (${note})` : ""}`, () => {
      const ratio = contrast(token(fg, block_), token(bg, block_));
      assert(
        ratio >= min,
        `${ratio.toFixed(2)}:1 is below ${min}:1 — ` +
          `--${fg} ${token(fg, block_)} on --${bg} ${token(bg, block_)}`,
      );
    });
  }
}

Deno.test("the two dark blocks carry identical values", () => {
  // The three-state contract duplicates the dark set on purpose, so an
  // explicit choice beats the OS in both directions. Duplication that
  // drifts is worse than no duplication at all.
  const values = (b: string) =>
    [...b.matchAll(/--([a-z-]+):\s*([^;]+);/g)]
      .map(([, k, v]) => `${k}: ${v.trim()}`)
      .sort();
  assertEquals(values(DARK_MEDIA), values(DARK));
});

/** The comment on a token's own declaration, if it has one. */
function comment(name: string, theme: string): string | undefined {
  return theme.match(
    new RegExp(`--${name}:\\s*[^;]+;[ \\t]*/\\*([\\s\\S]*?)\\*/`),
  )?.[1];
}

/**
 * What ratio, if any, the stylesheet claims for one pair.
 *
 * Two forms, because a reader wants the number wherever they happen to
 * be looking:
 *
 *   on the foreground  `--page-cold: #05555f; /* 6.90:1 *\/`
 *                      `--tx: #12150e; /* 14.97:1 on --surface *\/`
 *   on the background  `--panel: #dddfd9; /* --tx on it 13.72:1 *\/`
 *
 * A bare ratio on a foreground token means "against --surface", so a
 * token drawn on more than one ground has to name which. That rule is
 * what stopped `--tx`'s one comment being read as a claim about
 * `--panel` and `--tint` as well.
 */
function claimed(fg: string, bg: string, theme: string): number | undefined {
  const onFg = comment(fg, theme);
  if (onFg) {
    const named = onFg.match(new RegExp(`(\\d+\\.\\d+):1 on --${bg}\\b`));
    if (named) return Number(named[1]);
    const bare = onFg.match(/(\d+\.\d+):1(?! on --)/);
    if (bare && bg === "surface") return Number(bare[1]);
  }

  const onBg = comment(bg, theme);
  const fromBg = onBg?.match(new RegExp(`--${fg} on it (\\d+\\.\\d+):1`));
  return fromBg ? Number(fromBg[1]) : undefined;
}

Deno.test("every ratio written in a comment matches the hex beside it", () => {
  const drift: string[] = [];

  for (const [name, block_] of [["light", LIGHT], ["dark", DARK]] as const) {
    for (const { fg, bg } of PAIRS) {
      const says = claimed(fg, bg, block_);
      if (says === undefined) continue;

      const actual = contrast(token(fg, block_), token(bg, block_));
      if (Math.abs(actual - says) > 0.01) {
        drift.push(
          `${name}: --${fg} on --${bg} says ${says}:1, measures ${actual.toFixed(2)}:1`,
        );
      }
    }
  }

  assertEquals(drift, []);
});

Deno.test("the acids all carry a measured ratio, in both themes", () => {
  // The eight acid tokens are the ones most likely to be retuned by
  // eye, so each states its number where the retuning happens.
  const missing: string[] = [];
  for (const [name, block_] of [["light", LIGHT], ["dark", DARK]] as const) {
    for (const t of ["act", "cold", "heat", "live"]) {
      if (claimed(`page-${t}`, "surface", block_) === undefined) {
        missing.push(`${name}: --page-${t}`);
      }
      if (claimed("shelf-tx", `shelf-${t}`, block_) === undefined) {
        missing.push(`${name}: --shelf-${t}`);
      }
    }
  }
  assertEquals(missing, []);
});

Deno.test("no token resolves to a colour keyword or a gradient", () => {
  // Role tokens are flat colour. DS-01 §2.1: depth comes from layering
  // and overlap, never from lighting — a gradient in this file is that
  // rule being broken one declaration at a time.
  const bad = [...css.matchAll(/--[a-z-]+:\s*(linear-gradient|radial-gradient)[^;]*;/g)];
  assertEquals(bad.map((m) => m[0]), []);
});
