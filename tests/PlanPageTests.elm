module PlanPageTests exposing (suite)

{-| The meal plan page — `docs/decisions.md`.

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
    | Lift Day Int
    | Place Plan.Target
    | Remove Day Int
    | LabelOpen Day Int
    | SetLabel Day Int (Maybe String)
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
    , inspired = Nothing
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
    , labelOpen = Nothing
    , clearArmed = False
    , onOpen = Open
    , onInput = Input
    , onCancel = Cancel
    , onKeep = Keep
    , onPick = Pick
    , onLift = Lift
    , onPlace = Place
    , onRemove = Remove
    , onLabelOpen = LabelOpen
    , onLabel = SetLabel
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


{-| The week, with a second meal on Wednesday. -}
twoOnWed : Plan.Plan
twoOnWed =
    Plan.add Wed (Plan.recipe "classic-lasagna" "Classic lasagna") aWeek |> Result.withDefault aWeek


{-| The week, with five on one day. -}
fiveOn : Day -> Plan.Plan
fiveOn d =
    List.foldl (\_ p -> Plan.add d spaghetti p |> Result.withDefault p) aWeek (List.range 1 5)


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
                        |> Event.expect (Lift Wed 0)
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
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> dayRow Wed
                        |> Query.find [ Selector.class "plan-swap" ]
                        |> Query.has
                            [ Selector.class "is-seated"
                            , Selector.attribute (Attr.attribute "aria-pressed" "true")
                            ]
            , test "and says , lifted to a screen reader" <|
                \_ ->
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> dayRow Wed
                        |> Query.has [ Selector.text ", lifted. Press to put it back" ]
            , test "every empty day becomes a place to set it down" <|
                \_ ->
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> Expect.all
                            (List.map
                                (\d ->
                                    dayRow d
                                        >> Query.children [ Selector.class "plan-place" ]
                                        >> Query.count (Expect.equal 1)
                                )
                                [ Mon, Tue, Thu, Fri, Sat ]
                            )
            , test "its own day offers no end to set it at: that is putting it back" <|
                \_ ->
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> dayRow Wed
                        |> Query.hasNot [ Selector.class "plan-end" ]
            , test "a full day says it will swap" <|
                \_ ->
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> dayRow Sun
                        |> Query.has [ Selector.text ", swap Spaghetti with Donuts" ]
            , test "pressing a day places it there" <|
                \_ ->
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> dayRow Fri
                        |> Query.find [ Selector.class "plan-place" ]
                        |> Event.simulate Event.click
                        |> Event.expect (Place (Plan.OntoDay Fri))
            , test "nothing destructive is under the hand" <|
                \_ ->
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "plan-drop" ]
                            , Query.hasNot [ Selector.class "plan-clear" ]
                            ]
            , test "the standfirst says what is held and how to put it back" <|
                \_ ->
                    render { config | lifted = Just ( Wed, 0 ) }
                        |> Query.find [ Selector.class "plan-standfirst" ]
                        |> Query.has
                            [ Selector.text "Holding Spaghetti. Press a meal to swap with it, or Set here to put it at the end of a day. Press Spaghetti again to put it back." ]
            ]
        , describe "a day of several — docs/decisions.md"
            [ test "a week of one meal a day shows no label marks" <|
                \_ ->
                    render config
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "plan-label-mark" ]
                            , Query.hasNot [ Selector.text "No label" ]
                            ]
            , test "a held day offers ADD, quietly" <|
                \_ ->
                    render config
                        |> dayRow Wed
                        |> Query.find [ Selector.class "plan-add" ]
                        |> Event.simulate Event.click
                        |> Event.expect (Open Wed)
            , test "an empty day has no ADD: its name is the press" <|
                \_ ->
                    render config
                        |> dayRow Mon
                        |> Query.hasNot [ Selector.class "plan-add" ]
            , test "a day of five says so where ADD was" <|
                \_ ->
                    render { config | plan = fiveOn Thu }
                        |> dayRow Thu
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "plan-add" ]
                            , Query.has [ Selector.text "Five is a full day." ]
                            ]
            , test "a day of two shows each meal's label mark, in the data voice" <|
                \_ ->
                    render { config | plan = twoOnWed }
                        |> dayRow Wed
                        |> Query.findAll [ Selector.class "plan-label-mark" ]
                        |> Expect.all
                            [ Query.count (Expect.equal 2)
                            , Query.first >> Query.has [ Selector.class "mono", Selector.text "No label" ]
                            ]
            , test "a labelled meal on a day of one still shows its label" <|
                \_ ->
                    render { config | plan = aWeek |> Plan.label Wed 0 (Just "lunch") }
                        |> dayRow Wed
                        |> Query.find [ Selector.class "plan-label-mark" ]
                        |> Query.has [ Selector.text "lunch" ]
            , test "the mark opens the five words and None" <|
                \_ ->
                    render { config | plan = twoOnWed, labelOpen = Just ( Wed, 1 ) }
                        |> Query.findAll [ Selector.class "plan-label-opt" ]
                        |> Query.count (Expect.equal 6)
            , test "a word labels that meal" <|
                \_ ->
                    render { config | plan = twoOnWed, labelOpen = Just ( Wed, 1 ) }
                        |> Query.findAll [ Selector.class "plan-label-opt" ]
                        |> Query.index 1
                        |> Event.simulate Event.click
                        |> Event.expect (SetLabel Wed 1 (Just "lunch"))
            , test "each meal on a day is removed on its own" <|
                \_ ->
                    render { config | plan = twoOnWed }
                        |> dayRow Wed
                        |> Query.findAll [ Selector.class "plan-drop" ]
                        |> Query.index 1
                        |> Event.simulate Event.click
                        |> Event.expect (Remove Wed 1)
            , test "the standfirst counts meals once a day holds more than one" <|
                \_ ->
                    render { config | plan = twoOnWed }
                        |> Query.find [ Selector.class "plan-standfirst" ]
                        |> Query.has [ Selector.text "2 of 7 days planned, 3 meals." ]
            , test "held over a full day, the day's end is a sentence, not a press" <|
                \_ ->
                    render { config | plan = fiveOn Thu |> Plan.set Sun spaghetti, lifted = Just ( Sun, 0 ) }
                        |> dayRow Thu
                        |> Expect.all
                            [ Query.hasNot [ Selector.class "plan-end" ]
                            , Query.has [ Selector.text "Five is a full day." ]
                            ]
            , test "held, a meal on another day swaps with it" <|
                \_ ->
                    render { config | plan = twoOnWed, lifted = Just ( Sun, 0 ) }
                        |> dayRow Wed
                        |> Query.findAll [ Selector.class "plan-swap" ]
                        |> Query.index 1
                        |> Event.simulate Event.click
                        |> Event.expect (Place (Plan.OntoEntry Wed 1))
            , test "held, a held day's end sets it at the end" <|
                \_ ->
                    render { config | plan = twoOnWed, lifted = Just ( Sun, 0 ) }
                        |> dayRow Wed
                        |> Query.find [ Selector.class "plan-end" ]
                        |> Event.simulate Event.click
                        |> Event.expect (Place (Plan.OntoDay Wed))
            ]
        , describe "the entry field"
            [ test "is labelled by its day" <|
                \_ ->
                    typing ""
                        |> Query.find [ Selector.tag "label" ]
                        |> Query.has
                            [ Selector.text "A meal for Monday"
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
                    render { config | lifted = Just ( Wed, 0 ) }
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
            , test "the words say every meal of a day, with its label and source" <|
                \_ ->
                    render (let c = made { canShare = False, canCopy = False } in { c | plan = twoOnWed |> Plan.label Wed 0 (Just "lunch") })
                        |> Query.find [ Selector.class "plan-picture" ]
                        |> Query.has
                            [ Selector.attribute
                                (Attr.alt
                                    ("The week, as a picture. Sunday: Donuts, from the archive. "
                                        ++ "Monday: nothing planned. Tuesday: nothing planned. "
                                        ++ "Wednesday: Spaghetti, lunch; Classic lasagna, from the archive. "
                                        ++ "Thursday: nothing planned. Friday: nothing planned. Saturday: nothing planned."
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
