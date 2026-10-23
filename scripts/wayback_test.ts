/**
 * The way back — `src/wayback.js`, over a history the test drives.
 *
 * The rule a reader sees: BACK lands on the last *page* they were on,
 * never on an earlier section of the recipe they are reading, and
 * never outside the archive. Each case below is a walk through the
 * app, ending with the steps BACK would take (0: follow the link's own
 * address instead).
 */

import { assertEquals } from "@std/assert";
import { behindOnPush, keepTheWayBack, stepsBehind } from "../src/wayback.js";

/** A session history: entries, a cursor, and Elm's empty states. */
function session(landing: string) {
  const base = "https://delishh.test";
  const entries: Array<{ url: string; state: unknown }> = [
    { url: landing, state: null },
  ];
  let at = 0;
  const location = {
    get href() {
      return new URL(entries[at].url, base).href;
    },
  };
  const history = {
    get state() {
      return entries[at].state;
    },
    pushState(state: unknown, _t: string, url: string) {
      entries.splice(at + 1);
      entries.push({ url, state });
      at += 1;
    },
    replaceState(state: unknown, _t: string, url: string) {
      entries[at] = { url, state };
    },
    go(n: number) {
      at += n;
    },
  };
  keepTheWayBack(history, location);
  return {
    // what Elm's Nav.pushUrl does
    push: (url: string) => history.pushState({}, "", url),
    replace: (url: string) => history.replaceState({}, "", url),
    go: (n: number) => history.go(n),
    back: () => stepsBehind(history.state),
    where: () => entries[at].url,
  };
}

Deno.test("from the shelf, back is the shelf", () => {
  const s = session("/");
  s.push("/recipe/classic-lasagna");
  assertEquals(s.back(), 1);
});

Deno.test("reading down the side nav does not lengthen the way back", () => {
  const s = session("/");
  s.push("/recipe/classic-lasagna");
  s.push("/recipe/classic-lasagna#steps");
  s.push("/recipe/classic-lasagna#keeps");
  assertEquals(s.back(), 3);
  s.go(-s.back());
  assertEquals(s.where(), "/");
});

Deno.test("a recipe opened from a message has nothing behind it", () => {
  const s = session("/recipe/classic-lasagna");
  assertEquals(s.back(), 0);
  s.push("/recipe/classic-lasagna#steps");
  assertEquals(s.back(), 0);
});

Deno.test("out of cook mode is back to the recipe, and on from there to the shelf", () => {
  const s = session("/");
  s.push("/recipe/classic-lasagna");
  s.push("/recipe/classic-lasagna/cook?scale=1.5");
  assertEquals(s.back(), 1);
  s.go(-s.back());
  assertEquals(s.where(), "/recipe/classic-lasagna");
  assertEquals(s.back(), 1);
  s.go(-s.back());
  assertEquals(s.where(), "/");
});

Deno.test("the count belongs to the entry, whichever way the reader came", () => {
  // Landed on one recipe, went home, opened another; then the
  // browser's own back twice. The first recipe still has nothing of
  // ours behind it, though the page shown before it was the shelf.
  const s = session("/recipe/cottage-pie");
  s.push("/");
  s.push("/recipe/classic-lasagna");
  s.go(-2);
  assertEquals(s.where(), "/recipe/cottage-pie");
  assertEquals(s.back(), 0);
  s.go(2);
  assertEquals(s.back(), 1);
});

Deno.test("a replaced address keeps its entry's count", () => {
  const s = session("/");
  s.push("/recipe/classic-lasagna");
  s.replace("/recipe/classic-lasagna?form=card");
  assertEquals(s.back(), 1);
});

Deno.test("the rule, as a table", () => {
  assertEquals(behindOnPush(null, "/", "/recipe/a"), 1);
  assertEquals(behindOnPush(null, "/recipe/a", "/recipe/a"), 0);
  assertEquals(behindOnPush({ behind: 2 }, "/recipe/a", "/recipe/a"), 3);
  assertEquals(behindOnPush({ behind: 2 }, "/recipe/a", "/plan"), 1);
  // a state some other code wrote is not a count
  assertEquals(stepsBehind({}), 0);
  assertEquals(stepsBehind({ behind: "2" }), 0);
  assertEquals(stepsBehind({ behind: -1 }), 0);
});
