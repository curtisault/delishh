module GroceryListTests exposing (suite)

{-| The shopping list, and the four ways it could quietly be wrong.

A wrong recipe page is read at a bench, beside the thing it describes,
by somebody who can see that 4.5 eggs is not a number. A wrong
shopping list is read in a shop, with no recipe in front of you, and
every one of these failures looks exactly like a correct list:

  - **the same thing twice**, because two recipes spell it differently
  - **a number that was converted**, because two recipes measured it
    differently and something decided a cup of flour weighs 120 g
  - **a number rounded down**, sending you home one egg short
  - **a tick that survived** the recipe that put the row there

So the tests are about those, rather than about the functions.

-}

import Expect
import GroceryList exposing (Entry)
import Json.Decode as D
import Json.Encode as E
import Test exposing (Test, describe, test)



-- FIXTURES


{-| An entry with everything defaulted, so a test can set the one
field it is actually about.
-}
entry : String -> Entry
entry buyAs =
    { value = Just 1
    , max = Nothing
    , unit = Nothing
    , unitKind = Nothing
    , buyAs = buyAs
    , aisle = "produce"
    }


measured : String -> Float -> String -> String -> Entry
measured buyAs value unit kind =
    { value = Just value
    , max = Nothing
    , unit = Just unit
    , unitKind = Just kind
    , buyAs = buyAs
    , aisle = "produce"
    }


mass : String -> Float -> String -> Entry
mass buyAs value unit =
    measured buyAs value unit "mass"


volume : String -> Float -> String -> Entry
volume buyAs value unit =
    measured buyAs value unit "volume"


counted : String -> Float -> String -> Entry
counted buyAs value unit =
    measured buyAs value unit "count"


bare : String -> Float -> Entry
bare buyAs value =
    let
        base =
            entry buyAs
    in
    { base | value = Just value }


{-| A real thing to buy with no number on it — "flaky salt, to finish".
-}
unmeasured : String -> Entry
unmeasured buyAs =
    let
        base =
            entry buyAs
    in
    { base | value = Nothing }


inAisle : String -> String -> Entry
inAisle aisle buyAs =
    let
        base =
            entry buyAs
    in
    { base | aisle = aisle }


{-| The high end of a range — "2–3 cloves".
-}
upTo : Float -> Entry -> Entry
upTo high item =
    { item | max = Just high }


from : String -> Float -> List Entry -> GroceryList.Contribution
from slug factor items =
    { slug = slug, title = String.toUpper slug, factor = factor, items = items }


listOf : List GroceryList.Contribution -> GroceryList.Model
listOf =
    List.foldl GroceryList.toggle GroceryList.empty


{-| Every row on a list, both groups, as `name` → `quantity`.
-}
rows : GroceryList.Model -> List ( String, String )
rows model =
    let
        { toBuy, inCart } =
            GroceryList.lines model
    in
    (List.concatMap .items toBuy ++ inCart)
        |> List.map (\l -> ( l.name, l.quantity ))


quantityOf : String -> GroceryList.Model -> String
quantityOf name model =
    rows model
        |> List.filter (\( n, _ ) -> n == name)
        |> List.map Tuple.second
        |> String.join " AND ALSO "



-- THE SUITE


suite : Test
suite =
    describe "GroceryList"
        [ merging
        , kinds
        , roundingUp
        , grouping
        , ticking
        , storage
        , clearing
        ]


clearing : Test
clearing =
    describe "clearing takes two presses"
        [ test "the first press does not clear anything" <|
            \_ ->
                -- The whole point. This is the one irreversible thing
                -- on the page, pressed one-handed beside a trolley.
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.clearPress False
                    |> Tuple.first
                    |> rows
                    |> Expect.equal [ ( "potatoes", "4" ) ]
        , test "the first press arms it" <|
            \_ ->
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.clearPress False
                    |> Tuple.second
                    |> Expect.equal True
        , test "the second press clears" <|
            \_ ->
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.clearPress True
                    |> Tuple.first
                    |> GroceryList.isEmpty
                    |> Expect.equal True
        , test "and disarms, so a third press cannot clear again" <|
            \_ ->
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.clearPress True
                    |> Tuple.second
                    |> Expect.equal False
        , test "clearing takes the ticks with it" <|
            \_ ->
                -- A tick is a fact about a row, and there are no rows.
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.check "potatoes"
                    |> GroceryList.clearPress True
                    |> Tuple.first
                    |> GroceryList.lines
                    |> Expect.equal { toBuy = [], inCart = [] }
        , test "a cleared list forgets which recipes made it" <|
            \_ ->
                listOf [ from "lasagna" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.clearPress True
                    |> Tuple.first
                    |> GroceryList.member "lasagna"
                    |> Expect.equal False
        , test "a cleared list stores nothing to come back from" <|
            \_ ->
                -- boot.js removes the key outright when there are no
                -- contributions, which is what the colophon promises.
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.clearPress True
                    |> Tuple.first
                    |> GroceryList.encode
                    |> E.encode 0
                    |> D.decodeString
                        (D.field "contributions" (D.list (D.succeed ())))
                    |> Expect.equal (Ok [])
        ]


merging : Test
merging =
    describe "one thing to buy is one row"
        [ test "two recipes wanting the same purchase make one row" <|
            \_ ->
                listOf
                    [ from "a" 1 [ bare "potatoes" 4 ]
                    , from "b" 1 [ bare "potatoes" 2 ]
                    ]
                    |> rows
                    |> Expect.equal [ ( "potatoes", "6" ) ]
        , test "the purchase name is what merges, not the recipe's words" <|
            \_ ->
                -- The build has already resolved "yellow onion" and
                -- "yellow onions" to one `buyAs`; this is the half of
                -- that contract this module is responsible for.
                listOf
                    [ from "a" 1 [ bare "yellow onions" 1 ]
                    , from "b" 1 [ bare "yellow onions" 2 ]
                    ]
                    |> rows
                    |> Expect.equal [ ( "yellow onions", "3" ) ]
        , test "the factor a recipe went on at is applied" <|
            \_ ->
                listOf [ from "a" 2 [ mass "flour" 250 "g" ] ]
                    |> quantityOf "flour"
                    |> Expect.equal "500 g"
        , test "taking a recipe off subtracts only its share" <|
            \_ ->
                let
                    both =
                        listOf
                            [ from "a" 1 [ bare "potatoes" 4 ]
                            , from "b" 1 [ bare "potatoes" 2 ]
                            ]
                in
                both
                    |> GroceryList.toggle (from "b" 1 [ bare "potatoes" 2 ])
                    |> rows
                    |> Expect.equal [ ( "potatoes", "4" ) ]
        , test "adding the same recipe twice cannot double it" <|
            \_ ->
                let
                    once =
                        from "a" 1 [ bare "potatoes" 4 ]
                in
                listOf [ once, once, once ]
                    |> rows
                    |> Expect.equal [ ( "potatoes", "4" ) ]
        , test "removing a recipe by slug takes only its share" <|
            \_ ->
                listOf
                    [ from "a" 1 [ bare "potatoes" 4 ]
                    , from "b" 1 [ bare "potatoes" 2 ]
                    ]
                    |> GroceryList.remove "b"
                    |> rows
                    |> Expect.equal [ ( "potatoes", "4" ) ]
        , test "removing a recipe that is not on the list changes nothing" <|
            \_ ->
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.remove "never-added"
                    |> rows
                    |> Expect.equal [ ( "potatoes", "4" ) ]
        , test "removing the last recipe empties the list" <|
            \_ ->
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.remove "a"
                    |> GroceryList.isEmpty
                    |> Expect.equal True
        , test "removing a recipe leaves the other recipes' ticks alone" <|
            \_ ->
                listOf
                    [ from "a" 1 [ bare "potatoes" 4 ]
                    , from "b" 1 [ bare "carrots" 2 ]
                    ]
                    |> GroceryList.check "potatoes"
                    |> GroceryList.remove "b"
                    |> GroceryList.lines
                    |> .inCart
                    |> List.map .name
                    |> Expect.equal [ "potatoes" ]
        , test "a purchase with no number is still a row" <|
            \_ ->
                -- "flaky salt, to finish" is a real thing to buy.
                listOf [ from "a" 1 [ unmeasured "flaky salt" ] ]
                    |> rows
                    |> Expect.equal [ ( "flaky salt", "" ) ]
        , test "an ingredient the build did not place never arrives" <|
            \_ ->
                -- `fromRecipe` drops these; nothing downstream has to
                -- know that tap water is not shopping.
                listOf [ from "a" 1 [] ]
                    |> rows
                    |> Expect.equal []
        ]


kinds : Test
kinds =
    describe "what sums, and what refuses to"
        [ test "grams and kilograms meet in grams" <|
            \_ ->
                listOf
                    [ from "a" 1 [ mass "flour" 500 "g" ]
                    , from "b" 1 [ mass "flour" 1 "kg" ]
                    ]
                    |> quantityOf "flour"
                    |> Expect.equal "1500 g"
        , test "spoons and cups meet in millilitres" <|
            \_ ->
                listOf
                    [ from "a" 1 [ volume "milk" 1 "cup" ]
                    , from "b" 1 [ volume "milk" 2 "tbsp" ]
                    ]
                    |> quantityOf "milk"
                    |> Expect.equal "270 ml"
        , test "a unit everybody agreed on survives" <|
            \_ ->
                -- The ×1-identity instinct: nobody needed this
                -- converted, so nothing converts it. A list that
                -- answered "480 ml" here would be changing the
                -- subject.
                listOf
                    [ from "a" 1 [ volume "chicken broth" 1 "cup" ]
                    , from "b" 1 [ volume "chicken broth" 1 "cup" ]
                    ]
                    |> quantityOf "chicken broth"
                    |> Expect.equal "2 cups"
        , test "one cup stays one cup, singular" <|
            \_ ->
                listOf [ from "a" 1 [ volume "chicken broth" 1 "cup" ] ]
                    |> quantityOf "chicken broth"
                    |> Expect.equal "1 cup"
        , test "mass and volume of one thing sit side by side" <|
            \_ ->
                -- THE test. A cup of flour weighs what it weighs on
                -- the day, and the archive does not know what day it
                -- is. One row, two numbers, no invented conversion.
                listOf
                    [ from "a" 1 [ mass "flour" 500 "g" ]
                    , from "b" 1 [ volume "flour" 2 "cup" ]
                    ]
                    |> quantityOf "flour"
                    |> Expect.equal "500 g + 2 cups"
        , test "the order of the halves does not depend on who was added first" <|
            \_ ->
                listOf
                    [ from "b" 1 [ volume "flour" 2 "cup" ]
                    , from "a" 1 [ mass "flour" 500 "g" ]
                    ]
                    |> quantityOf "flour"
                    |> Expect.equal "500 g + 2 cups"
        , test "two count units of one thing never sum" <|
            \_ ->
                -- Two cloves and a head of garlic are both garlic and
                -- neither is the other; they are two things to pick up.
                listOf
                    [ from "a" 1 [ counted "garlic" 2 "clove" ]
                    , from "b" 1 [ counted "garlic" 1 "head" ]
                    ]
                    |> quantityOf "garlic"
                    |> Expect.equal "2 cloves + 1 head"
        , test "the same count unit does sum, and pluralises" <|
            \_ ->
                listOf
                    [ from "a" 1 [ counted "garlic" 2 "clove" ]
                    , from "b" 1 [ counted "garlic" 3 "clove" ]
                    ]
                    |> quantityOf "garlic"
                    |> Expect.equal "5 cloves"
        , test "a bare count is its own bucket beside a measured one" <|
            \_ ->
                listOf
                    [ from "a" 1 [ counted "lemons" 2 "slice" ]
                    , from "b" 1 [ bare "lemons" 1 ]
                    ]
                    |> quantityOf "lemons"
                    |> Expect.equal "2 slices + 1"
        ]


roundingUp : Test
roundingUp =
    describe "a shop rounds up, and never to nothing"
        [ test "half an egg is one egg" <|
            \_ ->
                listOf [ from "a" 0.5 [ bare "large eggs" 1 ] ]
                    |> quantityOf "large eggs"
                    |> Expect.equal "1"
        , test "two and a half eggs is three" <|
            \_ ->
                listOf [ from "a" 0.5 [ bare "large eggs" 5 ] ]
                    |> quantityOf "large eggs"
                    |> Expect.equal "3"
        , test "a whole number of eggs is not nudged to the next one" <|
            \_ ->
                -- Float sums land just under the integer often enough
                -- that a bare ceiling would put four eggs on a list
                -- that wanted three.
                listOf
                    [ from "a" 1 [ bare "large eggs" 1 ]
                    , from "b" 1 [ bare "large eggs" 1 ]
                    , from "c" 1 [ bare "large eggs" 1 ]
                    ]
                    |> quantityOf "large eggs"
                    |> Expect.equal "3"
        , test "a third of a batch still buys the ingredient" <|
            \_ ->
                listOf [ from "a" 0.5 [ mass "flaky salt" 1 "g" ] ]
                    |> quantityOf "flaky salt"
                    |> Expect.equal "1 g"
        , test "a range asks for its high end" <|
            \_ ->
                listOf
                    [ from "a" 1 [ upTo 3 (counted "garlic" 2 "clove") ] ]
                    |> quantityOf "garlic"
                    |> Expect.equal "3 cloves"
        , test "grams above a hundred step by five, upward" <|
            \_ ->
                listOf [ from "a" 1 [ mass "flour" 287 "g" ] ]
                    |> quantityOf "flour"
                    |> Expect.equal "290 g"
        , test "grams below a hundred keep their gram" <|
            \_ ->
                listOf [ from "a" 1 [ mass "cocoa powder" 12 "g" ] ]
                    |> quantityOf "cocoa powder"
                    |> Expect.equal "12 g"
        , test "a part of a cup is a glyph, never a decimal" <|
            \_ ->
                listOf
                    [ from "a" 1 [ volume "buttermilk" 1 "cup" ]
                    , from "b" 0.5 [ volume "buttermilk" 1 "cup" ]
                    ]
                    |> quantityOf "buttermilk"
                    |> Expect.equal "1½ cups"
        , test "a part of a cup rounds up to the next quarter" <|
            \_ ->
                listOf [ from "a" 1 [ volume "buttermilk" 0.6 "cup" ] ]
                    |> quantityOf "buttermilk"
                    |> Expect.equal "¾ cup"
        , test "kilograms keep their decimal rather than becoming grams" <|
            \_ ->
                listOf [ from "a" 1.5 [ mass "yellow onions" 1 "kg" ] ]
                    |> quantityOf "yellow onions"
                    |> Expect.equal "1.5 kg"
        ]


grouping : Test
grouping =
    describe "the list is a walk through a shop"
        [ test "aisles come in walk order, not alphabetically" <|
            \_ ->
                listOf
                    [ from "a"
                        1
                        [ inAisle "frozen" "vanilla ice cream"
                        , inAisle "produce" "carrots"
                        , inAisle "spices" "salt"
                        ]
                    ]
                    |> GroceryList.lines
                    |> .toBuy
                    |> List.map .aisle
                    |> Expect.equal [ "produce", "spices", "frozen" ]
        , test "an aisle nothing is bought in has no heading" <|
            \_ ->
                listOf [ from "a" 1 [ inAisle "produce" "carrots" ] ]
                    |> GroceryList.lines
                    |> .toBuy
                    |> List.length
                    |> Expect.equal 1
        , test "every group carries the words to print above it" <|
            \_ ->
                listOf [ from "a" 1 [ inAisle "dairy" "milk" ] ]
                    |> GroceryList.lines
                    |> .toBuy
                    |> List.map .label
                    |> Expect.equal [ "Dairy & eggs" ]
        , test "rows inside an aisle are in a stable order" <|
            \_ ->
                listOf
                    [ from "a" 1 [ entry "scallions", entry "carrots" ] ]
                    |> GroceryList.lines
                    |> .toBuy
                    |> List.concatMap (.items >> List.map .name)
                    |> Expect.equal [ "carrots", "scallions" ]
        , test "an empty list has nothing in either group" <|
            \_ ->
                GroceryList.empty
                    |> GroceryList.lines
                    |> Expect.equal { toBuy = [], inCart = [] }
        ]


ticking : Test
ticking =
    describe "in the cart"
        [ test "a ticked row leaves its aisle for the cart" <|
            \_ ->
                listOf [ from "a" 1 [ entry "carrots", entry "scallions" ] ]
                    |> GroceryList.check "carrots"
                    |> GroceryList.lines
                    |> (\{ toBuy, inCart } ->
                            ( List.concatMap (.items >> List.map .name) toBuy
                            , List.map .name inCart
                            )
                       )
                    |> Expect.equal ( [ "scallions" ], [ "carrots" ] )
        , test "a ticked row keeps its quantity — you re-read it at the till" <|
            \_ ->
                listOf [ from "a" 1 [ bare "potatoes" 4 ] ]
                    |> GroceryList.check "potatoes"
                    |> GroceryList.lines
                    |> .inCart
                    |> List.map .quantity
                    |> Expect.equal [ "4" ]
        , test "ticking twice puts it back in the aisle" <|
            \_ ->
                listOf [ from "a" 1 [ entry "carrots" ] ]
                    |> GroceryList.check "carrots"
                    |> GroceryList.check "carrots"
                    |> GroceryList.lines
                    |> .inCart
                    |> Expect.equal []
        , test "a tick is a property of the row, not of the recipe" <|
            \_ ->
                -- Two recipes want carrots; ticking the row ticks the
                -- row, and removing one recipe leaves it ticked.
                listOf
                    [ from "a" 1 [ bare "carrots" 2 ]
                    , from "b" 1 [ bare "carrots" 3 ]
                    ]
                    |> GroceryList.check "carrots"
                    |> GroceryList.toggle (from "b" 1 [ bare "carrots" 3 ])
                    |> GroceryList.lines
                    |> .inCart
                    |> List.map (\l -> ( l.name, l.quantity ))
                    |> Expect.equal [ ( "carrots", "2" ) ]
        ]


storage : Test
storage =
    describe "what survives a reload"
        [ test "a list round-trips through storage unchanged" <|
            \_ ->
                let
                    original =
                        listOf
                            [ from "a" 2 [ mass "flour" 500 "g", bare "potatoes" 4 ]
                            , from "b" 1 [ volume "flour" 2 "cup" ]
                            ]
                            |> GroceryList.check "potatoes"
                in
                GroceryList.encode original
                    |> E.encode 0
                    |> D.decodeString GroceryList.decoder
                    |> Result.map rows
                    |> Expect.equal (Ok (rows original))
        , test "the ticks round-trip too" <|
            \_ ->
                let
                    original =
                        listOf [ from "a" 1 [ entry "carrots", entry "scallions" ] ]
                            |> GroceryList.check "carrots"
                in
                GroceryList.encode original
                    |> E.encode 0
                    |> D.decodeString GroceryList.decoder
                    |> Result.map (GroceryList.lines >> .inCart >> List.map .name)
                    |> Expect.equal (Ok [ "carrots" ])
        , test "which recipes are on it round-trips" <|
            \_ ->
                listOf [ from "lasagna" 2 [ bare "potatoes" 1 ] ]
                    |> GroceryList.encode
                    |> E.encode 0
                    |> D.decodeString GroceryList.decoder
                    |> Result.map (GroceryList.member "lasagna")
                    |> Expect.equal (Ok True)
        , test "a tick with no row left is not written back" <|
            \_ ->
                -- Take the last recipe that wanted carrots off the
                -- list, and carrots should not come back ticked.
                listOf [ from "a" 1 [ entry "carrots" ] ]
                    |> GroceryList.check "carrots"
                    |> GroceryList.toggle (from "a" 1 [ entry "carrots" ])
                    |> GroceryList.encode
                    |> E.encode 0
                    |> D.decodeString (D.field "checked" (D.list D.string))
                    |> Expect.equal (Ok [])
        , test "garbage does not decode" <|
            \_ ->
                "{\"nonsense\":true}"
                    |> D.decodeString GroceryList.decoder
                    |> Result.toMaybe
                    |> Expect.equal Nothing
        , test "a list from another build's schema does not decode" <|
            \_ ->
                -- The caller degrades to an empty list. Losing a
                -- shopping list is an afternoon; a shell that will not
                -- boot is the product.
                "{\"v\":99,\"contributions\":[],\"checked\":[]}"
                    |> D.decodeString GroceryList.decoder
                    |> Result.toMaybe
                    |> Expect.equal Nothing
        , test "an empty list is empty, and says so" <|
            \_ ->
                GroceryList.empty
                    |> GroceryList.isEmpty
                    |> Expect.equal True
        ]
