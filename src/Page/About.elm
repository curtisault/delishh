module Page.About exposing (view)

{-| The second route, which exists mostly to prove there is more than
one: the site nav, `Route`, `public/_redirects` and the shell's
viewport rules all need two addresses before any of them mean
anything.
-}

import Doc
import Html exposing (Html, p, text)
import Html.Attributes exposing (class)


view : Doc.Chrome msg -> Html msg
view chrome =
    Doc.view
        { tag = "ABOUT"
        , kicker = "Colophon"
        , rev = "Rev. 0"
        , revDate = "2026-09-19"
        , titleLines = [ "About" ]
        , standfirst = "Who made this, what it is built from, and how to reach whoever keeps it."
        , sections = [ who, colophon ]
        , footNote = [ text "Placeholder footer. Whatever must appear on every page goes here." ]
        , chrome = chrome
        }


who : Doc.Section msg
who =
    { anchor = "sec-who"
    , tocLabel = "Who made it"
    , title = "Who made it"
    , intent = "And who to ask"
    , body =
        Doc.Clauses
            [ p [ class "lede" ]
                [ text "Say who is responsible for this and how to reach them. A document with no author is a document nobody can question." ]
            ]
    }


colophon : Doc.Section msg
colophon =
    { anchor = "sec-colophon"
    , tocLabel = "Colophon"
    , title = "Colophon"
    , intent = "Type and tooling"
    , body =
        Doc.Clauses
            [ p []
                [ text "Elm compiled by Vite, served as static files. The display voice is Archivo Expanded and the data voice is JetBrains Mono, both self-hosted under the SIL Open Font License; body copy is a system serif." ]
            , p []
                [ text "There is no analytics on this site and nothing is stored about a reader. The one thing kept in this browser is which lighting you chose." ]
            ]
    }
