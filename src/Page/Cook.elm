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
import Html exposing (Html, a, div, h1, h2, li, ol, p, section, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, id, type_)
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

    -- the block or step under the reader's eye, reported by boot.js
    -- and marked in the rail. Nothing before the first scroll.
    , active : Maybe String
    }


view : Config msg -> Html msg
view config =
    let
        r =
            config.recipe
    in
    div [ class "cook-shell", class ("acid-" ++ Recipe.dominantAcid r) ]
        [ sideNav config
        , div [ class "cook-layout" ]
            [ header config
            , ingredients config
            , steps config
            , watchpoints r

            -- Last, and last on purpose. Watchpoints are limits you
            -- hold to while it is going right; rescues are what you
            -- reach for once it has not. They arrive in the order the
            -- cook needs them.
            , rescues r
            ]
        ]



-- THE RAIL


{-| The rail — where you are in the cook, and the way back to any of
it without scrolling past a hot pan.

**It is not the recipe page's nav at cook scale.** That one lists
seven blocks; this one has to answer "which step was I on" from two
feet away, which means the steps themselves are rows. They are their
numbers rather than their sentences: a nav that repeated twelve
step texts would be the document again, and a document is the thing
you came here to stop reading.

The step chips carry **done as a fill, not as a colour** — filled
against outlined is a shape a monochrome screen and a colour-blind
reader both keep (§04), and it is the one glance that says how far
in you are.

Hidden below 64rem, for the reason the recipe page's nav is: on a
phone there is no "side", and a list of anchors above the ingredients
costs exactly what it claims to save.

-}
sideNav : Config msg -> Html msg
sideNav config =
    let
        r =
            config.recipe
    in
    Html.nav [ class "cook-nav", attribute "aria-label" "On this cook" ]
        [ div [ class "cook-nav-inner" ]
            (span [ class "cook-nav-head mono" ] [ text (methodWord r.method) ]
                :: navLink config "cook-ingredients" "Ingredients"
                :: List.filterMap (groupLink config) (List.indexedMap Tuple.pair r.ingredients)
                ++ navLink config "cook-steps" "Steps"
                :: stepStrip config
                :: navFor config "cook-watchpoints" "Watchpoints" r.watchpoints
                ++ navFor config "cook-rescues" "Rescues" r.rescues
            )
        ]


{-| A row for a block that may not be there. An absent block is an
absent row, the same rule the recipe page's nav follows: a rail cannot
offer an anchor that resolves to nothing.
-}
navFor : Config msg -> String -> String -> List a -> List (Html msg)
navFor config anchor label items =
    if List.isEmpty items then
        []

    else
        [ navLink config anchor label ]


navLink : Config msg -> String -> String -> Html msg
navLink config anchor label =
    let
        here =
            config.active == Just anchor
    in
    a
        (class "cook-nav-link u"
            :: classList [ ( "is-active", here ) ]
            :: href ("#" ++ anchor)
            -- present or absent, never "false" — the contract the
            -- documents' rail and the recipe's nav both keep
            :: (if here then
                    [ attribute "aria-current" "true" ]

                else
                    []
               )
        )
        [ text label ]


{-| An ingredient group, **only when it has a name.** An unnamed group
is the recipe's one list, and a rail row reading "Ingredients" twice
is a row that answers nothing. Scrolling through an unnamed group
leaves the Ingredients row marked, which is the truth.
-}
groupLink : Config msg -> ( Int, Recipe.IngredientGroup ) -> Maybe (Html msg)
groupLink config ( i, group ) =
    Maybe.map
        (\name ->
            let
                anchor =
                    groupAnchor i

                here =
                    config.active == Just anchor
            in
            a
                (class "cook-nav-link cook-nav-sub u"
                    :: classList [ ( "is-active", here ) ]
                    :: href ("#" ++ anchor)
                    :: (if here then
                            [ attribute "aria-current" "true" ]

                        else
                            []
                       )
                )
                [ text name ]
        )
        group.name


stepStrip : Config msg -> Html msg
stepStrip config =
    div [ class "cook-nav-steps" ]
        (List.map (stepChip config) config.recipe.steps)


stepChip : Config msg -> Recipe.Step -> Html msg
stepChip config s =
    let
        anchor =
            stepAnchor s.n

        here =
            config.active == Just anchor

        stamped =
            Set.member s.n config.done
    in
    a
        (class "cook-nav-step mono"
            :: classList [ ( "is-active", here ), ( "is-done", stamped ) ]
            :: href ("#" ++ anchor)
            -- The fill says "done" to an eye; this says it to a
            -- screen reader. Neither is the only carrier (§04).
            :: attribute "aria-label"
                ("Step "
                    ++ String.fromInt s.n
                    ++ (if stamped then
                            ", done"

                        else
                            ""
                       )
                )
            :: (if here then
                    [ attribute "aria-current" "true" ]

                else
                    []
               )
        )
        [ text (String.padLeft 2 '0' (String.fromInt s.n)) ]


groupAnchor : Int -> String
groupAnchor i =
    "cook-group-" ++ String.fromInt i


stepAnchor : Int -> String
stepAnchor n =
    "cook-step-" ++ String.fromInt n


{-| The method as the rail wears it, the same word the recipe page's
nav head carries — one recipe, one name for what it is.
-}
methodWord : String -> String
methodWord =
    String.replace "-" " " >> String.toUpper



-- THE HEADER


header : Config msg -> Html msg
header config =
    let
        r =
            config.recipe

        scaled =
            Scale.toFloat config.factor /= 1
    in
    -- The id is how `Main.stickyChromeHeight` measures what this
    -- covers: it is the tallest sticky chrome in the product, and an
    -- anchor that ignored it would land every step underneath the
    -- scale badge.
    div [ id "cook-head", class "cook-head" ]
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
    section [ id "cook-ingredients", class "cook-block" ]
        [ h2 [ class "cook-h u" ] [ text "Ingredients" ]
        , div []
            (List.indexedMap (ingredientGroup config) config.recipe.ingredients)
        ]


{-| A named group is a `<section id>` and therefore something the rail
can mark and jump to; an unnamed one is a plain list. An id on a group
with no name would be an anchor with no row, and the reading line
would land on it and unmark the block above.
-}
ingredientGroup : Config msg -> Int -> Recipe.IngredientGroup -> Html msg
ingredientGroup config i group =
    let
        body =
            [ ul [ class "cook-ings" ]
                (List.map (ingredientRow config) group.items)
            ]
    in
    case group.name of
        Just name ->
            section [ id (groupAnchor i) ]
                (h2 [ class "cook-sub u" ] [ text name ] :: body)

        Nothing ->
            div [] body


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
    section [ id "cook-steps", class "cook-block" ]
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
        [ id (stepAnchor s.n)
        , class "cook-step"
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
        section [ id "cook-watchpoints", class "cook-block" ]
            [ h2 [ class "cook-h u" ] [ text "Watchpoints" ]
            , ul [ class "cook-watch" ]
                (List.map (\w -> li [] [ text w ]) r.watchpoints)
            ]



-- RESCUES


{-| What has gone wrong, what caused it, and whether it can be saved
— on the screen you are standing in front of when it goes wrong.

**This block was missing from cook mode, and it is the one block
whose whole subject is the present tense.** Watchpoints are the limits
you hold to while it is going right; a rescue is for the moment it has
not, which is exactly when leaving cook mode to find the document is
the last thing anybody is going to do with a pan smoking.

Last on the page for the same reason: you scroll to it when you need
it, and never otherwise.

A rescue that cannot be saved is **marked, not softened**. Saying "it
does not come back" plainly is the most generous sentence a recipe can
carry (DS-01 §06), and it is more generous still before you have spent
another twenty minutes on it.

-}
rescues : Recipe -> Html msg
rescues r =
    if List.isEmpty r.rescues then
        text ""

    else
        section [ id "cook-rescues", class "cook-block" ]
            [ h2 [ class "cook-h u" ] [ text "Rescues" ]
            , ul [ class "cook-rescues" ] (List.map rescue r.rescues)
            ]


rescue : Recipe.Rescue -> Html msg
rescue x =
    li
        [ class "cook-rescue"
        , classList [ ( "is-terminal", not x.recoverable ) ]
        ]
        [ span [ class "cook-rescue-sym u" ] [ text x.symptom ]
        , span [ class "cook-rescue-text" ] [ text x.text ]
        , if x.recoverable then
            text ""

          else
            -- Carries its word as well as its mark: the bad news has
            -- to be readable, not merely orange (§04).
            span [ class "cook-rescue-flag u" ] [ text "Cannot be saved" ]
        ]
