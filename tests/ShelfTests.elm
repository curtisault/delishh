module ShelfTests exposing (suite)

{-| The shelf's two refusals — DS-01 §07.

**Filters narrow; they never silently hide.** The whole point of
`judge` returning a `Verdict` rather than a filtered list is that an
excluded recipe stays on the page wearing the reason. A test that
only checked "the right things survive" would pass just as happily
against an implementation that threw the rest away — so these check
the *reasons* too.

**A dead end is a design failure.** Zero results always has somewhere
to go.

-}

import Expect
import Shelf exposing (Verdict(..))
import Test exposing (Test, describe, test)


recipe : String -> Shelf.Summary
recipe slug =
    { slug = slug
    , title = slug
    , tested = "2026-01-01"
    , active = 10
    , total = 20
    , slot = [ "dinner" ]
    , course = "main"
    , flavor = [ { name = "savory", level = Nothing } ]
    , method = "bake"
    , effort = "relaxed"
    , dietary = [ "vegetarian" ]
    , cuisine = []
    , keepsFor = Nothing
    , inspired = Nothing
    }


caramel : Shelf.Summary
caramel =
    { slug = "salted-caramel"
    , title = "Salted Caramel"
    , tested = "2026-03-11"
    , active = 15
    , total = 45
    , slot = [ "dessert" ]
    , course = "sauce"
    , flavor = [ { name = "sweet", level = Just 3 }, { name = "salty", level = Nothing } ]
    , method = "sugar-work"
    , effort = "focused"
    , dietary = [ "vegetarian", "gluten-free" ]
    , cuisine = []
    , keepsFor = Just { where_ = "fridge", amount = 14, unit = "d" }
    , inspired = Nothing
    }


pickles : Shelf.Summary
pickles =
    { slug = "fridge-pickles"
    , title = "Fridge Pickles"
    , tested = "2026-08-02"
    , active = 20
    , total = 2880
    , slot = [ "lunch", "dinner" ]
    , course = "side"
    , flavor = [ { name = "tangy", level = Just 2 }, { name = "salty", level = Just 1 } ]
    , method = "pickle"
    , effort = "relaxed"
    , dietary = [ "vegan", "gluten-free" ]
    , cuisine = []
    , keepsFor = Nothing
    , inspired = Nothing
    }


corpus : List Shelf.Summary
corpus =
    [ caramel, pickles ]


with : Shelf.Path -> String -> Shelf.Filters
with p value =
    Shelf.toggle p value Shelf.noFilters


suite : Test
suite =
    describe "Shelf"
        [ describe "no filters means no filtering"
            [ test "everything is shown" <|
                \_ ->
                    List.map (Shelf.judge Shelf.noFilters) corpus
                        |> Expect.equal [ Shown, Shown ]
            , test "a path with nothing selected excludes nothing" <|
                \_ ->
                    -- The empty set must read as "not used", never as
                    -- "match nothing" — the difference between a shelf
                    -- that opens full and one that opens empty.
                    Shelf.judge Shelf.noFilters caramel |> Expect.equal Shown
            ]
        , describe "a filter excludes, and says which one did"
            [ test "the match survives" <|
                \_ ->
                    Shelf.judge (with Shelf.ByFlavor "sweet") caramel
                        |> Expect.equal Shown
            , test "the miss is excluded BY NAME, not dropped" <|
                \_ ->
                    -- If this ever returns `Excluded []` the row loses
                    -- its lockout tag and the reader cannot tell why
                    -- the list shrank.
                    Shelf.judge (with Shelf.ByFlavor "sweet") pickles
                        |> Expect.equal (Excluded [ Shelf.ByFlavor ])
            , test "every recipe is still in the ranked list" <|
                \_ ->
                    -- The list never gets shorter. That is the rule.
                    Shelf.ranked (with Shelf.ByFlavor "sweet") corpus
                        |> List.length
                        |> Expect.equal 2
            ]
        , describe "selections within a path widen, across paths narrow"
            [ test "two values in one path keep both recipes" <|
                \_ ->
                    let
                        sweetOrTangy =
                            Shelf.toggle Shelf.ByFlavor "tangy" (with Shelf.ByFlavor "sweet")
                    in
                    List.map (Shelf.judge sweetOrTangy) corpus
                        |> Expect.equal [ Shown, Shown ]
            , test "one value in each of two paths keeps only the overlap" <|
                \_ ->
                    let
                        sweetAndRelaxed =
                            Shelf.toggle Shelf.ByEffort "relaxed" (with Shelf.ByFlavor "sweet")
                    in
                    -- Caramel is sweet but focused; pickles are relaxed
                    -- but not sweet. Nothing satisfies both.
                    List.map (Shelf.judge sweetAndRelaxed) corpus
                        |> Expect.equal
                            [ Excluded [ Shelf.ByEffort ], Excluded [ Shelf.ByFlavor ] ]
            , test "a recipe failing two paths names both" <|
                \_ ->
                    let
                        both =
                            Shelf.toggle Shelf.ByMeal "breakfast" (with Shelf.ByFlavor "sweet")
                    in
                    Shelf.judge both pickles
                        |> Expect.equal (Excluded [ Shelf.ByMeal, Shelf.ByFlavor ])
            ]
        , describe "a toggle is a toggle"
            [ test "off again clears it" <|
                \_ ->
                    Shelf.toggle Shelf.ByFlavor "sweet" (with Shelf.ByFlavor "sweet")
                        |> Shelf.active
                        |> Expect.equal []
            ]
        , describe "search"
            [ test "matches the title" <|
                \_ ->
                    Shelf.judge { noFilters | query = "caramel" } caramel
                        |> Expect.equal Shown
            , test "matches a facet the reader typed rather than clicked" <|
                \_ ->
                    Shelf.judge { noFilters | query = "vegan" } pickles
                        |> Expect.equal Shown
            , test "a second word narrows rather than widens" <|
                \_ ->
                    Shelf.judge { noFilters | query = "caramel pickle" } caramel
                        |> Expect.equal (Excluded [])
            , test "a search miss carries no path tag" <|
                \_ ->
                    -- The query is not one of the four paths, and
                    -- tagging a row "hidden by By flavour" when the
                    -- reader is mid-word would be a lie.
                    Shelf.judge { noFilters | query = "zzzq" } caramel
                        |> Expect.equal (Excluded [])
            , test "a stray single character does not empty the shelf" <|
                \_ ->
                    Shelf.judge { noFilters | query = "caramel x" } caramel
                        |> Expect.equal Shown
            , test "matches the attribution, which the row does not draw" <|
                \_ ->
                    -- The restaurant's name is how a reader remembers
                    -- the dish (docs/decisions.md, 2026-10-04).
                    Shelf.judge { noFilters | query = "corner bakery" }
                        { caramel | inspired = Just "The Corner Bakery" }
                        |> Expect.equal Shown
            , test "an absent attribution matches nothing" <|
                \_ ->
                    Shelf.judge { noFilters | query = "corner" } caramel
                        |> Expect.equal (Excluded [])
            ]
        , describe "order"
            [ test "default sort is last tested, newest first" <|
                \_ ->
                    -- The archive's own working order beats the
                    -- dictionary's (DS-01 §07).
                    Shelf.ranked Shelf.noFilters corpus
                        |> List.map (Tuple.first >> .slug)
                        |> Expect.equal [ "fridge-pickles", "salted-caramel" ]
            , test "shown rows come before excluded ones" <|
                \_ ->
                    -- Pickles are newer, so only the filter can put
                    -- caramel first.
                    Shelf.ranked (with Shelf.ByFlavor "sweet") corpus
                        |> List.map (Tuple.first >> .slug)
                        |> Expect.equal [ "salted-caramel", "fridge-pickles" ]
            ]
        , describe "a dead end always has somewhere to go"
            [ test "zero results still offers a nearest recipe" <|
                \_ ->
                    Shelf.nearestByTime (with Shelf.ByMeal "breakfast") corpus
                        |> Maybe.map .slug
                        |> Expect.notEqual Nothing
            , test "an empty archive offers nothing, rather than crashing" <|
                \_ ->
                    Shelf.nearestByTime Shelf.noFilters []
                        |> Expect.equal Nothing
            , test "nearest means nearest by total, not by active" <|
                \_ ->
                    -- Pickles are 20 min active and two days total. A
                    -- reader asking for something quick is asking
                    -- about the total, which is the whole reason both
                    -- are carried.
                    Shelf.nearestByTime Shelf.noFilters corpus
                        |> Maybe.map .slug
                        |> Expect.equal (Just "salted-caramel")
            ]
        , describe "clearing"
            [ test "drops every path at once" <|
                \_ ->
                    Shelf.toggle Shelf.ByMeal "dinner" (with Shelf.ByFlavor "sweet")
                        |> Shelf.clear
                        |> Shelf.active
                        |> Expect.equal []
            ]
        , describe "the paths cover the vocabulary they offer"
            [ test "each facet path reads a facet every recipe carries" <|
                \_ ->
                    -- The place path is the exception on purpose: an
                    -- attribution is optional, and a recipe with none
                    -- carries nothing for it (below).
                    Shelf.paths
                        |> List.filter (\p -> p /= Shelf.ByPlace)
                        |> List.filter (\p -> List.isEmpty (Shelf.facetsOf p (recipe "x")))
                        |> Expect.equal []
            ]
        , describe "the fifth path — inspired by (DS-01 §07, amended 2026-10-04)"
            [ test "a place keeps the recipe after it" <|
                \_ ->
                    Shelf.judge (with Shelf.ByPlace "The Corner Bakery")
                        { caramel | inspired = Just "The Corner Bakery" }
                        |> Expect.equal Shown
            , test "a recipe after nowhere is excluded by name, not dropped" <|
                \_ ->
                    -- Nothing is inferred to fill the gap: the row
                    -- stays, wearing "Hidden by place".
                    Shelf.judge (with Shelf.ByPlace "The Corner Bakery") pickles
                        |> Expect.equal (Excluded [ Shelf.ByPlace ])
            , test "the name matches exactly as authored" <|
                \_ ->
                    Shelf.judge (with Shelf.ByPlace "Corner Bakery")
                        { caramel | inspired = Just "The Corner Bakery" }
                        |> Expect.equal (Excluded [ Shelf.ByPlace ])
            , test "the tile and the lockout tag use different words" <|
                \_ ->
                    -- "Hidden by Inspired by" is the sentence this
                    -- rule exists to prevent.
                    ( Shelf.pathLabel Shelf.ByPlace, Shelf.pathNoun Shelf.ByPlace )
                        |> Expect.equal ( "Inspired by", "place" )
            ]
        , describe "marking where the query landed"
            [ test "a match is cut out of the text, in the text's own case" <|
                \_ ->
                    Shelf.marks "caram" "Salted Caramel"
                        |> Expect.equal
                            [ ( "Salted ", False ), ( "Caram", True ), ( "el", False ) ]
            , test "an empty query marks nothing, and does not shred the text" <|
                \_ ->
                    Shelf.marks "" "Salted Caramel"
                        |> Expect.equal [ ( "Salted Caramel", False ) ]
            , test "a one-letter query marks nothing, as it also filters nothing" <|
                \_ ->
                    -- The mark reads the same `needles` the judgement
                    -- does. If it did not, a single letter would fill
                    -- half the archive while narrowing none of it.
                    Shelf.marks "a" "Salted Caramel"
                        |> Expect.equal [ ( "Salted Caramel", False ) ]
            , test "every word of the query is marked, wherever it fell" <|
                \_ ->
                    Shelf.marks "salt car" "Salted Caramel"
                        |> Expect.equal
                            [ ( "Salt", True )
                            , ( "ed ", False )
                            , ( "Car", True )
                            , ( "amel", False )
                            ]
            , test "overlapping words make one run, not two marks touching" <|
                \_ ->
                    Shelf.marks "cara aram" "Caramel"
                        |> Expect.equal [ ( "Caram", True ), ( "el", False ) ]
            , test "a match that covers the whole text is one run" <|
                \_ ->
                    Shelf.marks "bake" "BAKE"
                        |> Expect.equal [ ( "BAKE", True ) ]
            , test "empty text is no runs at all" <|
                \_ ->
                    Shelf.marks "caram" ""
                        |> Expect.equal []
            , test "a query that is nowhere in the text leaves it whole" <|
                \_ ->
                    -- The query matched some facet the row does not
                    -- print. There is nothing here to point at, and
                    -- pointing anyway would be the lie.
                    Shelf.marks "vegan" "Salted Caramel"
                        |> Expect.equal [ ( "Salted Caramel", False ) ]
            ]
        ]


noFilters : Shelf.Filters
noFilters =
    Shelf.noFilters
