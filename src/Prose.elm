module Prose exposing
    ( Block(..)
    , Masthead
    , Section
    , Span(..)
    , config
    , section
    )

{-| The rendered form of a prose document.

**This module is the boundary between markdown and the house chrome.**
`docs/*.md` is the prose of record; `scripts/build-docs.ts` parses it
into the values below and writes them as
`src/Generated/*.elm`; this module turns them into `Doc.Section`s
wearing the house classes.

The generator is deliberately dumb — it emits data and knows nothing
about a class name. **Every styling decision lives here, in
hand-written Elm that a reviewer reads.** That split is what stops a
markdown pipeline from quietly becoming the thing that owns the
typography.

The block set is small on purpose: it is exactly what DS-01 uses and
nothing more. Widening it means the standard grew a construct, which
is a decision worth seeing in a diff — not a thing to accommodate
speculatively.

-}

import Doc
import Html exposing (Html, code, div, h3, li, ol, p, span, strong, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (class)


{-| Inline formatting. Four cases, matching the four type voices of
DS-01 §05 minus the display voice, which is structural rather than
inline.
-}
type Span
    = Text String
    | Strong String
    | Emph String
    | Mono String


{-| A top-level block inside a section.

  - `Sub` — an `###` subhead.
  - `Why` — a blockquote, rendered as the rationale voice: the serif
    aside that says why a rule exists.
  - `Grid` — a reference table of any width. The first column is the
    term being defined and is set in the data voice.
  - `Pre` — a fenced block: a specimen, a schema, a sample row. The
    one place the document shows rather than tells.

-}
type Block
    = Para (List Span)
    | Sub String
    | Bullets (List (List Span))
    | Numbered (List (List Span))
    | Grid (List String) (List (List (List Span)))
    | Why (List Span)
    | Pre String


{-| One section, as the generator emits it. Mirrors `Doc.Section`
minus the rendered body — `panel` chooses which `Doc.Body` wraps it.
-}
type alias Section =
    { anchor : String
    , tocLabel : String
    , title : String
    , intent : String
    , panel : Bool
    , blocks : List Block
    }


{-| The masthead, carried in the document's own frontmatter so the
markdown stays the single source for the whole page and not merely
its body.
-}
type alias Masthead =
    { tag : String
    , kicker : String
    , rev : String
    , revDate : String
    , titleLines : List String
    , standfirst : String
    , footNote : String
    }


{-| Assemble a full `Doc.Config` from a parsed document.
-}
config : Masthead -> List Section -> Doc.Chrome msg -> Doc.Config msg
config masthead sections chrome =
    { tag = masthead.tag
    , kicker = masthead.kicker
    , rev = masthead.rev
    , revDate = masthead.revDate
    , titleLines = masthead.titleLines
    , standfirst = masthead.standfirst
    , sections = List.map section sections
    , footNote = [ text masthead.footNote ]
    , chrome = chrome
    }


{-| One parsed section, through the house chrome.

`panel` picks the numbering: apparatus with its own internal structure
is numbered at section level, prose earns a citable `§N.M` per block
(`Doc.Body`).

-}
section : Section -> Doc.Section msg
section s =
    { anchor = s.anchor
    , tocLabel = s.tocLabel
    , title = s.title
    , intent = s.intent
    , body =
        let
            blocks =
                List.map viewBlock s.blocks
        in
        if s.panel then
            Doc.Panel blocks

        else
            Doc.Clauses blocks
    }



-- BLOCKS


viewBlock : Block -> Html msg
viewBlock block =
    case block of
        Para spans ->
            p [] (List.map viewSpan spans)

        Sub copy ->
            h3 [] [ text copy ]

        Bullets items ->
            ul [ class "doc-list" ] (List.map viewItem items)

        Numbered items ->
            ol [ class "doc-list" ] (List.map viewItem items)

        Why spans ->
            p [ class "doc-why" ] (List.map viewSpan spans)

        Grid headers rows ->
            viewGrid headers rows

        Pre body ->
            -- Deliberately not a `doc-scroller`: a specimen is read as
            -- a shape, and wrapping it would destroy the alignment
            -- that is the entire point of showing it.
            div [ class "doc-scroller" ]
                [ Html.pre [ class "doc-pre" ] [ code [] [ text body ] ] ]


viewItem : List Span -> Html msg
viewItem spans =
    li [] (List.map viewSpan spans)


{-| A reference table of any width. Wide content scrolls inside its
own container so the sheet never scrolls sideways — on a phone a table
that widens the page takes the whole document with it.

The first cell of each row is the term being defined and is set in the
data voice; the rest is procedure. That asymmetry is the table's whole
grammar, so it is applied here rather than asked of the markdown.

-}
viewGrid : List String -> List (List (List Span)) -> Html msg
viewGrid headers rows =
    div [ class "doc-scroller" ]
        [ table [ class "doc-grid" ]
            [ thead []
                [ tr [] (List.map (\h -> th [ class "u" ] [ text h ]) headers) ]
            , tbody [] (List.map viewRow rows)
            ]
        ]


viewRow : List (List Span) -> Html msg
viewRow cells =
    tr []
        (List.indexedMap
            (\i cell ->
                td []
                    (if i == 0 then
                        [ span [ class "mono" ] (List.map viewSpan cell) ]

                     else
                        List.map viewSpan cell
                    )
            )
            cells
        )


viewSpan : Span -> Html msg
viewSpan s =
    case s of
        Text copy ->
            text copy

        Strong copy ->
            strong [] [ text copy ]

        Emph copy ->
            Html.em [] [ text copy ]

        Mono copy ->
            code [ class "mono" ] [ text copy ]
