module Plan exposing
    ( Day(..)
    , Meal
    , Plan
    , Source(..)
    , clear
    , clearAll
    , clearPress
    , count
    , dayKey
    , dayName
    , days
    , decoder
    , describe
    , empty
    , encode
    , get
    , isEmpty
    , move
    , own
    , placeRecipe
    , plannedOn
    , recipe
    , set
    , toShare
    )

{-| The meal plan — a week, Sunday to Saturday, one meal a day.

**Pure.** No `Html`, no `Cmd`, no ports, the split `GroceryList` and
`Shelf` run on. See `docs/meal-planner.md` for the rulings this module
implements.

**The shape is private, on purpose.** `docs/meal-planner-expansion.md`
grows a day from one meal to a list of five. Pages read and write the
plan only through this API, so that change lands here and on the
presses that are new, never in the shell.

Three things this refuses to do:

  - **Date the week.** Days are names. The plan is _this week_,
    whichever week you are in, and clearing it is how it becomes the
    next one.
  - **Turn a typed meal into a recipe**, or the reverse. `Own
    "donuts"` is the word donuts, whether or not the archive has a
    donut. Nothing is inferred (DS-01 §06).
  - **Hold a blank.** An own meal is trimmed, and nothing trims to a
    meal: `own "  "` is `Nothing`, so the only way a day is empty is
    `clear`.

-}

import Dict exposing (Dict)
import Json.Decode as D exposing (Decoder)
import Json.Encode as E



-- THE WEEK


type Day
    = Sun
    | Mon
    | Tue
    | Wed
    | Thu
    | Fri
    | Sat


{-| The week, in order. **The one place the order is written**;
everything that walks the week walks this.
-}
days : List Day
days =
    [ Sun, Mon, Tue, Wed, Thu, Fri, Sat ]


{-| A day as the reader reads it.
-}
dayName : Day -> String
dayName day =
    case day of
        Sun ->
            "Sunday"

        Mon ->
            "Monday"

        Tue ->
            "Tuesday"

        Wed ->
            "Wednesday"

        Thu ->
            "Thursday"

        Fri ->
            "Friday"

        Sat ->
            "Saturday"


{-| A day as the store spells it — and as an anchor or a key would.
-}
dayKey : Day -> String
dayKey day =
    case day of
        Sun ->
            "sun"

        Mon ->
            "mon"

        Tue ->
            "tue"

        Wed ->
            "wed"

        Thu ->
            "thu"

        Fri ->
            "fri"

        Sat ->
            "sat"


dayFromKey : String -> Maybe Day
dayFromKey key =
    List.filter (\d -> dayKey d == key) days
        |> List.head


{-| A day's position, for the private dict. Nothing outside reads it.
-}
dayIndex : Day -> Int
dayIndex day =
    days
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, d ) -> d == day)
        |> List.head
        |> Maybe.map Tuple.first
        |> Maybe.withDefault 0



-- MEALS


{-| One meal: a recipe from the archive, or words the reader typed.
Opaque, so a blank own meal cannot be built.
-}
type Meal
    = Recipe { slug : String, title : String }
    | Own String


{-| A recipe meal. The title is a snapshot, like the shopping list's:
the plan page reads what you planned without fetching every recipe
on it, and a recipe retitled since still reads as the thing you chose.
-}
recipe : String -> String -> Meal
recipe slug title =
    Recipe { slug = slug, title = title }


{-| An own meal, exactly as typed less its edges — or `Nothing` if
there is nothing there.
-}
own : String -> Maybe Meal
own typed =
    case String.trim typed of
        "" ->
            Nothing

        trimmed ->
            Just (Own trimmed)


{-| Where a meal came from. The picture says it; the page links it.
-}
type Source
    = Archive String
    | Typed


{-| A meal as a view needs it: the words, and where they came from.
-}
describe : Meal -> { name : String, source : Source }
describe meal =
    case meal of
        Recipe r ->
            { name = r.title, source = Archive r.slug }

        Own words ->
            { name = words, source = Typed }



-- THE PLAN


type Plan
    = Plan (Dict Int Meal)


empty : Plan
empty =
    Plan Dict.empty


isEmpty : Plan -> Bool
isEmpty (Plan d) =
    Dict.isEmpty d


{-| How many days hold a meal — how much of the week is covered.
-}
count : Plan -> Int
count (Plan d) =
    Dict.size d


get : Day -> Plan -> Maybe Meal
get day (Plan d) =
    Dict.get (dayIndex day) d


{-| Put a meal on a day, replacing whatever was there.
-}
set : Day -> Meal -> Plan -> Plan
set day meal (Plan d) =
    Plan (Dict.insert (dayIndex day) meal d)


clear : Day -> Plan -> Plan
clear day (Plan d) =
    Plan (Dict.remove (dayIndex day) d)


clearAll : Plan -> Plan
clearAll _ =
    empty


{-| Pick up the meal on one day and set it down on another.

  - an **empty** day takes it, and the day it left is empty
  - a **full** day swaps: its meal goes to the day that was lifted
    from, so a move never loses a meal
  - the **same** day puts it back — identity
  - lifting an **empty** day moves nothing, including the target's
    meal: a swap with nothing is not a request to clear

-}
move : Day -> Day -> Plan -> Plan
move from to plan =
    if from == to then
        plan

    else
        case get from plan of
            Nothing ->
                plan

            Just lifted ->
                case get to plan of
                    Nothing ->
                        plan |> clear from |> set to lifted

                    Just displaced ->
                        plan |> set to lifted |> set from displaced



-- PRESSES


{-| Every day a recipe is on, in week order. By slug, never by title:
the title is a snapshot and the recipe may have been retitled since.
-}
plannedOn : String -> Plan -> List Day
plannedOn slug plan =
    List.filter
        (\day ->
            case get day plan of
                Just (Recipe r) ->
                    r.slug == slug

                _ ->
                    False
        )
        days


{-| A day press on the recipe page's picker, and what it does.

  - a day holding **this** recipe takes it off — the press is a toggle,
    and that is also how a recipe moves: off one day, onto another
  - an **empty** day takes it
  - a day holding **another** meal is armed by the first press and
    replaced by the second. Replacing is the first planner's only
    lossy press, so it is the one that asks; the armed day comes back
    so the press can say what the next one will do

Any press on a different day disarms, because reaching elsewhere is
the reader saying they meant something else.

-}
placeRecipe : Meal -> Maybe Day -> Day -> Plan -> ( Plan, Maybe Day )
placeRecipe meal armed day plan =
    case ( meal, get day plan ) of
        ( Recipe mine, Just (Recipe theirs) ) ->
            if mine.slug == theirs.slug then
                ( clear day plan, Nothing )

            else
                replaceOrArm meal armed day plan

        ( _, Nothing ) ->
            ( set day meal plan, Nothing )

        _ ->
            replaceOrArm meal armed day plan


replaceOrArm : Meal -> Maybe Day -> Day -> Plan -> ( Plan, Maybe Day )
replaceOrArm meal armed day plan =
    if armed == Just day then
        ( set day meal plan, Nothing )

    else
        ( plan, Just day )


{-| Empty the week — in two presses, the shopping list's rule
(`GroceryList.clearPress`). The first arms and changes nothing; the
second clears and disarms. An empty week never arms.
-}
clearPress : Bool -> Plan -> ( Plan, Bool )
clearPress armed plan =
    if isEmpty plan then
        ( plan, False )

    else if armed then
        ( empty, False )

    else
        ( plan, True )



-- STORAGE


{-| The stored shape: an object keyed by day, an empty day absent.

    { "sun": { "recipe": "donuts", "title": "Donuts" }
    , "wed": { "own": "Spaghetti" }
    }

**There is no version field**, unlike the shopping list's. The
expansion stores a day as an array of entries and tells the two apart
by that, which is a fact about the value rather than a number nothing
forces to move (the revision counter's retirement, 2026-09-21).

Strict, and total at the call site: an unknown day, a meal of neither
kind, or a blank own meal fails the whole decode, and the shell
discards what it cannot read (DS-01 §12). A plan is a Sunday evening's
work; a shell that will not boot is the product.

-}
decoder : Decoder Plan
decoder =
    D.keyValuePairs mealDecoder
        |> D.andThen
            (\pairs ->
                List.foldr
                    (\( key, meal ) acc ->
                        D.andThen
                            (\d ->
                                case dayFromKey key of
                                    Just day ->
                                        D.succeed (Dict.insert (dayIndex day) meal d)

                                    Nothing ->
                                        D.fail ("no day is called " ++ key)
                            )
                            acc
                    )
                    (D.succeed Dict.empty)
                    pairs
            )
        |> D.map Plan


mealDecoder : Decoder Meal
mealDecoder =
    D.oneOf
        [ D.map2 recipe
            (D.field "recipe" D.string)
            (D.field "title" D.string)
        , D.field "own" D.string
            |> D.andThen
                (\words ->
                    case own words of
                        Just meal ->
                            D.succeed meal

                        Nothing ->
                            D.fail "an own meal cannot be blank"
                )
        ]


encode : Plan -> E.Value
encode plan =
    days
        |> List.filterMap
            (\day -> get day plan |> Maybe.map (\meal -> ( dayKey day, encodeMeal meal )))
        |> E.object


encodeMeal : Meal -> E.Value
encodeMeal meal =
    case meal of
        Recipe r ->
            E.object [ ( "recipe", E.string r.slug ), ( "title", E.string r.title ) ]

        Own words ->
            E.object [ ( "own", E.string words ) ]



-- THE PICTURE


{-| What the shared picture is drawn from: seven rows, always, Sunday
first. The drawing never learns what a slug or a `Day` is — it gets
words, and whether each came from the archive — so it changes when
this shape changes and not before.

An empty day is a row with `null` meal and source: a receiver should
see that Thursday is open.

-}
toShare : Plan -> E.Value
toShare plan =
    days
        |> E.list
            (\day ->
                let
                    ( meal, source ) =
                        case get day plan |> Maybe.map describe of
                            Just m ->
                                ( E.string m.name
                                , E.string
                                    (case m.source of
                                        Archive _ ->
                                            "archive"

                                        Typed ->
                                            "own"
                                    )
                                )

                            Nothing ->
                                ( E.null, E.null )
                in
                E.object
                    [ ( "day", E.string (dayName day) )
                    , ( "meal", meal )
                    , ( "source", source )
                    ]
            )
