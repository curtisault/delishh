/**
 * The install, held to the rest of the product — docs/installable.md.
 *
 * Almost nothing here fails loudly on its own. A manifest whose colour
 * drifted from theme.css still installs; an icon the manifest names
 * but the disk lacks still installs, with a blank tile; a worker that
 * serves /content/* cache-first still passes every page test, and
 * then shows a reader last month's recipe with no way to tell. So the
 * rules that can be read out of the files are read out of them here.
 *
 * What this cannot check is a phone: install, launch, airplane mode,
 * print from the home-screen app. Those are Phase 6 of the plan, by
 * hand.
 */

import { assert, assertEquals } from "@std/assert";
import { ICONS, tokenIn } from "./manifest.ts";
import { RENDERS } from "./build-icons.ts";

const theme = await Deno.readTextFile("src/theme.css");
const index = await Deno.readTextFile("index.html");
const notFound = await Deno.readTextFile("public/404.html");
const headers = await Deno.readTextFile("public/_headers");
const boot = await Deno.readTextFile("src/boot.js");
/** The worker's code, without its commentary — which names `/content/*`
 * and "cache-first" in prose. Only comments that begin a line are
 * stripped: the code holds regex literals that a naive block-comment
 * match would eat half a file of. */
const worker = (await Deno.readTextFile("src/sw.js"))
  .replace(/^\s*\/\*[\s\S]*?\*\//gm, "")
  .replace(/^\s*\/\/.*$/gm, "");
const manifest = JSON.parse(
  await Deno.readTextFile("public/manifest.webmanifest"),
);

/** The dark theme's value of a token, from the explicit dark block —
 * which theme.css's three-state contract makes identical to the
 * prefers-color-scheme block (contrast_test.ts reads both). */
function darkToken(name: string): string {
  const css = theme.replace(/\/\*[\s\S]*?\*\//g, "");
  const block = css.match(/:root\[data-theme='dark'\]\s*\{([^}]*)\}/);
  assert(block, "theme.css has no :root[data-theme='dark'] block");
  const m = block[1].match(new RegExp(`${name}\\s*:\\s*(#[0-9a-f]{6})`, "i"));
  assert(m, `the dark block does not set ${name} to a hex`);
  return m[1].toLowerCase();
}

/** A PNG's pixel size, out of its IHDR chunk. */
async function pngSize(path: string): Promise<[number, number]> {
  const bytes = await Deno.readFile(path);
  const view = new DataView(bytes.buffer);
  assertEquals(
    [...bytes.slice(1, 4)].map((b) => String.fromCharCode(b)).join(""),
    "PNG",
    `${path} is not a PNG`,
  );
  return [view.getUint32(16), view.getUint32(20)];
}

/** The Cache-Control set for an exact path in _headers. */
function cacheRule(path: string): string | undefined {
  const lines = headers.split("\n");
  const at = lines.findIndex((l) => l.trim() === path);
  return at === -1 ? undefined : lines[at + 1]?.trim();
}

// ---- the manifest ----

Deno.test("the manifest opens the whole site, standalone", () => {
  assertEquals(manifest.id, "/");
  assertEquals(manifest.start_url, "/");
  assertEquals(manifest.scope, "/");
  assertEquals(manifest.display, "standalone");
});

Deno.test("the manifest's colours are theme.css's", () => {
  assertEquals(manifest.background_color, tokenIn(theme, "--surface"));
  assertEquals(manifest.theme_color, tokenIn(theme, "--stencil-bg"));
});

Deno.test("every icon the manifest names exists, at the size it claims", async () => {
  assertEquals(manifest.icons, ICONS);
  assert(
    ICONS.some((i) => i.purpose === "maskable"),
    "no maskable icon: Android crops the tile into a white circle",
  );
  for (const icon of ICONS) {
    const path = `public${icon.src}`;
    await Deno.stat(path);
    if (icon.type === "image/png") {
      const [w, h] = await pngSize(path);
      assertEquals(`${w}x${h}`, icon.sizes, `${path} is not ${icon.sizes}`);
    }
  }
});

Deno.test("every rendered PNG is the size its renderer says", async () => {
  for (const [path, px] of Object.entries(RENDERS)) {
    assertEquals(await pngSize(path), [px, px], `${path} is not ${px}px`);
  }
});

Deno.test("the icon's colours are the stencil field and volt", async () => {
  const svg = await Deno.readTextFile("public/icons/icon.svg");
  const hexes = new Set(
    [...svg.matchAll(/#[0-9a-f]{6}\b/gi)].map((m) => m[0].toLowerCase()),
  );
  assertEquals(
    hexes,
    new Set([tokenIn(theme, "--stencil-bg"), tokenIn(theme, "--shelf-act")]),
    "icon.svg carries a colour theme.css does not, or has lost one",
  );
});

// ---- the head ----

Deno.test("index.html links the manifest and the iOS icon", async () => {
  assert(index.includes('<link rel="manifest" href="/manifest.webmanifest"'));
  const apple = index.match(/rel="apple-touch-icon" href="([^"]+)"/);
  assert(apple, "no apple-touch-icon: iOS ignores the manifest's icons");
  await Deno.stat(`public${apple[1]}`);
});

Deno.test("404.html links the manifest", () => {
  assert(notFound.includes('<link rel="manifest" href="/manifest.webmanifest"'));
});

Deno.test("the theme-color metas are --stencil-bg in each lighting", () => {
  const metas = [
    ...index.matchAll(
      /<meta\s+name="theme-color"\s+media="\(prefers-color-scheme: (\w+)\)"\s+content="([^"]+)"/g,
    ),
  ].map((m) => [m[1], m[2].toLowerCase()]);
  assertEquals(metas, [
    ["light", tokenIn(theme, "--stencil-bg")],
    ["dark", darkToken("--stencil-bg")],
  ]);
});

// ---- the cache headers ----

Deno.test("the worker, the manifest and the icons revalidate", () => {
  for (const path of ["/sw.js", "/manifest.webmanifest", "/icons/*"]) {
    const rule = cacheRule(path);
    assert(rule, `_headers has no rule for ${path}`);
    assert(/max-age=0\b/.test(rule), `${path} is cached: ${rule}`);
  }
});

// ---- the worker ----

Deno.test("the worker keeps one cache, named for its build", () => {
  assertEquals(worker.split("'__BUILD__'").length, 2, "BUILD is not stamped exactly once");
  assert(
    /const CACHE = `delishh-archive-\$\{BUILD\}`/.test(worker),
    "the cache name is not delishh-archive-<build>",
  );
  const opened = [...worker.matchAll(/caches\.open\(([^)]*)\)/g)].map((m) => m[1]);
  assert(opened.length > 0, "the worker opens no cache");
  assertEquals(new Set(opened), new Set(["CACHE"]), "the worker opens a second cache");
});

Deno.test("cache-first is exactly the paths _headers calls immutable", () => {
  const listed = worker.match(/const IMMUTABLE = \[([^\]]*)\]/);
  assert(listed, "the worker has no IMMUTABLE list");
  const cacheFirst = [...listed[1].matchAll(/'([^']+)'/g)].map((m) => m[1]);
  const immutable = [...headers.matchAll(/^(\/\S+)\*\n\s+Cache-Control:.*\bimmutable\b/gm)]
    .map((m) => m[1]);
  assertEquals(cacheFirst.sort(), immutable.sort());
});

Deno.test("/content/* is never served cache-first", () => {
  // The inversion that would show a reader last month's recipe as
  // this month's, with nothing on the page to say so.
  const listed = worker.match(/const IMMUTABLE = \[([^\]]*)\]/)![1];
  assert(!listed.includes("/content"), "/content/ is in the cache-first list");
  assert(
    /max-age=0/.test(cacheRule("/content/*") ?? ""),
    "_headers no longer revalidates /content/*",
  );
});

Deno.test("an unreachable, unkept recipe is a 503, which Reach.elm reads", async () => {
  assert(/status:\s*503/.test(worker), "the worker no longer answers 503");
  const reach = await Deno.readTextFile("src/Reach.elm");
  assert(/Http\.BadStatus 503 ->\s*Unkept/.test(reach), "Reach.elm no longer reads the 503");
});

Deno.test("boot.js registers the worker, in production only", () => {
  assert(
    /if \(import\.meta\.env\.PROD && 'serviceWorker' in navigator\)\s*\{\s*navigator\.serviceWorker\.register\('\/sw\.js'\)/
      .test(boot),
    "the registration is missing, or no longer guarded to production",
  );
});
