/**
 * What the manifest generator and its test share: the icon list and
 * the one way a token's light value is read out of `theme.css`.
 */

/** The icons the manifest names. One drawing, three purposes: the SVG
 * is full bleed with its mark inside the maskable safe circle, so the
 * maskable entry is the same file rather than a second drawing that
 * could drift. Listed separately, not as `"any maskable"`, which
 * Chrome warns wastes the padding on the `any` render. */
export const ICONS = [
  { src: "/icons/icon.svg", sizes: "any", type: "image/svg+xml", purpose: "any" },
  { src: "/icons/icon-192.png", sizes: "192x192", type: "image/png", purpose: "any" },
  { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "any" },
  { src: "/icons/icon-512.png", sizes: "512x512", type: "image/png", purpose: "maskable" },
];

/** The body of the first bare `:root { … }` — the complete light set. */
function lightRoot(theme: string): string {
  const css = theme.replace(/\/\*[\s\S]*?\*\//g, "");
  const m = css.match(/(?:^|\n):root\s*\{([^}]*)\}/);
  if (!m) throw new Error("theme.css has no bare :root block");
  return m[1];
}

/** A token's light value, as written. Throws if it is not a hex:
 * a manifest cannot resolve `var()`. */
export function tokenIn(theme: string, name: string): string {
  const m = lightRoot(theme).match(
    new RegExp(`${name.replace(/-/g, "\\-")}\\s*:\\s*([^;]+);`),
  );
  if (!m) throw new Error(`theme.css :root does not define ${name}`);
  const value = m[1].trim();
  if (!/^#[0-9a-f]{6}$/i.test(value)) {
    throw new Error(`${name} is ${value}, not a hex a manifest can carry`);
  }
  return value.toLowerCase();
}
