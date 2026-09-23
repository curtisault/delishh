/**
 * The tap floor — DS-01 §12, machine-checked.
 *
 * "Tap targets at 2.75rem minimum, scaling with text" was a §08
 * clause for three phases: cook mode, on the reasoning that wet hands
 * at arm's length are the hard case. It was promoted to §12 on
 * 2026-09-24, because the hand is the same hand in a shop with a
 * trolley in it and on a phone propped on a counter, and neither of
 * those is cook mode. The filter chips were 22px.
 *
 * **WHAT THIS FILE CAN AND CANNOT SEE.** It reads the stylesheets, so
 * it checks that every control NAMES the floor — not that the browser
 * ends up honouring it, which depends on the box each one lands in.
 * That is the same bargain `print_test.ts` states in its own header:
 * a static read catches the failure that actually happens, which is
 * someone adding a control and not thinking about a thumb at all.
 *
 * The rendered sizes were measured in a browser at 1280, 760 and
 * 360 px on the day the floor went in, and every control cleared it.
 * Re-measuring after a layout change is a human's job.
 */

import { assert, assertEquals } from "@std/assert";

const SHEETS = ["theme", "sheet", "shelf", "recipe", "cook", "list", "print"];

const sources = new Map<string, string>();
for (const name of SHEETS) {
  sources.set(name, await Deno.readTextFile(`src/${name}.css`));
}

const stripped = (name: string) =>
  sources.get(name)!.replace(/\/\*[\s\S]*?\*\//g, "");

/** Every rule body in a sheet, keyed by its selector list. */
function rules(css: string): Array<[string, string]> {
  const out: Array<[string, string]> = [];
  for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
    out.push([m[1].trim().replace(/\s+/g, " "), m[2]]);
  }
  return out;
}

// ---------------------------------------------------------------------------

Deno.test("the floor is one token, and it is a rem", () => {
  // A px floor stops scaling the moment a reader raises their default
  // font, which is the reader most likely to need it (§12).
  const m = stripped("theme").match(/--tap:\s*([^;]+);/);
  assert(m, "theme.css declares no --tap");
  assertEquals(m![1].trim(), "2.75rem");
});

Deno.test("nothing names the floor as a literal", () => {
  // One token, so raising the floor is one edit and cannot half-apply.
  const offenders: string[] = [];
  for (const name of SHEETS) {
    for (const [sel, body] of rules(stripped(name))) {
      if (/min-(height|width):\s*2\.75rem/.test(body)) {
        offenders.push(`${name}.css — ${sel} hard-codes 2.75rem`);
      }
    }
  }
  assertEquals(offenders, []);
});

Deno.test("every control names the floor, one way or the other", () => {
  // Two ways to honour it (theme.css): a control with room GROWS, and
  // one in the fixed-height site bar or inline in a sentence keeps its
  // box and lays a transparent `::after` over it at the floor.
  //
  // The list is written out rather than derived from `cursor: pointer`
  // on purpose: a control that stops being in this list should fail
  // here, not quietly drop off a scan.
  const GROWS = [
    ["sheet", ".press-block"], //  the nine dressed controls, at once
    ["sheet", ".doc-search-input"],
    ["shelf", ".shelf-query"],
    ["recipe", ".scaler-btn"],
    ["print", ".printer-btn"],
    ["list", ".list-tick"],
    ["cook", ".cook-stamp"],
    ["cook", ".cook-timer-btn"],
    ["cook", ".cook-nav-step"],
    ["cook", ".cook-nav-link"],
    ["sheet", ".doc-toc-link"],
    ["recipe", ".recipe-nav-link"],
  ];
  const OVERLAYS = [
    ["sheet", ".nav-toggle"],
    ["sheet", ".site-nav a"],
    ["sheet", ".theme-btn"],
    ["list", ".list-source-link"],
    ["list", ".list-drop"],
    ["list", ".list-clear"],
  ];

  const missing: string[] = [];

  for (const [sheet, sel] of GROWS) {
    const hit = rules(stripped(sheet)).find(([s]) =>
      s.split(",").map((x) => x.trim()).includes(sel)
    );
    if (!hit) missing.push(`${sheet}.css has no rule for ${sel}`);
    else if (!/min-height:\s*var\(--tap\)/.test(hit[1])) {
      missing.push(`${sheet}.css — ${sel} does not grow to the floor`);
    }
  }

  for (const [sheet, sel] of OVERLAYS) {
    const css = stripped(sheet);
    const overlay = rules(css).find(([s]) =>
      s.split(",").map((x) => x.trim()).includes(`${sel}::after`)
    );
    if (!overlay) missing.push(`${sheet}.css — ${sel} has no tap overlay`);
    else if (!/height:\s*var\(--tap\)/.test(overlay[1])) {
      missing.push(`${sheet}.css — ${sel}'s overlay is not the floor`);
    } // and it has to carry the WIDTH too: LIST is 34px of word, and a
    // height-only overlay leaves it a tall sliver to aim at.
    else if (!/left:\s*min\(0px, calc\(\(100% - var\(--tap\)\) \/ 2\)\)/.test(overlay[1])) {
      missing.push(`${sheet}.css — ${sel}'s overlay carries no width floor`);
    }
  }

  assertEquals(missing, []);
});

Deno.test("a tap overlay never becomes a visible box", () => {
  // The overlay exists to be hit, not to be seen: it is laid over an
  // item inside a bar whose height is load-bearing, so a fill or a
  // border on it would be a 2.75rem block bursting a 2.4rem bar.
  const offenders: string[] = [];
  for (const name of SHEETS) {
    for (const [sel, body] of rules(stripped(name))) {
      if (!/::after/.test(sel) || !/height:\s*var\(--tap\)/.test(body)) continue;
      if (/background(-color)?:\s*(?!none)/.test(body) || /border:\s*(?!0)/.test(body)) {
        offenders.push(`${name}.css — ${sel} paints something`);
      }
    }
  }
  assertEquals(offenders, []);
});

Deno.test("the dress carries the floor on both axes", () => {
  // `.press-block` is worn by nine controls across four surfaces, and
  // the smallest of them is a filter chip whose word is two syllables.
  // A height-only floor leaves that chip 22px tall and 115px wide's
  // worth of nothing to aim at vertically.
  const hit = rules(stripped("sheet")).find(([s]) => s === ".press-block");
  assert(hit, "sheet.css has no .press-block rule");
  assert(/min-height:\s*var\(--tap\)/.test(hit![1]), "the dress has no height floor");
  assert(/min-width:\s*var\(--tap\)/.test(hit![1]), "the dress has no width floor");
});
