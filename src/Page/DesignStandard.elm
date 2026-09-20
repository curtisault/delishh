module Page.DesignStandard exposing (view)

{-| DS-01 — the aesthetic contract for delishh.

**This module is now four lines of wiring.** The prose of record is
`docs/design-standard.md`; `scripts/build-docs.ts` parses it into
`Generated.DesignStandard` on every build, and `Prose` renders that
through the house chrome. There is no second copy of the standard
anywhere — editing the markdown is the only way to change this page.

**Section numbers are positional.** `Doc` numbers sections from their
order, and the generator checks each `## NN.` heading against its own
position, so a reordered section fails the build instead of silently
repointing every in-prose `§`. Anchors are pinned in the markdown's
`<!-- doc ... -->` directives, which is what keeps `Search.index` in
step with them.

-}

import Doc
import Generated.DesignStandard as DS
import Html exposing (Html)
import Prose


view : Doc.Chrome msg -> Html msg
view chrome =
    Doc.view (Prose.config DS.masthead DS.sections chrome)
