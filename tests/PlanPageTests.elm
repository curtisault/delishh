module PlanPageTests exposing (suite)

{-| The meal plan page — `docs/meal-planner.md`.

`PlanTests` proves the week's rules. This proves what the rendered
page does with them, which a correct `Plan.move` would not give you:

**An empty day draws nothing.** Its name is the press; there is no
_empty_, no placeholder, no dashed box (DS-01 §06).

**Lifted carries more than one signal.** The seated slab is for an
eye, ", lifted" is for a screen reader, and the hint word is the
third. And while a meal is in the hand, nothing destructive is under
it.

**One field, two outcomes, and the reader picks.** A match press sets
a recipe; KEEP (and Enter, which submits the form) sets the words as
typed. Typing a recipe's name never becomes that recipe by itself.

-}

import Expect
import Html.Attributes as Attr
import Page.Plan exposing (Archive(..), Outcome(..), Picture(..))
import Plan exposing (Day(..))
import Shelf
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector



-- FIXTURES


type Msg
    = Open Day
    | Input String
    | Cancel
    | Keep
    | Pick String String
    | Lift Day
    | Place Day
    | Remove Day
    | Clear
    | Make
    | ShareIt
    | CopyIt


summary : String -> String -> Shelf.Summary
summary slug title =
    { slug = slug
    , title = title
    , tested = "2026-09-20"
    , active = 10
    , total = 30
    , slot = [ "dinner" ]
    , course = "main"
    , flavor = []
    , method = "bake"
    , effort = "easy"
    , dietary = []
    , cuisine = []
    , keepsFor = Nothing
    }


archive : Archive
archive =
    Searchable
        [ summary "classic-lasagna" "Classic lasagna"
        , summary "donuts" "Donuts"
        ]


spaghetti : Plan.Meal
spaghetti =
    Plan.own "Spaghetti" |> Maybe.withDefault (Plan.recipe "x" "x")


{-| Donuts from the archive on Sunday, spaghetti of your own on
Wednesday.
-}
aWeek : Plan.Plan
aWeek =
    Plan.empty
        |> Plan.set Sun (Plan.recipe "donuts" "Donuts")
        |> Plan.set Wed spaghetti


config : Page.Plan.Config Msg
config =
    { plan = aWeek
    , archive = archive
    , lifted = Nothing
    , entry = Nothing
    , clearArmed = False
    , onOpen = Open
    , onInput = Input
    , onCancel = Cancel
    , onKeep = Keep
    , onPick = Pick
    , onLift = Lift
    , onPlace = Place
    , onRemove = Remove
    , onClear = Clear
    , picture = NotMade
    , outcome = Nothing
    , onMake = Make
    , onShare = ShareIt
    , onCopy = CopyIt
    }


made : { canShare : Bool, canCopy : Bool } -> Page.Plan.Config Msg
made can =
    { config
        | picture = Made { url = "blob:week", canShare = can.canShare, canCopy = can.canCopy }
    }


render : Page.Plan.Config Msg -> Query.Single Msg
render c =
    Query.fromHtml (Page.Plan.view c)


dayRow : Day -> Query.Single Msg -> Query.Single Msg
dayRow d page =
    page |> Query.find [ Selector.id ("day-" ++ Plan.dayKey d) ]


typing : String -> Query.Single Msg
typing words =
    render { config | entry = Just { day = Mon, text = words } }



-- TESTS


suite : Test
suite =
    describe "Page.Plan"
        [ describe "the week"
            [ test "draws seven days, Sunday first" <|
                \_ ->
                    render config
                        |> Query.findAll [ Selector.class "plan-day" ]
                        |> Query.first
                        |> Query.has [ Selector.id "day-sun" ]
            , test "all seven" <|
                \_ ->
                    render config
                        |> Query.findAll [ Selector.class "plan-day" ]
                        |> Query.count (Expect.equal 7)
            , test "an empty day is its name and nothing visible besides" <|
                \_ ->
                    render config
                        |> dayRow Mon
                        |> Query.find [ Selector.class "plan-open" ]
                        |> Query.children [ Selector.class "plan-meal-name" ]
                        |> Query.count (Expect.equal 0)
            , test "an empty day never says it is empty" <|
                \_ ->
                    render config
                        |> dayRow Mon
                        |> Query.hasNot [ Selector.text "Empty" ]
            , test "pressing an empty day opens it" <|
                \_ ->
                    render config
                        |> dayRow Mon
                        |> Query.find [ Selector.class "plan-open" ]
                        |> Event.simulate Event.click
                        |> Event.expect (Open Mon)
            , test "the standfirst counts days covered" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.class "plan-standfirst" ]
                        |> Query.has [ Selector.text "2 of 7 days planned." ]
            , test "an empty week says what a press does" <|
                \_ ->
                    render { config | plan = Plan.empty }
                        |> Query.find [ Selector.class "plan-standfirst" ]
                        |> Query.has [ Selector.text "Press a day to put a meal on it." ]
            , test "an empty week offers nothing to clear" <|
                \_ ->
                    render { config | plan = Plan.empty }
                        |> Query.hasNot [ Selector.class "plan-clear" ]
            ]
        , describe "a held day"
            [ test "an archive meal links to its recipe" <|
                \_ ->
                    render config
                        |> dayRow Sun
                        |> Query.find [ Selector.class "plan-recipe-link" ]
                        |> Query.has [ Selector.attribute (Attr.href "/recipe/donuts") ]
            , test "a meal of your own links nowhere" <|
                \_ ->
                    render config
                        |> dayRow Wed
                        |> Query.hasNot [ Selector.class "plan-recipe-link" ]
            , test "pressing the meal lifts it" <|
                \_ ->
                    render config
                        |> dayRow Wed
                        |> Query.find [ Selector.class "plan-meal" ]
                        |> Event.simulate Event.click
                        |> Event.expect (Lift Wed)
            , test "each Remove names what it removes" <|
                \_ ->
                    render config
                        |> dayRow Wed
                        |> Query.find [ Selector.class "plan-drop" ]
                        |> Query.has [ Selector.text " Spaghetti from Wednesday" ]
            ]
        , describe "a lifted meal"
            [ test "its own day is seated" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> dayRow Wed
                        |> Query.find [ Selector.class "plan-place" ]
                        |> Query.has
                            [ Selector.class "is-seated"
                            , Selector.attribute (Attr.attribute "aria-pressed" "true")
                            ]
            , test "and says , lifted to a screen reader" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> dayRow Wed
                        |> Query.has [ Selector.text ", lifted. Press to put it back" ]
            , test "every day becomes a place to set it down" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> Query.findAll [ Selector.class "plan-place" ]
                        |> Query.count (Expect.equal 7)
            , test "a full day says it will swap" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> dayRow Sun
                        |> Query.has [ Selector.text ", swap Spaghetti with Donuts" ]
            , test "pressing a day places it there" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> dayRow Fri
                        |> Query.find [ Selector.class "plan-place" ]
                        |> Event.simulate Event.click
                        |> Event.expect (Place Fri)
            , test "nothing destructive is under the hand" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "plan-drop" ]
                            , Query.hasNot [ Selector.class "plan-clear" ]
                            ]
            , test "the standfirst says what is held and how to put it back" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> Query.find [ Selector.class "plan-standfirst" ]
                        |> Query.has
                            [ Selector.text "Holding Spaghetti. Press a day to set it down, or Wednesday to put it back." ]
            ]
        , describe "the entry field"
            [ test "is labelled by its day" <|
                \_ ->
                    typing ""
                        |> Query.find [ Selector.tag "label" ]
                        |> Query.has
                            [ Selector.text "Monday"
                            , Selector.attribute (Attr.for "plan-entry")
                            ]
            , test "a match press sets the recipe" <|
                \_ ->
                    typing "lasagna"
                        |> Query.find [ Selector.class "plan-match" ]
                        |> Event.simulate Event.click
                        |> Event.expect (Pick "classic-lasagna" "Classic lasagna")
            , test "matches the way the shelf matches" <|
                \_ ->
                    typing "classic lasagna"
                        |> Query.findAll [ Selector.class "plan-match" ]
                        |> Query.count (Expect.equal 1)
            , test "Enter keeps the words as typed" <|
                \_ ->
                    typing "Spaghetti"
                        |> Query.find [ Selector.tag "form" ]
                        |> Event.simulate Event.submit
                        |> Event.expect Keep
            , test "KEEP says the words it will keep" <|
                \_ ->
                    typing "  Spaghetti "
                        |> Query.find [ Selector.class "plan-keep" ]
                        |> Query.has [ Selector.text "Keep “Spaghetti”" ]
            , test "a recipe's name typed out is still offered as words" <|
                \_ ->
                    -- The match is offered; KEEP is still there. Nothing
                    -- picks the recipe on the reader's behalf.
                    typing "donuts"
                        |> Expect.all
                            [ Query.has [ Selector.class "plan-match" ]
                            , Query.find [ Selector.class "plan-keep" ]
                                >> Query.has [ Selector.text "Keep “donuts”" ]
                            ]
            , test "a blank field cannot keep anything" <|
                \_ ->
                    typing "   "
                        |> Query.find [ Selector.class "plan-keep" ]
                        |> Query.has [ Selector.disabled True ]
            , test "nothing matching says so, and offers the words" <|
                \_ ->
                    typing "spaghetti"
                        |> Query.has [ Selector.text "Nothing in the archive matches. Keep it as written." ]
            , test "an archive that could not be searched still keeps words" <|
                \_ ->
                    render { config | archive = Unsearchable, entry = Just { day = Mon, text = "Soup" } }
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "plan-match" ]
                            , Query.find [ Selector.class "plan-keep" ]
                                >> Query.has [ Selector.disabled False ]
                            ]
            , test "Cancel leaves" <|
                \_ ->
                    typing "x"
                        |> Query.find [ Selector.class "plan-cancel" ]
                        |> Event.simulate Event.click
                        |> Event.expect Cancel
            ]
        , describe "the picture"
            [ test "is offered once there is a week to picture" <|
                \_ ->
                    render config
                        |> Query.find [ Selector.class "plan-make" ]
                        |> Event.simulate Event.click
                        |> Event.expect Make
            , test "is not offered for an empty week" <|
                \_ ->
                    render { config | plan = Plan.empty }
                        |> Query.hasNot [ Selector.class "plan-share" ]
            , test "is not offered while a meal is in the hand" <|
                \_ ->
                    render { config | lifted = Just Wed }
                        |> Query.hasNot [ Selector.class "plan-share" ]
            , test "is not offered beside an open day, so KEEP is the one volt" <|
                \_ ->
                    typing "Soup"
                        |> Query.hasNot [ Selector.class "plan-make" ]
            , test "says it is drawing while it draws" <|
                \_ ->
                    render { config | picture = Making }
                        |> Query.find [ Selector.class "plan-share" ]
                        |> Query.has [ Selector.text "Drawing the week…" ]
            , test "a failed draw says so, and offers another go" <|
                \_ ->
                    render { config | picture = Unmade }
                        |> Expect.all
                            [ Query.has [ Selector.text "The picture could not be drawn in this browser." ]
                            , Query.find [ Selector.class "plan-make" ]
                                >> Query.has [ Selector.text "Try again" ]
                            ]
            , test "the preview is the file" <|
                \_ ->
                    render (made { canShare = False, canCopy = False })
                        |> Query.find [ Selector.class "plan-picture" ]
                        |> Query.has [ Selector.attribute (Attr.src "blob:week") ]
            , test "and says in words what the picture says, empty days too" <|
                \_ ->
                    render (made { canShare = False, canCopy = False })
                        |> Query.find [ Selector.class "plan-picture" ]
                        |> Query.has
                            [ Selector.attribute
                                (Attr.alt
                                    ("The week, as a picture. Sunday: Donuts, from the archive. "
                                        ++ "Monday: nothing planned. Tuesday: nothing planned. "
                                        ++ "Wednesday: Spaghetti. Thursday: nothing planned. "
                                        ++ "Friday: nothing planned. Saturday: nothing planned."
                                    )
                                )
                            ]
            , test "SAVE is always there, and is a download of the same file" <|
                \_ ->
                    render (made { canShare = False, canCopy = False })
                        |> Query.find [ Selector.tag "a", Selector.class "plan-send" ]
                        |> Query.has
                            [ Selector.attribute (Attr.href "blob:week")
                            , Selector.attribute (Attr.attribute "download" "delishh-week.png")
                            ]
            , test "SHARE and COPY are absent where the browser cannot do them" <|
                \_ ->
                    render (made { canShare = False, canCopy = False })
                        |> Query.findAll [ Selector.tag "button", Selector.class "plan-send" ]
                        |> Query.count (Expect.equal 0)
            , test "SHARE sends the picture where the browser can" <|
                \_ ->
                    render (made { canShare = True, canCopy = False })
                        |> Query.find [ Selector.tag "button", Selector.class "plan-send" ]
                        |> Event.simulate Event.click
                        |> Event.expect ShareIt
            , test "COPY copies it where the browser can" <|
                \_ ->
                    render (made { canShare = False, canCopy = True })
                        |> Query.find [ Selector.tag "button", Selector.class "plan-send" ]
                        |> Event.simulate Event.click
                        |> Event.expect CopyIt
            , test "a refused share is reported as not shared" <|
                \_ ->
                    render (let c = made { canShare = True, canCopy = False } in { c | outcome = Just Refused })
                        |> Query.has [ Selector.text "Not shared. The share was cancelled or blocked." ]
            , test "boot.js's words map to outcomes, and anything else is a failure" <|
                \_ ->
                    [ "shared", "copied", "refused", "unsupported", "saved", "" ]
                        |> List.map Page.Plan.outcomeFromString
                        |> Expect.equal [ Shared, Copied, Refused, Unsupported, Failed, Failed ]
            ]
        , describe "clearing the week"
            [ test "armed is a word" <|
                \_ ->
                    render { config | clearArmed = True }
                        |> Query.find [ Selector.class "plan-clear" ]
                        |> Query.has [ Selector.text "Press again to clear" ]
            ]
        ]
