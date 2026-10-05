module ShelfPageTests exposing (suite)

{-| The shelf's query line — DS-01 §07, and the clear ruled
2026-10-05 (docs/decisions.md).

The clear is always in the line and hidden by visibility while the
query is empty, so the field never changes width when the word
appears. These hold the markup's half of that: the class the CSS
keys off, and that a hidden clear is out of the tab order and the
accessibility tree, since a control a sighted reader cannot see is
not one a screen reader should be offered.

-}

import Expect
import Html.Attributes as Attr
import Install
import Page.Shelf
import Set
import Shelf
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


index : Shelf.Index
index =
    { vocabulary = []
    , recipes =
        [ { slug = "cornbread"
          , title = "Cornbread"
          , tested = "2026-01-01"
          , active = 10
          , total = 30
          , slot = [ "dinner" ]
          , course = "side"
          , flavor = [ { name = "savory", level = Nothing } ]
          , method = "bake"
          , effort = "relaxed"
          , dietary = [ "vegetarian" ]
          , cuisine = []
          , keepsFor = Nothing
          , inspired = Nothing
          }
        ]
    }


{-| The shelf with this query typed and nothing else set.
-}
withQuery : String -> Query.Single ()
withQuery q =
    Query.fromHtml
        (Page.Shelf.view
            { index = index
            , filters = (\f -> { f | query = q }) Shelf.noFilters
            , console = False
            , unfolded = Set.empty
            , onConsole = ()
            , onUnfold = always ()
            , onToggle = \_ _ -> ()
            , onQuery = always ()
            , onClearQuery = ()
            , onClear = ()
            , install = Install.NoOffer
            , installHelp = False
            , onInstall = ()
            }
        )


suite : Test
suite =
    describe "the query line's clear"
        [ test "it is a button inside the line, not a link" <|
            \_ ->
                withQuery "corn"
                    |> Query.find [ Selector.class "query-line" ]
                    |> Query.find [ Selector.class "query-clear" ]
                    |> Query.has [ Selector.tag "button", Selector.attribute (Attr.type_ "button") ]
        , test "it says the word" <|
            \_ ->
                withQuery "corn"
                    |> Query.find [ Selector.class "query-clear" ]
                    |> Query.has [ Selector.text "Clear" ]
        , test "with a query, it is reachable and the line is not marked empty" <|
            \_ ->
                withQuery "corn"
                    |> Expect.all
                        [ Query.find [ Selector.class "query-clear" ]
                            >> Query.has
                                [ Selector.attribute (Attr.tabindex 0)
                                , Selector.attribute (Attr.attribute "aria-hidden" "false")
                                ]
                        , Query.find [ Selector.class "query-line" ]
                            >> Query.hasNot [ Selector.class "is-empty" ]
                        ]
        , test "with no query, it is still in the line but out of reach" <|
            \_ ->
                -- Hidden by visibility, so the field keeps its width;
                -- and out of the tab order, so a keyboard never lands
                -- on a word it cannot see.
                withQuery ""
                    |> Expect.all
                        [ Query.find [ Selector.class "query-clear" ]
                            >> Query.has
                                [ Selector.attribute (Attr.tabindex -1)
                                , Selector.attribute (Attr.attribute "aria-hidden" "true")
                                ]
                        , Query.find [ Selector.class "query-line" ]
                            >> Query.has [ Selector.class "is-empty" ]
                        ]
        ]
