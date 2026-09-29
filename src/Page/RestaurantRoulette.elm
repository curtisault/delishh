module Page.RestaurantRoulette exposing (Config, view)

{-| Restaurant Roulette — `docs/decisions.md`, ruled 2026-09-28.

**The domain is a restaurant, and the page says so everywhere.** The
masthead, the standfirst, the entry field's label and its help line
all carry the word, because this is the one surface in the archive
that is not about cooking, and a reader who took it for a recipe
picker would be planning a dinner nobody is making.

**A browse-class surface, one acid.** Volt lands on SPIN — the one
actionable thing in view — and nowhere else. The settled name is
carried by type and by the sentence *Tonight:*, never by colour.

Four things that are decisions rather than details:

  - **The reel is a readout.** `Roulette.showing` reads the name off
    the clock; the answer was drawn at the press. While it runs the
    reel is hidden from assistive technology and SPIN is inert; the
    answer is written once into a polite live region when it lands.
  - **A veto is one press, for one spin.** *Not that one* is absent
    when the wheel would be empty without the answer.
  - **The pick lands on the week by one press**, as an own meal. The
    day row appears only once a name has settled, and a full day says
    so rather than doing nothing.
  - **Empty shows the field and no press.** A SPIN that would do
    nothing is a control lying about itself; one name spins to itself
    at once and says so.

-}

import Html exposing (Html, a, button, div, form, h1, h2, input, label, li, p, section, span, text, ul)
import Html.Attributes exposing (attribute, autocomplete, class, classList, disabled, for, href, id, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Plan exposing (Plan)
import Roulette exposing (Refusal(..), Roulette, Spin(..))
import Route
import Time


type alias Config msg =
    { roulette : Roulette
    , spin : Spin

    -- the instant the reel is read at
    , now : Time.Posix

    -- the entry field's text, and why the last ADD was refused
    , entry : String
    , refusal : Maybe Refusal

    -- the week, for what each day holds; the day the answer was put
    -- on; the day that was full
    , plan : Plan
    , placed : Maybe Plan.Day
    , refused : Maybe Plan.Day

    -- whether CLEAR has been armed by a first press
    , clearArmed : Bool
    , onInput : String -> msg
    , onAdd : msg
    , onRemove : String -> msg
    , onSpin : msg
    , onVeto : msg
    , onDay : Plan.Day -> msg
    , onClear : msg
    }


view : Config msg -> Html msg
view config =
    div [ class "roulette-layout" ]
        [ div [ class "restaurant-roulette leaf" ]
            [ div [ class "roulette-plate" ]
                [ h1 [ class "roulette-title" ] [ text "Restaurant Roulette" ]
                , p [ class "roulette-standfirst" ]
                    [ text "For the night nobody is cooking. Keep the places you like to order from or go out to, spin, and eat where it lands." ]
                ]
            , if Roulette.isEmpty config.roulette then
                text ""

              else
                wheel config
            , restaurants config
            ]
        ]



-- THE WHEEL


wheel : Config msg -> Html msg
wheel config =
    let
        spinning =
            case config.spin of
                Spinning _ ->
                    True

                _ ->
                    False
    in
    section [ class "roulette-wheel", attribute "aria-labelledby" "roulette-wheel-h" ]
        [ h2 [ id "roulette-wheel-h", class "roulette-h u" ] [ text "Spin" ]
        , reel config spinning
        , answer config
        , div [ class "roulette-actions" ]
            [ button
                [ type_ "button"
                , class "press-block roulette-spin"
                , classList [ ( "is-spinning", spinning ) ]
                , disabled spinning
                , onClick config.onSpin
                ]
                [ text (spinWord config.spin) ]
            , veto config
            ]
        , week config
        ]


spinWord : Spin -> String
spinWord spin =
    case spin of
        Idle ->
            "Spin"

        Spinning _ ->
            "Spinning"

        Settled _ ->
            "Spin again"


{-| The reel: a box of fixed height holding the name at this instant.
Hidden from assistive technology while it runs — thirty names read
aloud is not a spin — and the answer reaches a screen reader through
the sentence beneath, once.
-}
reel : Config msg -> Bool -> Html msg
reel config spinning =
    div
        [ class "roulette-reel"
        , classList [ ( "is-spinning", spinning ), ( "is-settled", isSettled config.spin ) ]
        , attribute "aria-hidden" "true"
        ]
        [ span [ class "roulette-reel-name" ]
            [ text
                (case Roulette.showing config.now config.spin of
                    Just name ->
                        name

                    Nothing ->
                        countSentence (Roulette.count config.roulette)
                )
            ]
        ]


countSentence : Int -> String
countSentence n =
    case n of
        1 ->
            "One place to pick from"

        _ ->
            String.fromInt n ++ " places to pick from"


{-| The answer, said once. Polite, so it is read when the reel lands
and not over the reader's own press.
-}
answer : Config msg -> Html msg
answer config =
    p [ class "roulette-answer", attribute "aria-live" "polite" ]
        [ case config.spin of
            Settled name ->
                if Roulette.count config.roulette == 1 then
                    text ("Tonight: " ++ name ++ ". Only one place to pick from.")

                else
                    text ("Tonight: " ++ name ++ ".")

            _ ->
                text ""
        ]


{-| NOT THAT ONE: a spin over every name but the answer. Absent when
that wheel would be empty.
-}
veto : Config msg -> Html msg
veto config =
    case config.spin of
        Settled name ->
            if List.isEmpty (Roulette.wheel (Just name) config.roulette) then
                text ""

            else
                button
                    [ type_ "button"
                    , class "roulette-veto u"
                    , onClick config.onVeto
                    ]
                    [ text "Not that one" ]

        _ ->
            text ""


{-| The seven days, once a name has settled. A press puts the name on
that day as an own meal through the plan's own `add`; a full day
answers with a sentence rather than doing nothing. Once placed, the
row gives way to the sentence and a link to the week.
-}
week : Config msg -> Html msg
week config =
    case ( config.spin, config.placed ) of
        ( Settled name, Just day ) ->
            div [ class "roulette-week" ]
                [ p [ class "roulette-week-note", attribute "aria-live" "polite" ]
                    [ text (name ++ " is on " ++ Plan.dayName day ++ ". ")
                    , a [ class "roulette-week-link u", href (Route.toPath Route.Plan) ] [ text "The whole week" ]
                    ]
                ]

        ( Settled _, Nothing ) ->
            div [ class "roulette-week", attribute "role" "group", attribute "aria-labelledby" "roulette-week-h" ]
                [ h2 [ id "roulette-week-h", class "roulette-h u" ] [ text "Put it on the week" ]
                , ul [ class "roulette-days" ] (List.map (dayPress config) Plan.days)
                , case config.refused of
                    Just d ->
                        p [ class "roulette-week-note", attribute "aria-live" "polite" ]
                            [ text (Plan.dayName d ++ " holds five. Five is a full day.") ]

                    Nothing ->
                        text ""
                ]

        _ ->
            text ""


dayPress : Config msg -> Plan.Day -> Html msg
dayPress config d =
    let
        held =
            List.length (Plan.entries d config.plan)

        full =
            held >= Plan.cap

        ( word, spoken ) =
            if full then
                ( "Full", ", holds five. Five is a full day" )

            else
                case held of
                    0 ->
                        ( "", ", put it here" )

                    1 ->
                        ( "1 meal", ", holds one meal. Press to add this after it" )

                    n ->
                        ( String.fromInt n ++ " meals", ", holds " ++ String.fromInt n ++ " meals. Press to add this after them" )
    in
    li []
        [ button
            [ type_ "button"
            , class "press-block roulette-day"
            , classList [ ( "is-full", full ) ]
            , onClick (config.onDay d)
            ]
            [ span [ class "roulette-dayname u", attribute "aria-hidden" "true" ] [ text (Plan.dayName d) ]
            , span [ class "roulette-holds", attribute "aria-hidden" "true" ] [ text word ]
            , span [ class "vh" ] [ text (Plan.dayName d ++ spoken) ]
            ]
        ]


isSettled : Spin -> Bool
isSettled spin =
    case spin of
        Settled _ ->
            True

        _ ->
            False



-- THE RESTAURANTS


restaurants : Config msg -> Html msg
restaurants config =
    let
        n =
            Roulette.count config.roulette
    in
    section [ class "roulette-list", attribute "aria-labelledby" "roulette-list-h" ]
        [ h2 [ id "roulette-list-h", class "roulette-h u" ]
            [ text
                (case n of
                    0 ->
                        "No restaurants yet"

                    1 ->
                        "One restaurant"

                    _ ->
                        String.fromInt n ++ " restaurants"
                )
            ]
        , if n == 0 then
            text ""

          else
            ul [ class "roulette-names" ] (List.map (row config) (Roulette.names config.roulette))
        , entryForm config
        , if n == 0 then
            text ""

          else
            div [ class "roulette-foot" ] [ clear config ]
        ]


row : Config msg -> String -> Html msg
row config name =
    li [ class "roulette-row" ]
        [ span [ class "roulette-name" ] [ text name ]
        , button
            [ type_ "button"
            , class "roulette-drop u"
            , onClick (config.onRemove name)
            ]
            [ text "Remove"
            , span [ class "vh" ] [ text (" " ++ name) ]
            ]
        ]


{-| One field and ADD. A `form`, so Enter adds. The label and the help
line both say *restaurant*: the field is where a reader arriving from
the shelf would type a recipe's name, and it is the place to tell
them this is not that.
-}
entryForm : Config msg -> Html msg
entryForm config =
    let
        field =
            "roulette-entry"

        blank =
            String.trim config.entry == ""
    in
    form [ class "roulette-entry", onSubmit config.onAdd ]
        [ label [ class "roulette-entry-label", for field ] [ text "Add a restaurant" ]
        , div [ class "roulette-entry-line" ]
            [ input
                [ id field
                , class "roulette-entry-input"
                , type_ "text"
                , autocomplete False
                , value config.entry
                , onInput config.onInput
                , attribute "aria-describedby" "roulette-entry-help"
                ]
                []
            , button
                [ type_ "submit"
                , class "press-block roulette-add"
                , disabled blank
                ]
                [ text "Add" ]
            ]
        , p [ id "roulette-entry-help", class "roulette-entry-help", attribute "aria-live" "polite" ]
            [ text
                (case config.refusal of
                    Just (Duplicate existing) ->
                        existing ++ " is already on the list."

                    Just Blank ->
                        "A name is enough, but it cannot be blank."

                    Nothing ->
                        "A name is enough. Nothing here is a recipe — a place you order from, or go to."
                )
            ]
        ]


clear : Config msg -> Html msg
clear config =
    button
        [ type_ "button"
        , class "roulette-clear u"
        , classList [ ( "is-armed", config.clearArmed ) ]
        , onClick config.onClear
        ]
        [ text
            (if config.clearArmed then
                "Press again to clear"

             else
                "Clear the list"
            )
        ]
