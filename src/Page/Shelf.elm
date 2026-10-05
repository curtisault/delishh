module Page.Shelf exposing (Config, view, viewFailed, viewLoading)

{-| The shelf — DS-01 §07.

**This is the loudest surface in the product**, and deliberately so.
Browsing is the enjoyable half of a recipe archive: you are choosing
what to cook, not following a procedure with a pan on the heat. So
the plate overprints, the flavour chips are stickers, and decoration
is permitted here and nowhere else (§2.2). The five paths are the
**console** (§07 as amended 2026-10-04): one line under the query,
five lines of words when it is open, and the words are the controls.

The two refusals that shape the list:

  - **Filters narrow; they never silently hide.** An excluded row
    stays on the page wearing the filter that excluded it. You can
    always see why the list is the size it is.
  - **Active and total time are both shown.** A twelve-hour cure is
    not a twenty-minute recipe.

Like the recipe page, this does not wear `Doc`: a shelf is not a
prose document and has no sections to number.

-}

import Html exposing (Html, a, button, div, h1, h2, input, li, mark, p, section, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, for, href, id, placeholder, type_, value)
import Flavor
import Install
import Html.Events exposing (onClick, onInput)
import Reach
import Set exposing (Set)
import Shelf exposing (Filters, Path, Summary, Verdict(..))


type alias Config msg =
    { index : Shelf.Index
    , filters : Filters
    , console : Bool
    , unfolded : Set String
    , onConsole : msg
    , onUnfold : Path -> msg
    , onToggle : Path -> String -> msg
    , onQuery : String -> msg
    , onClearQuery : msg
    , onClear : msg
    , install : Install.Offer
    , installHelp : Bool
    , onInstall : msg
    }



-- STATES


viewLoading : Html msg
viewLoading =
    shell [ p [ class "shelf-state" ] [ text "Opening the archive…" ] ]


{-| "A reload usually settles it" is false with no signal, and a
sentence that is sometimes false is one the reader learns to ignore —
so it is said only when the archive answered and a reload might help.
-}
viewFailed : Reach.Failure -> Html msg
viewFailed failure =
    shell
        [ h1 [ class "shelf-title" ] [ text "The archive did not open" ]
        , p [ class "shelf-state" ]
            [ text <|
                case failure of
                    Reach.Unkept ->
                        "There is no connection, and no copy of the archive has been kept on this device yet. It opens once there is a signal."

                    Reach.Unreachable ->
                        "There is no connection, so the index could not be fetched. It opens once there is a signal."

                    _ ->
                        "The index could not be fetched. A reload usually settles it."
            ]
        ]


shell : List (Html msg) -> Html msg
shell body =
    div [ class "shelf-layout" ] [ div [ class "shelf leaf" ] body ]



-- THE SHELF


view : Config msg -> Html msg
view config =
    let
        rows =
            Shelf.ranked config.filters config.index.recipes

        shown =
            List.filter (\( _, v ) -> v == Shown) rows
    in
    div [ class "shelf-layout" ]
        [ div [ class "shelf leaf" ]
            [ masthead config
            , activeBar config
            , results config shown rows
            ]
        ]


masthead : Config msg -> Html msg
masthead config =
    div [ class "shelf-plate" ]
        [ div [ class "shelf-head" ]
            [ h1 [ class "shelf-title" ] [ text "delishh" ]
            , installPress config
            ]
        , installHelp config
        , p [ class "shelf-standfirst" ]
            [ text "A recipe archive. "
            , span [ class "mono" ]
                [ text (String.fromInt (List.length config.index.recipes)) ]
            , text
                (if List.length config.index.recipes == 1 then
                    " recipe, newest batch first."

                 else
                    " recipes, newest batch first."
                )
            ]
        , searchLine config

        -- The console is the query line's second row: one
        -- instrument on the plate, the rule beneath both.
        , console config
        ]


{-| The home-screen install, top right of the masthead
(`docs/decisions.md`).

Drawn only when pressing it will do something: the browser's own
dialog where the browser offers one, the one sentence Safari needs
where it does not, and nothing at all when the archive is already
installed or the browser cannot install. The mark is a tray and an
arrow, and on screen it is only the mark: a word beside it made the
press a second slab competing with the title plate. The word is still
there for a screen reader (`.vh`), and the share-sheet path spells out
what the press means the moment it is pressed.

On the share-sheet path the press is a toggle — seated while its
sentence shows, and saying so to a screen reader.

-}
installPress : Config msg -> Html msg
installPress config =
    let
        dress extra =
            button
                ([ type_ "button"
                 , class "press-block shelf-install"
                 , onClick config.onInstall
                 ]
                    ++ extra
                )
                [ span [ class "shelf-install-mark", attribute "aria-hidden" "true" ] []
                , span [ class "vh" ] [ text "Install on this device" ]
                ]
    in
    case config.install of
        Install.Prompt ->
            dress []

        Install.ShareSheet ->
            dress
                [ classList [ ( "is-seated", config.installHelp ) ]
                , attribute "aria-expanded"
                    (if config.installHelp then
                        "true"

                     else
                        "false"
                    )
                , attribute "aria-controls" "shelf-install-help"
                ]

        Install.NoOffer ->
            text ""


installHelp : Config msg -> Html msg
installHelp config =
    if config.install == Install.ShareSheet && config.installHelp then
        p [ id "shelf-install-help", class "shelf-install-help" ]
            [ text "Press Share, then Add to Home Screen. It opens from there without the browser, and without a signal." ]

    else
        text ""


{-| The query line — a labelled instrument, not a box with a
magnifier in it.

The label is a real `<label>`, so its word *is* the field's
accessible name and clicking it lands the caret. The `▸` is the
marker between the two and nothing else, which is why it is hidden
from assistive tech: read aloud it would be a shape with no meaning
between a label and its field.

-}
searchLine : Config msg -> Html msg
searchLine config =
    let
        empty =
            String.isEmpty config.filters.query
    in
    div [ class "shelf-search" ]
        [ Html.label
            [ class "query-line"
            , classList [ ( "is-empty", empty ) ]
            , for "shelf-query"
            ]
            [ span [ class "query-k mono" ] [ text "Query" ]
            , span [ class "query-mark mono", attribute "aria-hidden" "true" ]
                [ text "▸" ]
            , input
                [ type_ "search"
                , id "shelf-query"
                , class "shelf-query mono"
                , placeholder "Search the archive"
                , value config.filters.query
                , onInput config.onQuery
                ]
                []

            -- The clear (docs/decisions.md, 2026-10-05, CL-05 off
            -- the bench): the word CLEAR with a volt rule under it,
            -- the way-back link's dress. Text, not a slab, because
            -- the line is an instrument and a slab on an instrument
            -- is a sticker. A button inside the label is interactive
            -- content, so the label does not redirect its click to
            -- the field; the shell puts the caret back itself. It is
            -- always rendered and hidden by visibility while the
            -- query is empty, so the line's width never moves when
            -- it appears. The browser's own cancel mark is
            -- suppressed in shelf.css; this is the only clear.
            , Html.button
                [ type_ "button"
                , class "query-clear mono u"
                , attribute "aria-hidden" (bool empty)
                , Html.Attributes.tabindex
                    (if empty then
                        -1

                     else
                        0
                    )
                , onClick config.onClearQuery
                ]
                [ text "Clear" ]
            ]
        ]



-- THE CONSOLE


{-| A console line shows this many words before it folds. Eight is
past every closed vocabulary (the longest is seven), so only the
open-ended group — the places — can ever fold.
-}
foldAt : Int
foldAt =
    8


{-| The five paths as a console — DS-01 §07 as amended 2026-10-04.

Closed, it is one line: `FILTER ▸ by meal, flavour, effort, needs or place`, with a count beside it once anything is on. Open, it is
five lines, one per path, the path's noun with its acid as a bar and
its words set in the data voice as presses. Text only: the words are
the controls, and a word that is on wears the stencil.

**The console reads the query.** A non-empty query marks the letters
it reached in every word, the same mark the rows wear, and dims the
words it did not reach — dims, never removes, because a reader who
cannot see a word cannot tell *no such place* from *mistyped*. The
shell also opens the console on the first letter typed, since typing
is a hand reaching for it.

The lines are rendered only while open, and the stagger they arrive
with is CSS on a fresh element (`@starting-style`), so a reader who
asked for calm gets five lines at once.

-}
console : Config msg -> Html msg
console config =
    let
        on =
            List.length (List.concatMap Tuple.second (Shelf.active config.filters))
    in
    div [ class "console", classList [ ( "open", config.console ) ] ]
        [ Html.button
            [ type_ "button"
            , class "con-line"
            , attribute "aria-expanded" (bool config.console)
            , attribute "aria-controls" "con-rows"
            , onClick config.onConsole
            ]
            [ span [ class "con-k mono u" ] [ text "Filter" ]
            , span [ class "con-what" ]
                [ text "by meal, flavour, effort, needs or place"

                -- The cursor: a console waiting for you. It blinks
                -- whenever the console is closed and is gone while
                -- it is open, since an open console is no longer
                -- waiting. Still, not gone, for a reader who asked
                -- for calm.
                , if config.console then
                    text ""

                  else
                    span [ class "con-cursor", attribute "aria-hidden" "true" ] []
                ]

            -- The count only when something is on. A zero tells the
            -- reader nothing, and at a phone's width it is the 37px
            -- that pushes the sentence onto a second line.
            , if on == 0 then
                text ""

              else
                span [ class "con-count mono" ] [ text (String.fromInt on ++ " on") ]

            -- The keycap: the one stencil block on the line, so the
            -- eye finds it with no motion at all, carrying a drawn
            -- sliders mark. Open, it goes from filled to outlined.
            -- Hidden from assistive tech: the button's
            -- `aria-expanded` already says what it says.
            , span [ class "con-key", attribute "aria-hidden" "true" ]
                [ span [ class "con-key-mark" ] [] ]
            ]
        , if config.console then
            div [ id "con-rows", class "con-rows" ]
                (div [ class "con-head", attribute "aria-hidden" "true" ] []
                    :: List.map (consoleRow config) Shelf.paths
                )

          else
            text ""
        ]


{-| One line of the console. `Shelf.fold` decides which words show
and the view only draws them; an unfolded line shows the whole
vocabulary until the reader leaves the shelf.
-}
consoleRow : Config msg -> Path -> Html msg
consoleRow config p =
    let
        folded =
            Shelf.fold foldAt p config.filters config.index

        ( words, hidden ) =
            if Set.member (Shelf.path p) config.unfolded then
                ( Shelf.vocabularyFor p config.index, 0 )

            else
                ( folded.shown, folded.hidden )

        more =
            if hidden == 0 then
                []

            else
                [ Html.button
                    [ type_ "button"
                    , class "con-word con-more mono"
                    , onClick (config.onUnfold p)
                    ]
                    [ text ("+" ++ String.fromInt hidden ++ " more") ]
                ]
    in
    div [ class ("con-row path-" ++ Shelf.path p) ]
        [ span [ class "con-group mono u" ] [ text (Shelf.pathNoun p) ]
        , span [ class "con-words" ] (List.map (consoleWord config p) words ++ more)
        ]


consoleWord : Config msg -> Path -> String -> Html msg
consoleWord config p word =
    let
        on =
            List.member word (Shelf.facetValues p config.filters)

        -- A vocabulary word is a key — `gluten-free` — and reads
        -- with its hyphen opened. A place is a name, as typed, and
        -- is shown as typed: nothing about it is a key.
        shown =
            case p of
                Shelf.ByPlace ->
                    word

                _ ->
                    String.replace "-" " " word

        typed =
            not (List.isEmpty (Shelf.needles config.filters.query))

        dim =
            typed && not on && not (Shelf.reaches config.filters.query word)
    in
    Html.button
        [ type_ "button"
        , class "con-word mono"
        , classList [ ( "on", on ), ( "is-dim", dim ) ]
        , attribute "aria-pressed" (bool on)
        , onClick (config.onToggle p word)
        ]
        (List.map hit (Shelf.marks config.filters.query shown))


bool : Bool -> String
bool b =
    if b then
        "true"

    else
        "false"



-- WHAT IS NARROWED


{-| Every active filter, stating what it excludes.

A chip that says only its own name leaves the reader to infer the
rule; one that says what it keeps out is the same information
without the inference (DS-01 §2.5).

-}
activeBar : Config msg -> Html msg
activeBar config =
    case Shelf.active config.filters of
        [] ->
            text ""

        entries ->
            div [ class "active-bar" ]
                (span [ class "active-k u" ] [ text "Showing only" ]
                    :: List.map activeEntry entries
                    ++ [ Html.button
                            [ type_ "button"
                            , class "press-block active-clear u"
                            , onClick config.onClear
                            ]
                            [ text "Clear all" ]
                       ]
                )


activeEntry : ( Path, List String ) -> Html msg
activeEntry ( p, values ) =
    span [ class "active-entry" ]
        [ span [ class "active-path u" ] [ text (Shelf.pathLabel p) ]
        , span [ class "active-values" ]
            [ text (String.join " or " (List.map (String.replace "-" " ") values)) ]
        ]



-- RESULTS


results : Config msg -> List ( Summary, Verdict ) -> List ( Summary, Verdict ) -> Html msg
results config shown rows =
    section [ id "results", class "results" ]
        (if List.isEmpty shown then
            [ zeroState config ]

         else
            [ h2 [ class "results-h u" ]
                [ text
                    (String.fromInt (List.length shown)
                        ++ (if List.length shown == 1 then
                                " recipe"

                            else
                                " recipes"
                           )
                    )
                ]
            , ul [ class "row-list" ] (List.map (row config.filters.query) rows)
            ]
        )


{-| One row. Dense and scannable — the shelf is used for retrieval,
and retrieval wants text you can run your eye down.

An excluded row is **tagged, not removed**: struck through, carrying
the filter that excluded it, and still a link. It is the difference
between "this is not what you asked for" and "this does not exist".

**The query is marked where it landed.** A row is in the list because
some word of the query is somewhere in it, and the fill says which
letters — the same information the lockout tag gives an excluded row,
for the rows that stayed. It marks the two texts the row actually
draws; a match that came from a facet the row does not print marks
nothing, because there is nothing there to point at.

-}
row : String -> ( Summary, Verdict ) -> Html msg
row query ( recipe, verdict ) =
    let
        excluded =
            verdict /= Shown

        marked =
            List.map hit << Shelf.marks query
    in
    li [ class "row", classList [ ( "is-excluded", excluded ) ] ]
        [ a [ class "row-link", href ("/recipe/" ++ recipe.slug) ]
            [ span [ class "row-no mono" ]
                (marked (String.toUpper (String.replace "-" " " recipe.method)))
            , span [ class "row-title" ] (marked recipe.title)
            , span [ class "row-chips" ]
                (List.map (Flavor.chip "chip-flavor") recipe.flavor)
            , span [ class "row-times mono" ]
                [ span [ class "row-active" ] [ text (minutes recipe.active) ]
                , span [ class "row-sep" ] [ text " · " ]

                -- Both, always. A twelve-hour cure is not a
                -- twenty-minute recipe, and collapsing the two is the
                -- most common lie in recipe software (DS-01 §07).
                , span [ class "row-total" ] [ text (minutes recipe.total ++ " total") ]

                -- …and how long it lasts once it is made, which is a
                -- third fact and not a fourth version of the first
                -- two. It rides with the times because that is where
                -- the eye already is at the end of a row.
                , keepsTag recipe
                ]
            ]
        , case verdict of
            Excluded reasons ->
                span [ class "row-lockout u" ]
                    [ text
                        (case reasons of
                            [] ->
                                "Hidden by the search"

                            _ ->
                                "Hidden by "
                                    ++ String.join " and " (List.map Shelf.pathNoun reasons)
                        )
                    ]

            Shown ->
                text ""
        ]


{-| How long it keeps — the last thing in the row, and absent when
the recipe does not say.

**Nothing stands in for an unstated life.** No dash, no "unknown", no
hedge: an absent tag means nobody has established how long this
lasts, and a placeholder in that slot is the archive filling a
silence it has no right to fill (DS-01 §12).

-}
keepsTag : Summary -> Html msg
keepsTag recipe =
    case recipe.keepsFor of
        Nothing ->
            text ""

        Just life ->
            span [ class "row-keeps" ]
                [ span [ class "row-sep" ] [ text " · " ]
                , span [ class "row-keeps-k u" ] [ text "Keeps" ]
                , text (" " ++ keepsText life)
                ]


{-| `3 mo · freezer`. **The place is never dropped to save a
centimetre**: most of this archive states a freezer life and no
fridge one, and a duration on its own at the end of a row reads as a
claim about the dish in a fridge (DS-01 §06).
-}
keepsText : Shelf.Keeps -> String
keepsText life =
    String.fromInt life.amount ++ " " ++ life.unit ++ " · " ++ life.where_


{-| One run of a marked text. `<mark>` is the house's applied block
and already wears its fill in `theme.css` — the shelf does not get a
highlight of its own, because two marks are two things a reader has
to learn.
-}
hit : ( String, Bool ) -> Html msg
hit ( run, matched ) =
    if matched then
        mark [] [ text run ]

    else
        text run


minutes : Int -> String
minutes total =
    let
        days =
            total // 1440

        hours =
            modBy 1440 total // 60

        mins =
            modBy 60 total

        part n suffix =
            if n == 0 then
                []

            else
                [ String.fromInt n ++ suffix ]
    in
    case part days "d" ++ part hours "h" ++ part mins "min" of
        [] ->
            "0min"

        parts ->
            String.join " " parts


{-| **A dead end is a design failure, not an edge case** (DS-01 §07).
Zero results is designed copy with somewhere to go: the nearest
recipe by total time, and a way out of the filters that produced the
emptiness.
-}
zeroState : Config msg -> Html msg
zeroState config =
    div [ class "zero" ]
        [ h2 [ class "zero-h u" ] [ text "Nothing matches" ]
        , case Shelf.nearestByTime config.filters config.index.recipes of
            Just near ->
                div []
                    [ p [ class "zero-lead" ] [ text "Closest by time:" ]
                    , a [ class "zero-near", href ("/recipe/" ++ near.slug) ]
                        [ span [ class "row-no mono" ]
                            [ text (String.toUpper (String.replace "-" " " near.method)) ]
                        , span [ class "row-title" ] [ text near.title ]
                        , span [ class "row-times mono" ]
                            [ text (minutes near.total ++ " total") ]
                        ]
                    ]

            Nothing ->
                p [ class "zero-lead" ] [ text "The archive is empty." ]
        , Html.button
            [ type_ "button", class "press-block zero-clear u", onClick config.onClear ]
            [ text "Clear the filters" ]
        ]
