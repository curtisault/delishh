module Page.Cook exposing (Config, view)

{-| Cook mode — DS-01 §08.

**Reading a recipe while cooking is a different activity from
browsing one**, and it imposes constraints no other screen in the
product has: you are two to three feet away, your hands are wet or
greasy or full, the light is bad, and you are under time pressure
with something on the heat.

So this screen breaks the type scale in the one direction nothing
else does — body at 20px equivalent or larger, step numbers larger
again — and every rule below follows from the hands:

  - **No hover-only information, anywhere.** There may be no pointer
    at all, and if there is one it is attached to a dirty hand.
  - **Completed steps stamp; they never grey out.** You will re-read a
    done step to check what you already did. Tagged, not disabled.
  - **Tap targets at 2.75rem minimum**, scaling with the text.
  - **The scale is displayed permanently and cannot be changed here.**
    It is set before you start (§08). A scaled recipe that does not
    say it is scaled is dangerous, and a scale control you could
    nudge with a forearm mid-cook is worse.

-}

import Cook exposing (Wake)
import Html exposing (Html, a, div, h1, h2, li, ol, p, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, type_)
import Html.Events exposing (onClick)
import Recipe exposing (Recipe)
import Scale
import Set exposing (Set)
import Time


type alias Config msg =
    { recipe : Recipe
    , factor : Scale.Factor
    , done : Set Int
    , onStamp : Int -> msg
    , timer : Maybe Cook.Timer
    , now : Time.Posix
    , onStartTimer : Int -> Int -> msg
    , onStopTimer : msg
    , wake : Wake
    }


view : Config msg -> Html msg
view config =
    let
        r =
            config.recipe
    in
    div
        [ class "cook-layout"
        , class ("acid-" ++ Recipe.dominantAcid r)
        ]
        [ header config
        , ingredients config
        , steps config
        , watchpoints r
        ]



-- THE HEADER


header : Config msg -> Html msg
header config =
    let
        r =
            config.recipe

        scaled =
            Scale.toFloat config.factor /= 1
    in
    div [ class "cook-head" ]
        [ div [ class "cook-head-row" ]
            [ h1 [ class "cook-title" ] [ text r.title ]
            , a
                [ class "cook-exit u"
                , href ("/recipe/" ++ r.slug)
                ]
                [ text "Exit" ]
            ]
        , div [ class "cook-badges" ]
            [ -- Permanently, and loudly when it is not ×1. This is the
              -- one number on the screen that, if wrong, ruins the dish
              -- rather than merely the timing.
              span
                [ class "cook-scale u", classList [ ( "is-scaled", scaled ) ] ]
                [ text
                    (if scaled then
                        "SCALED " ++ Scale.label config.factor

                     else
                        "×1 — as written"
                    )
                ]
            , wakeBadge config.wake
            ]
        ]


{-| The wake-lock notice, saying what is actually true.

Carries its word as well as its mark, so it survives a colour-blind
reader and a monochrome screenshot alike — and so the bad news is
readable rather than merely orange (§04).

-}
wakeBadge : Wake -> Html msg
wakeBadge wake =
    span
        [ class "cook-wake u"
        , classList [ ( "is-held", Cook.wakeIsHonest wake ) ]
        ]
        [ text (Cook.wakeNotice wake) ]



-- INGREDIENTS


{-| Scaled, in the data voice, at cook-mode size. Present because the
alternative is holding a phone in one hand and scrolling back up with
the other.
-}
ingredients : Config msg -> Html msg
ingredients config =
    div [ class "cook-block" ]
        [ h2 [ class "cook-h u" ] [ text "Ingredients" ]
        , div []
            (List.map (ingredientGroup config) config.recipe.ingredients)
        ]


ingredientGroup : Config msg -> Recipe.IngredientGroup -> Html msg
ingredientGroup config group =
    div []
        ((case group.name of
            Just name ->
                [ h2 [ class "cook-sub u" ] [ text name ] ]

            Nothing ->
                []
         )
            ++ [ ul [ class "cook-ings" ]
                    (List.map (ingredientRow config) group.items)
               ]
        )


ingredientRow : Config msg -> Recipe.Ingredient -> Html msg
ingredientRow config item =
    let
        scaled =
            Maybe.map
                (\a ->
                    Scale.ingredient config.factor
                        { text = a.text
                        , value = a.value
                        , max = a.max
                        , unit = item.unit
                        , kind = item.unitKind
                        , indivisible = item.indivisible
                        }
                )
                item.amount
    in
    li [ class "cook-ing" ]
        [ span [ class "cook-qty mono" ]
            [ text
                (case scaled of
                    Just s ->
                        s.text
                            ++ Maybe.withDefault ""
                                (Maybe.map (\u -> " " ++ Scale.unitLabel s.text u) item.unit)

                    Nothing ->
                        ""
                )
            ]
        , span []
            [ text item.item
            , case item.note of
                Just n ->
                    span [ class "cook-ing-note" ] [ text (", " ++ n) ]

                Nothing ->
                    text ""
            ]
        , case Maybe.andThen .note scaled of
            Just n ->
                span [ class "cook-scaled-note" ] [ text n ]

            Nothing ->
                text ""
        ]



-- STEPS


steps : Config msg -> Html msg
steps config =
    div [ class "cook-block" ]
        [ h2 [ class "cook-h u" ] [ text "Steps" ]
        , ol [ class "cook-steps" ] (List.map (step config) config.recipe.steps)
        ]


{-| One step, at arm's length.

The whole row is the tap target — a 2.75rem button inside a step is a
thing to aim at, and aiming is what wet hands cannot do. Stamping is
the only thing tapping the step does; the timer is its own control so
that reaching for one can never trigger the other.

-}
step : Config msg -> Recipe.Step -> Html msg
step config s =
    let
        stamped =
            Set.member s.n config.done

        running =
            case config.timer of
                Just t ->
                    t.step == s.n

                Nothing ->
                    False
    in
    li
        [ class "cook-step"
        , classList [ ( "is-done", stamped ), ( "is-running", running ) ]
        ]
        [ Html.button
            [ type_ "button"
            , class "cook-stamp"
            , attribute "aria-pressed"
                (if stamped then
                    "true"

                 else
                    "false"
                )
            , onClick (config.onStamp s.n)
            ]
            [ span [ class "cook-n mono" ]
                [ text (String.padLeft 2 '0' (String.fromInt s.n)) ]
            , span [ class "cook-step-body" ]
                [ p [ class "cook-text" ] [ text s.text ]
                , case s.cue of
                    Just cue ->
                        p [ class "cook-cue mono u" ] [ text cue ]

                    Nothing ->
                        text ""
                ]

            -- Stamped, not greyed: a completed step stays fully
            -- legible because you WILL re-read it to check what you
            -- already did (§08).
            , if stamped then
                span [ class "cook-done-mark u" ] [ text "Done" ]

              else
                text ""
            ]
        , timerFor config s
        ]


{-| The step's timer, when its cue named a duration the build could
count down.

On expiry it shows **the step's own doneness cue**, not an alarm. The
clock was never the answer — the tell was (§05), and the timer's job
was only ever to say when to start looking.

-}
timerFor : Config msg -> Recipe.Step -> Html msg
timerFor config s =
    case s.timer of
        Nothing ->
            text ""

        Just seconds ->
            case config.timer of
                Just t ->
                    if t.step /= s.n then
                        startButton config s.n seconds

                    else if Cook.expired config.now t then
                        div [ class "cook-timer is-up" ]
                            [ span [ class "cook-timer-clock mono" ] [ text "0:00" ]
                            , span [ class "cook-timer-tell u" ]
                                [ text
                                    ("Time up — "
                                        ++ Maybe.withDefault "check it" s.cue
                                    )
                                ]
                            , stopButton config "Clear"
                            ]

                    else
                        div [ class "cook-timer is-running" ]
                            [ span [ class "cook-timer-clock mono" ]
                                [ text (Cook.clock (Cook.remaining config.now t)) ]
                            , stopButton config "Stop"
                            ]

                Nothing ->
                    startButton config s.n seconds


startButton : Config msg -> Int -> Int -> Html msg
startButton config n seconds =
    div [ class "cook-timer" ]
        [ Html.button
            [ type_ "button"
            , class "cook-timer-btn u"
            , onClick (config.onStartTimer n seconds)
            ]
            [ text ("Start " ++ Cook.clock seconds) ]
        ]


stopButton : Config msg -> String -> Html msg
stopButton config label =
    Html.button
        [ type_ "button"
        , class "cook-timer-btn u"
        , onClick config.onStopTimer
        ]
        [ text label ]



-- WATCHPOINTS


{-| The critical limits, kept on screen rather than a tap away. These
are the sentences that decide whether the dish works, and cook mode is
exactly when you need them without navigating.
-}
watchpoints : Recipe -> Html msg
watchpoints r =
    if List.isEmpty r.watchpoints then
        text ""

    else
        div [ class "cook-block" ]
            [ h2 [ class "cook-h u" ] [ text "Watchpoints" ]
            , ul [ class "cook-watch" ]
                (List.map (\w -> li [] [ text w ]) r.watchpoints)
            ]
