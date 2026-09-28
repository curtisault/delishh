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

    -- the entry in the hand, as its day and its place on that day
    , lifted : Maybe ( Day, Int )
    , entry : Maybe Entry

    -- the entry whose label choices are open, if any
    , labelOpen : Maybe ( Day, Int )

    -- Whether CLEAR THE WEEK has been armed by a first press. Held by
    -- the shell, so leaving the page disarms it.
    , clearArmed : Bool
    , onOpen : Day -> msg
    , onInput : String -> msg
    , onCancel : msg
    , onKeep : msg
    , onPick : String -> String -> msg
    , onLift : Day -> Int -> msg
    , onPlace : Plan.Target -> msg
    , onRemove : Day -> Int -> msg
    , onLabelOpen : Day -> Int -> msg
    , onLabel : Day -> Int -> Maybe Plan.Slot -> msg
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


{-| Days, and — once any day holds more than one — meals as well. A
week of one meal a day reads exactly as the first planner's did.
-}
standfirst : Config msg -> String
standfirst config =
    case liftedMeal config of
        Just ( _, name ) ->
            "Holding "
                ++ name
                ++ ". Press a meal to swap with it, or Set here to put it at the end of a day. Press "
                ++ name
                ++ " again to put it back."

        Nothing ->
            let
                meals =
                    Plan.days |> List.map (\d -> List.length (Plan.entries d config.plan)) |> List.sum

                days =
                    Plan.count config.plan

                mealWords =
                    if meals > days then
                        ", " ++ String.fromInt meals ++ " meals"

                    else
                        ""
            in
            case days of
                0 ->
                    "Nothing planned yet. Press a day to put a meal on it."

                7 ->
                    "Every day is planned" ++ mealWords ++ "."

                n ->
                    String.fromInt n ++ " of 7 days planned" ++ mealWords ++ "."


liftedMeal : Config msg -> Maybe ( ( Day, Int ), String )
liftedMeal config =
    config.lifted
        |> Maybe.andThen
            (\( from, index ) ->
                Plan.entries from config.plan
                    |> List.drop index
                    |> List.head
                    |> Maybe.map (\e -> ( ( from, index ), (Plan.describe e.meal).name ))
            )



-- A DAY


day : Config msg -> Day -> Html msg
day config d =
    let
        list =
            Plan.entries d config.plan

        opened =
            config.entry |> Maybe.andThen (\e -> if e.day == d then Just e else Nothing)
    in
    li
        [ id ("day-" ++ Plan.dayKey d)
        , class "plan-day"
        , classList
            [ ( "is-held", not (List.isEmpty list) )
            , ( "is-lifted", Maybe.map Tuple.first config.lifted == Just d )
            ]
        ]
        [ case liftedMeal config of
            Just ( held, name ) ->
                placing config held name d list

            Nothing ->
                case ( list, opened ) of
                    ( [], Nothing ) ->
                        button
                            [ type_ "button"
                            , class "press-block plan-row plan-open"
                            , onClick (config.onOpen d)
                            ]
                            [ dayName d
                            , span [ class "vh" ] [ text ", add a meal" ]
                            ]

                    ( [], Just entry ) ->
                        div [ class "plan-row plan-entry-row" ]
                            [ dayName d
                            , div [ class "plan-body" ] [ entryForm config entry ]
                            ]

                    ( _, _ ) ->
                        div [ class "plan-row plan-held-row" ]
                            [ dayName d
                            , div [ class "plan-body" ]
                                (List.indexedMap (resting config d (showLabels list)) list
                                    ++ [ case opened of
                                            Just entry ->
                                                entryForm config entry

                                            Nothing ->
                                                addOrFull config d list
                                       ]
                                )
                            ]
        ]


dayName : Day -> Html msg
dayName d =
    span [ class "plan-dayname u" ] [ text (Plan.dayName d) ]


{-| Label marks appear once a day holds two meals, or on a meal that
already carries one. A day of one is never made to show a label it
does not have — the first planner's "never says dinner", kept.
-}
showLabels : List Plan.Entry -> Bool
showLabels list =
    List.length list >= 2 || List.any (\e -> e.label /= Nothing) list


{-| ADD, or the sentence that stands where ADD was. The limit is said
in words where the press would be, never a control that silently
went away (the expansion's cap ruling).
-}
addOrFull : Config msg -> Day -> List Plan.Entry -> Html msg
addOrFull config d list =
    if List.length list >= Plan.cap then
        p [ class "plan-full" ] [ text "Five is a full day." ]

    else
        div [ class "plan-add-line" ]
            [ button
                [ type_ "button"
                , class "plan-add u"
                , onClick (config.onOpen d)
                ]
                [ text "Add"
                , span [ class "vh" ] [ text (" a meal to " ++ Plan.dayName d) ]
                ]
            ]


{-| One meal on a day with nothing in anybody's hand.
-}
resting : Config msg -> Day -> Bool -> Int -> Plan.Entry -> Html msg
resting config d labels index entry =
    let
        m =
            Plan.describe entry.meal

        open =
            config.labelOpen == Just ( d, index )
    in
    div [ class "plan-item" ]
        [ div [ class "plan-item-line" ]
            [ button
                [ type_ "button"
                , class "press-block plan-meal"
                , onClick (config.onLift d index)
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
            , if labels then
                button
                    [ type_ "button"
                    , class "plan-label-mark mono u"
                    , classList [ ( "is-unset", entry.label == Nothing ) ]
                    , attribute "aria-expanded"
                        (if open then
                            "true"

                         else
                            "false"
                        )
                    , onClick (config.onLabelOpen d index)
                    ]
                    [ span [ class "vh" ] [ text ("Label for " ++ m.name ++ ": ") ]
                    , text (Maybe.withDefault "No label" entry.label)
                    ]

              else
                text ""
            , button
                [ type_ "button"
                , class "plan-drop u"
                , onClick (config.onRemove d index)
                ]
                [ text "Remove"
                , span [ class "vh" ] [ text (" " ++ m.name ++ " from " ++ Plan.dayName d) ]
                ]
            ]
        , if open then
            labelChoices config d index entry m.name

          else
            text ""
        ]


{-| The five words and NONE. The current one is seated — a shape, and
`aria-pressed` says it too.
-}
labelChoices : Config msg -> Day -> Int -> Plan.Entry -> String -> Html msg
labelChoices config d index entry name =
    div
        [ class "plan-labels"
        , attribute "role" "group"
        , attribute "aria-label" ("Label " ++ name)
        ]
        (List.map
            (\choice ->
                let
                    on =
                        entry.label == choice
                in
                button
                    [ type_ "button"
                    , class "press-block plan-label-opt u"
                    , classList [ ( "is-seated", on ) ]
                    , attribute "aria-pressed"
                        (if on then
                            "true"

                         else
                            "false"
                        )
                    , onClick (config.onLabel d index choice)
                    ]
                    [ text (Maybe.withDefault "None" choice) ]
            )
            (List.map Just Plan.slots ++ [ Nothing ])
        )


{-| A day while a meal is in the hand. Every meal is a press that swaps
with it; each day's end is a press that sets it there; the meal that
was lifted is seated and puts itself back. Nothing destructive is on
screen: REMOVE, ADD and CLEAR THE WEEK wait until it is set down.
-}
placing : Config msg -> ( Day, Int ) -> String -> Day -> List Plan.Entry -> Html msg
placing config ( from, liftedAt ) lifted d list =
    case list of
        [] ->
            button
                [ type_ "button"
                , class "press-block plan-row plan-place"
                , onClick (config.onPlace (Plan.OntoDay d))
                ]
                [ dayName d
                , span [ class "plan-meal-name" ] []
                , span [ class "plan-hint u", attribute "aria-hidden" "true" ] [ text "Set here" ]
                , span [ class "vh" ] [ text (", set " ++ lifted ++ " here") ]
                ]

        _ ->
            div [ class "plan-row plan-held-row" ]
                [ dayName d
                , div [ class "plan-body" ]
                    (List.indexedMap
                        (\i entry ->
                            let
                                name =
                                    (Plan.describe entry.meal).name

                                home =
                                    d == from && i == liftedAt
                            in
                            button
                                [ type_ "button"
                                , class "press-block plan-place plan-swap"
                                , classList [ ( "is-seated", home ) ]
                                , attribute "aria-pressed"
                                    (if home then
                                        "true"

                                     else
                                        "false"
                                    )
                                , onClick (config.onPlace (Plan.OntoEntry d i))
                                ]
                                [ span [ class "plan-meal-name" ] [ text name ]
                                , span [ class "plan-hint u", attribute "aria-hidden" "true" ]
                                    [ text
                                        (if home then
                                            "Put back"

                                         else
                                            "Swap"
                                        )
                                    ]
                                , span [ class "vh" ]
                                    [ text
                                        (if home then
                                            ", lifted. Press to put it back"

                                         else
                                            ", swap " ++ lifted ++ " with " ++ name
                                        )
                                    ]
                                ]
                        )
                        list
                        ++ [ if d == from then
                                text ""

                             else if List.length list >= Plan.cap then
                                p [ class "plan-full" ] [ text "Five is a full day." ]

                             else
                                button
                                    [ type_ "button"
                                    , class "press-block plan-place plan-end"
                                    , onClick (config.onPlace (Plan.OntoDay d))
                                    ]
                                    [ span [ class "plan-hint u", attribute "aria-hidden" "true" ] [ text "Set here" ]
                                    , span [ class "vh" ] [ text (Plan.dayName d ++ ", set " ++ lifted ++ " at the end") ]
                                    ]
                           ]
                    )
                ]



-- THE ENTRY FIELD


{-| The entry field: one field, the archive's matches under it, and
the two ways out — keep the words, or leave. It adds to the end of its
day, empty or not.

A `form`, so Enter keeps what was typed. Enter never picks a match:
the match is the choice that needs a look, and a keystroke that
silently chose the first one would be the archive guessing.

-}
entryForm : Config msg -> Entry -> Html msg
entryForm config entry =
    let
        field =
            "plan-entry"

        typed =
            Plan.own entry.text
    in
    form [ class "plan-entry", onSubmit config.onKeep ]
        [ label [ class "vh", for field ] [ text ("A meal for " ++ Plan.dayName entry.day) ]
        , input
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
the picture says, in the order it says it — every meal of a day with
its label and where it came from, and an empty day too, because the
picture shows it open.
-}
alt : Plan -> String
alt plan =
    "The week, as a picture. "
        ++ String.join " "
            (List.map
                (\d ->
                    Plan.dayName d
                        ++ ": "
                        ++ (case Plan.entries d plan of
                                [] ->
                                    "nothing planned."

                                list ->
                                    String.join "; " (List.map spoken list) ++ "."
                           )
                )
                Plan.days
            )


spoken : Plan.Entry -> String
spoken entry =
    let
        m =
            Plan.describe entry.meal
    in
    m.name
        ++ (case entry.label of
                Just word ->
                    ", " ++ word

                Nothing ->
                    ""
           )
        ++ (case m.source of
                Plan.Archive _ ->
                    ", from the archive"

                Plan.Typed ->
                    ""
           )
