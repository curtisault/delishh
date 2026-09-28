module Page.Plan exposing (Archive(..), Config, Entry, Outcome(..), Picture(..), alt, outcomeFromString, view)

{-| The meal plan — the week, Sunday to Saturday. `docs/meal-planner.md`.

**A fourth surface, and it runs quiet**, in the shopping list's
register: `--page-*` marks only, the neutral press face, and volt on
the one actionable thing in view — KEEP, when the entry field is
open. Like the list, **it does not wear `Doc`**.

Four things that are decisions rather than details:

  - **An empty day says nothing.** Not _empty_, not a dashed box: the
    day's name is the press that puts a meal on it, and absent is
    absent (DS-01 §06). The standfirst says what pressing does.
  - **One entry field, two outcomes, and the reader picks.** Typing
    narrows the archive with the shelf's own `matchesQuery`, so the
    matches are the matches the shelf would give. A press on one sets
    a recipe; KEEP sets the words as typed. Nothing is inferred —
    typing _donuts_ does not become the donuts recipe by itself.
  - **Pick up, then place.** Pressing a meal lifts it, and while it is
    lifted every day is a place to set it down: an empty day takes it,
    a full day swaps, its own day puts it back. The lifted row is
    **seated** and says ", lifted" — the shape is never the only
    carrier (§04). Nothing slides: the register is zero here (§10).
  - **Moving hides the other controls, on purpose.** While a meal is
    in your hand every row is one press, because a row that was both
    a place to set it down and a REMOVE button would put a destructive
    control under the thumb that is aiming somewhere else.

-}

import Html exposing (Html, a, button, div, form, h1, h2, img, input, label, li, ol, p, section, span, text, ul)
import Html.Attributes exposing (attribute, autocomplete, class, classList, disabled, for, href, id, src, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Plan exposing (Day, Plan)
import Route
import Shelf


{-| The archive, as far as the entry field can see it. The index is
fetched like the shelf's, so it has the shelf's three states — and a
failed fetch still leaves the field working, because a meal of your
own needs nothing from the archive.
-}
type Archive
    = Opening
    | Searchable (List Shelf.Summary)
    | Unsearchable


{-| The shared picture, as far as the page knows it.

`Made` carries what this browser can do with the file, measured by
boot.js when it drew it, so a SHARE press is never offered on a
browser that would refuse it. `Unmade` is a draw that failed — a
token that would not resolve, a canvas that would not encode — and it
says so rather than showing a black rectangle.

-}
type Picture
    = NotMade
    | Making
    | Made { url : String, canShare : Bool, canCopy : Bool }
    | Unmade


{-| What actually happened to a share or a copy, as boot.js reports
it. Each reaches the reader as its own sentence: "Shared" on a browser
that refused is the wake badge's lie all over again (DS-01 §08).

SAVE reports nothing, on purpose. It is a plain download link; the
page cannot know whether the file landed, and a sentence saying it
did would be a guess.

-}
type Outcome
    = Shared
    | Copied
    | Refused
    | Unsupported
    | Failed


outcomeFromString : String -> Outcome
outcomeFromString word =
    case word of
        "shared" ->
            Shared

        "copied" ->
            Copied

        "refused" ->
            Refused

        "unsupported" ->
            Unsupported

        _ ->
            Failed


outcomeSentence : Outcome -> String
outcomeSentence outcome =
    case outcome of
        Shared ->
            "Shared."

        Copied ->
            "Copied. Paste it into a message."

        Refused ->
            "Not shared. The share was cancelled or blocked."

        Unsupported ->
            "This browser cannot do that. Save the picture instead."

        Failed ->
            "That did not work. Save the picture instead."


{-| The entry field: which day it is open on, and what is in it.
-}
type alias Entry =
    { day : Day, text : String }


type alias Config msg =
    { plan : Plan
    , archive : Archive
    , lifted : Maybe Day
    , entry : Maybe Entry

    -- Whether CLEAR THE WEEK has been armed by a first press. Held by
    -- the shell, so leaving the page disarms it.
    , clearArmed : Bool
    , onOpen : Day -> msg
    , onInput : String -> msg
    , onCancel : msg
    , onKeep : msg
    , onPick : String -> String -> msg
    , onLift : Day -> msg
    , onPlace : Day -> msg
    , onRemove : Day -> msg
    , onClear : msg

    -- the picture: its state, what the last share or copy did, and
    -- the three presses that make and send it
    , picture : Picture
    , outcome : Maybe Outcome
    , onMake : msg
    , onShare : msg
    , onCopy : msg
    }


view : Config msg -> Html msg
view config =
    div [ class "plan-layout" ]
        [ div [ class "meal-plan leaf" ]
            [ div [ class "plan-plate" ]
                [ h1 [ class "plan-title" ] [ text "Meal plan" ]

                -- Polite, because it is the sentence that changes when
                -- a meal is lifted, and a screen reader should hear
                -- what the next press will do.
                , p [ class "plan-standfirst", attribute "aria-live" "polite" ]
                    [ text (standfirst config) ]
                ]
            , ol [ class "plan-week" ] (List.map (day config) Plan.days)
            , if Plan.isEmpty config.plan || config.lifted /= Nothing then
                text ""

              else
                div [ class "plan-foot" ] [ clear config ]

            -- Not while a meal is lifted or a day is open: the picture
            -- would be of a week the reader is in the middle of
            -- changing, and MAKE THE PICTURE is volt, which would put a
            -- second acid beside KEEP.
            , if Plan.isEmpty config.plan || config.lifted /= Nothing || config.entry /= Nothing then
                text ""

              else
                sharing config
            ]
        ]


standfirst : Config msg -> String
standfirst config =
    case liftedMeal config of
        Just ( from, name ) ->
            "Holding "
                ++ name
                ++ ". Press a day to set it down, or "
                ++ Plan.dayName from
                ++ " to put it back."

        Nothing ->
            case Plan.count config.plan of
                0 ->
                    "Nothing planned yet. Press a day to put a meal on it."

                7 ->
                    "Every day is planned."

                n ->
                    String.fromInt n ++ " of 7 days planned."


liftedMeal : Config msg -> Maybe ( Day, String )
liftedMeal config =
    config.lifted
        |> Maybe.andThen
            (\from ->
                Plan.get from config.plan
                    |> Maybe.map (\m -> ( from, (Plan.describe m).name ))
            )



-- A DAY


day : Config msg -> Day -> Html msg
day config d =
    let
        meal =
            Plan.get d config.plan |> Maybe.map Plan.describe
    in
    li
        [ id ("day-" ++ Plan.dayKey d)
        , class "plan-day"
        , classList
            [ ( "is-held", meal /= Nothing )
            , ( "is-lifted", config.lifted == Just d )
            ]
        ]
        [ case ( liftedMeal config, config.entry ) of
            ( Just ( from, name ), _ ) ->
                place config from name d meal

            ( Nothing, Just entry ) ->
                if entry.day == d then
                    entryRow config entry

                else
                    resting config d meal

            ( Nothing, Nothing ) ->
                resting config d meal
        ]


dayName : Day -> Html msg
dayName d =
    span [ class "plan-dayname u" ] [ text (Plan.dayName d) ]


{-| A day with nothing in anybody's hand.
-}
resting : Config msg -> Day -> Maybe { name : String, source : Plan.Source } -> Html msg
resting config d meal =
    case meal of
        Nothing ->
            button
                [ type_ "button"
                , class "press-block plan-row plan-open"
                , onClick (config.onOpen d)
                ]
                [ dayName d
                , span [ class "vh" ] [ text ", add a meal" ]
                ]

        Just m ->
            div [ class "plan-row" ]
                [ dayName d
                , div [ class "plan-held" ]
                    [ button
                        [ type_ "button"
                        , class "press-block plan-meal"
                        , onClick (config.onLift d)
                        ]
                        [ span [ class "plan-meal-name" ] [ text m.name ]
                        , span [ class "vh" ] [ text ", move" ]
                        ]
                    , case m.source of
                        Plan.Archive slug ->
                            a
                                [ class "plan-recipe-link u"
                                , href (Route.toPath (Route.Recipe slug))
                                ]
                                [ text "Recipe"
                                , span [ class "vh" ] [ text (" for " ++ m.name) ]
                                ]

                        Plan.Typed ->
                            text ""
                    , button
                        [ type_ "button"
                        , class "plan-drop u"
                        , onClick (config.onRemove d)
                        ]
                        [ text "Remove"
                        , span [ class "vh" ] [ text (" " ++ m.name ++ " from " ++ Plan.dayName d) ]
                        ]
                    ]
                ]


{-| Every day while a meal is lifted: one press, saying what it does.
-}
place : Config msg -> Day -> String -> Day -> Maybe { name : String, source : Plan.Source } -> Html msg
place config from lifted d meal =
    let
        home =
            from == d

        ( hint, spoken ) =
            if home then
                ( "Put back", ", lifted. Press to put it back" )

            else
                case meal of
                    Just m ->
                        ( "Swap", ", swap " ++ lifted ++ " with " ++ m.name )

                    Nothing ->
                        ( "Set here", ", set " ++ lifted ++ " here" )
    in
    button
        [ type_ "button"
        , class "press-block plan-row plan-place"
        , classList [ ( "is-seated", home ) ]
        , attribute "aria-pressed"
            (if home then
                "true"

             else
                "false"
            )
        , onClick (config.onPlace d)
        ]
        [ dayName d
        , span [ class "plan-meal-name" ]
            [ text (Maybe.map .name meal |> Maybe.withDefault "") ]
        , span [ class "plan-hint u", attribute "aria-hidden" "true" ] [ text hint ]
        , span [ class "vh" ] [ text spoken ]
        ]



-- THE ENTRY FIELD


{-| An open day: one field, the archive's matches under it, and the
two ways out — keep the words, or leave.

A `form`, so Enter keeps what was typed. Enter never picks a match:
the match is the choice that needs a look, and a keystroke that
silently chose the first one would be the archive guessing.

-}
entryRow : Config msg -> Entry -> Html msg
entryRow config entry =
    let
        field =
            "plan-entry"

        typed =
            Plan.own entry.text
    in
    div [ class "plan-row plan-entry-row" ]
        [ label [ class "plan-dayname u", for field ] [ text (Plan.dayName entry.day) ]
        , form [ class "plan-entry", onSubmit config.onKeep ]
            [ input
                [ id field
                , class "plan-entry-input"
                , type_ "text"
                , autocomplete False
                , value entry.text
                , onInput config.onInput
                , attribute "aria-describedby" "plan-entry-help"
                ]
                []
            , matches config entry.text
            , div [ class "plan-entry-actions" ]
                [ button
                    [ type_ "submit"
                    , class "press-block plan-keep"
                    , disabled (typed == Nothing)
                    ]
                    [ text
                        (case typed of
                            Just meal ->
                                "Keep “" ++ (Plan.describe meal).name ++ "”"

                            Nothing ->
                                "Keep"
                        )
                    ]
                , button
                    [ type_ "button"
                    , class "plan-cancel u"
                    , onClick config.onCancel
                    ]
                    [ text "Cancel" ]
                ]
            ]
        ]


{-| Up to five of the archive's recipes, matched the way the shelf's
search box matches — `Shelf.matchesQuery` over `Shelf.needles`, so a
word the shelf would not search on does not search here either.
-}
matches : Config msg -> String -> Html msg
matches config typed =
    let
        help sentence =
            p [ id "plan-entry-help", class "plan-entry-help" ] [ text sentence ]
    in
    case config.archive of
        Unsearchable ->
            help "The archive could not be searched, so what you type is kept as written."

        Opening ->
            help "Type a meal of your own, or the name of a recipe."

        Searchable recipes ->
            if List.isEmpty (Shelf.needles typed) then
                help "Type a meal of your own, or the name of a recipe."

            else
                case List.filter (Shelf.matchesQuery typed) recipes |> List.take 5 of
                    [] ->
                        help "Nothing in the archive matches. Keep it as written."

                    found ->
                        div []
                            [ help "From the archive, or keep it as written."
                            , ul [ class "plan-matches" ]
                                (List.map
                                    (\r ->
                                        li []
                                            [ button
                                                [ type_ "button"
                                                , class "press-block plan-match"
                                                , onClick (config.onPick r.slug r.title)
                                                ]
                                                [ text r.title ]
                                            ]
                                    )
                                    found
                                )
                            ]



-- UNMAKING THE WEEK


{-| Empty the week — in two presses, the shopping list's rule. The
armed state is a word: the button says what the next press will do.
-}
clear : Config msg -> Html msg
clear config =
    button
        [ type_ "button"
        , class "plan-clear u"
        , classList [ ( "is-armed", config.clearArmed ) ]
        , onClick config.onClear
        ]
        [ text
            (if config.clearArmed then
                "Press again to clear"

             else
                "Clear the week"
            )
        ]



-- THE PICTURE


{-| The week as a picture: make it, look at it, send it.

**The preview is the file.** The `img` shows the very blob SHARE,
COPY and SAVE hand on, so what the reader sees is what the receiver
gets. There is one renderer, and it is boot.js.

**MAKE THE PICTURE is the volt press** — the one actionable thing in
view once the week is set. The three that send it are neutral, and
each exists only when this browser can honour it: SAVE always, SHARE
and COPY when boot.js found the API that does them.

-}
sharing : Config msg -> Html msg
sharing config =
    section [ class "plan-share", attribute "aria-labelledby" "plan-share-h" ]
        [ h2 [ id "plan-share-h", class "plan-h u" ] [ text "Share the week" ]
        , case config.picture of
            NotMade ->
                makeButton config "Make the picture"

            Making ->
                p [ class "plan-share-state", attribute "aria-live" "polite" ]
                    [ text "Drawing the week…" ]

            Unmade ->
                div []
                    [ p [ class "plan-share-state", attribute "aria-live" "polite" ]
                        [ text "The picture could not be drawn in this browser." ]
                    , makeButton config "Try again"
                    ]

            Made made ->
                div [ class "plan-share-made" ]
                    [ img
                        [ class "plan-picture"
                        , src made.url
                        , Html.Attributes.alt (alt config.plan)
                        ]
                        []
                    , div [ class "plan-share-actions" ]
                        (List.filterMap identity
                            [ if made.canShare then
                                Just (sendButton config.onShare "Share")

                              else
                                Nothing
                            , if made.canCopy then
                                Just (sendButton config.onCopy "Copy")

                              else
                                Nothing
                            , Just
                                (a
                                    [ class "press-block plan-send u"
                                    , href made.url
                                    , attribute "download" "delishh-week.png"
                                    ]
                                    [ text "Save" ]
                                )
                            ]
                        )
                    , p [ class "plan-share-state", attribute "aria-live" "polite" ]
                        [ text (Maybe.map outcomeSentence config.outcome |> Maybe.withDefault "") ]
                    ]
        ]


makeButton : Config msg -> String -> Html msg
makeButton config label_ =
    button
        [ type_ "button"
        , class "press-block plan-make u"
        , onClick config.onMake
        ]
        [ text label_ ]


sendButton : msg -> String -> Html msg
sendButton msg label_ =
    button
        [ type_ "button"
        , class "press-block plan-send u"
        , onClick msg
        ]
        [ text label_ ]


{-| The picture, in words, for a reader who cannot see it. Everything
the picture says, in the order it says it — an empty day included,
because the picture shows it open.
-}
alt : Plan -> String
alt plan =
    "The week, as a picture. "
        ++ String.join " "
            (List.map
                (\d ->
                    Plan.dayName d
                        ++ ": "
                        ++ (case Plan.get d plan |> Maybe.map Plan.describe of
                                Just m ->
                                    m.name
                                        ++ (case m.source of
                                                Plan.Archive _ ->
                                                    ", from the archive."

                                                Plan.Typed ->
                                                    "."
                                           )

                                Nothing ->
                                    "nothing planned."
                           )
                )
                Plan.days
            )
