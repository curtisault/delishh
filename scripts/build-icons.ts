/**
 * The home-screen PNGs, rendered from `public/icons/icon.svg`.
 *
 * The SVG is the drawing of record; the PNGs exist because iOS reads
 * only `apple-touch-icon` (a bitmap) and Android's splash wants a 512.
 * They are committed rather than built, because the renderer is not a
 * package: `resvg` resolves off PATH, and CI should not need it to
 * ship a site whose icon has not changed. Edit the SVG, run
 * `deno task icons`, commit all four files together.
 *
 * `scripts/pwa_test.ts` holds each PNG's pixel size to its name.
 */

const SOURCE = "public/icons/icon.svg";

/** Output name → edge in pixels. */
export const RENDERS: Record<string, number> = {
  "public/icons/icon-192.png": 192,
  "public/icons/icon-512.png": 512,
  // iOS: 180 is the current home-screen size, and the file must be
  // opaque — the SVG is full bleed, so it is.
  "public/icons/apple-touch-icon.png": 180,
};

if (import.meta.main) {
  for (const [out, px] of Object.entries(RENDERS)) {
    const { code, stderr } = await new Deno.Command("resvg", {
      args: ["-w", String(px), "-h", String(px), SOURCE, out],
    }).output();
    if (code !== 0) {
      console.error(new TextDecoder().decode(stderr));
      Deno.exit(1);
    }
    console.log(`${out} (${px}px)`);
  }
}
