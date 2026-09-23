/**
 * The issued sheet's ink discipline — DS-01 §09, machine-checked.
 *
 * **Print is the one surface nobody looks at.** A colour that leaks
 * into the print path costs toner on every page and nobody notices
 * for months, because you have to actually print something to see it.
 * The type floors are the same: 9pt body renders fine on a screen
 * preview and is unreadable on a counter at arm's length.
 *
 * So the rules that can be read out of the stylesheet are read out of
 * it here:
 *
 *  - every colour inside `@media print` is greyscale
 *  - body is 11pt or larger, step numbers 14pt or larger
 *  - the break law is declared
 *  - screen controls are hidden
 *  - `@page` margins are in physical units
 *
 * What this canNOT check is page COUNT. "A card is one page" and "a
 * booklet is at most four" are contracts against real paginated
 * output, and no static read of the CSS establishes them. They need a
 * human with a print preview — noted in the plan, not pretended at
 * here.
 */

import { assert, assertEquals } from "@std/assert";

const source = await Deno.readTextFile("src/print.css");

/** The stylesheet with comments stripped.
 *
 * Not cosmetic: this file's own header explains the print path in
 * prose, and the words `@media print` appear in it. Brace-matching
 * over the raw text finds that mention first and returns the wrong
 * block — which is exactly what happened the first time these tests
 * ran, and why they now read the CSS rather than the commentary. */
const css = source.replace(/\/\*[\s\S]*?\*\//g, "");

/** The body of an at-rule or selector, by brace matching — regex
 * cannot balance braces and `@media print` is full of nested rules. */
function blockAfter(source: string, opener: string): string {
  const at = source.indexOf(opener);
  assert(at !== -1, `no \`${opener}\` in print.css`);
  const start = source.indexOf("{", at);
  let depth = 0;
  for (let i = start; i < source.length; i++) {
    if (source[i] === "{") depth++;
    if (source[i] === "}") {
      depth--;
      if (depth === 0) return source.slice(start + 1, i);
    }
  }
  throw new Error(`unbalanced braces after ${opener}`);
}

const PRINT = blockAfter(css, "@media print");

/** A declaration's value, for one selector inside the print block. */
function declaration(selector: string, property: string): string | undefined {
  const rule = blockAfter(PRINT, selector);
  return rule.match(new RegExp(`(?:^|[;{\\s])${property}:\\s*([^;]+)`))?.[1].trim();
}

function points(value: string | undefined): number | undefined {
  const m = value?.match(/([\d.]+)pt/);
  return m ? Number(m[1]) : undefined;
}

// ---------------------------------------------------------------------------

Deno.test("every colour in the print path is greyscale", () => {
  // Acid does not survive a monochrome laser and wastes colour toner
  // on a page that will be thrown away (DS-01 §09). This catches an
  // acid token that was overridden on screen but not here, and a hex
  // typed straight into a print rule.
  const coloured: string[] = [];

  for (const [, hex] of PRINT.matchAll(/#([0-9a-fA-F]{3,6})\b/g)) {
    const full = hex.length === 3
      ? hex.split("").map((c) => c + c).join("")
      : hex;
    const [r, g, b] = [0, 2, 4].map((i) => parseInt(full.slice(i, i + 2), 16));
    if (!(r === g && g === b)) coloured.push(`#${hex}`);
  }

  for (const [whole] of PRINT.matchAll(/rgba?\([^)]*\)/g)) {
    const [r, g, b] = whole.match(/[\d.]+/g)?.map(Number) ?? [];
    if (!(r === g && g === b)) coloured.push(whole);
  }

  assertEquals(coloured, []);
});

Deno.test("every acid token is overridden to ink for print", () => {
  // The mechanism: `--acid` and the four `--page-*` are redefined at
  // :root inside @media print, which turns every rule, mark and step
  // number black without touching a single component rule. Miss one
  // and exactly one element prints in colour.
  const root = blockAfter(PRINT, ":root,");
  for (const token of ["acid", "page-heat", "page-cold", "page-live", "page-act", "accent"]) {
    const value = root.match(new RegExp(`--${token}:\\s*([^;]+)`))?.[1].trim();
    assert(value, `--${token} is not overridden for print`);
    const hex = value.replace(/\s*!important$/, "");
    assert(/^#([0-9a-f])\1\1(\1\1\1)?$/i.test(hex), `--${token} prints as ${hex}`);
  }
});

Deno.test("the print palette outranks the dark theme", () => {
  // THE BUG THIS EXISTS FOR, found by screenshot and not by reading:
  // a media query contributes no specificity, so the print block
  // competes with theme.css on selector weight alone and loses —
  // `:root:not([data-theme='light'])` is (0,2,0) against a bare
  // `:root`'s (0,1,0). A reader with dark mode on printed a near-black
  // page. `!important` is the only fix that does not depend on which
  // stylesheet the bundler happens to put last.
  const root = blockAfter(PRINT, ":root,");
  const weak = [...root.matchAll(/(--[a-z-]+):\s*([^;]+);/g)]
    .filter(([, , value]) => !value.includes("!important"))
    .map(([, token]) => token);
  assertEquals(weak, [], "these print tokens lose to the dark theme");

  const body = blockAfter(PRINT, "body");
  for (const property of ["background", "color"]) {
    const value = body.match(new RegExp(`${property}:\\s*([^;]+)`))?.[1] ?? "";
    assert(
      value.includes("!important"),
      `print body ${property} is \`${value}\` — the dark theme outranks it`,
    );
  }
});

Deno.test("body is at least 11pt and step numbers at least 14pt", () => {
  // Larger than the screen, because the sheet sits on a counter and
  // you are standing over it (DS-01 §09).
  const body = points(declaration("body", "font-size"));
  assert(body !== undefined, "print body has no pt font-size");
  assert(body >= 11, `print body is ${body}pt, below the 11pt floor`);

  const step = points(declaration(".step-n", "font-size"));
  assert(step !== undefined, "step numbers have no pt font-size");
  assert(step >= 14, `step numbers are ${step}pt, below the 14pt floor`);
});

Deno.test("no form drops body type below the 11pt floor", () => {
  // The card is the dense one and therefore the one that will be
  // tempted downward. 10pt chrome is fine; 10pt PROCEDURE is not.
  const readable = [".form-card .step-text", ".form-card .ing"];
  for (const selector of readable) {
    const size = points(declaration(selector, "font-size"));
    if (size === undefined) continue;
    assert(size >= 9.5, `${selector} is ${size}pt — too small to cook from`);
  }
});

Deno.test("the break law is declared", () => {
  // Never inside a step, never inside an ingredient row, never orphan
  // the rescues, never a heading separated from what it heads.
  for (const selector of [".ing,", ".recipe-h"]) {
    const rule = blockAfter(PRINT, selector);
    assert(
      /break-(inside|after):\s*avoid/.test(rule),
      `${selector} declares no break rule`,
    );
  }
  assert(PRINT.includes("page-break-inside: avoid"), "no legacy page-break fallback");
});

Deno.test("screen controls do not print", () => {
  // The nav, the scaler and the print picker are all things you press,
  // and paper has nothing to press.
  const hidden = blockAfter(PRINT, ".site-nav,");
  assert(/display:\s*none/.test(hidden), "screen controls are not hidden in print");
  // The band itself goes too, not only its children: an emptied flex
  // row still contributes its gap to the page.
  for (
    const control of [
      ".recipe-controls",
      ".scaler",
      ".printer",
      ".recipe-back",
      ".recipe-nav",
      ".cook-enter",
    ]
  ) {
    assert(
      PRINT.includes(control),
      `${control} is not in the print-hidden list`,
    );
  }
});

Deno.test("all three forms are styled, and prep rides alongside", () => {
  for (const form of ["form-card", "form-booklet", "form-sheet"]) {
    assert(css.includes(form), `${form} is never styled in print.css`);
  }
  assert(
    /\.with-prep\s+\.prep-card[\s\S]*?break-before:\s*page/.test(PRINT),
    "the prep card does not start its own page",
  );
});

Deno.test("the bench layout does not reach paper", () => {
  // The two-column screen layout is collapsed EXPLICITLY rather than
  // left to fall under the screen tier's min-width. A4 portrait is
  // ~49.6rem and so already below both tiers, but "the paper happened
  // to be narrow enough" is not a rule — landscape and legal must not
  // print a rail either.
  const cols = blockAfter(PRINT, ".recipe-cols");
  assert(/display:\s*block/.test(cols), ".recipe-cols still lays out as a grid on paper");

  const inner = blockAfter(PRINT, ".recipe-side-inner");
  assert(/position:\s*static/.test(inner), "the rail is still sticky on paper");
});

Deno.test("the traceability line prints on every page", () => {
  // A sheet found in a drawer in three years should be able to tell
  // you what it is and how out of date it is (DS-01 §09).
  const footer = blockAfter(PRINT, ".print-footer");
  assert(/position:\s*fixed/.test(footer), "the footer is not fixed to the page box");
  assert(/display:\s*flex/.test(footer), "the footer is hidden in print");
});

Deno.test("@page margins are physical units", () => {
  // Sized for the sheet to be handled at the edge and held by a clip.
  // `rem` here would scale the margin with the reader's font setting,
  // which is not a thing paper does.
  const page = blockAfter(css, "@page");
  const margin = page.match(/margin:\s*([^;]+)/)?.[1];
  assert(margin, "@page sets no margin");
  assert(
    margin.split(/\s+/).every((v) => /^[\d.]+(mm|cm|in|pt)$/.test(v)),
    `@page margin is \`${margin}\` — not physical units`,
  );
});

// --- the page, not the printout (§09, amended 2026-09-21) ------------------

Deno.test("ingredients set as a grid, never as flowed columns", () => {
  // `columns: 2` balances by HEIGHT, so one wrapped ingredient name
  // drifts the two stacks apart and the hairline under each row stops
  // at the gutter. The bug reads as a broken table because it is a
  // list impersonating one.
  const list = blockAfter(PRINT, ".ing-list");
  assert(
    !/(^|[;{\s])columns:/.test(list),
    ".ing-list flows its columns again — rows will not share a baseline",
  );
  assert(
    /grid-template-columns:\s*1fr\s+1fr/.test(list),
    ".ing-list is not a two-track grid on paper",
  );
  // The card's denser version must be the SAME grid, not a third
  // layout — otherwise there are two ingredient renderers to reason
  // about and only one of them is ever looked at.
  const cardList = blockAfter(PRINT, ".form-card .ing-list");
  assert(
    !/(^|[;{\s])columns:/.test(cardList),
    "the card form still flows its ingredient columns",
  );
  assert(
    /grid-template-columns:\s*repeat\(3/.test(cardList),
    "the card's ingredient grid is not three tracks",
  );
});

Deno.test("the cue rides the step's number line", () => {
  // On paper the clock and the tell sit beside the step number, where
  // a standing reader scans for their place. The wrapper dissolves so
  // both become grid items of the step itself.
  const body = blockAfter(PRINT, ".step-body");
  assert(
    /display:\s*contents/.test(body),
    ".step-body still boxes the cue below the text on paper",
  );
  assertEquals(declaration(".step-cue", "grid-row"), "1", "the cue is not on row 1");
  assertEquals(declaration(".step-cue", "grid-column"), "2", "the cue is not beside the number");
  assertEquals(declaration(".step-n", "grid-row"), "1", "the number is not on row 1");
  // The text names its column but NOT its row, so it lands under a
  // cue when there is one and on the number's own line when there is
  // not — no empty first line either way.
  assertEquals(declaration(".step-text", "grid-column"), "2");
  assertEquals(
    declaration(".step-text", "grid-row"),
    undefined,
    "pinning the text's row leaves a blank line on a step with no cue",
  );
});

Deno.test("the sheet folds at the bench seam, and only the sheet", () => {
  // Procedure on the front, recovery on the back. The break is before
  // WATCHPOINTS: a watchpoint is read before trouble, so it belongs
  // with the reference half rather than at the end of the procedure.
  assert(
    /\.form-sheet\s+#watchpoints[\s\S]*?break-before:\s*page/.test(PRINT),
    "the sheet does not break before Watchpoints — it is a printout, not a leaf",
  );
  // A card is one page by contract, and the booklet already starts
  // its steps on a fresh page. Both opt out explicitly.
  for (const form of [".form-card", ".form-booklet"]) {
    assertEquals(
      declaration(`${form} #watchpoints`, "break-before"),
      "auto",
      `${form} inherits the sheet's duplex break`,
    );
  }
});

Deno.test("facet chips do not print", () => {
  // Facets exist so you can FIND a recipe (§07). A sheet in your hand
  // has been found, and the ink goes to the gauge strip instead.
  const chips = blockAfter(PRINT, ".recipe-chips");
  assert(
    /display:\s*none/.test(chips),
    "the facet chips still cost ink on paper",
  );
});

Deno.test("the gauge strip prints, ruled and unbroken", () => {
  const strip = blockAfter(PRINT, ".recipe-gauges");
  assert(/border-top:/.test(strip) && /border-bottom:/.test(strip), "the strip is not ruled");
  assert(
    /break-inside:\s*avoid/.test(strip),
    "the gauge strip may split across a page — the one band that must not",
  );
  // It may set larger than the body: it is read from a metre away.
  const value = points(declaration(".recipe-gauge-v", "font-size"));
  assert(value !== undefined && value >= 11, `gauge values at ${value}pt — under the body floor`);
});

Deno.test("a recipe block states its own margin, both sides", () => {
  // `sheet.css` carries a bare `section { margin-top: 2.6rem }` for
  // the prose documents, and a recipe block is a <section> too. This
  // class beats that element selector — but only for properties it
  // actually names. Setting margin-bottom alone left ≈31pt of
  // inherited air above every block on the sheet.
  const block = blockAfter(PRINT, ".recipe-block");
  const margin = block.match(/(?:^|[;{\s])margin:\s*([^;]+)/)?.[1]?.trim();
  assert(
    margin,
    ".recipe-block sets margin-bottom only — sheet.css's `section` rule governs the top",
  );
  assert(
    margin.split(/\s+/).length >= 2,
    `.recipe-block margin is \`${margin}\` — the top is still inherited`,
  );
});

Deno.test("no rule styles a block the schema no longer has", () => {
  // `#history` outlived the block by one revision (retired
  // 2026-09-21). A selector for something that cannot render is dead
  // weight that reads as intent.
  for (const dead of ["#history", "#revision", ".recipe-number"]) {
    assert(!css.includes(dead), `print.css still styles \`${dead}\`, which nothing emits`);
  }
});

Deno.test("the print path carries no JavaScript hook", () => {
  // DS-01 §12: printing is pure CSS. No `window.print` wiring, no
  // beforeprint listener, no second renderer.
  const boot = Deno.readTextFileSync("src/boot.js")
    .replace(/\/\/[^\n]*/g, "");
  for (const hook of ["beforeprint", "afterprint", "window.print", "matchMedia('print"]) {
    assert(!boot.includes(hook), `boot.js wires ${hook} — print must stay pure CSS`);
  }
});

Deno.test("the liner never prints, and the leaf is the paper", () => {
  // The backing paper (DS-01 §04, 2026-09-23) is a screen ground. A
  // fixed element prints on EVERY page — the debugger badge taught
  // that on 2026-09-21 — so the liner is gone rather than dimmed, and
  // the leaf's kiss-cut edge, fill and seat go with it: a border
  // round a printed recipe would be a frame round a frame.
  assert(/display:\s*none/.test(blockAfter(PRINT, ".liner")), "the liner is not hidden in print");
  const leaf = blockAfter(PRINT, ".leaf");
  for (const [property, value] of [
    ["border", "0"],
    ["background", "none"],
    ["box-shadow", "none"],
    ["padding", "0"],
  ]) {
    assert(
      new RegExp(`${property}:\\s*${value}\\b`).test(leaf),
      `the leaf's ${property} reaches paper`,
    );
  }
});
