import { defineConfig } from 'vite'
import elmPlugin from 'vite-plugin-elm'

// vite-plugin-elm (≤ 3.1.x) emits `import.meta.hot.accept([""])` when an
// Elm module imports no other local .elm files; Vite 8's import analysis
// rejects the empty specifier. Rewrite it to a bare self-accept.
const fixElmEmptyHmrAccept = {
  name: 'fix-elm-empty-hmr-accept',
  transform(code, id) {
    if (!id.endsWith('.elm')) return null
    const fixed = code.replace(
      /import\.meta\.hot\.accept\(\[\s*""\s*\],/,
      'import.meta.hot.accept([],'
    )
    return fixed === code ? null : { code: fixed, map: null }
  },
}

export default defineConfig({
  plugins: [elmPlugin(), fixElmEmptyHmrAccept],
  server: {
    // The dev server has one address, and `strictPort` is what makes
    // that sentence true. Vite's default is to walk up to the next
    // free port, which means a stray server left running silently
    // moves the site to 5179 — and a bookmark, a second tab or a
    // screenshot then shows yesterday's build with no indication
    // anything is wrong. Failing to start is the honest outcome:
    // the port is busy, and something you have forgotten about is
    // holding it.
    port: 5178,
    strictPort: true,
  },
  preview: {
    // Same rule for the production preview, one port along, so the
    // two can run side by side without either wandering.
    port: 5179,
    strictPort: true,
  },
  build: {
    // Pre-16.4 iOS WebKit can't parse minified range media queries
    // (`(width<=960px)`); pin an older CSS floor so queries ship in the
    // universally-parsed form. An unparseable media query never
    // matches, so this fails silently — phones get the desktop layout
    // while desktop responsive testing looks fine.
    cssTarget: ['chrome87', 'safari13.1', 'firefox78'],
  },
})
