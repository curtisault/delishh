/**
 * `public/sw.js`, from `src/sw.js` with the build stamp substituted.
 *
 * The worker is not bundled: a service worker's URL is its identity,
 * so it cannot carry a Vite hash, and it must sit at the root to
 * control the root. What makes a browser install a new worker is a
 * byte of difference, so every build writes a new stamp — which also
 * names the one cache, so the new worker's activate clears the old
 * build's hashed assets.
 *
 * Generated and gitignored, like `public/content`. Edit `src/sw.js`.
 */

export const PLACEHOLDER = "__BUILD__";

const source = await Deno.readTextFile("src/sw.js");
if (source.split(PLACEHOLDER).length !== 2) {
  console.error(`src/sw.js must hold ${PLACEHOLDER} exactly once`);
  Deno.exit(1);
}

const stamp = new Date().toISOString().replace(/[-:.]/g, "");
await Deno.writeTextFile(
  "public/sw.js",
  `// GENERATED from src/sw.js by scripts/build-sw.ts. Do not edit.\n` +
    source.replace(PLACEHOLDER, stamp),
);
console.log(`public/sw.js (${stamp})`);
