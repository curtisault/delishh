module GroceryListPageTests exposing (suite)

{-| The shopping list page — DS-01 §04, amended 2026-09-22.

`GroceryListTests` proves the arithmetic. This proves the three things
about the rendered page that no amount of correct arithmetic would
give you, and that a screenshot would not catch either:

**In the cart carries more than one signal.** The filled box is for an
eye, the hidden words are for a screen reader, and the line through
the name is decoration on top of both. Any one of them alone is the
failure §12 forbids.

**A ticked row keeps its words and its number.** It sinks; it is not
disabled, greyed past reading, or removed. You look down at it to
check whether you already got the butter, and you read the number
again at the till.

**The empty state is a way somewhere.** A page that tells you it has
nothing and stops is a dead end.

-}

import Expect
import GroceryList
import Html.Attributes as Attr
import Page.GroceryList
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector



-- FIXTURES


entry : String -> String -> Float -> GroceryList.Entry
entry buyAs aisle value =
    { value = Just value
    , max = Nothing
    , unit = Nothing
    , unitKind = Nothing
    , buyAs = buyAs
    , aisle = aisle
    }


{-| Two recipes, four rows, across two aisles.
-}
stocked : GroceryList.Model
stocked =
    GroceryList.empty
        |> GroceryList.toggle
            { slug = "lasagna"
            , title = "Classic lasagna"
            , factor = 2
            , items =
                [ entry "yellow onions" "produce" 1
                , entry "garlic" "produce" 2
                ]
            }
        |> GroceryList.toggle
            { slug = "chili"
            , title = "Beef chili"
            , factor = 1
            , items = [ entry "yellow onions" "produce" 1, entry "salt" "spices" 1 ]
            }


rendered : GroceryList.Model -> Query.Single ()
rendered list =
    Query.fromHtml
        (Page.GroceryList.view { list = list, onCheck = always () })


ticked : Query.Single ()
ticked =
    rendered (GroceryList.check "garlic" stocked)



-- THE SUITE


suite : Test
suite =
    describe "the shopping list page"
        [ describe "the standfirst counts what is LEFT"
            [ test "an untouched list counts every row" <|
                \_ ->
                    rendered stocked
                        |> Query.find [ Selector.class "list-standfirst" ]
                        |> Query.has [ Selector.text "3 things left to buy." ]
            , test "ticking something takes it out of the count" <|
                \_ ->
                    -- A standfirst that kept counting the cart would be
                    -- the page disagreeing with itself two inches down,
                    -- and this is the number you glance at to decide
                    -- whether you can leave.
                    ticked
                        |> Query.find [ Selector.class "list-standfirst" ]
                        |> Query.has [ Selector.text "2 things left to buy." ]
            , test "a finished shop says so" <|
                \_ ->
                    stocked
                        |> GroceryList.check "garlic"
                        |> GroceryList.check "yellow onions"
                        |> GroceryList.check "salt"
                        |> rendered
                        |> Query.find [ Selector.class "list-standfirst" ]
                        |> Query.has [ Selector.text "Everything is in the cart." ]
            , test "an empty list does not claim the cart is full" <|
                \_ ->
                    rendered GroceryList.empty
                        |> Query.find [ Selector.class "list-standfirst" ]
                        |> Query.has [ Selector.text "Nothing on it yet." ]
            ]
        , describe "the empty state"
            [ test "says how the list gets filled" <|
                \_ ->
                    rendered GroceryList.empty
                        |> Query.has [ Selector.text "Add to list" ]
            , test "offers a way back to the shelf rather than stopping" <|
                \_ ->
                    rendered GroceryList.empty
                        |> Query.find [ Selector.class "list-back" ]
                        |> Query.has
                            [ Selector.attribute (Attr.href "/") ]
            , test "has no aisles at all" <|
                \_ ->
                    rendered GroceryList.empty
                        |> Query.findAll [ Selector.class "list-aisle" ]
                        |> Query.count (Expect.equal 0)
            ]
        , describe "the rows"
            [ test "two recipes wanting one thing render one row" <|
                \_ ->
                    rendered stocked
                        |> Query.findAll [ Selector.class "list-name" ]
                        |> Query.count (Expect.equal 3)
            , test "an aisle heads its group with words" <|
                \_ ->
                    rendered stocked
                        |> Query.has [ Selector.text "Produce" ]
            , test "the quantity is on the row" <|
                \_ ->
                    -- Two onions at ×2 and one at ×1.
                    rendered stocked
                        |> Query.findAll [ Selector.class "list-qty" ]
                        |> Query.index 1
                        |> Query.has [ Selector.text "3" ]
            , test "every row is a control, not a checkbox glyph" <|
                \_ ->
                    -- A character checkbox is a font dependency, and
                    -- this one is drawn (§09).
                    rendered stocked
                        |> Query.findAll [ Selector.class "list-tick" ]
                        |> Query.count (Expect.equal 3)
            ]
        , describe "in the cart"
            [ test "a ticked row says so to a screen reader" <|
                \_ ->
                    ticked
                        |> Query.find [ Selector.id "in-cart" ]
                        |> Query.has [ Selector.text ", in cart" ]
            , test "and says so through aria-pressed" <|
                \_ ->
                    ticked
                        |> Query.find [ Selector.id "in-cart" ]
                        |> Query.find [ Selector.class "list-tick" ]
                        |> Query.has
                            [ Selector.attribute
                                (Attr.attribute "aria-pressed" "true")
                            ]
            , test "an unticked row does not" <|
                \_ ->
                    rendered stocked
                        |> Query.hasNot [ Selector.text ", in cart" ]
            , test "the cart is its own group at the end" <|
                \_ ->
                    ticked
                        |> Query.has [ Selector.id "in-cart" ]
            , test "a ticked row keeps its name readable" <|
                \_ ->
                    -- Struck, never removed and never hidden: you look
                    -- down to check you already got it.
                    ticked
                        |> Query.find [ Selector.id "in-cart" ]
                        |> Query.has [ Selector.text "garlic" ]
            , test "a ticked row keeps its quantity" <|
                \_ ->
                    ticked
                        |> Query.find [ Selector.id "in-cart" ]
                        |> Query.has [ Selector.class "list-qty" ]
            , test "nothing is in the cart until something is ticked" <|
                \_ ->
                    rendered stocked
                        |> Query.hasNot [ Selector.id "in-cart" ]
            ]
        , describe "where the list came from"
            [ test "each contributing recipe is named and linked" <|
                \_ ->
                    rendered stocked
                        |> Query.find [ Selector.class "list-sources" ]
                        |> Query.has [ Selector.text "Classic lasagna" ]
            , test "a scaled recipe says what scale it went on at" <|
                \_ ->
                    -- The list is a sum; the only way to read where a
                    -- number came from is to see what went into it.
                    rendered stocked
                        |> Query.find [ Selector.class "list-source-scale" ]
                        |> Query.has [ Selector.text "×2" ]
            , test "an unscaled recipe says nothing about scale" <|
                \_ ->
                    rendered stocked
                        |> Query.findAll [ Selector.class "list-source-scale" ]
                        |> Query.count (Expect.equal 1)
            ]
        ]
