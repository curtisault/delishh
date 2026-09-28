/**
 * The motion register — DS-01 §10, machine-checked.
 *
 * **§10 opens the register at zero and keeps it there.** Nothing
 * loops, drifts, breathes or pulses; what a surface is permitted is
 * *acknowledgement* of a hand, and only on the shelf.
 *
 * The rule these tests exist for is the subtle one:
 *
 *   New motion is authored INSIDE `@media (prefers-reduced-motion:
 *   no-preference)`, so reduced-motion readers never have motion
 *   DEFINED — rather than having it defined and then overridden.
 *
 * The difference is invisible until someone adds a property to a
 * transition list and forgets the override, at which point a reader
 * who asked for stillness gets exactly one thing moving. Authoring
 * inside the query makes that failure impossible instead of unlikely.
 *
 * The one sanctioned exception is the step timer, and it is not a
 * transition at all — the number changes because the number IS the
 * information (§10).
 */

import { assert, assertEquals } from "@std/assert";

const SHEETS = ["theme", "sheet", "shelf", "recipe", "cook", "list", "plan", "print"];

const sources = new Map<string, string>();
for (const name of SHEETS) {
  sources.set(
    name,
    (await Deno.readTextFile(`src/${name}.css`)).replace(/\/\*[\s\S]*?\*\//g, ""),
  );
}

/** Ranges of a stylesheet that sit inside a reduced-motion guard. */
function guardedRanges(css: string): Array<[number, number]> {
  const ranges: Array<[number, number]> = [];
  const guard = /@media\s*\(prefers-reduced-motion:\s*no-preference\)\s*\{/g;
  let m: RegExpExecArray | null;
  while ((m = guard.exec(css)) !== null) {
    let depth = 0;
    for (let i = m.index + m[0].length - 1; i < css.length; i++) {
      if (css[i] === "{") depth++;
      else if (css[i] === "}") {
        depth--;
        if (depth === 0) {
          ranges.push([m.index, i]);
          break;
        }
      }
    }
  }
  return ranges;
}

// ---------------------------------------------------------------------------

Deno.test("nothing in the product animates on its own, but the paper", () => {
  // No keyframes anywhere — with one entry in the register since
  // 2026-09-23: the backing paper drifts (§10). An animation
  // that runs without being asked for is ambient motion by definition,
  // so the exception is held to exactly one block, by name, in the
  // chrome sheet, and the test below holds that block's shape.
  const offenders: string[] = [];
  for (const [name, css] of sources) {
    if (name === "sheet") continue;
    if (/@keyframes/.test(css)) offenders.push(`${name}.css declares @keyframes`);
    if (/\banimation(-name)?\s*:/.test(css)) offenders.push(`${name}.css sets an animation`);
  }
  assertEquals(offenders, []);
});

Deno.test("the paper drifts slowly, on the liner only, inside the guard", () => {
  // The one sanctioned ambient motion (§10, amended 2026-09-23). What
  // keeps it one: a single keyframes block, applied on the liner's
  // rows and nowhere else (so it reaches exactly the routes `Liner.on`
  // names, and never cook mode), authored inside the reduced-motion
  // guard so a reader who asked for stillness never has it defined,
  // and no faster than 45 s a cycle — the floor that stops a drift
  // becoming a marquee.
  const css = sources.get("sheet")!;
  const ranges = guardedRanges(css);
  const inside = (i: number) => ranges.some(([from, to]) => i > from && i < to);

  const keyframes = [...css.matchAll(/@keyframes\s+([\w-]+)/g)];
  assertEquals(keyframes.map((m) => m[1]), ["liner-drift"], "sheet.css declares keyframes other than the drift");
  assert(inside(keyframes[0].index!), "the drift's keyframes sit outside the reduced-motion guard");

  const animations = [...css.matchAll(/([^{}]+)\{[^{}]*\banimation(?:-name)?\s*:\s*([^;]+);/g)];
  assertEquals(animations.length, 1, "sheet.css sets more than one animation");
  const [m] = animations;
  assertEquals(m[1].trim(), ".liner .liner-rows", "the drift is applied to something other than the liner's rows");
  assert(inside(m.index!), "the drift is applied outside the reduced-motion guard");
  const period = m[2].match(/(\d+(?:\.\d+)?)s\b/);
  assert(period, "the drift declares no period");
  assert(Number(period[1]) >= 45, `the paper drifts every ${period[1]}s; the floor is 45`);
  assert(/\binfinite\b/.test(m[2]) && /\blinear\b/.test(m[2]), "the drift is a linear loop, or it is a different thing");
});

Deno.test("every transition is authored inside a reduced-motion guard", () => {
  const unguarded: string[] = [];

  for (const [name, css] of sources) {
    const ranges = guardedRanges(css);
    for (const m of css.matchAll(/\btransition(-[a-z]+)?\s*:/g)) {
      const inside = ranges.some(([from, to]) => m.index! > from && m.index! < to);
      if (!inside) {
        const line = css.slice(0, m.index).split("\n").length;
        unguarded.push(`${name}.css:${line} — transition outside the guard`);
      }
    }
  }

  assertEquals(unguarded, []);
});

Deno.test("the quiet surfaces stay quiet", () => {
  // §10: "Recipe pages hold still." Cook mode is the stillest surface
  // in the product — a step that animates as you mark it done is a
  // thing to wait for, with your hands full.
  for (const name of ["recipe", "cook"]) {
    const css = sources.get(name)!;
    assert(
      !/\btransition\s*:/.test(css),
      `${name}.css has a transition; the quiet layer does not move`,
    );
  }
});

Deno.test("the shelf's motion is short and stepped", () => {
  // Under 200 ms, stepped or snappy easing, no spring that overshoots
  // more than it travels — machinery with good detents, not jelly.
  const css = sources.get("shelf")!;
  const durations = [...css.matchAll(/(\d+)ms/g)].map((m) => Number(m[1]));
  assert(durations.length > 0, "the shelf declares no durations at all");

  const tooSlow = durations.filter((d) => d > 200);
  assertEquals(tooSlow, [], "shelf motion over 200ms");

  assert(
    !/cubic-bezier\([^)]*-[\d.]/.test(css),
    "a negative bezier control point is an overshoot — no springs (§10)",
  );
});

Deno.test("focus is never inside a motion guard", () => {
  // Focus is not decoration and not motion: it is how a keyboard says
  // where it is. A reader who asked for reduced motion needs it just
  // as much, so it must be defined unconditionally.
  const missing: string[] = [];

  for (const [name, css] of sources) {
    const ranges = guardedRanges(css);
    for (const m of css.matchAll(/:focus-visible[^{]*\{([^}]*)\}/g)) {
      if (!/outline\s*:/.test(m[1])) continue;
      const inside = ranges.some(([from, to]) => m.index! > from && m.index! < to);
      if (inside) missing.push(`${name}.css hides a focus outline behind a motion query`);
    }
  }

  assertEquals(missing, []);
});

Deno.test("every interactive surface declares a focus outline", () => {
  // No hover-only information, anywhere (§08) — which also means no
  // hover-only *affordance*. Every surface that answers a pointer has
  // to answer a keyboard.
  for (const name of ["shelf", "recipe", "cook"]) {
    const css = sources.get(name)!;
    assert(
      /:focus-visible/.test(css),
      `${name}.css styles no focus state`,
    );
  }
});

Deno.test("the leaf seats in under 150ms, inside the guard, in the chrome sheet only", () => {
  // The landing (§10, amended 2026-09-23): a new page is a new sheet
  // laid on the liner, and it arrives held a few pixels off the paper
  // then seats flush. It is a box-shadow and not a transform, because
  // `Main.jumpTo` measures the anchor in the frame the page renders
  // and a translated leaf would put every deep link a few pixels low.
  // It is under 150 ms because it lands on reading surfaces as well
  // as the shelf, and that is §10's ceiling there.
  const sheet = sources.get("sheet")!;
  const ranges = guardedRanges(sheet);

  const seat = sheet.match(/\.leaf\s*\{[^}]*transition:\s*box-shadow\s+(\d+)ms[^}]*\}/);
  assert(seat, "sheet.css declares no box-shadow transition on .leaf");
  assert(Number(seat[1]) <= 150, `the leaf seats in ${seat[1]}ms; reading surfaces allow 150`);
  assert(
    !/\.leaf\s*\{[^}]*transition:[^}]*transform/.test(sheet),
    "the leaf transitions transform — a leaf that moves puts every anchor jump off",
  );

  for (const [name, css] of sources) {
    for (const m of css.matchAll(/@starting-style/g)) {
      assertEquals(name, "sheet", `${name}.css declares @starting-style; only the leaf lands`);
      const inside = ranges.some(([from, to]) => m.index! > from && m.index! < to);
      assert(inside, "sheet.css authors @starting-style outside the reduced-motion guard");
    }
  }
});
