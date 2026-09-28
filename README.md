# delishh

A personal recipe archive — browse, search, filter, print.

The design language is DS-01, set out in `docs/design-standard.md`.
That markdown is the prose of record: `deno task content` generates the
`/design-standard` page from it, so there is no second copy to drift.

## Running it

The toolchain is pinned in `mise.toml`. There is no Node: Deno runs
Vite, wrangler and the Elm test bundle.

```sh
mise install        # deno 2, elm 0.19.1, elm-test-rs
deno install        # vite, vite-plugin-elm, wrangler
deno task dev       # http://localhost:5173
```

| Task | Does |
|------|------|
| `deno task content` | markdown → JSON and generated Elm, with validation |
| `deno task dev` | content, then the Vite dev server |
| `deno task build` | content, then production build to `dist/` |
| `deno task test` | content, the validator's tests, then the Elm suite |
| `deno task deploy` | build, then deploy `dist/` to Cloudflare Pages |

`mise install` is required before `build` or `test`: neither the Elm
compiler nor the test runner is a package, and both resolve off PATH.

## Layout

```
src/Route.elm      routes — add one here AND in public/_redirects
src/Doc.elm        the document format: it numbers and frames
src/Page/*.elm     pure views, one per route
src/Main.elm       the TEA shell: URL, viewport, theme, search
src/Viewport.elm   whether a URL change moves the reader
src/Search.elm     the hand-written, machine-checked site index
src/Prose.elm      markdown blocks → the house chrome
src/Generated/     GENERATED from docs/ — never edited, never committed
src/theme.css      tokens only
src/fonts.css      @font-face only
src/sheet.css      components
scripts/           the content build: recipes and prose → Elm and JSON
content/recipes/   one markdown file per recipe, the source of record
docs/              the standard, the colophon, the facet constraints, the decision record
```

Working on this with Claude Code: read `CLAUDE.md` first.
