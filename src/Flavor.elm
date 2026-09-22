module Flavor exposing (Flavor, chip, decoder)

{-| A flavour, and how loudly it speaks — DS-01 §06, amended
2026-09-21.

`level` is the author's judgement (1 background · 2 present ·
3 defining), or `Nothing` when unstated. **Never zero.** An absent
level is a judgement not yet made — the same contract as an absent
dietary flag — and the meter draws only what has actually been
judged, because nothing is ever inferred.

The chip is one view shared by the recipe plate and the shelf's
rows: two renderings of the same mark are two meters that drift.
The stencil before the word is CSS (`.chip.f-*` carries a mask in
`sheet.css`) — this module emits words and class names and draws
nothing, which is the same division of labour as `Prose`.

-}

import Html exposing (Html, span, text)
import Html.Attributes exposing (attribute, class, classList)
import Json.Decode as D


type alias Flavor =
    { name : String
    , level : Maybe Int
    }


decoder : D.Decoder Flavor
decoder =
    D.map2 Flavor
        (D.field "name" D.string)
        (D.field "level" (D.nullable D.int))


{-| The word chip, with its meter when the level is stated.

The segments are marks for sighted readers and are hidden from
assistive tech; the level reaches a screen reader as words instead
(`.vh`), because "2 of 3" without "present" is a number with no
meaning. Unstated renders exactly what it renders today: the word.

-}
chip : String -> Flavor -> Html msg
chip kind f =
    span [ class ("chip " ++ kind ++ " u f-" ++ f.name) ]
        (text f.name :: meter f.level)


meter : Maybe Int -> List (Html msg)
meter level =
    case level of
        Nothing ->
            []

        Just n ->
            [ span
                [ class "chip-meter"
                , attribute "aria-hidden" "true"
                ]
                (List.map
                    (\i ->
                        span
                            [ classList
                                [ ( "chip-seg", True )
                                , ( "on", i <= n )
                                ]
                            ]
                            []
                    )
                    [ 1, 2, 3 ]
                )
            , span [ class "vh" ]
                [ text (" — " ++ levelWord n ++ ", " ++ String.fromInt n ++ " of 3") ]
            ]


{-| The three levels, in the contract's own words
(`content/recipes/AGENTS.md` § Flavour levels). A level outside the
build's 1–3 cannot arrive through the validator; rendering it as
"level N" rather than crashing keeps a hand-edited JSON from taking
the page down.
-}
levelWord : Int -> String
levelWord n =
    case n of
        1 ->
            "background"

        2 ->
            "present"

        3 ->
            "defining"

        _ ->
            "level " ++ String.fromInt n
