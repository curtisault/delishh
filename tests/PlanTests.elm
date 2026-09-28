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
import Plan exposing (Day(..), Plan, Source(..))
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
            , test "an empty day takes the recipe at once" <|
                \_ ->
                    Plan.placeRecipe donuts Nothing Tue Plan.empty
                        |> Tuple.mapFirst (Plan.get Tue)
                        |> Expect.equal ( Just donuts, Nothing )
            , test "a day holding this recipe gives it up" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue donuts
                        |> Plan.placeRecipe donuts Nothing Tue
                        |> Tuple.mapFirst Plan.isEmpty
                        |> Expect.equal ( True, Nothing )
            , test "a day holding another meal only arms on the first press" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue spaghetti
                        |> Plan.placeRecipe donuts Nothing Tue
                        |> Tuple.mapFirst (Plan.get Tue)
                        |> Expect.equal ( Just spaghetti, Just Tue )
            , test "and replaces on the second" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue spaghetti
                        |> Plan.placeRecipe donuts (Just Tue) Tue
                        |> Tuple.mapFirst (Plan.get Tue)
                        |> Expect.equal ( Just donuts, Nothing )
            , test "an armed day does not replace a different one" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue spaghetti
                        |> Plan.set Thu spaghetti
                        |> Plan.placeRecipe donuts (Just Tue) Thu
                        |> Tuple.mapFirst (Plan.get Thu)
                        |> Expect.equal ( Just spaghetti, Just Thu )
            , test "another recipe on the day is still another meal" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Tue (Plan.recipe "lasagna" "Lasagna")
                        |> Plan.placeRecipe donuts Nothing Tue
                        |> Tuple.second
                        |> Expect.equal (Just Tue)
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
                        |> Expect.equal "{\"wed\":{\"own\":\"Spaghetti\"}}"
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
                    [ "[]", "null", "\"Spaghetti\"", "{\"sun\":[{\"own\":\"Soup\"}]}" ]
                        |> List.map (D.decodeString Plan.decoder >> Result.toMaybe)
                        |> Expect.equal [ Nothing, Nothing, Nothing, Nothing ]
            ]
        , describe "the picture's data"
            [ test "is seven rows, Sunday first, an empty day null" <|
                \_ ->
                    Plan.empty
                        |> Plan.set Sun donuts
                        |> Plan.set Wed spaghetti
                        |> Plan.toShare
                        |> E.encode 0
                        |> Expect.equal
                            ("["
                                ++ String.join ","
                                    [ "{\"day\":\"Sunday\",\"meal\":\"Donuts\",\"source\":\"archive\"}"
                                    , "{\"day\":\"Monday\",\"meal\":null,\"source\":null}"
                                    , "{\"day\":\"Tuesday\",\"meal\":null,\"source\":null}"
                                    , "{\"day\":\"Wednesday\",\"meal\":\"Spaghetti\",\"source\":\"own\"}"
                                    , "{\"day\":\"Thursday\",\"meal\":null,\"source\":null}"
                                    , "{\"day\":\"Friday\",\"meal\":null,\"source\":null}"
                                    , "{\"day\":\"Saturday\",\"meal\":null,\"source\":null}"
                                    ]
                                ++ "]"
                            )
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
