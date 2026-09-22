module Page.Recipe exposing (Config, view, viewFailed, viewLoading)

{-| A recipe, rendered — DS-01 §06.

**This page does not wear `Doc`.** `Doc` frames prose documents: a
masthead, a contents rail, numbered sections, citable `§N.M` clause
marks. A recipe is a different object. Its nine blocks are a fixed
form, not a numbered specification, and giving them clause marks would
be the "controlled document" register that DS-01 Revision 2
deliberately dropped (§01). There is no serial at all since the
2026-09-21 amendment: identity is the name and the address, and the
plate leads with the method — the fact that colours the page.

**The quiet layer.** One acid dominates, chosen from the recipe's
method (`Recipe.dominantAcid`), and it appears as *marks* only —
rules, the method plate, the step numbers. Never a fill behind
procedure, and never on a quantity: amounts, temperatures and times
are ink, which is the rule that makes a dense page trustworthy (§04).

**Flavour chips are neutral here.** On the shelf they take full-colour
fills; on a recipe page four coloured chips would be four acids on one
surface. They keep their words — information is never colour-only —
and print as outlined capsules, which is the same treatment (§09).

-}

import Html exposing (Html, a, div, h1, h2, li, ol, p, section, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Flavor
import Html.Events exposing (onClick)
import Print
import Recipe exposing (Recipe)
import Route
import Scale


type alias Config msg =
    { recipe : Recipe
    , factor : Scale.Factor
    , onScale : Scale.Factor -> msg
    , form : Print.Form
    , onForm : Print.Form -> msg
    , prepCard : Bool
    , onPrepCard : msg
    , origin : String
    , today : String

    -- Which block the reader is inside, for the side nav's mark.
    -- Arrives from boot.js through `sectionSeen`, the same port the
    -- documents' contents rail uses — a recipe's blocks are marked
    -- the way a document's sections are.
    , active : Maybe String
    }



-- STATES


viewLoading : Html msg
viewLoading =
    shell [ p [ class "recipe-state" ] [ text "Fetching the recipe…" ] ]


{-| A failure states what is missing and offers the way back. A dead
end is a design failure, not an edge case (DS-01 §07).
-}
viewFailed : String -> Html msg
viewFailed slug =
    shell
        [ div [ class "recipe-plate" ]
            [ h1 [ class "recipe-title" ] [ text "No such recipe" ]
            , p [ class "recipe-state" ]
                [ text "Nothing in the archive is filed under "
                , span [ class "mono" ] [ text slug ]
                , text ". It may have been renumbered, or never written."
                ]
            , p [] [ a [ class "recipe-back u", href "/" ] [ text "Back to the archive" ] ]
            ]
        ]


shell : List (Html msg) -> Html msg
shell body =
    div [ class "recipe-layout" ] [ div [ class "recipe" ] body ]



-- THE DOCUMENT


view : Config msg -> Html msg
view config =
    let
        r =
            config.recipe
    in
    div
        [ class "recipe-layout"
        , class ("acid-" ++ Recipe.dominantAcid r)
        , class (Print.className config.form)
        , classList [ ( "with-prep", config.prepCard ) ]
        ]
        [ sideNav config
        , div [ class "recipe" ]
            [ plate config
            , div [ class "recipe-cols" ]
                [ -- What you NEED. Sticky on a wide screen, so the
                  -- quantities stay beside the step that uses them —
                  -- most of the reason to widen at all.
                  div [ class "recipe-side" ]
                    [ div [ class "recipe-side-inner" ]
                        (equipment r ++ ingredients config)
                    ]

                -- What you DO.
                , div [ class "recipe-main" ]
                    (photo r
                        ++ steps config
                        ++ watchpoints r
                        ++ rescues r
                        ++ keeps r
                        ++ note r
                        ++ [ prep config, footer config ]
                    )
                ]
            ]
        ]


{-| The side nav — an actual side nav.

**Chrome, not a widget in the rail.** It holds the viewport's left
margin outside the centred content, the same geometry as the
documents' contents rail — which is where it ended up after the first
bench alternative put it above the equipment and it read as part of
the ingredients rather than as navigation.

It is *not* `Doc` chrome: no numbered sections, no clause marks, no
search. A recipe is not a prose document (§06), and its blocks are a
fixed form rather than a specification you cite.

Rows are derived from the blocks this recipe actually has, so the nav
can never offer an anchor that resolves to nothing. The prep card is
never listed — it is furniture for paper, not reading matter.

-}
sideNav : Config msg -> Html msg
sideNav config =
    let
        row ( anchor, label ) =
            let
                here =
                    config.active == Just anchor
            in
            a
                (class "recipe-nav-link u"
                    :: classList [ ( "is-active", here ) ]
                    :: href ("#" ++ anchor)
                    -- present or absent, never "false" — the same
                    -- contract as the documents' rail (`Doc.tocLink`)
                    :: (if here then
                            [ attribute "aria-current" "true" ]

                        else
                            []
                       )
                )
                [ text label ]
    in
    Html.nav
        [ class "recipe-nav", attribute "aria-label" "On this recipe" ]
        [ div [ class "recipe-nav-inner" ]
            (span [ class "recipe-nav-head mono" ]
                [ text (methodWord config.recipe.method) ]
                :: List.map row (blocksPresent config.recipe)
            )
        ]


{-| The blocks this recipe has, in document order, as
`( anchor, label )`. Absent blocks are absent here for the same
reason they are absent from the page: a heading over nothing is not a
thing to navigate to.
-}
blocksPresent : Recipe -> List ( String, String )
blocksPresent r =
    let
        keep ( anchor, label, hasIt ) =
            if hasIt then
                Just ( anchor, label )

            else
                Nothing
    in
    List.filterMap keep
        [ ( "equipment", "Equipment", not (List.isEmpty r.equipment) )
        , ( "ingredients", "Ingredients", not (List.isEmpty r.ingredients) )
        , ( "steps", "Steps", not (List.isEmpty r.steps) )
        , ( "watchpoints", "Watchpoints", not (List.isEmpty r.watchpoints) )
        , ( "rescues", "Rescues", not (List.isEmpty r.rescues) )
        , ( "keeps", "Keeps", not (List.isEmpty r.keeps) )
        , ( "note", "Note", not (List.isEmpty r.note) )
        ]


{-| A block, or nothing at all when it is empty.

**An empty block is absent, never a heading over blank space.** The
same rule as the photograph: a recipe with no rescues has not failed
to fill something in, it simply has none.

-}
block : String -> String -> List (Html msg) -> List (Html msg)
block anchor heading body =
    if List.isEmpty body then
        []

    else
        [ section [ id anchor, class "recipe-block" ]
            (h2 [ class "recipe-h u" ] [ text heading ] :: body)
        ]



-- 1 · THE PLATE


plate : Config msg -> Html msg
plate config =
    let
        r =
            config.recipe
    in
    div [ class "recipe-plate" ]
        ([ div [ class "recipe-serial mono" ]
            [ -- The method leads the plate: the word for the acid the
              -- whole page runs on. Information is never colour-only
              -- (§04), and this is that rule kept where it is loudest.
              span [ class "recipe-mark" ] [ text (methodWord r.method) ]
            , span [] [ text ("LAST BATCH " ++ r.tested) ]
            ]
        , h1 [ class "recipe-title" ] [ text r.title ]
        , div [ class "recipe-facts mono" ]
            [ fact "YIELD" (yieldText config)
            , fact "ACTIVE" (duration r.time.active)
            , fact "TOTAL" (duration r.time.total)
            ]
        , div [ class "recipe-chips" ]
            (List.map (Flavor.chip "chip-flavor") r.flavor
                ++ List.map (chip "chip-slot") r.slot
                ++ [ chip "chip-effort" r.effort ]
                ++ List.map (chip "chip-diet") r.dietary
                ++ List.map (chip "chip-diet") r.cuisine
            )
        ]
            ++ gauges r
            ++ [ -- Settings on the left, the action on the right.
                 -- The scale and the form are things you *set* before
                 -- you start; cooking is the thing you then do, and
                 -- stacking it under them read as a fourth setting.
                 -- DOM order is unchanged, so the tab order still
                 -- runs scale → form → go.
                 div [ class "recipe-controls" ]
                    [ div [ class "recipe-settings" ]
                        [ scaler config, printer config ]
                    , cookLink config
                    ]
               ]
        )


{-| The gauge strip: the recipe's operating numbers, authored in the
frontmatter (DS-01 §06, amended 2026-09-21).

**Absent when the recipe has none** — the same rule every block on
this page follows. A drink blended until it is smooth has no
temperature to report, and an empty strip would be a row of labels
over nothing.

On paper this is the band that replaces the facet chips: a sheet in
your hand has already been found, so the ink goes to the numbers you
cook by instead of the words you searched by (§09).

-}
gauges : Recipe -> List (Html msg)
gauges r =
    if List.isEmpty r.gauges then
        []

    else
        [ div [ class "recipe-gauges mono" ] (List.map gauge r.gauges) ]


gauge : Recipe.Gauge -> Html msg
gauge g =
    div [ class "recipe-gauge" ]
        [ span [ class "recipe-gauge-k u" ] [ text (String.toUpper g.label) ]
        , span [ class "recipe-gauge-v" ] [ text g.value ]
        , case g.note of
            Nothing ->
                text ""

            Just n ->
                span [ class "recipe-gauge-n" ] [ text n ]
        ]


fact : String -> String -> Html msg
fact key value =
    div [ class "recipe-fact" ]
        [ span [ class "recipe-fact-k u" ] [ text key ]
        , span [ class "recipe-fact-v" ] [ text value ]
        ]


{-| Every chip carries its word. A chip that is only a colour is
confetti (DS-01 §04).
-}
chip : String -> String -> Html msg
chip kind word =
    span [ class ("chip " ++ kind ++ " u") ] [ text (chipWord word) ]


chipWord : String -> String
chipWord =
    String.replace "-" " "


{-| The method as the plate and the nav wear it: its word, uppercased
in the data voice — `sugar-work` reads SUGAR WORK.
-}
methodWord : String -> String
methodWord =
    chipWord >> String.toUpper


{-| `90` → `1 H 30 MIN`. Total always includes every hold, because the
build refuses a recipe whose total is less than its active time — the
number here cannot be the "ready in 20 minutes" lie (DS-01 §11).
-}
duration : Int -> String
duration minutes =
    let
        days =
            minutes // 1440

        hours =
            modBy 1440 minutes // 60

        mins =
            modBy 60 minutes

        part n suffix =
            if n == 0 then
                []

            else
                [ String.fromInt n ++ " " ++ suffix ]
    in
    case part days "D" ++ part hours "H" ++ part mins "MIN" of
        [] ->
            "0 MIN"

        parts ->
            String.join " " parts


yieldText : Config msg -> String
yieldText config =
    let
        y =
            config.recipe.yield

        base =
            Scale.yield config.factor { amount = y.amount, unit = y.unit } ++ " " ++ y.unit
    in
    case y.servings of
        Just n ->
            base ++ " · " ++ String.fromInt (Scale.servings config.factor n) ++ " SERVINGS"

        Nothing ->
            base



-- THE SCALE CONTROL


{-| Set before you start, and displayed permanently once it is not ×1.

DS-01 §08: a scaled recipe that does not say it is scaled is
dangerous. The control is the one place on a recipe page that takes
the actionable acid, because it is the only thing here you press.

-}
scaler : Config msg -> Html msg
scaler config =
    div [ class "scaler" ]
        [ span [ class "scaler-k u" ] [ text "Scale" ]
        , div [ class "scaler-set", attribute "role" "group", attribute "aria-label" "Scale" ]
            (List.map (scaleButton config) Scale.factors)
        , if Scale.toFloat config.factor == 1 then
            text ""

          else
            span [ class "scaler-live u" ]
                [ text ("SCALED " ++ Scale.label config.factor) ]
        ]


scaleButton : Config msg -> Scale.Factor -> Html msg
scaleButton config factor =
    let
        current =
            Scale.toFloat factor == Scale.toFloat config.factor
    in
    Html.button
        [ Html.Attributes.type_ "button"
        , class "scaler-btn u"
        , classList [ ( "active", current ) ]
        , attribute "aria-pressed"
            (if current then
                "true"

             else
                "false"
            )
        , onClick (config.onScale factor)
        ]
        [ text (Scale.label factor) ]



-- 2 · THE PHOTOGRAPH


{-| One per recipe, or none. **Never a placeholder, never a grey
box** (DS-01 §06) — a recipe with no photograph has no photo block.

Clamped toward the neutral family in CSS: the food supplies the
warmth, and an unclamped photo blows the page's colour budget on its
own.

-}
photo : Recipe -> List (Html msg)
photo r =
    case r.photo of
        Nothing ->
            []

        Just file ->
            [ div [ class "recipe-photo" ]
                [ Html.img
                    [ Html.Attributes.src ("/photos/" ++ file)
                    , Html.Attributes.alt (r.title ++ " — as made")
                    -- `elm/html` has no `loading` helper; DS-01 §12
                    -- wants the one photograph lazy on a phone.
                    , attribute "loading" "lazy"
                    , attribute "decoding" "async"
                    ]
                    []
                ]
            ]



-- 3 · INGREDIENTS


{-| Above the fold, because a returning cook needs quantities and a
first-time cook needs a shopping list, and neither needs a paragraph
first (DS-01 §06).

Mass first and in the data voice; the preparation note after it, in
body. Quantities never take acid.

-}
ingredients : Config msg -> List (Html msg)
ingredients config =
    block "ingredients" "Ingredients" <|
        List.concatMap (ingredientGroup config) config.recipe.ingredients


ingredientGroup : Config msg -> Recipe.IngredientGroup -> List (Html msg)
ingredientGroup config group =
    (case group.name of
        Just name ->
            [ h2 [ class "recipe-sub u" ] [ text name ] ]

        Nothing ->
            []
    )
        ++ [ ul [ class "ing-list" ] (List.map (ingredientRow config) group.items) ]


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
    li [ class "ing" ]
        [ span [ class "ing-qty mono" ]
            [ text
                (case scaled of
                    Just s ->
                        s.text
                            ++ Maybe.withDefault ""
                                (Maybe.map
                                    (\u -> " " ++ Scale.unitLabel s.text u)
                                    item.unit
                                )

                    Nothing ->
                        ""
                )
            ]
        , span [ class "ing-item" ]
            (text item.item
                :: (case item.note of
                        Just n ->
                            [ span [ class "ing-note" ] [ text (", " ++ n) ] ]

                        Nothing ->
                            []
                   )
            )
        , case Maybe.andThen .note scaled of
            Just n ->
                -- The honest note. An indivisible count that the
                -- arithmetic wanted a fraction of says so, rather than
                -- handing over a number that is quietly wrong.
                span [ class "ing-scaled" ] [ text n ]

            Nothing ->
                text ""
        ]



-- 4 · EQUIPMENT


equipment : Recipe -> List (Html msg)
equipment r =
    block "equipment" "Equipment" <|
        if List.isEmpty r.equipment then
            []

        else
            [ ul [ class "doc-list" ] (List.map (\e -> li [] [ text e ]) r.equipment) ]



-- 5 · STEPS


{-| Numbered, each carrying its own temperature, duration and
doneness tell on its own line. No tooltip, no hover, no "see notes
below": if a step needs external explanation its design has failed
(DS-01 §2.5).
-}
steps : Config msg -> List (Html msg)
steps config =
    block "steps" "Steps" <|
        if List.isEmpty config.recipe.steps then
            []

        else
            [ ol [ class "step-list" ] (List.map step config.recipe.steps) ]


step : Recipe.Step -> Html msg
step s =
    li [ class "step" ]
        (span [ class "step-n mono" ] [ text (String.padLeft 2 '0' (String.fromInt s.n)) ]
            :: div [ class "step-body" ]
                (p [ class "step-text" ] [ text s.text ]
                    :: (case s.cue of
                            Just cue ->
                                [ p [ class "step-cue mono u" ] [ text cue ] ]

                            Nothing ->
                                []
                       )
                )
            :: []
        )



-- 6 · WATCHPOINTS


watchpoints : Recipe -> List (Html msg)
watchpoints r =
    block "watchpoints" "Watchpoints" <|
        if List.isEmpty r.watchpoints then
            []

        else
            [ ul [ class "doc-list watch-list" ]
                (List.map (\w -> li [] [ text w ]) r.watchpoints)
            ]



-- 7 · RESCUES


{-| What goes wrong, what caused it, and whether it can be saved.

The block conventional recipe sites omit, and the reason to build this
at all. A rescue that cannot be saved is marked rather than softened —
saying "it does not come back" plainly is the most generous sentence a
recipe can carry (DS-01 §06).

-}
rescues : Recipe -> List (Html msg)
rescues r =
    block "rescues" "Rescues" <|
        if List.isEmpty r.rescues then
            []

        else
            [ ul [ class "rescue-list" ] (List.map rescue r.rescues) ]


rescue : Recipe.Rescue -> Html msg
rescue x =
    li [ class "rescue", classList [ ( "terminal", not x.recoverable ) ] ]
        [ span [ class "rescue-sym u" ] [ text x.symptom ]
        , span [ class "rescue-text" ] [ text x.text ]
        , if x.recoverable then
            text ""

          else
            -- Carries its word as well as its mark, so the warning
            -- survives a monochrome printout and a colour-blind reader.
            span [ class "rescue-flag u" ] [ text "Cannot be saved" ]
        ]



-- 8 · KEEPS


keeps : Recipe -> List (Html msg)
keeps r =
    block "keeps" "Keeps" <|
        if List.isEmpty r.keeps then
            []

        else
            [ ul [ class "doc-list" ] (List.map (\k -> li [] [ text k ]) r.keeps) ]



-- 9 · THE NOTE


{-| Yours. Serif, sentence case, first person, unedited — and the
content build's word rules never read it.

At the bottom on purpose: it is the reward for having read the
document, not the introduction to it (DS-01 §06).

-}
note : Recipe -> List (Html msg)
note r =
    block "note" "Note" <|
        if List.isEmpty r.note then
            []

        else
            [ div [ class "recipe-note human" ]
                (List.map (\para -> p [] [ text para ]) r.note)
            ]



{-| The way into cook mode, carrying the scale it was set at.

The factor rides in the address rather than in the shell, so entering
cook mode cannot quietly change the quantities — and a half batch
becomes a thing you can bookmark (DS-01 §08).

-}
cookLink : Config msg -> Html msg
cookLink config =
    a
        [ class "cook-enter u"
        , href
            (Route.withQuery (Route.Cook config.recipe.slug)
                [ ( "scale"
                  , if Scale.toFloat config.factor == 1 then
                        ""

                    else
                        Scale.toString config.factor
                  )
                ]
            )
        ]
        [ text "Cook this" ]



-- THE PRINT CONTROL


{-| Which form the sheet takes, and whether the prep card rides
along.

Screen furniture only — it sets a class and nothing more, because the
whole of DS-01 §09 lives in `print.css` and there is no
print-specific JavaScript anywhere (§12). Every option states its own
use, so nobody has to print one to find out what it does.

-}
printer : Config msg -> Html msg
printer config =
    div [ class "printer" ]
        [ span [ class "printer-k u" ] [ text "Print" ]
        , div
            [ class "printer-set"
            , attribute "role" "group"
            , attribute "aria-label" "Print form"
            ]
            (List.map (formButton config) Print.all)
        , Html.button
            [ Html.Attributes.type_ "button"
            , class "printer-prep u"
            , classList [ ( "active", config.prepCard ) ]
            , attribute "aria-pressed"
                (if config.prepCard then
                    "true"

                 else
                    "false"
                )
            , onClick config.onPrepCard
            ]
            [ text "+ Prep card" ]
        ]


formButton : Config msg -> Print.Form -> Html msg
formButton config form =
    let
        current =
            form == config.form
    in
    Html.button
        [ Html.Attributes.type_ "button"
        , class "printer-btn"
        , classList [ ( "active", current ) ]
        , attribute "aria-pressed"
            (if current then
                "true"

             else
                "false"
            )
        , onClick (config.onForm form)
        ]
        [ span [ class "printer-btn-k u" ] [ text (Print.label form) ]
        , span [ class "printer-btn-note" ] [ text (Print.note form) ]
        ]



-- THE PREP CARD


{-| Supplemental, and printed *alongside* any of the three forms
(DS-01 §09): what to buy, and what to have done before the heat goes
on.

Both halves are derived from what the recipe already carries — the
shopping list is the ingredients without their preparation, and the
prep tasks are exactly the ingredients that *have* one. Nothing new
is asked of the schema, which is why this is a rendering decision and
not an amendment.

-}
prep : Config msg -> Html msg
prep config =
    let
        items =
            List.concatMap .items config.recipe.ingredients

        tasks =
            List.filter (\i -> i.note /= Nothing) items
    in
    section [ id "prep", class "prep-card" ]
        [ h2 [ class "recipe-h u" ] [ text "Prep card" ]
        , div [ class "prep-cols" ]
            [ div []
                [ h2 [ class "recipe-sub u" ] [ text "To buy" ]
                , ul [ class "prep-list" ] (List.map (buyRow config) items)
                ]
            , div []
                [ h2 [ class "recipe-sub u" ] [ text "To have done" ]
                , ul [ class "prep-list" ] (List.map prepRow tasks)
                ]
            ]
        , if List.isEmpty config.recipe.equipment then
            text ""

          else
            div []
                [ h2 [ class "recipe-sub u" ] [ text "To have out" ]
                , ul [ class "prep-list" ]
                    (List.map (\e -> li [ class "prep-item" ] [ box, span [] [ text e ] ])
                        config.recipe.equipment
                    )
                ]
        ]


{-| An unticked box, drawn as a rule rather than a character: a glyph
checkbox is a font dependency, and this sheet gets ticked with a pen.
-}
box : Html msg
box =
    span [ class "prep-box", attribute "aria-hidden" "true" ] []


buyRow : Config msg -> Recipe.Ingredient -> Html msg
buyRow config item =
    li [ class "prep-item" ]
        [ box
        , span [ class "prep-qty mono" ] [ text (quantity config item) ]
        , span [] [ text item.item ]
        ]


prepRow : Recipe.Ingredient -> Html msg
prepRow item =
    li [ class "prep-item" ]
        [ box
        , span []
            [ text item.item
            , span [ class "ing-note" ]
                [ text (" — " ++ Maybe.withDefault "" item.note) ]
            ]
        ]



-- THE FOOTER


{-| Traceability — DS-01 §09.

**A sheet found in a drawer in three years should be able to tell you
what it is and how out of date it is.** The recipe's name — on every
page, so page three of a booklet still says what it belongs to — its
last-batch date, the scale it was printed at, the date it was pulled,
and the address it came from. Staleness is the sheet's
LAST BATCH date against the site's — the lot-code idiom is straight
out of DS-01 §03's reference table; the revision counter this used to carry was a
hand-maintained claim nothing forced to move, and the change log is
git's job (DS-01 §06, amended 2026-09-21). Screen-hidden: this is
furniture for paper.

The scale is here and not merely in the header because a scaled sheet
that does not say so is dangerous (§08), and a printout has no live
control to check.

-}
footer : Config msg -> Html msg
footer config =
    let
        r =
            config.recipe
    in
    Html.footer [ class "print-footer mono" ]
        [ span []
            [ text (String.toUpper r.title ++ " · LAST BATCH " ++ r.tested) ]
        , span [] [ text ("SCALE " ++ Scale.label config.factor) ]
        , span [] [ text ("PULLED " ++ config.today) ]
        , span [ class "print-url" ]
            [ text (config.origin ++ "/recipe/" ++ r.slug) ]
        ]


{-| One ingredient's quantity, scaled, with its unit — the same
reading the ingredients block gives, reused so a shopping list can
never disagree with the recipe it was made from.
-}
quantity : Config msg -> Recipe.Ingredient -> String
quantity config item =
    case item.amount of
        Nothing ->
            ""

        Just a ->
            let
                scaled =
                    Scale.ingredient config.factor
                        { text = a.text
                        , value = a.value
                        , max = a.max
                        , unit = item.unit
                        , kind = item.unitKind
                        , indivisible = item.indivisible
                        }
            in
            scaled.text
                ++ Maybe.withDefault ""
                    (Maybe.map (\u -> " " ++ Scale.unitLabel scaled.text u) item.unit)
