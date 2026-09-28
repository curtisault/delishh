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
  background_color: tokenIn(theme, "--surface"),
  theme_color: tokenIn(theme, "--stencil-bg"),
  icons: ICONS,
};

await Deno.writeTextFile(
  "public/manifest.webmanifest",
  JSON.stringify(manifest, null, 2) + "\n",
);
console.log("public/manifest.webmanifest");
