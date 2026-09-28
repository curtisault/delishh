/**
 * The meal plan's picture, held to the rules the stylesheets keep.
 *
 * The picture is the one place in the product that draws colour and
 * type from JavaScript. That makes `boot.js` a fourth stylesheet that
 * none of the others' tests read, and each rule below is one of theirs
 * restated for it:
 *
 *   - **No raw hex.** Colours are theme.css tokens read at draw time;
 *     a hex here is a second palette `contrast_test.ts` never checks.
 *   - **No family spelled.** Faces are `--font-*` stacks; a family
 *     named here drifts from fonts.css exactly the way `fonts_test.ts`
 *     exists to catch.
 *   - **Every token it reads exists.** A misspelled token resolves to
 *     an empty string and the canvas draws it black — no error, a
 *     picture that looks drawn. (`boot.js` also throws on an empty
 *     token; this catches it before anyone presses anything.)
 *   - **Every text pair it draws is a checked pair.** The picture's
 *     contrast is "whatever the theme's checked pairs give", which is
 *     only true while each pair it uses is in contrast_test.ts.
 *   - **Share and copy stay inside the press.** Safari refuses both
 *     outside a user gesture, so nothing may be awaited before them.
 *   - **No `beforeprint`**, restated from print_test.ts for the file
 *     that now has more reasons to grow.
 */

import { assert, assertEquals } from "@std/assert";

const boot = await Deno.readTextFile("src/boot.js");
const theme = await Deno.readTextFile("src/theme.css");
const contrast = await Deno.readTextFile("scripts/contrast_test.ts");

/** boot.js with its comments gone, so a rule quoted in prose does not
 * count as a rule broken in code. */
const code = boot
  .replace(/\/\*[\s\S]*?\*\//g, "")
  .replace(/(^|[^:'"`])\/\/.*$/gm, "$1");

/** The picture's own code: from its first const to the end of the file. */
const pictureCode = code.slice(code.indexOf("const PICTURE"));

/** Every `token(style, '--name')` the drawing reads. */
const tokensRead = [...pictureCode.matchAll(/token\(style,\s*'(--[\w-]+)'\)/g)]
  .map((m) => m[1]);

Deno.test("the picture's code is found", () => {
  assert(code.includes("const PICTURE"), "boot.js has no PICTURE block");
  assert(tokensRead.length > 0, "the picture reads no tokens");
});

Deno.test("boot.js writes no raw hex", () => {
  assertEquals(code.match(/#[0-9a-fA-F]{3,8}\b/g), null);
});

Deno.test("boot.js spells no font family", () => {
  const named = code.match(
    /['"`][^'"`\n]*\b(Archivo|Inter|JetBrains|Instrument|serif|sans-serif|monospace)\b[^'"`\n]*['"`]/g,
  );
  assertEquals(named, null, "a family is named in boot.js rather than read off a --font-* token");
});

Deno.test("every token the picture reads is declared in theme.css", () => {
  const missing = tokensRead.filter((t) => !new RegExp(`${t}\\s*:`).test(theme));
  assertEquals(missing, []);
});

Deno.test("every text pair the picture draws is a checked pair", () => {
  // The drawing's three pairs: the day and meal on the ground, the
  // ARCHIVE mark on the ground, the wordmark on the stencil band.
  const PAIRS = [
    ["tx", "surface"],
    ["tx-dim", "surface"],
    ["stencil-mark", "stencil-bg"],
  ];
  for (const [fg, bg] of PAIRS) {
    assert(tokensRead.includes(`--${fg}`), `the picture no longer reads --${fg}; update this list`);
    assert(tokensRead.includes(`--${bg}`), `the picture no longer reads --${bg}; update this list`);
    assert(
      contrast.includes(`{ fg: "${fg}", bg: "${bg}"`),
      `--${fg} on --${bg} is drawn by the picture but not checked in contrast_test.ts`,
    );
  }
});

Deno.test("share and copy are called before anything is awaited", () => {
  for (const [fn, call] of [
    ["sharePicture", "navigator.share("],
    ["copyPicture", "navigator.clipboard.write("],
  ]) {
    const start = pictureCode.indexOf(`async function ${fn}`);
    assert(start !== -1, `boot.js has no ${fn}`);
    const body = pictureCode.slice(start, pictureCode.indexOf("\n}\n", start));
    const firstAwait = body.indexOf("await ");
    assert(
      firstAwait === body.indexOf(`await ${call}`),
      `${fn} awaits something before ${call} — Safari will refuse it outside the press`,
    );
  }
});

Deno.test("boot.js has no beforeprint hook", () => {
  assertEquals(/beforeprint/.test(code), false);
});
