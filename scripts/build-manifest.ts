/**
 * `public/manifest.webmanifest`, written from `theme.css`.
 *
 * A manifest is hex literals, and raw hex outside `theme.css` is a
 * bug. So the two colours it carries are read out of the bare `:root`
 * block — the complete light set — at build time, and the file is
 * generated and gitignored like `public/content`. A manifest has no
 * dark variant; the light pair is the one the launcher shows.
 *
 *  - `background_color` is `--surface`, the page ground: the splash
 *    an Android launch shows before the first paint.
 *  - `theme_color` is `--stencil-bg`, the site bar's field, so the
 *    system bar above it reads as the bar's continuation.
 *  - `launch_handler` sends a link the installed app catches (Android,
 *    and desktop Chrome where the reader allows it) to the window
 *    already open, at the link's address — not a second window, and
 *    not `focus-existing`, which raises the window and leaves it where
 *    it was unless the page reads `launchQueue` itself. `auto` is the
 *    browser's own choice where it knows no other. iOS has none of
 *    this: a link always opens in Safari (docs/decisions.md,
 *    2026-10-21).
 */

import { ICONS, tokenIn } from "./manifest.ts";

const theme = await Deno.readTextFile("src/theme.css");

const manifest = {
  id: "/",
  name: "delishh",
  short_name: "delishh",
  description: "A personal recipe archive: browse, search, filter, print.",
  lang: "en",
  start_url: "/",
  scope: "/",
  display: "standalone",
  launch_handler: { client_mode: ["navigate-existing", "auto"] },
  background_color: tokenIn(theme, "--surface"),
  theme_color: tokenIn(theme, "--stencil-bg"),
  icons: ICONS,
};

await Deno.writeTextFile(
  "public/manifest.webmanifest",
  JSON.stringify(manifest, null, 2) + "\n",
);
console.log("public/manifest.webmanifest");
