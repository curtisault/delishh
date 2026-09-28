module PlanTests exposing (suite)

{-| The meal plan, and the ways it could quietly be wrong.

Every one of these produces a week that looks like a plan:

  - **a move that loses a meal**, because the day it landed on was
    full and the swap forgot the other half
  - **a blank day that is not empty**, because an own meal of spaces
    was kept and draws as nothing
  - **a typed meal that became a recipe**, or a recipe that lost its
    address, somewhere between the store and the page
  - **a stored week that will not decode crashing the shell** rather
    than becoming an empty one

-}

import Expect
import Json.Decode as D
import Json.Encode as E
import Plan exposing (Day(..), Plan, Refusal(..), Source(..), Target(..))
import Test exposing (Test, describe, test)



-- FIXTURES


donuts : Plan.Meal
donuts =
    Plan.recipe "donuts" "Donuts"


spaghetti : Plan.Meal
spaghetti =
    Plan.own "Spaghetti" |> Maybe.withDefault donuts


{-| Every day, as (key, meal name) — what a reader would see.
-}
week : Plan -> List ( String, Maybe String )
week plan =
    Plan.days
        |> List.map
            (\d -> ( Plan.dayKey d, Plan.get d plan |> Maybe.map (Plan.describe >> .name) ))


{-| Donuts then spaghetti, on one day. -}
two : Day -> Plan
two day =
    Plan.empty
        |> Plan.set day donuts
        |> (\p -> Plan.add day spaghetti p |> Result.withDefault p)


{-| A day holding five. -}
full : Day -> Plan
full day =
    List.foldl (\_ p -> Plan.add day donuts p |> Result.withDefault p) Plan.empty (List.range 1 5)


roundTrip : Plan -> Result D.Error Plan
roundTrip plan =
    D.decodeString Plan.decoder (E.encode 0 (Plan.encode plan))


suite : Test
suite =
    describe "Plan"
        [ describe "the week"
            [ test "runs Sunday to Saturday" <|
                \_ ->
                    List.map Plan.dayName Plan.days
                        |> Expect.equal
                            [ "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" ]
            , test "starts empty, and says so" <|
                \_ ->
                    ( Plan.isEmpty Plan.empty, Plan.count Plan.empty )
                        |> Expect.equal ( True, 0 )
            , test "counts days covered" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.set Wed spaghetti
                        |> Plan.count
                        |> Expect.equal 2
            , test "a day holds one meal: setting again replaces" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Wed donuts
                        |> Plan.set Wed spaghetti
                        |> Plan.get Wed
                        |> Maybe.map (Plan.describe >> .name)
                        |> Expect.equal (Just "Spaghetti")
            , test "clear empties one day and no other" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.set Mon spaghetti
                        |> Plan.clear Sun
                        |> week
                        |> List.filterMap (\( k, m ) -> Maybe.map (Tuple.pair k) m)
                        |> Expect.equal [ ( "mon", "Spaghetti" ) ]
            , test "clearAll empties the week" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.set Sat spaghetti
                        |> Plan.clearAll
                        |> Plan.isEmpty
                        |> Expect.equal True
            ]
        , describe "an own meal"
            [ test "keeps exactly what was typed, less its edges" <|
                \_ ->
                    Plan.own "  Spaghetti, the good kind "
                        |> Maybe.map (Plan.describe >> .name)
                        |> Expect.equal (Just "Spaghetti, the good kind")
            , test "cannot be blank" <|
                \_ ->
                    [ Plan.own "", Plan.own "   ", Plan.own "\t\n" ]
                        |> Expect.equal [ Nothing, Nothing, Nothing ]
            , test "is never a recipe, even when its words name one" <|
                \_ ->
                    Plan.own "donuts"
                        |> Maybe.map (Plan.describe >> .source)
                        |> Expect.equal (Just Typed)
            , test "a recipe meal keeps its address" <|
                \_ ->
                    (Plan.describe donuts).source
                        |> Expect.equal (Archive "donuts")
            ]
        , describe "move"
            [ test "to an empty day takes it, and the day it left is empty" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.move Sun Thu
                        |> week
                        |> Expect.equal
                            [ ( "sun", Nothing )
                            , ( "mon", Nothing )
                            , ( "tue", Nothing )
                            , ( "wed", Nothing )
                            , ( "thu", Just "Donuts" )
                            , ( "fri", Nothing )
                            , ( "sat", Nothing )
                            ]
            , test "to a full day swaps, and loses nothing" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.set Sat spaghetti
                        |> Plan.move Sun Sat
                        |> (\p -> ( Plan.get Sun p, Plan.get Sat p, Plan.count p ))
                        |> Expect.equal ( Just spaghetti, Just donuts, 2 )
            , test "to the same day is identity" <|
                \_ ->
                    let
                        plan =
                            Plan.empty |> Plan.set Tue donuts
                    in
                    Plan.move Tue Tue plan
                        |> week
                        |> Expect.equal (week plan)
            , test "from an empty day moves nothing, and clears nothing" <|
                \_ ->
                    let
                        plan =
                            Plan.empty |> Plan.set Fri spaghetti
                    in
                    Plan.move Mon Fri plan
                        |> week
                        |> Expect.equal (week plan)
            ]
        , describe "the recipe page's picker"
            [ test "plannedOn finds a recipe by slug, in week order" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Fri donuts
                        |> Plan.set Mon (Plan.recipe "donuts" "Donuts, retitled")
                        |> Plan.set Wed spaghetti
                        |> Plan.plannedOn "donuts"
                        |> Expect.equal [ Mon, Fri ]
            , test "an empty day takes the recipe" <|
                \_ ->
                    Plan.placeRecipe donuts Tue Plan.empty
                        |> Result.map (Plan.get Tue)
                        |> Expect.equal (Ok (Just donuts))
            , test "a day holding this recipe gives it up" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue donuts
                        |> Plan.placeRecipe donuts Tue
                        |> Result.map Plan.isEmpty
                        |> Expect.equal (Ok True)
            , test "a day holding another meal takes this one at the end, losing nothing" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue spaghetti
                        |> Plan.placeRecipe donuts Tue
                        |> Result.map (Plan.entries Tue >> List.map .meal)
                        |> Expect.equal (Ok [ spaghetti, donuts ])
            , test "a full day refuses, with its reason" <|
                \_ ->
                    full Tue
                        |> Plan.placeRecipe (Plan.recipe "lasagna" "Lasagna") Tue
                        |> Expect.equal (Err DayFull)
            , test "indexOn finds the recipe's place on a day" <|
                \_ ->
                    two Tue
                        |> Plan.indexOn "donuts" Tue
                        |> Expect.equal (Just 0)
            ]
        , describe "clearing the week"
            [ test "the first press arms and keeps everything" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.clearPress False
                        |> Tuple.mapFirst Plan.count
                        |> Expect.equal ( 1, True )
            , test "the second press clears and disarms" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.clearPress True
                        |> Tuple.mapFirst Plan.isEmpty
                        |> Expect.equal ( True, False )
            , test "an empty week never arms" <|
                \_ ->
                    Plan.clearPress False Plan.empty
                        |> Tuple.second
                        |> Expect.equal False
            ]
        , describe "the store"
            [ test "round-trips both kinds of meal" <|
                \_ ->
                    let
                        plan =
                            Plan.empty
                                |> Plan.set Sun donuts
                                |> Plan.set Wed spaghetti
                    in
                    roundTrip plan
                        |> Result.map (\p -> ( week p, Plan.get Sun p, Plan.get Wed p ))
                        |> Expect.equal (Ok ( week plan, Just donuts, Just spaghetti ))
            , test "writes an empty day as absent" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Wed spaghetti
                        |> Plan.encode
                        |> E.encode 0
                        |> Expect.equal "{\"wed\":[{\"own\":\"Spaghetti\"}]}"
            , test "an empty plan writes an empty object, which boot.js clears" <|
                \_ ->
                    Plan.encode Plan.empty
                        |> E.encode 0
                        |> Expect.equal "{}"
            , test "reads the shape the expansion will keep reading forever" <|
                \_ ->
                    -- A first-planner value, verbatim. The browser that
                    -- still holds one after the expansion ships is real.
                    D.decodeString Plan.decoder
                        """{"sun":{"recipe":"donuts","title":"Donuts"},"wed":{"own":"Spaghetti"}}"""
                        |> Result.map (\p -> ( Plan.get Sun p, Plan.get Wed p, Plan.count p ))
                        |> Expect.equal (Ok ( Just donuts, Just spaghetti, 2 ))
            , test "refuses an unknown day rather than dropping it" <|
                \_ ->
                    D.decodeString Plan.decoder """{"sun":{"own":"Soup"},"funday":{"own":"Cake"}}"""
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "refuses a blank own meal" <|
                \_ ->
                    D.decodeString Plan.decoder """{"sun":{"own":"   "}}"""
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "refuses a meal of neither kind" <|
                \_ ->
                    D.decodeString Plan.decoder """{"sun":{"dish":"Soup"}}"""
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "refuses what is not a week at all" <|
                \_ ->
                    [ "[]", "null", "\"Spaghetti\"" ]
                        |> List.map (D.decodeString Plan.decoder >> Result.toMaybe)
                        |> Expect.equal [ Nothing, Nothing, Nothing ]
            ]
        , describe "a day of several — docs/decisions.md"
            [ test "add appends, in the order added" <|
                \_ ->
                    Plan.empty
                        |> Plan.add Tue donuts
                        |> Result.andThen (Plan.add Tue spaghetti)
                        |> Result.map (Plan.entries Tue >> List.map (.meal >> Plan.describe >> .name))
                        |> Expect.equal (Ok [ "Donuts", "Spaghetti" ])
            , test "a day holds five, and the sixth is refused with its reason" <|
                \_ ->
                    full Tue
                        |> Plan.add Tue donuts
                        |> Expect.equal (Err DayFull)
            , test "five unlabelled entries is a full day too" <|
                \_ ->
                    full Tue
                        |> Plan.entries Tue
                        |> List.map .label
                        |> Expect.equal [ Nothing, Nothing, Nothing, Nothing, Nothing ]
            , test "the week still counts days, not meals" <|
                \_ ->
                    full Tue |> Plan.count |> Expect.equal 1
            , test "remove takes one entry and keeps the rest in order" <|
                \_ ->
                    two Tue
                        |> Plan.remove Tue 0
                        |> Plan.entries Tue
                        |> List.map (.meal >> Plan.describe >> .name)
                        |> Expect.equal [ "Spaghetti" ]
            , test "removing the last entry empties the day, not a list of nothing" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue donuts
                        |> Plan.remove Tue 0
                        |> (\p -> ( Plan.isEmpty p, Plan.encode p |> E.encode 0 ))
                        |> Expect.equal ( True, "{}" )
            , test "a label sets and unsets" <|
                \_ ->
                    let
                        labelled =
                            two Tue |> Plan.label Tue 1 (Just "lunch")
                    in
                    ( List.map .label (Plan.entries Tue labelled)
                    , Plan.label Tue 1 Nothing labelled |> Plan.entries Tue |> List.map .label
                    )
                        |> Expect.equal ( [ Nothing, Just "lunch" ], [ Nothing, Nothing ] )
            , test "labels are not unique: two snacks is a real day" <|
                \_ ->
                    two Tue
                        |> Plan.label Tue 0 (Just "snack")
                        |> Plan.label Tue 1 (Just "snack")
                        |> Plan.entries Tue
                        |> List.map .label
                        |> Expect.equal [ Just "snack", Just "snack" ]
            , test "a label never reorders the day" <|
                \_ ->
                    two Tue
                        |> Plan.label Tue 1 (Just "breakfast")
                        |> Plan.entries Tue
                        |> List.map (.meal >> Plan.describe >> .name)
                        |> Expect.equal [ "Donuts", "Spaghetti" ]
            , test "a word outside the vocabulary is not a label" <|
                \_ ->
                    two Tue
                        |> Plan.label Tue 0 (Just "brunch")
                        |> Plan.entries Tue
                        |> List.map .label
                        |> Expect.equal [ Nothing, Nothing ]
            , test "onto a day, an entry goes to the end, and its label goes with it" <|
                \_ ->
                    two Tue
                        |> Plan.label Tue 0 (Just "lunch")
                        |> Plan.set Fri spaghetti
                        |> Plan.moveEntry ( Tue, 0 ) (OntoDay Fri)
                        |> Result.map
                            (\p ->
                                ( List.map (.meal >> Plan.describe >> .name) (Plan.entries Fri p)
                                , List.map .label (Plan.entries Fri p)
                                , List.length (Plan.entries Tue p)
                                )
                            )
                        |> Expect.equal (Ok ( [ "Spaghetti", "Donuts" ], [ Nothing, Just "lunch" ], 1 ))
            , test "onto its own day, an entry is put back" <|
                \_ ->
                    two Tue
                        |> Plan.moveEntry ( Tue, 0 ) (OntoDay Tue)
                        |> Result.map (Plan.entries Tue >> List.map (.meal >> Plan.describe >> .name))
                        |> Expect.equal (Ok [ "Donuts", "Spaghetti" ])
            , test "onto a full day, nothing moves and the reason comes back" <|
                \_ ->
                    full Fri
                        |> Plan.set Tue donuts
                        |> Plan.moveEntry ( Tue, 0 ) (OntoDay Fri)
                        |> Expect.equal (Err DayFull)
            , test "onto an entry on the same day, the two swap, which is reordering" <|
                \_ ->
                    two Tue
                        |> Plan.moveEntry ( Tue, 1 ) (OntoEntry Tue 0)
                        |> Result.map (Plan.entries Tue >> List.map (.meal >> Plan.describe >> .name))
                        |> Expect.equal (Ok [ "Spaghetti", "Donuts" ])
            , test "onto an entry on a full day, the swap goes through and nothing overfills" <|
                \_ ->
                    full Fri
                        |> Plan.set Tue spaghetti
                        |> Plan.moveEntry ( Tue, 0 ) (OntoEntry Fri 2)
                        |> Result.map
                            (\p ->
                                ( List.length (Plan.entries Fri p)
                                , Plan.entries Fri p |> List.drop 2 |> List.head |> Maybe.map (.meal >> Plan.describe >> .name)
                                , Plan.get Tue p
                                )
                            )
                        |> Expect.equal (Ok ( 5, Just "Spaghetti", Just donuts ))
            , test "lifting a position with nothing at it moves nothing" <|
                \_ ->
                    two Tue
                        |> Plan.moveEntry ( Tue, 4 ) (OntoDay Wed)
                        |> Result.map Plan.count
                        |> Expect.equal (Ok 1)
            , test "the one-meal move carries a whole day of several" <|
                \_ ->
                    two Tue
                        |> Plan.move Tue Sat
                        |> (\p -> ( List.length (Plan.entries Sat p), Plan.entries Tue p ))
                        |> Expect.equal ( 2, [] )
            , test "plannedOn finds a recipe anywhere in a day" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Mon spaghetti
                        |> (\p -> Plan.add Mon donuts p |> Result.withDefault p)
                        |> Plan.plannedOn "donuts"
                        |> Expect.equal [ Mon ]
            , test "the picker takes off this recipe and nothing else on the day" <|
                \_ ->
                    two Tue
                        |> Plan.placeRecipe donuts Tue
                        |> Result.map (Plan.entries Tue >> List.map (.meal >> Plan.describe >> .name))
                        |> Expect.equal (Ok [ "Spaghetti" ])
            , test "the vocabulary is the recipes' slot list" <|
                \_ ->
                    Plan.slots
                        |> Expect.equal [ "breakfast", "lunch", "dinner", "snack", "dessert" ]
            ]
        , describe "the stored shapes"
            [ test "a day of several round-trips with its labels" <|
                \_ ->
                    let
                        plan =
                            two Tue |> Plan.label Tue 1 (Just "dinner")
                    in
                    roundTrip plan
                        |> Result.map (Plan.entries Tue)
                        |> Expect.equal (Ok (Plan.entries Tue plan))
            , test "writes arrays only, and a label only when there is one" <|
                \_ ->
                    two Tue
                        |> Plan.label Tue 1 (Just "dinner")
                        |> Plan.encode
                        |> E.encode 0
                        |> Expect.equal """{"tue":[{"recipe":"donuts","title":"Donuts"},{"own":"Spaghetti","label":"dinner"}]}"""
            , test "the first planner's shape reads as a list of one, unlabelled" <|
                \_ ->
                    D.decodeString Plan.decoder """{"wed":{"own":"Spaghetti"}}"""
                        |> Result.map (Plan.entries Wed)
                        |> Expect.equal (Ok [ { meal = spaghetti, label = Nothing } ])
            , test "both shapes may sit in one stored week" <|
                \_ ->
                    D.decodeString Plan.decoder """{"sun":{"own":"Soup"},"mon":[{"own":"Eggs","label":"breakfast"}]}"""
                        |> Result.map Plan.count
                        |> Expect.equal (Ok 2)
            , test "refuses an empty array, six entries, and a label it does not know" <|
                \_ ->
                    [ """{"sun":[]}"""
                    , """{"sun":[{"own":"a"},{"own":"b"},{"own":"c"},{"own":"d"},{"own":"e"},{"own":"f"}]}"""
                    , """{"sun":[{"own":"Soup","label":"brunch"}]}"""
                    , """{"sun":[{"own":"Soup","label":3}]}"""
                    ]
                        |> List.map (D.decodeString Plan.decoder >> Result.toMaybe)
                        |> Expect.equal [ Nothing, Nothing, Nothing, Nothing ]
            ]
        , describe "the picture's data"
            [ test "is seven days, Sunday first, an empty day with no meals" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.set Wed spaghetti
                        |> Plan.toShare
                        |> E.encode 0
                        |> Expect.equal
                            ("["
                                ++ String.join ","
                                    [ "{\"day\":\"Sunday\",\"meals\":[{\"meal\":\"Donuts\",\"source\":\"archive\",\"label\":null}]}"
                                    , "{\"day\":\"Monday\",\"meals\":[]}"
                                    , "{\"day\":\"Tuesday\",\"meals\":[]}"
                                    , "{\"day\":\"Wednesday\",\"meals\":[{\"meal\":\"Spaghetti\",\"source\":\"own\",\"label\":null}]}"
                                    , "{\"day\":\"Thursday\",\"meals\":[]}"
                                    , "{\"day\":\"Friday\",\"meals\":[]}"
                                    , "{\"day\":\"Saturday\",\"meals\":[]}"
                                    ]
                                ++ "]"
                            )
            , test "carries every meal of a day, in order, with its label" <|
                \_ ->
                    two Tue
                        |> Plan.label Tue 1 (Just "dinner")
                        |> Plan.toShare
                        |> E.encode 0
                        |> String.contains "{\"day\":\"Tuesday\",\"meals\":[{\"meal\":\"Donuts\",\"source\":\"archive\",\"label\":null},{\"meal\":\"Spaghetti\",\"source\":\"own\",\"label\":\"dinner\"}]}"
                        |> Expect.equal True
            , test "never carries a slug" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun (Plan.recipe "a-secret-slug" "Donuts")
                        |> Plan.toShare
                        |> E.encode 0
                        |> String.contains "a-secret-slug"
                        |> Expect.equal False
            ]
        ]
