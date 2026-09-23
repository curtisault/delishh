module Page.Shelf exposing (Config, view, viewFailed, viewLoading)

{-| The shelf — DS-01 §07.

**This is the loudest surface in the product**, and deliberately so.
Browsing is the enjoyable half of a recipe archive: you are choosing
what to cook, not following a procedure with a pan on the heat. So
the four path tiles take full-acid fills, the flavour chips are
stickers, and decoration is permitted here and nowhere else (§2.2).

The two refusals that shape the list:

  - **Filters narrow; they never silently hide.** An excluded row
    stays on the page wearing the filter that excluded it. You can
    always see why the list is the size it is.
  - **Active and total time are both shown.** A twelve-hour cure is
    not a twenty-minute recipe.

Like the recipe page, this does not wear `Doc`: a shelf is not a
prose document and has no sections to number.

-}

import Html exposing (Html, a, div, h1, h2, input, li, mark, p, section, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, for, href, id, placeholder, type_, value)
import Flavor
import Html.Events exposing (onClick, onInput)
import Shelf exposing (Filters, Path, Summary, Verdict(..))


type alias Config msg =
    { index : Shelf.Index
    , filters : Filters
    , openPath : Maybe Path
    , onOpen : Maybe Path -> msg
    , onToggle : Path -> String -> msg
    , onQuery : String -> msg
    , onClear : msg
    }



-- STATES


viewLoading : Html msg
viewLoading =
    shell [ p [ class "shelf-state" ] [ text "Opening the archive…" ] ]


viewFailed : Html msg
viewFailed =
    shell
        [ h1 [ class "shelf-title" ] [ text "The archive did not open" ]
        , p [ class "shelf-state" ]
            [ text "The index could not be fetched. A reload usually settles it." ]
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
            , tiles config
            , activeBar config
            , results config shown rows
            ]
        ]


masthead : Config msg -> Html msg
masthead config =
    div [ class "shelf-plate" ]
        [ h1 [ class "shelf-title" ] [ text "delishh" ]
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
        ]


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
    div [ class "shelf-search" ]
        [ Html.label [ class "query-line", for "shelf-query" ]
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
            ]
        ]



-- THE FOUR PATHS


{-| Full-acid tiles, one per way in. An open tile shows its chips
beneath; one at a time, because four open facet sets is a wall rather
than a choice — selections persist when a tile closes, which is what
lets paths compose.
-}
tiles : Config msg -> Html msg
tiles config =
    div [ class "paths" ]
        (List.map (tile config) Shelf.paths)


tile : Config msg -> Path -> Html msg
tile config p =
    let
        open =
            config.openPath == Just p

        chosen =
            List.length (Shelf.facetValues p config.filters)
    in
    div [ class "path", classList [ ( "open", open ) ] ]
        [ Html.button
            [ type_ "button"
            , class ("press-block path-tile path-" ++ Shelf.path p)
            , attribute "aria-expanded"
                (if open then
                    "true"

                 else
                    "false"
                )
            , onClick
                (config.onOpen
                    (if open then
                        Nothing

                     else
                        Just p
                    )
                )
            ]
            [ span [ class "path-label u" ] [ text (Shelf.pathLabel p) ]
            , span [ class "path-note" ] [ text (Shelf.pathNote p) ]
            , if chosen == 0 then
                text ""

              else
                span [ class "path-count mono" ] [ text (String.fromInt chosen) ]
            ]
        , if open then
            div [ class "path-chips" ]
                (List.map (facetChip config p) (Shelf.vocabularyFor p config.index))

          else
            text ""
        ]


facetChip : Config msg -> Path -> String -> Html msg
facetChip config p word =
    let
        on =
            List.member word (Shelf.facetValues p config.filters)
    in
    Html.button
        [ type_ "button"
        , -- `f-<word>` puts the flavour stencil on the filter chip
          -- too — same mark, same place, so the association is built
          -- where the words are first met. On any other path the
          -- class matches no mask and draws nothing.
          class ("press-block chip chip-" ++ Shelf.path p ++ " u f-" ++ word)
        , classList [ ( "on", on ), ( "is-seated", on ) ]
        , attribute "aria-pressed"
            (if on then
                "true"

             else
                "false"
            )
        , onClick (config.onToggle p word)
        ]
        [ text (word |> String.replace "-" " ") ]



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
