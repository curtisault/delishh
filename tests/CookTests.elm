module CookTests exposing (suite)

{-| Cook mode's live state — DS-01 §08, §10.

The two things here that can be wrong without looking wrong:

**A timer that drifts.** It counts to an absolute end rather than down
a decrementing counter, so a throttled background tab resumes correct
instead of minutes behind. A decrementing counter passes every test
you would think to write against it and loses four minutes the first
time you check a message.

**A wake badge that lies.** DS-01 §08 says hold the screen awake and
*say so on screen*. Every state a browser can hand back has to reach
the reader as its own sentence, because "screen held" on a browser
that refused is how you find out with your hands covered in flour.

-}

import Cook
import Expect
import Html.Attributes as Attr
import Page.Cook
import Recipe
import Scale
import Set
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector
import Time


at : Int -> Time.Posix
at seconds =
    Time.millisToPosix (seconds * 1000)


suite : Test
suite =
    describe "Cook"
        [ describe "the timer counts to an end, not down a counter"
            [ test "starts at its full duration" <|
                \_ ->
                    Cook.start 3 360 (at 0)
                        |> Cook.remaining (at 0)
                        |> Expect.equal 360
            , test "loses a second per second" <|
                \_ ->
                    Cook.start 3 360 (at 0)
                        |> Cook.remaining (at 1)
                        |> Expect.equal 359
            , test "a tab that slept for five minutes resumes correct" <|
                \_ ->
                    -- THE POINT. `Time.every` is throttled in a
                    -- background tab, so a decrementing counter would
                    -- be 300 seconds wrong here and look fine.
                    Cook.start 3 360 (at 0)
                        |> Cook.remaining (at 300)
                        |> Expect.equal 60
            , test "never goes negative" <|
                \_ ->
                    Cook.start 3 60 (at 0)
                        |> Cook.remaining (at 9999)
                        |> Expect.equal 0
            , test "expires exactly at zero, not before" <|
                \_ ->
                    let
                        timer =
                            Cook.start 3 60 (at 0)
                    in
                    ( Cook.expired (at 59) timer, Cook.expired (at 60) timer )
                        |> Expect.equal ( False, True )
            , test "remembers which step owns it" <|
                \_ ->
                    (Cook.start 4 60 (at 0)).step |> Expect.equal 4
            ]
        , describe "the clock never changes width as it counts"
            [ test "seconds are always two digits" <|
                \_ ->
                    -- A timer that reflows the step it sits in would
                    -- be motion the register never granted (§10).
                    [ 0, 5, 59, 60, 65, 600 ]
                        |> List.map Cook.clock
                        |> Expect.equal
                            [ "0:00", "0:05", "0:59", "1:00", "1:05", "10:00" ]
            , test "every reading under ten minutes is the same length" <|
                \_ ->
                    List.range 0 599
                        |> List.map (Cook.clock >> String.length)
                        |> List.filter (\n -> n /= 4)
                        |> Expect.equal []
            ]
        , describe "the wake badge says what is true"
            [ test "held is the only honest state" <|
                \_ ->
                    [ Cook.Held, Cook.Off, Cook.Unsupported, Cook.Refused ]
                        |> List.map Cook.wakeIsHonest
                        |> Expect.equal [ True, False, False, False ]
            , test "every state has its own sentence" <|
                \_ ->
                    -- Not one sentence with a colour swapped: a reader
                    -- who cannot see the colour still has to learn the
                    -- screen is about to go dark (§04).
                    [ Cook.Held, Cook.Off, Cook.Unsupported, Cook.Refused ]
                        |> List.map Cook.wakeNotice
                        |> (\notices ->
                                List.length notices
                                    - List.length (dedupe notices)
                                    |> Expect.equal 0
                           )
            , test "an unsupported browser is named as such, not as off" <|
                \_ ->
                    Cook.wakeNotice Cook.Unsupported
                        |> String.contains "no wake lock"
                        |> Expect.equal True
            , test "only the held notice omits the warning" <|
                \_ ->
                    [ Cook.Off, Cook.Unsupported, Cook.Refused ]
                        |> List.map (Cook.wakeNotice >> String.contains "will sleep")
                        |> Expect.equal [ True, True, True ]
            , test "and the held one does not warn" <|
                \_ ->
                    Cook.wakeNotice Cook.Held
                        |> String.contains "will sleep"
                        |> Expect.equal False
            ]
        , viewSuite
        , describe "the port's vocabulary round-trips"
            [ test "each flag boot.js can send maps to its own state" <|
                \_ ->
                    [ "held", "unsupported", "refused", "off" ]
                        |> List.map Cook.wakeFromFlag
                        |> Expect.equal
                            [ Cook.Held, Cook.Unsupported, Cook.Refused, Cook.Off ]
            , test "anything unrecognised falls back to off, never to held" <|
                \_ ->
                    -- The safe default is the one that warns.
                    Cook.wakeFromFlag "something-new"
                        |> Expect.equal Cook.Off
            ]
        ]


-- THE VIEW
--
-- Rendered rather than driven: the browser tooling could not be made
-- to click a step this session, and the contract these hold is the
-- one that matters anyway — what a stamped step LOOKS like, and that
-- an expired timer hands back the tell rather than an alarm.


step : Int -> Maybe String -> Maybe Int -> Recipe.Step
step n cue timer =
    { n = n, text = "Step " ++ String.fromInt n, cue = cue, timer = timer }


fixture : Recipe.Recipe
fixture =
    { slug = "salted-caramel"
    , title = "Salted Caramel"
    , tested = "2026-03-11"
    , yield = { amount = 340, unit = "g", servings = Just 8 }
    , time = { active = 15, total = 45 }
    , slot = [ "dessert" ]
    , course = "sauce"
    , flavor = [ { name = "sweet", level = Just 3 } ]
    , method = "sugar-work"
    , effort = "focused"
    , dietary = []
    , cuisine = []
    , print = "sheet"
    , photo = Nothing
    , keepsFor = Just { where_ = "fridge", amount = 14, unit = "d" }
    , inspired = Nothing
    , gauges = []
    , ingredients =
        [ { name = Nothing
          , items =
                [ { amount = Just { value = 200, max = Nothing, text = "200" }
                  , unit = Just "g"
                  , unitKind = Just "mass"
                  , indivisible = False
                  , item = "caster sugar"
                  , note = Nothing
                  , shop = Just { aisle = "baking", buyAs = "caster sugar" }
                  }
                ]
          }
        ]
    , equipment = []
    , steps = [ step 1 (Just "6–9 MIN · UNTIL THE EDGES RUN CLEAR") (Just 360) ]
    , watchpoints = [ "Past 190 °C it is bitter." ]
    , rescues = []
    , keeps = []
    , note = []
    }


{-| A second specimen, for the rail: named ingredient groups, three
steps, and rescues — including one that cannot be saved. The bench
fixture above deliberately has none of those, which is what makes it
the proof that an absent block is an absent row.
-}
richer : Recipe.Recipe
richer =
    { fixture
        | ingredients =
            [ { name = Just "Chili", items = [] }
            , { name = Just "Cornbread lid", items = [] }
            ]
        , steps =
            [ step 1 Nothing Nothing
            , step 2 Nothing Nothing
            , step 3 Nothing Nothing
            ]
        , rescues =
            [ { symptom = "Grainy", recoverable = True, text = "Add 30 g water." }
            , { symptom = "Bitter", recoverable = False, text = "Past 190 °C." }
            ]
    }


rendered :
    { factor : Float, done : List Int, timer : Maybe Cook.Timer, now : Int, wake : Cook.Wake }
    -> Query.Single ()
rendered =
    render fixture Nothing


{-| The richer specimen, with an optional anchor standing in for what
boot.js would have reported as the reader's position.
-}
richly : Maybe String -> List Int -> Query.Single ()
richly active done =
    render richer active { factor = 1, done = done, timer = Nothing, now = 0, wake = Cook.Held }


render :
    Recipe.Recipe
    -> Maybe String
    -> { factor : Float, done : List Int, timer : Maybe Cook.Timer, now : Int, wake : Cook.Wake }
    -> Query.Single ()
render recipe active opts =
    Query.fromHtml
        (Page.Cook.view
            { recipe = recipe
            , active = active
            , factor =
                Scale.factors
                    |> List.filter (\f -> Scale.toFloat f == opts.factor)
                    |> List.head
                    |> Maybe.withDefault Scale.one
            , done = Set.fromList opts.done
            , onStamp = always ()
            , timer = opts.timer
            , now = at opts.now
            , onStartTimer = \_ _ -> ()
            , onStopTimer = ()
            , wake = opts.wake
            }
        )


plain : Query.Single ()
plain =
    rendered { factor = 1, done = [], timer = Nothing, now = 0, wake = Cook.Held }


viewSuite : Test
viewSuite =
    describe "the cook screen"
        [ test "says ×1 plainly when nothing is scaled" <|
            \_ -> plain |> Query.has [ Selector.text "×1 — as written" ]
        , test "and shouts the factor when something is" <|
            \_ ->
                -- A scaled recipe that does not say it is scaled is
                -- dangerous (§08), and a printout has no live control
                -- to check against.
                rendered { factor = 1.5, done = [], timer = Nothing, now = 0, wake = Cook.Held }
                    |> Query.has [ Selector.text "SCALED ×1.5" ]
        , test "quantities are scaled, not the originals" <|
            \_ ->
                rendered { factor = 1.5, done = [], timer = Nothing, now = 0, wake = Cook.Held }
                    |> Query.has [ Selector.text "300 g" ]
        , test "the wake badge reports what actually happened" <|
            \_ ->
                rendered { factor = 1, done = [], timer = Nothing, now = 0, wake = Cook.Unsupported }
                    |> Query.has [ Selector.text "Screen will sleep — this browser has no wake lock" ]
        , test "a stamped step keeps its words" <|
            \_ ->
                -- STAMPED, NOT GREYED. You will re-read a done step to
                -- check what you already did (§08), so the test that
                -- matters is that the text survives the stamp.
                rendered { factor = 1, done = [ 1 ], timer = Nothing, now = 0, wake = Cook.Held }
                    |> Expect.all
                        [ Query.has [ Selector.text "Step 1" ]
                        , Query.has [ Selector.text "Done" ]
                        , Query.has [ Selector.class "is-done" ]
                        ]
        , test "an unstamped step carries no done mark" <|
            \_ -> plain |> Query.hasNot [ Selector.class "is-done" ]
        , test "the step is the tap target, and it says whether it is pressed" <|
            \_ ->
                plain
                    |> Query.find [ Selector.class "cook-stamp" ]
                    |> Query.has [ Selector.attribute (Attr.attribute "aria-pressed" "false") ]
        , test "a step with a duration offers to count it" <|
            \_ -> plain |> Query.has [ Selector.text "Start 6:00" ]
        , test "a running timer shows the clock, not the offer" <|
            \_ ->
                rendered
                    { factor = 1
                    , done = []
                    , timer = Just (Cook.start 1 360 (at 0))
                    , now = 60
                    , wake = Cook.Held
                    }
                    |> Expect.all
                        [ Query.has [ Selector.text "5:00" ]
                        , Query.hasNot [ Selector.text "Start 6:00" ]
                        ]
        , test "an expired timer hands back the step's own tell" <|
            \_ ->
                -- The clock was never the answer — the tell was (§05).
                -- No alarm, because the archive does not know it is
                -- done; it knows when to start looking.
                rendered
                    { factor = 1
                    , done = []
                    , timer = Just (Cook.start 1 360 (at 0))
                    , now = 400
                    , wake = Cook.Held
                    }
                    |> Query.has
                        [ Selector.text "Time up — 6–9 MIN · UNTIL THE EDGES RUN CLEAR" ]
        , test "watchpoints stay on screen rather than a tap away" <|
            \_ -> plain |> Query.has [ Selector.text "Past 190 °C it is bitter." ]
        , test "the way out is a link, not a gesture" <|
            \_ ->
                plain
                    |> Query.find [ Selector.class "cook-exit" ]
                    |> Query.has [ Selector.attribute (Attr.href "/recipe/salted-caramel") ]

        -- RESCUES, on the screen you are standing in front of when it
        -- goes wrong. Nobody leaves cook mode to find the document
        -- with a pan smoking, which is what made their absence here a
        -- bug rather than a scope decision.
        , test "rescues are on the cook screen" <|
            \_ ->
                richly Nothing []
                    |> Expect.all
                        [ Query.has [ Selector.text "Grainy" ]
                        , Query.has [ Selector.text "Add 30 g water." ]
                        ]
        , test "one that cannot be saved says so in words, not only in a rule" <|
            \_ ->
                -- The bad news has to be readable rather than merely
                -- orange (§04) — and more so before you spend another
                -- twenty minutes on it.
                richly Nothing []
                    |> Expect.all
                        [ Query.has [ Selector.text "Cannot be saved" ]
                        , Query.has [ Selector.class "is-terminal" ]
                        ]
        , test "rescues come last: the order the cook needs them in" <|
            \_ ->
                -- Watchpoints are the limits you hold to while it is
                -- going right; a rescue is for after it has not.
                richly Nothing []
                    |> Query.find [ Selector.class "cook-layout" ]
                    |> Query.children []
                    |> Query.index -1
                    |> Query.has [ Selector.id "cook-rescues" ]
        , test "a recipe with no rescues grows no rescue block" <|
            \_ -> plain |> Query.hasNot [ Selector.text "Cannot be saved" ]
        , describe "the rail"
        [ test "it lists the blocks this cook actually has" <|
            \_ ->
                richly Nothing []
                    |> Query.find [ Selector.class "cook-nav" ]
                    |> Expect.all
                        [ Query.has [ Selector.text "Ingredients" ]
                        , Query.has [ Selector.text "Steps" ]
                        , Query.has [ Selector.text "Watchpoints" ]
                        , Query.has [ Selector.text "Rescues" ]
                        ]
        , test "an absent block is an absent row" <|
            \_ ->
                -- The rail cannot be allowed to offer an anchor that
                -- resolves to nothing — the same rule the recipe
                -- page's nav keeps.
                plain
                    |> Query.find [ Selector.class "cook-nav" ]
                    |> Query.hasNot [ Selector.text "Rescues" ]
        , test "a named ingredient group is a row" <|
            \_ ->
                richly Nothing []
                    |> Query.find [ Selector.class "cook-nav" ]
                    |> Expect.all
                        [ Query.has [ Selector.text "Chili" ]
                        , Query.has [ Selector.text "Cornbread lid" ]
                        ]
        , test "an unnamed group is not, because it would name nothing" <|
            \_ ->
                plain
                    |> Query.find [ Selector.class "cook-nav" ]
                    |> Query.findAll [ Selector.class "cook-nav-sub" ]
                    |> Query.count (Expect.equal 0)
        , test "every step gets a chip" <|
            \_ ->
                richly Nothing []
                    |> Query.find [ Selector.class "cook-nav-steps" ]
                    |> Query.children []
                    |> Query.count (Expect.equal 3)
        , test "a done step's chip says done to a screen reader too" <|
            \_ ->
                -- The fill is the mark an eye reads; this is the other
                -- carrier. Information is never colour-only, and a
                -- filled square is not a sentence (§04).
                richly Nothing [ 2 ]
                    |> Query.find [ Selector.classes [ "cook-nav-step", "is-done" ] ]
                    |> Query.has
                        [ Selector.attribute (Attr.attribute "aria-label" "Step 2, done") ]
        , test "an unstamped chip claims nothing" <|
            \_ ->
                richly Nothing []
                    |> Query.findAll [ Selector.class "is-done" ]
                    |> Query.count (Expect.equal 0)
        , test "the reader's position is marked, and stated" <|
            \_ ->
                richly (Just "cook-steps") []
                    |> Query.find [ Selector.classes [ "cook-nav-link", "is-active" ] ]
                    |> Query.has
                        [ Selector.attribute (Attr.attribute "aria-current" "true") ]
        , test "a step under the eye marks its own chip" <|
            \_ ->
                richly (Just "cook-step-2") []
                    |> Query.find [ Selector.classes [ "cook-nav-step", "is-active" ] ]
                    |> Query.has [ Selector.text "02" ]
        , test "no position, no mark — never a row guessed at" <|
            \_ ->
                richly Nothing []
                    |> Query.findAll [ Selector.class "is-active" ]
                    |> Query.count (Expect.equal 0)
            ]
        ]


dedupe : List String -> List String
dedupe =
    List.foldl
        (\x acc ->
            if List.member x acc then
                acc

            else
                acc ++ [ x ]
        )
        []
