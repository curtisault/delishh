module Page.About exposing (view)

{-| The colophon — what this is, what it is built from, and what is
never kept about a reader.

Four lines of wiring, the same as the standard: the prose of record
is `docs/about.md`, and `scripts/build-docs.ts` compiles it into
`Generated.About` on every build. **There is no hand-written prose
page left in `src/`** — a page you can edit in two places is a page
that disagrees with itself eventually, which is exactly how the old
colophon came to claim the body voice was a system serif months after
it stopped being one.

-}

import Doc
import Generated.About as About
import Html exposing (Html)
import Prose


view : Doc.Chrome msg -> Html msg
view chrome =
    Doc.view (Prose.config About.masthead About.sections chrome)
