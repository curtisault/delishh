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

import Html exposing (Html, a, div, h1, h2, input, li, p, section, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, id, placeholder, type_, value)
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
    div [ class "shelf-layout" ] [ div [ class "shelf" ] body ]



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
        [ div [ class "shelf" ]
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
                    " recipe, newest test first."

                 else
                    " recipes, newest test first."
                )
            ]
        , div [ class "shelf-search" ]
            [ input
                [ type_ "search"
                , class "shelf-query mono"
                , placeholder "Search the archive"
                , value config.filters.query
                , attribute "aria-label" "Search recipes"
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
            , class ("path-tile path-" ++ Shelf.path p)
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
        , class ("chip chip-" ++ Shelf.path p ++ " u")
        , classList [ ( "on", on ) ]
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
                            , class "active-clear u"
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
            , ul [ class "row-list" ] (List.map row rows)
            ]
        )


{-| One row. Dense and scannable — the shelf is used for retrieval,
and retrieval wants text you can run your eye down.

An excluded row is **tagged, not removed**: struck through, carrying
the filter that excluded it, and still a link. It is the difference
between "this is not what you asked for" and "this does not exist".

-}
row : ( Summary, Verdict ) -> Html msg
row ( recipe, verdict ) =
    let
        excluded =
            verdict /= Shown
    in
    li [ class "row", classList [ ( "is-excluded", excluded ) ] ]
        [ a [ class "row-link", href ("/recipe/" ++ recipe.slug) ]
            [ span [ class "row-no mono" ] [ text ("Nº " ++ String.fromInt recipe.number) ]
            , span [ class "row-title" ] [ text recipe.title ]
            , span [ class "row-chips" ]
                (List.map
                    (\f -> span [ class "chip chip-flavor u" ] [ text f ])
                    recipe.flavor
                )
            , span [ class "row-times mono" ]
                [ span [ class "row-active" ] [ text (minutes recipe.active) ]
                , span [ class "row-sep" ] [ text " · " ]

                -- Both, always. A twelve-hour cure is not a
                -- twenty-minute recipe, and collapsing the two is the
                -- most common lie in recipe software (DS-01 §07).
                , span [ class "row-total" ] [ text (minutes recipe.total ++ " total") ]
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
                            [ text ("Nº " ++ String.fromInt near.number) ]
                        , span [ class "row-title" ] [ text near.title ]
                        , span [ class "row-times mono" ]
                            [ text (minutes near.total ++ " total") ]
                        ]
                    ]

            Nothing ->
                p [ class "zero-lead" ] [ text "The archive is empty." ]
        , Html.button
            [ type_ "button", class "zero-clear u", onClick config.onClear ]
            [ text "Clear the filters" ]
        ]
