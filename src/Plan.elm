module Plan exposing
    ( Day(..)
    , Entry
    , Meal
    , Plan
    , Refusal(..)
    , Slot
    , Source(..)
    , Target(..)
    , add
    , cap
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
    , entries
    , get
    , indexOn
    , isEmpty
    , label
    , move
    , moveEntry
    , own
    , placeRecipe
    , plannedOn
    , recipe
    , remove
    , set
    , slots
    , toShare
    )

{-| The meal plan — a week, Sunday to Saturday, up to five meals a day.

**Pure.** No `Html`, no `Cmd`, no ports, the split `GroceryList` and
`Shelf` run on. See `docs/meal-planner.md` for the rulings this module
implements.

**The shape is private, on purpose.** A day is a list of entries —
`docs/meal-planner-expansion.md` — and the first planner's one meal a
day is the list of one. The one-meal functions (`get`, `set`, `move`,
`placeRecipe`) keep their exact behaviour on a day of one, so the
pages built for the first planner run unchanged on this shape until
the expansion's own presses replace them.

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


{-| Each held day's entries, in the order they were added. **A day in
the dict is never an empty list**: every write that could empty one
removes the key instead, so `isEmpty` and `count` can trust the size.
-}
type Plan
    = Plan (Dict Int (List Entry))


empty : Plan
empty =
    Plan Dict.empty


isEmpty : Plan -> Bool
isEmpty (Plan d) =
    Dict.isEmpty d


{-| How many days hold a meal — how much of the week is covered.
Days, not meals: five meals on Monday covers Monday once.
-}
count : Plan -> Int
count (Plan d) =
    Dict.size d


{-| A day's entries, in order. Empty for an empty day.
-}
entries : Day -> Plan -> List Entry
entries day (Plan d) =
    Dict.get (dayIndex day) d |> Maybe.withDefault []


{-| Replace a day's entries, keeping the no-empty-list promise.
-}
putEntries : Day -> List Entry -> Plan -> Plan
putEntries day list (Plan d) =
    case list of
        [] ->
            Plan (Dict.remove (dayIndex day) d)

        _ ->
            Plan (Dict.insert (dayIndex day) list d)


{-| The first planner's view of a day: its first meal. On a day of one
this is the day; the expansion's pages read `entries` instead.
-}
get : Day -> Plan -> Maybe Meal
get day plan =
    entries day plan |> List.head |> Maybe.map .meal


{-| The first planner's write: the day becomes this one meal,
unlabelled, whatever it held. The expansion's pages `add` instead.
-}
set : Day -> Meal -> Plan -> Plan
set day meal =
    putEntries day [ { meal = meal, label = Nothing } ]


clear : Day -> Plan -> Plan
clear day =
    putEntries day []


clearAll : Plan -> Plan
clearAll _ =
    empty


{-| Pick up the meal on one day and set it down on another — the first
planner's move, over whole days.

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
        case ( entries from plan, entries to plan ) of
            ( [], _ ) ->
                plan

            ( lifted, displaced ) ->
                plan |> putEntries to lifted |> putEntries from displaced



-- ENTRIES — docs/meal-planner-expansion.md


{-| A label from the recipes' own slot vocabulary. **Held to
`scripts/vocabulary.ts` by `scripts/plan_slots_test.ts`**, spelling
and order, the way `GroceryList.aisles` is held by `aisles_test.ts`.
-}
type alias Slot =
    String


slots : List Slot
slots =
    [ "breakfast", "lunch", "dinner", "snack", "dessert" ]


{-| One meal on a day, and the label the reader gave it, if any. A
label is optional because a one-meal day should never be made to say
_dinner_; it is not unique, because two snacks is a real day; and it
never reorders anything.
-}
type alias Entry =
    { meal : Meal, label : Maybe Slot }


{-| Five a day, the size of the slot vocabulary — a count, not a slot
check: five unlabelled entries is a full day too.
-}
cap : Int
cap =
    5


{-| Why a write was refused. One reason today; a type rather than a
`Bool` so the page says the reason instead of guessing it.
-}
type Refusal
    = DayFull


{-| Put a meal at the end of a day, unlabelled. A full day refuses and
says so — the plan is unchanged, and the page puts the sentence where
the press was.
-}
add : Day -> Meal -> Plan -> Result Refusal Plan
add day meal plan =
    let
        list =
            entries day plan
    in
    if List.length list >= cap then
        Err DayFull

    else
        Ok (putEntries day (list ++ [ { meal = meal, label = Nothing } ]) plan)


{-| Take one entry off a day, by its position. A position with nothing
at it changes nothing.
-}
remove : Day -> Int -> Plan -> Plan
remove day index plan =
    putEntries day
        (entries day plan
            |> List.indexedMap Tuple.pair
            |> List.filterMap
                (\( i, e ) ->
                    if i == index then
                        Nothing

                    else
                        Just e
                )
        )
        plan


{-| Set or unset one entry's label. A word that is not in `slots` is
refused by changing nothing — the vocabulary is closed here as it is
everywhere else.
-}
label : Day -> Int -> Maybe Slot -> Plan -> Plan
label day index slot plan =
    case slot of
        Just word ->
            if List.member word slots then
                relabel day index slot plan

            else
                plan

        Nothing ->
            relabel day index Nothing plan


relabel : Day -> Int -> Maybe Slot -> Plan -> Plan
relabel day index slot plan =
    putEntries day
        (List.indexedMap
            (\i e ->
                if i == index then
                    { e | label = slot }

                else
                    e
            )
            (entries day plan)
        )
        plan


{-| Where a lifted entry is set down.
-}
type Target
    = OntoDay Day
    | OntoEntry Day Int


{-| Pick up one entry and set it down.

  - **onto a day**, it goes to the end of that day. Its own day puts it
    back where it was — identity, the first planner's rule. A full day
    refuses, and nothing moves.
  - **onto an entry**, the two swap places, on one day or across two.
    So reordering a day is a swap with a neighbour, and a swap can
    never overfill a day: each side gives one and takes one.
  - lifting a position with nothing at it moves nothing.

Labels travel with their meal.

-}
moveEntry : ( Day, Int ) -> Target -> Plan -> Result Refusal Plan
moveEntry ( from, index ) target plan =
    case at from index plan of
        Nothing ->
            Ok plan

        Just lifted ->
            case target of
                OntoDay to ->
                    if to == from then
                        Ok plan

                    else if List.length (entries to plan) >= cap then
                        Err DayFull

                    else
                        Ok
                            (plan
                                |> remove from index
                                |> putEntries to (entries to plan ++ [ lifted ])
                            )

                OntoEntry to other ->
                    case at to other plan of
                        Nothing ->
                            Ok plan

                        Just displaced ->
                            Ok
                                (plan
                                    |> replaceAt from index displaced
                                    |> replaceAt to other lifted
                                )


at : Day -> Int -> Plan -> Maybe Entry
at day index plan =
    entries day plan |> List.drop index |> List.head


replaceAt : Day -> Int -> Entry -> Plan -> Plan
replaceAt day index entry plan =
    putEntries day
        (List.indexedMap
            (\i e ->
                if i == index then
                    entry

                else
                    e
            )
            (entries day plan)
        )
        plan



-- PRESSES


{-| Every day a recipe is on, in week order. By slug, never by title:
the title is a snapshot and the recipe may have been retitled since.
-}
plannedOn : String -> Plan -> List Day
plannedOn slug plan =
    List.filter (\day -> List.any (isRecipe slug) (entries day plan)) days


isRecipe : String -> Entry -> Bool
isRecipe slug entry =
    case entry.meal of
        Recipe r ->
            r.slug == slug

        Own _ ->
            False


{-| A day press on the recipe page's picker, and what it does.

  - a day holding **this** recipe gives it up — this recipe and
    nothing else on the day. The press is a toggle, and that is also
    how a recipe moves: off one day, onto another
  - any other day **takes it at the end**, empty or not, the way ADD
    does on the plan page
  - a **full** day refuses, with its reason

There is no replacing any more. The first planner armed a held day
and replaced it on the second press, because a day held one meal;
a day now holds five, so a held day simply takes one more, and the
picker's only lossy press is gone (docs/meal-planner-expansion.md,
Phase 2).

-}
placeRecipe : Meal -> Day -> Plan -> Result Refusal Plan
placeRecipe meal day plan =
    let
        list =
            entries day plan

        mine =
            case meal of
                Recipe r ->
                    List.any (isRecipe r.slug) list

                Own _ ->
                    False
    in
    if mine then
        Ok (putEntries day (List.filter (not << isRecipe (slugOf meal)) list) plan)

    else
        add day meal plan


{-| Where this recipe sits on a day, if it does — the entry a label
press on the recipe page acts on. The first, if it is there twice.
-}
indexOn : String -> Day -> Plan -> Maybe Int
indexOn slug day plan =
    entries day plan
        |> List.indexedMap Tuple.pair
        |> List.filter (\( _, e ) -> isRecipe slug e)
        |> List.head
        |> Maybe.map Tuple.first


slugOf : Meal -> String
slugOf meal =
    case meal of
        Recipe r ->
            r.slug

        Own _ ->
            ""


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


{-| The stored shape: an object keyed by day, each day an array of
entries, an empty day absent.

    { "sun": [ { "recipe": "donuts", "title": "Donuts" } ]
    , "wed": [ { "own": "Soup", "label": "lunch" }, { "own": "Spaghetti" } ]
    }

**Two shapes are read and one is written.** The first planner stored a
day as one meal object; that reads as a list of one, unlabelled, and
`PlanTests` keeps such a value as a fixture forever, because the
browser that still holds one is real. Only arrays are written. There
is no version field: the shape says which it is, which is a fact
about the value rather than a number nothing forces to move (the
revision counter's retirement, 2026-09-21).

Strict, and total at the call site: an unknown day, a meal of neither
kind, a blank own meal, an empty array, more than five entries, or a
label outside `slots` fails the whole decode, and the shell discards
what it cannot read (DS-01 §12).

-}
decoder : Decoder Plan
decoder =
    D.keyValuePairs dayDecoder
        |> D.andThen
            (\pairs ->
                List.foldr
                    (\( key, list ) acc ->
                        D.andThen
                            (\d ->
                                case dayFromKey key of
                                    Just day ->
                                        D.succeed (Dict.insert (dayIndex day) list d)

                                    Nothing ->
                                        D.fail ("no day is called " ++ key)
                            )
                            acc
                    )
                    (D.succeed Dict.empty)
                    pairs
            )
        |> D.map Plan


dayDecoder : Decoder (List Entry)
dayDecoder =
    D.oneOf
        [ D.list entryDecoder
            |> D.andThen
                (\list ->
                    if List.isEmpty list then
                        D.fail "an empty day is absent, never an empty list"

                    else if List.length list > cap then
                        D.fail "a day holds five at most"

                    else
                        D.succeed list
                )

        -- the first planner's shape: one meal, read as a list of one
        , D.map (\meal -> [ { meal = meal, label = Nothing } ]) mealDecoder
        ]


entryDecoder : Decoder Entry
entryDecoder =
    D.map2 Entry
        mealDecoder
        (D.maybe (D.field "label" D.value)
            |> D.andThen
                (\raw ->
                    case raw of
                        Nothing ->
                            D.succeed Nothing

                        Just value ->
                            case D.decodeValue D.string value of
                                Ok word ->
                                    if List.member word slots then
                                        D.succeed (Just word)

                                    else
                                        D.fail ("no slot is called " ++ word)

                                Err _ ->
                                    D.fail "a label is a word"
                )
        )


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
            (\day ->
                case entries day plan of
                    [] ->
                        Nothing

                    list ->
                        Just ( dayKey day, E.list encodeEntry list )
            )
        |> E.object


encodeEntry : Entry -> E.Value
encodeEntry entry =
    E.object
        (mealFields entry.meal
            ++ (case entry.label of
                    Just word ->
                        [ ( "label", E.string word ) ]

                    Nothing ->
                        []
               )
        )


mealFields : Meal -> List ( String, E.Value )
mealFields meal =
    case meal of
        Recipe r ->
            [ ( "recipe", E.string r.slug ), ( "title", E.string r.title ) ]

        Own words ->
            [ ( "own", E.string words ) ]



-- THE PICTURE


{-| What the shared picture is drawn from: seven days, always, Sunday
first, each with its meals in order —

    [ { "day": "Sunday"
      , "meals": [ { "meal": "Donuts", "source": "archive", "label": "breakfast" } ]
      }
    , { "day": "Monday", "meals": [] }
    , ...
    ]

The drawing never learns what a slug or a `Day` is — it gets words,
where each came from, and the label if there is one — so it changes
when this shape changes and not before.

An empty day has no meals: a receiver should see that Thursday is
open.

-}
toShare : Plan -> E.Value
toShare plan =
    days
        |> E.list
            (\day ->
                E.object
                    [ ( "day", E.string (dayName day) )
                    , ( "meals"
                      , E.list
                            (\entry ->
                                let
                                    m =
                                        describe entry.meal
                                in
                                E.object
                                    [ ( "meal", E.string m.name )
                                    , ( "source"
                                      , E.string
                                            (case m.source of
                                                Archive _ ->
                                                    "archive"

                                                Typed ->
                                                    "own"
                                            )
                                      )
                                    , ( "label", Maybe.map E.string entry.label |> Maybe.withDefault E.null )
                                    ]
                            )
                            (entries day plan)
                      )
                    ]
            )
