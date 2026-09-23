module LinerTests exposing (suite)

{-| The backing paper — DS-01 §04 as amended 2026-09-23.

Two things that can be wrong without looking wrong on the page you
happen to be looking at: the liner reaching cook mode (the one
surface it is barred from), and two different pages sharing a leaf
key, which would let a navigation arrive without the leaf landing.

-}

import Expect
import Html.Attributes as Attr
import Liner
import Route exposing (Route(..))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


everyRoute : List Route
everyRoute =
    [ Home, About, DesignStandard, Recipe "bench", Cook "bench", ShoppingList ]


suite : Test
suite =
    describe "Liner"
        [ describe "on"
            [ test "cook mode has no liner" <|
                \_ -> Liner.on (Cook "bench") |> Expect.equal False
            , test "every other route is laid on it" <|
                \_ ->
                    everyRoute
                        |> List.filter (\r -> r /= Cook "bench")
                        |> List.all Liner.on
                        |> Expect.equal True
            ]
        , describe "leafKey"
            [ test "no two routes share a leaf" <|
                \_ ->
                    List.map Liner.leafKey everyRoute
                        |> (\keys -> List.length keys == List.length (dedupe keys))
                        |> Expect.equal True
            , test "two recipes are two leaves" <|
                \_ ->
                    Liner.leafKey (Recipe "a")
                        |> Expect.notEqual (Liner.leafKey (Recipe "b"))
            , test "a recipe and its cook mode are two leaves" <|
                \_ ->
                    Liner.leafKey (Recipe "a")
                        |> Expect.notEqual (Liner.leafKey (Cook "a"))
            ]
        , describe "view"
            [ test "is hidden from assistive technology" <|
                \_ ->
                    Liner.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Attr.attribute "aria-hidden" "true") ]
            , test "holds no text of its own" <|
                \_ ->
                    Liner.view
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.text "delishh" ]
            ]
        ]


dedupe : List String -> List String
dedupe =
    List.foldl
        (\k acc ->
            if List.member k acc then
                acc

            else
                k :: acc
        )
        []
