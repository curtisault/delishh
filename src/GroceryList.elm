module GroceryList exposing
    ( Aisle
    , Contribution
    , Entry
    , Line
    , Model
    , aisles
    , check
    , clearPress
    , contributions
    , count
    , decoder
    , empty
    , encode
    , fromRecipe
    , isEmpty
    , lines
    , member
    , remove
    , toggle
    )

{-| The shopping list — what is on it, and how much of it.

**Pure.** No `Html`, no `Cmd`, no ports. The view decides what a row
looks like; this decides what is true, which is the same split
`Shelf` runs on.

The list is kept as **contributions, not items**: a recipe you added,
at the scale you added it at, carrying a snapshot of what it wanted.
Every line you read is derived by summing them. Two consequences, and
both are the reason for the shape:

  - **Adding twice cannot double anything.** The button toggles a
    slug in or out, so a thumb that lands twice in a shop leaves the
    list exactly as it found it. A list that accumulated presses
    would need an undo, and an undo is a thing to get wrong while
    holding a trolley.
  - **Taking a recipe back off subtracts cleanly**, including from a
    line two other recipes also contribute to. Nothing has to
    remember who put what there, because the sum is never stored.

**The items are a snapshot, taken when you press the button.** The
page that reads this list is read standing in a shop, possibly with
no signal, so it does no fetching: the list you made is the list you
made. Editing a recipe afterwards does not silently rewrite what you
went out to buy — toggling it off and on again does, which is the
only way that is ever a surprise you asked for.


## What merges, and what refuses to

Lines merge on `buyAs`, the purchase name the build joined on from
`scripts/pantry.ts`. Four potatoes and two potatoes are six potatoes
and one row.

Within a row, quantities sum **only inside a unit kind**:

  - mass with mass, volume with volume
  - a count unit only with the same count unit — two cloves and one
    head of garlic are one row and two numbers, because they are two
    things to pick up
  - a bare count with a bare count

Anything that will not sum sits side by side: `500 g + 2 cups`. There
is no conversion between kinds here and there must never be one — a
cup of flour weighs what it weighs on the day, and the one place that
number is read is the one place being wrong about it costs you the
shop.

**A unit is kept when every contribution agreed on it.** Two recipes
asking for cups are asked for in cups; cups and tablespoons together
fall back to millilitres, because that is the only honest thing left
to say. This is the same instinct as `Scale`'s ×1 identity: a number
nobody needed to convert is never quietly converted.

**Where it rounds, it rounds up.** Half an egg is not a thing to buy,
and a range asks for its high end — `2–3 cloves` puts three on the
list. This is the one place the ladder of DS-01 §05 deliberately
reads differently from the recipe page, which still states what the
arithmetic actually wanted (see `Scale`).

-}

import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Recipe exposing (Recipe)
import Scale
import Set exposing (Set)



-- THE AISLES


{-| An aisle token, as `scripts/vocabulary.ts` spells it.
-}
type alias Aisle =
    String


{-| The parts of a shop, in the order you walk them, each with the
words that head its group.

**This list is held to `scripts/vocabulary.ts` by
`scripts/aisles_test.ts`**, tokens, labels and order alike. It is
duplicated here rather than fetched because the list page does not
fetch anything — and a constant living in two languages is exactly
the drift `contrast_test.ts` and `fonts_test.ts` exist to catch, so
it is caught the same way.

-}
aisles : List ( Aisle, String )
aisles =
    [ ( "produce", "Produce" )
    , ( "meat", "Meat" )
    , ( "dairy", "Dairy & eggs" )
    , ( "bakery", "Bakery" )
    , ( "dry-goods", "Dry goods" )
    , ( "canned", "Canned & jarred" )
    , ( "spices", "Spices" )
    , ( "baking", "Baking" )
    , ( "condiments", "Oils & condiments" )
    , ( "frozen", "Frozen" )
    ]



-- THE LIST


{-| One ingredient, as it was when it went on the list.

Flat and self-sufficient on purpose: this is what gets written to
storage, and a stored shape that referred back to a recipe would need
that recipe to still exist, and to still say the same thing, for the
list to render at all.

`indivisible` is deliberately **not** carried. Everything it would
decide here is already decided by the unit — a count unit and a bare
count are the two shapes that round up, and both are visible in
`unit` and `unitKind`. A stored second opinion about a thing the data
already states is a field that can disagree with it.

-}
type alias Entry =
    { value : Maybe Float
    , max : Maybe Float
    , unit : Maybe String
    , unitKind : Maybe String
    , buyAs : String
    , aisle : Aisle
    }


{-| One recipe on the list, at the scale it was added at.
-}
type alias Contribution =
    { slug : String
    , title : String
    , factor : Float
    , items : List Entry
    }


type Model
    = Model
        { contributions : List Contribution
        , checked : Set String
        }


empty : Model
empty =
    Model { contributions = [], checked = Set.empty }


isEmpty : Model -> Bool
isEmpty (Model m) =
    List.isEmpty m.contributions


{-| Whether a recipe is already on the list — what the recipe page's
button reads itself from.
-}
member : String -> Model -> Bool
member slug (Model m) =
    List.any (\c -> c.slug == slug) m.contributions


{-| The recipes on the list, in the order they were added.
-}
contributions : Model -> List Contribution
contributions (Model m) =
    m.contributions


{-| How many recipes are on the list.

**Recipes, not rows.** The bar counts what the reader put there —
presses of one button they can undo with the same press — and not the
lines those presses summed into. Two recipes that both want onions
are two things on the list and one thing to pick up, and a badge that
said "7" where seven was the answer to a question nobody asked is the
count lying about what it is beside.

-}
count : Model -> Int
count (Model m) =
    List.length m.contributions


{-| Put a recipe on the list, or take it off.

Off is off **by slug**: the factor it went on at does not have to
match, because the reader pressing the button is looking at a row
naming one recipe, not one scale of one recipe.

-}
toggle : Contribution -> Model -> Model
toggle contribution (Model m) =
    if List.any (\c -> c.slug == contribution.slug) m.contributions then
        Model
            { m
                | contributions =
                    List.filter (\c -> c.slug /= contribution.slug) m.contributions
            }

    else
        Model { m | contributions = m.contributions ++ [ contribution ] }


{-| What a press of CLEAR THE LIST does, given whether an earlier
press already armed it. Returns the list and whether it is armed now.

**Separated out because it is the one irreversible thing a reader can
do here, and an inline `if` in the shell is the one place nothing can
check it.** The same reason `Viewport.actionFor` is its own module:
the rule is three lines and easy to get half-right — arming on the
press that should have cleared, or clearing on the press that should
have armed, and nobody finds out until a list is gone.

Clearing drops the ticks with the contributions. A tick is a fact
about a row, and there are no rows left.

-}
clearPress : Bool -> Model -> ( Model, Bool )
clearPress armed list =
    if armed then
        ( empty, False )

    else
        ( list, True )


{-| Take one recipe off the list, by slug.

`toggle` needs a whole `Contribution` because it may be putting one
on; this only ever takes one away, and the list page asking for a
recipe's ingredients back in order to throw them out would be the
page fetching something to discard it.

Ticks are left alone. A row two recipes wanted is still wanted by the
other one, and `encode` drops any tick that no longer names a row, so
nothing accumulates.

-}
remove : String -> Model -> Model
remove slug (Model m) =
    Model
        { m | contributions = List.filter (\c -> c.slug /= slug) m.contributions }


{-| Tick an item off, or put it back in the aisle. Keyed by purchase
name, which is what a row is.
-}
check : String -> Model -> Model
check key (Model m) =
    Model
        { m
            | checked =
                if Set.member key m.checked then
                    Set.remove key m.checked

                else
                    Set.insert key m.checked
        }


{-| A recipe's ingredients, snapshotted at a scale.

Ingredients with no `shop` are dropped — an authored non-purchase
(tap water; an option to add nothing at all) is the one thing on an
ingredient list that is not shopping.

-}
fromRecipe : Scale.Factor -> Recipe -> Contribution
fromRecipe factor recipe =
    { slug = recipe.slug
    , title = recipe.title
    , factor = Scale.toFloat factor
    , items =
        recipe.ingredients
            |> List.concatMap .items
            |> List.filterMap entryOf
    }


entryOf : Recipe.Ingredient -> Maybe Entry
entryOf ingredient =
    ingredient.shop
        |> Maybe.map
            (\shop ->
                { value = Maybe.map .value ingredient.amount
                , max = Maybe.andThen .max ingredient.amount
                , unit = ingredient.unit
                , unitKind = ingredient.unitKind
                , buyAs = shop.buyAs
                , aisle = shop.aisle
                }
            )



-- WHAT THE PAGE READS


{-| One row: a thing to buy, how much of it, and whether it is in the
cart already.
-}
type alias Line =
    { key : String
    , name : String
    , aisle : Aisle
    , quantity : String
    , checked : Bool
    }


{-| The list, ready to render: still to buy, grouped by aisle in walk
order, and everything already in the cart in one group at the end.

Empty aisles are absent rather than empty — a heading over nothing is
the same lie as a block over nothing (DS-01 §06).

-}
lines :
    Model
    ->
        { toBuy : List { aisle : Aisle, label : String, items : List Line }
        , inCart : List Line
        }
lines (Model m) =
    let
        ( inCart, toBuy ) =
            m.contributions
                |> List.concatMap (\c -> List.map (Tuple.pair c.factor) c.items)
                |> List.foldl collect Dict.empty
                |> Dict.toList
                |> List.map (toLine m.checked)
                |> List.partition .checked
    in
    { toBuy =
        aisles
            |> List.filterMap
                (\( aisle, label ) ->
                    case List.filter (\l -> l.aisle == aisle) toBuy of
                        [] ->
                            Nothing

                        items ->
                            Just
                                { aisle = aisle
                                , label = label
                                , items = List.sortBy .name items
                                }
                )
    , inCart = List.sortBy .name inCart
    }



-- SUMMING


{-| What one purchase has accumulated.

A bucket per group of units that will sum together — mass, volume,
and one per count unit. Inside a bucket the totals are kept **per
unit**, which is what lets a row that only ever heard about cups be
answered in cups.

`order` is the position the buckets render in, so `500 g + 2 cups`
never comes out the other way round between two reads of one list.

-}
type alias Tally =
    { aisle : Aisle
    , buckets : Dict String Bucket
    }


type alias Bucket =
    { order : Int
    , kind : String
    , byUnit : Dict String Float
    }


collect : ( Float, Entry ) -> Dict String Tally -> Dict String Tally
collect ( factor, entry ) acc =
    let
        tally =
            Dict.get entry.buyAs acc
                |> Maybe.withDefault { aisle = entry.aisle, buckets = Dict.empty }
    in
    case entry.value of
        Nothing ->
            -- "flaky salt, to finish" — a real thing to buy with no
            -- number on it. The row exists; the quantity does not.
            Dict.insert entry.buyAs tally acc

        Just value ->
            let
                -- A range asks for its high end: the list's job is to
                -- send you home with enough.
                wanted =
                    Maybe.withDefault value entry.max * factor

                ( key, kind, order ) =
                    bucketOf entry

                unit =
                    Maybe.withDefault "" entry.unit

                bucket =
                    Dict.get key tally.buckets
                        |> Maybe.withDefault
                            { order = order, kind = kind, byUnit = Dict.empty }

                running =
                    Dict.get unit bucket.byUnit |> Maybe.withDefault 0
            in
            Dict.insert entry.buyAs
                { tally
                    | buckets =
                        Dict.insert key
                            { bucket
                                | byUnit =
                                    Dict.insert unit (running + wanted) bucket.byUnit
                            }
                            tally.buckets
                }
                acc


{-| Which bucket an entry sums into, and where that bucket sorts.

Mass and volume pool by kind, so grams meet kilograms and cups meet
spoons. A count unit gets a bucket of its own — cloves and heads of
garlic are both garlic and neither is the other — and a bare count
gets one too.

-}
bucketOf : Entry -> ( String, String, Int )
bucketOf entry =
    case ( entry.unitKind, entry.unit ) of
        ( Just "mass", _ ) ->
            ( "mass", "mass", 0 )

        ( Just "volume", _ ) ->
            ( "volume", "volume", 1 )

        ( Just "count", Just unit ) ->
            ( "count:" ++ unit, "count", 2 )

        _ ->
            ( "bare", "bare", 3 )


toLine : Set String -> ( String, Tally ) -> Line
toLine checked ( name, tally ) =
    { key = name
    , name = name
    , aisle = tally.aisle
    , quantity =
        tally.buckets
            |> Dict.values
            |> List.sortBy .order
            |> List.map render
            |> List.filter (not << String.isEmpty)
            |> String.join " + "
    , checked = Set.member name checked
    }



-- RENDERING A BUCKET


{-| One bucket as words.

The unit survives when every contribution agreed on it. When they did
not, the bucket falls back to the kind's base unit — grams for mass,
millilitres for volume — which is the only thing left that is true of
all of them.

-}
render : Bucket -> String
render bucket =
    case ( bucket.kind, Dict.toList bucket.byUnit ) of
        ( _, [] ) ->
            ""

        ( "count", [ ( unit, total ) ] ) ->
            let
                n =
                    buyUp total
            in
            String.fromInt n ++ " " ++ Scale.unitLabel (String.fromInt n) unit

        ( "bare", [ ( _, total ) ] ) ->
            String.fromInt (buyUp total)

        ( _, [ ( unit, total ) ] ) ->
            inUnit unit total

        ( kind, several ) ->
            let
                base =
                    List.sum (List.map (\( u, v ) -> toBase kind u v) several)
            in
            inUnit (baseUnit kind) base


{-| A quantity in the unit it was asked for.
-}
inUnit : String -> Float -> String
inUnit unit total =
    case unit of
        "g" ->
            String.fromInt (gramsUp total) ++ " g"

        "ml" ->
            String.fromInt (gramsUp total) ++ " ml"

        "kg" ->
            trim2 total ++ " kg"

        "l" ->
            trim2 total ++ " l"

        _ ->
            -- A spoon or a cup. Quarters, because a shop does not sell
            -- eighths of a cup — `Scale` goes finer for the same
            -- number because a bench does.
            let
                amount =
                    quarterGlyph (quartersUp total)
            in
            amount ++ " " ++ Scale.unitLabel amount unit


{-| What a kind counts in when its units disagree.
-}
baseUnit : String -> String
baseUnit kind =
    if kind == "mass" then
        "g"

    else
        "ml"


{-| A value in its kind's base unit. The only conversions in this
module, and every one of them is exact — within a kind, a spoon *is*
five millilitres by definition. Nothing here converts between kinds,
where the factor would be a property of the food.
-}
toBase : String -> String -> Float -> Float
toBase kind unit value =
    case ( kind, unit ) of
        ( "mass", "kg" ) ->
            value * 1000

        ( "volume", "l" ) ->
            value * 1000

        ( "volume", "tsp" ) ->
            value * 5

        ( "volume", "tbsp" ) ->
            value * 15

        ( "volume", "cup" ) ->
            value * 240

        _ ->
            value



-- ROUNDING, ALWAYS UPWARD


{-| Grams and millilitres, rounded **up**.

The ladder is `Scale`'s — step 5 above 100, step 1 below, where a
scaled 287 g claims a precision the recipe never had. The direction
is not: `Scale` rounds to the nearest because the recipe has to stay
the recipe, and a shop is the other way round. Short is a second
trip; over is a cupboard.

-}
gramsUp : Float -> Int
gramsUp value =
    if value > 100 then
        max 5 (Basics.ceiling ((value - epsilon) / 5) * 5)

    else
        max 1 (Basics.ceiling (value - epsilon))


{-| Spoons and cups, in quarters, rounded up. Returns the count of
quarters so the glyph and the plural can be decided together.
-}
quartersUp : Float -> Int
quartersUp value =
    max 1 (Basics.ceiling ((value - epsilon) * 4))


{-| A count of quarters as a number with a fraction glyph — DS-01 §05
says volume fractions are glyphs, on every surface.
-}
quarterGlyph : Int -> String
quarterGlyph quarters =
    let
        whole =
            quarters // 4

        glyph =
            case quarters - (whole * 4) of
                1 ->
                    "¼"

                2 ->
                    "½"

                3 ->
                    "¾"

                _ ->
                    ""
    in
    if whole == 0 then
        glyph

    else
        String.fromInt whole ++ glyph


{-| A count, rounded up and never to zero. You cannot buy half an egg,
and an ingredient that vanished on a half batch would leave a list
that looks correct.
-}
buyUp : Float -> Int
buyUp value =
    max 1 (Basics.ceiling (value - epsilon))


{-| Two decimals with trailing zeros cut — `1.50` reads as `1.5`.
-}
trim2 : Float -> String
trim2 value =
    let
        hundredths =
            Basics.ceiling ((value - epsilon) * 100)

        whole =
            hundredths // 100

        rest =
            hundredths - (whole * 100)
    in
    if rest == 0 then
        String.fromInt whole

    else if Basics.remainderBy 10 rest == 0 then
        String.fromInt whole ++ "." ++ String.fromInt (rest // 10)

    else if rest < 10 then
        String.fromInt whole ++ ".0" ++ String.fromInt rest

    else
        String.fromInt whole ++ "." ++ String.fromInt rest


{-| Float sums land on 2.9999999999999996 often enough that a ceiling
without a nudge would put four eggs on a list that wanted three.
-}
epsilon : Float
epsilon =
    1.0e-9



-- STORAGE


{-| The stored shape, versioned.

The version is read and checked rather than ignored, and anything
this decoder cannot make sense of becomes an empty list at the call
site. A shopping list is worth less than a page that renders: losing
one is an afternoon, and a shell that will not boot is the product.

-}
decoder : Decoder Model
decoder =
    D.field "v" D.int
        |> D.andThen
            (\version ->
                if version /= storageVersion then
                    D.fail
                        ("shopping list v"
                            ++ String.fromInt version
                            ++ " was written by a different build"
                        )

                else
                    D.map2
                        (\cs ks ->
                            Model { contributions = cs, checked = Set.fromList ks }
                        )
                        (D.field "contributions" (D.list contributionDecoder))
                        (D.field "checked" (D.list D.string))
            )


storageVersion : Int
storageVersion =
    1


contributionDecoder : Decoder Contribution
contributionDecoder =
    D.map4 Contribution
        (D.field "slug" D.string)
        (D.field "title" D.string)
        (D.field "factor" D.float)
        (D.field "items" (D.list entryDecoder))


entryDecoder : Decoder Entry
entryDecoder =
    D.map6 Entry
        (D.field "value" (D.nullable D.float))
        (D.field "max" (D.nullable D.float))
        (D.field "unit" (D.nullable D.string))
        (D.field "unitKind" (D.nullable D.string))
        (D.field "buyAs" D.string)
        (D.field "aisle" D.string)


{-| Only ticks that still name a row are written back, so a list that
has been emptied and refilled does not carry last week's.
-}
encode : Model -> E.Value
encode model =
    let
        (Model m) =
            model

        live =
            lines model
                |> (\{ toBuy, inCart } -> List.concatMap .items toBuy ++ inCart)
                |> List.map .key
                |> Set.fromList
    in
    E.object
        [ ( "v", E.int storageVersion )
        , ( "contributions", E.list encodeContribution m.contributions )
        , ( "checked", E.list E.string (Set.toList (Set.intersect m.checked live)) )
        ]


encodeContribution : Contribution -> E.Value
encodeContribution c =
    E.object
        [ ( "slug", E.string c.slug )
        , ( "title", E.string c.title )
        , ( "factor", E.float c.factor )
        , ( "items", E.list encodeEntry c.items )
        ]


encodeEntry : Entry -> E.Value
encodeEntry e =
    E.object
        [ ( "value", maybe E.float e.value )
        , ( "max", maybe E.float e.max )
        , ( "unit", maybe E.string e.unit )
        , ( "unitKind", maybe E.string e.unitKind )
        , ( "buyAs", E.string e.buyAs )
        , ( "aisle", E.string e.aisle )
        ]


maybe : (a -> E.Value) -> Maybe a -> E.Value
maybe encoder =
    Maybe.map encoder >> Maybe.withDefault E.null
