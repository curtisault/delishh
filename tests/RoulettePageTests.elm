module RoulettePageTests exposing (suite)

{-| Restaurant Roulette's page — `docs/decisions.md`, ruled 2026-09-28.

`RouletteTests` proves the wheel and the reel. This proves what the
rendered page does with them:

**The domain is said, not implied.** The masthead, the standfirst and
the entry field all carry the word *restaurant*; a reader arriving
from the shelf is told this is not a recipe picker.

**Empty shows the field and no press.** A SPIN that would do nothing
is a control lying about itself.

**The reel is hidden from assistive technology and the answer is said
once**, through a polite live region, so a screen reader hears the
dinner and not thirty names.

**The pick lands on the week by one press**, and a full day says so.

-}

import Expect
import Html.Attributes as Attr
import Page.RestaurantRoulette
import Plan exposing (Day(..))
import Roulette exposing (Refusal(..), Spin(..))
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Time



-- FIXTURES


type Msg
    = Input String
    | Add
    | Remove String
    | Spin
    | Veto
    | OnDay Day
    | Clear


three : Roulette.Roulette
three =
    Roulette.empty
        |> Roulette.add "Thai Palace"
        |> Result.andThen (Roulette.add "Il Forno")
        |> Result.andThen (Roulette.add "Burger Barn")
        |> Result.withDefault Roulette.empty


one : Roulette.Roulette
one =
    Roulette.empty
        |> Roulette.add "Solo"
        |> Result.withDefault Roulette.empty


spaghetti : Plan.Meal
spaghetti =
    Plan.own "Spaghetti" |> Maybe.withDefault (Plan.recipe "x" "x")


fiveOn : Day -> Plan.Plan
fiveOn d =
    List.foldl (\_ p -> Plan.add d spaghetti p |> Result.withDefault p) Plan.empty (List.range 1 5)


config : Page.RestaurantRoulette.Config Msg
config =
    { roulette = three
    , spin = Idle
    , now = Time.millisToPosix 1000
    , entry = ""
    , refusal = Nothing
    , plan = Plan.empty
    , placed = Nothing
    , refused = Nothing
    , clearArmed = False
    , onInput = Input
    , onAdd = Add
    , onRemove = Remove
    , onSpin = Spin
    , onVeto = Veto
    , onDay = OnDay
    , onClear = Clear
    }


spinning : Spin
spinning =
    Roulette.start { calm = False, wheel = Roulette.names three, index = 1, now = Time.millisToPosix 1000 }


render : Page.RestaurantRoulette.Config Msg -> Query.Single Msg
render c =
    Query.fromHtml (Page.RestaurantRoulette.view c)



-- TESTS


suite : Test
suite =
    describe "Page.RestaurantRoulette"
        [ describe "the domain"
            [ test "the masthead is the full name" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.tag "h1" ]
                        |> Query.has [ Selector.text "Restaurant Roulette" ]
            , test "the standfirst says it is for ordering out, not cooking" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.class "roulette-standfirst" ]
                        |> Query.has [ Selector.text "For the night nobody is cooking" ]
            , test "the entry field is labelled as a restaurant" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.tag "label" ]
                        |> Query.has
                            [ Selector.text "Add a restaurant"
                            , Selector.attribute (Attr.for "roulette-entry")
                            ]
            , test "the help line says nothing here is a recipe" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.id "roulette-entry-help" ]
                        |> Query.has [ Selector.text "Nothing here is a recipe" ]
            ]
        , describe "empty"
            [ test "shows the field and no spin press" <|
                \_ ->
                    render { config | roulette = Roulette.empty }
                        |> Expect.all
                            [ Query.has [ Selector.class "roulette-entry-input" ]
                            , Query.hasNot [ Selector.class "roulette-spin" ]
                            , Query.hasNot [ Selector.class "roulette-days" ]
                            , Query.hasNot [ Selector.class "roulette-clear" ]
                            ]
            , test "says there are no restaurants yet" <|
                \_ ->
                    render { config | roulette = Roulette.empty }
                        |> Query.has [ Selector.text "No restaurants yet" ]
            ]
        , describe "the list"
            [ test "every name is a row with REMOVE" <|
                \_ ->
                    render config
                        |> Query.findAll [ Selector.class "roulette-drop" ]
                        |> Query.count (Expect.equal 3)
            , test "REMOVE names its restaurant" <|
                \_ ->
                    render config
                        |> Query.findAll [ Selector.class "roulette-drop" ]
                        |> Query.first
                        |> Event.simulate Event.click
                        |> Event.expect (Remove "Thai Palace")
            , test "Enter adds" <|
                \_ ->
                    render { config | entry = "Sushi Go" }
                        |> Query.find [ Selector.tag "form" ]
                        |> Event.simulate Event.submit
                        |> Event.expect Add
            , test "a blank field cannot add" <|
                \_ ->
                    render { config | entry = "  " }
                        |> Query.find [ Selector.class "roulette-add" ]
                        |> Query.has [ Selector.disabled True ]
            , test "a duplicate is refused in a sentence naming the spelling that is there" <|
                \_ ->
                    render { config | refusal = Just (Duplicate "Thai Palace") }
                        |> Query.find [ Selector.id "roulette-entry-help" ]
                        |> Query.has [ Selector.text "Thai Palace is already on the list." ]
            , test "CLEAR arms in a word" <|
                \_ ->
                    render { config | clearArmed = True }
                        |> Query.find [ Selector.class "roulette-clear" ]
                        |> Query.has [ Selector.text "Press again to clear", Selector.class "is-armed" ]
            ]
        , describe "one name"
            [ test "has a spin press and no veto" <|
                \_ ->
                    render { config | roulette = one, spin = Settled "Solo" }
                        |> Expect.all
                            [ Query.has [ Selector.class "roulette-spin" ]
                            , Query.hasNot [ Selector.class "roulette-veto" ]
                            ]
            , test "says there is only one place to pick from" <|
                \_ ->
                    render { config | roulette = one, spin = Settled "Solo" }
                        |> Query.find [ Selector.class "roulette-answer" ]
                        |> Query.has [ Selector.text "Tonight: Solo. Only one place to pick from." ]
            ]
        , describe "idle"
            [ test "SPIN spins" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.class "roulette-spin" ]
                        |> Event.simulate Event.click
                        |> Event.expect Spin
            , test "the reel holds the count, not a name" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.class "roulette-reel" ]
                        |> Query.has [ Selector.text "3 places to pick from" ]
            , test "no answer, no veto, no day row" <|
                \_ ->
                    render config
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "roulette-veto" ]
                            , Query.hasNot [ Selector.class "roulette-days" ]
                            ]
            ]
        , describe "spinning"
            [ test "the press is inert and says so" <|
                \_ ->
                    render { config | spin = spinning }
                        |> Query.find [ Selector.class "roulette-spin" ]
                        |> Query.has [ Selector.disabled True, Selector.text "Spinning" ]
            , test "the reel is hidden from assistive technology" <|
                \_ ->
                    render { config | spin = spinning }
                        |> Query.find [ Selector.class "roulette-reel" ]
                        |> Query.has [ Selector.attribute (Attr.attribute "aria-hidden" "true"), Selector.class "is-spinning" ]
            , test "the reel shows a name off the clock" <|
                \_ ->
                    render { config | spin = spinning, now = Time.millisToPosix 1400 }
                        |> Query.find [ Selector.class "roulette-reel-name" ]
                        |> Query.has [ Selector.tag "span" ]
            , test "no day row yet" <|
                \_ ->
                    render { config | spin = spinning }
                        |> Query.hasNot [ Selector.class "roulette-days" ]
            ]
        , describe "settled"
            [ test "the answer is said in the live region" <|
                \_ ->
                    render { config | spin = Settled "Il Forno" }
                        |> Query.find [ Selector.class "roulette-answer" ]
                        |> Query.has
                            [ Selector.attribute (Attr.attribute "aria-live" "polite")
                            , Selector.text "Tonight: Il Forno."
                            ]
            , test "the press offers another spin" <|
                \_ ->
                    render { config | spin = Settled "Il Forno" }
                        |> Query.find [ Selector.class "roulette-spin" ]
                        |> Query.has [ Selector.text "Spin again", Selector.disabled False ]
            , test "NOT THAT ONE vetoes" <|
                \_ ->
                    render { config | spin = Settled "Il Forno" }
                        |> Query.find [ Selector.class "roulette-veto" ]
                        |> Event.simulate Event.click
                        |> Event.expect Veto
            , test "the seven days appear" <|
                \_ ->
                    render { config | spin = Settled "Il Forno" }
                        |> Query.findAll [ Selector.class "roulette-day" ]
                        |> Query.count (Expect.equal 7)
            , test "a day press places on that day" <|
                \_ ->
                    render { config | spin = Settled "Il Forno" }
                        |> Query.findAll [ Selector.class "roulette-day" ]
                        |> Query.index 5
                        |> Event.simulate Event.click
                        |> Event.expect (OnDay Fri)
            , test "a full day says FULL and, refused, says so in a sentence" <|
                \_ ->
                    render { config | spin = Settled "Il Forno", plan = fiveOn Fri, refused = Just Fri }
                        |> Expect.all
                            [ Query.findAll [ Selector.class "roulette-day", Selector.class "is-full" ]
                                >> Query.count (Expect.equal 1)
                            , Query.has [ Selector.text "Friday holds five. Five is a full day." ]
                            ]
            , test "placed, the row gives way to the sentence and the week's link" <|
                \_ ->
                    render { config | spin = Settled "Il Forno", placed = Just Fri }
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "roulette-days" ]
                            , Query.has [ Selector.text "Il Forno is on Friday." ]
                            , Query.find [ Selector.class "roulette-week-link" ]
                                >> Query.has [ Selector.attribute (Attr.href "/plan") ]
                            ]
            ]
        ]
