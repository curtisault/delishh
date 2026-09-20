module Page.Home exposing (view)

{-| The front page. A pure view: it hands `Doc.view` one ordered list
of sections and gets the chrome back around them.

Everything below the `Doc.Config` is placeholder prose. It is here so
the format has something to frame — delete it, keep the shape.

-}

import Doc
import Html exposing (Html, p, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class)


view : Doc.Chrome msg -> Html msg
view chrome =
    Doc.view
        { tag = "DELISHH"
        , kicker = "A new document"
        , rev = "Rev. 0"
        , revDate = "2026-09-19"
        , titleLines = [ "Say what this", "is for" ]
        , standfirst = "One sentence under the masthead that tells a reader what they are looking at and why they should keep reading."
        , sections = [ what, format ]
        , footNote = [ text "Placeholder footer. Whatever must appear on every page goes here." ]
        , chrome = chrome
        }


what : Doc.Section msg
what =
    { anchor = "sec-what"
    , tocLabel = "What this is"
    , title = "What this is"
    , intent = "Start here"
    , body =
        Doc.Clauses
            [ p [ class "lede" ]
                [ text "This is a scaffold. Nothing on the page is real writing yet — it exists so the document format has something to frame: a masthead, numbered sections, a clause mark in the margin, and a contents rail that marks the section you are reading." ]
            , p []
                [ text "Each block you pass as a clause earns its own margin mark and its own address, so a sentence can be linked to directly. Blocks that are apparatus rather than prose go in a panel instead, which is numbered at section level only." ]
            , p []
                [ text "Replace this page and the one behind the About link. The chrome around them does not change." ]
            ]
    }


format : Doc.Section msg
format =
    { anchor = "sec-format"
    , tocLabel = "The format"
    , title = "What the format owns"
    , intent = "Doc.elm numbers and frames; a page renders"
    , body =
        Doc.Panel
            [ table []
                [ thead []
                    [ tr []
                        [ th [] [ text "Piece" ]
                        , th [] [ text "Who owns it" ]
                        ]
                    ]
                , tbody []
                    [ row "Masthead, kicker, revision mark" "Doc, from the Config you hand it"
                    , row "Section numbering" "Doc, derived from the list order"
                    , row "Contents rail and the active row" "Doc, from Chrome.active"
                    , row "Clause marks and their anchors" "Doc, from each section's anchor"
                    , row "Search box and the result list" "Doc, from Chrome.query"
                    , row "Everything inside a section body" "the page"
                    ]
                ]
            , p [ class "note" ]
                [ Html.b [] [ text "The boundary " ]
                , text "is worth defending: the moment Doc learns what one of your page's components is, it has stopped being a format and started being a page."
                ]
            ]
    }


row : String -> String -> Html msg
row piece owner =
    tr []
        [ td [] [ text piece ]
        , td [] [ text owner ]
        ]
