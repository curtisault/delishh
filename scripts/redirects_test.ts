/**
 * The client routes, held to what Cloudflare Pages actually does with
 * `public/_redirects`.
 *
 * Nothing here fails on its own. Pages uploads the file, says nothing,
 * and serves the site; the fault shows only when a reader opens a
 * link that is not `/`. Two rules it enforces that the file cannot:
 *
 * - every `/index.html` address is canonicalised to `/` with a 308,
 *   and a rewrite whose target is `/index.html` inherits that bounce;
 * - a splat rule whose target ends in `/index.html` is rejected by the
 *   parser as an infinite loop and dropped — the deploy log says so,
 *   the CI log never shows it, and the route serves the 404.
 *
 * Both held in production from the first deploy to 2026-10-04. So the
 * target of a rewrite is `/`, and every named route in Route.elm has a
 * line. A wildcard at the root is refused here as well as in CI.
 */

import { assert, assertEquals } from "@std/assert";

const redirects = await Deno.readTextFile("public/_redirects");
const route = await Deno.readTextFile("src/Route.elm");

interface Rule {
  from: string;
  to: string;
  status: string;
  line: number;
}

const rules: Rule[] = redirects
  .split("\n")
  .map((text, i) => ({ text: text.trim(), line: i + 1 }))
  .filter(({ text }) => text !== "" && !text.startsWith("#"))
  .map(({ text, line }) => {
    const [from, to, status = "302"] = text.split(/\s+/);
    return { from, to, status, line };
  });

/** The literal paths `Route.toPath` returns — the named routes. A
 * concatenation (`"/recipe/" ++ slug`) is a route that cannot be
 * named and is covered by the scoped wildcard instead. */
const named = [...route.matchAll(/^\s+"(\/[a-z-]*)"\s*$/gm)]
  .map((m) => m[1])
  .filter((p) => p !== "/");

Deno.test("the file parses into rules", () => {
  assert(rules.length > 0);
  for (const r of rules) {
    assert(r.from.startsWith("/"), `line ${r.line}: source is not a path`);
    assert(r.to !== undefined, `line ${r.line}: no target`);
  }
});

Deno.test("every rewrite targets `/`, never `/index.html`", () => {
  for (const r of rules) {
    assertEquals(r.status, "200", `line ${r.line}: ${r.from} is not a rewrite`);
    assertEquals(
      r.to,
      "/",
      `line ${r.line}: ${r.from} rewrites to ${r.to} — Pages 308s ` +
        `/index.html to / and drops a splat to it as a loop`,
    );
  }
});

Deno.test("no wildcard at the root", () => {
  for (const r of rules) {
    assert(
      r.from !== "/*" && r.from !== "/",
      `line ${r.line}: ${r.from} reinstates the SPA fallback`,
    );
  }
});

Deno.test("every named route in Route.elm has a line", () => {
  assert(named.length > 0, "found no literal paths in Route.toPath");
  const from = new Set(rules.map((r) => r.from));
  for (const p of named) {
    assert(from.has(p), `${p} is in Route.elm and not in _redirects`);
  }
});

Deno.test("the recipe wildcard is scoped and the only one", () => {
  const splats = rules.filter((r) => r.from.includes("*"));
  assertEquals(splats.map((r) => r.from), ["/recipe/*"]);
  assert(route.includes('"/recipe/" ++ slug'));
});
