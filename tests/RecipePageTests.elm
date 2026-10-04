module RecipePageTests exposing (suite)

{-| The bench layout — DS-01 §06 as amended 2026-09-20.

Three contracts that a screenshot would show you and nothing else
would:

**Equipment precedes Ingredients in the DOM.** Not in a stylesheet —
in the document. The wide screen sets the two in a column beside the
steps, but that is presentation; the order is the order, on a phone
and on paper too, and a CSS-only reordering would mean two orders to
reason about.

**The side nav offers only blocks that exist.** A row whose anchor
resolves to nothing is a navigation control that lies — a recipe with
no rescues must not offer a Rescues row.

**The reading mark is carried, not assumed.** It arrives through the
same port the documents' contents rail uses, and a nav that cannot
show where you are is a list of links.

-}

import Expect
import Html.Attributes as Attr
import Page.Recipe
import Plan exposing (Day(..))
import Print
import Recipe
import Scale
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


ingredient : String -> Recipe.Ingredient
ingredient item =
    { amount = Just { value = 200, max = Nothing, text = "200" }
    , unit = Just "g"
    , unitKind = Just "mass"
    , indivisible = False
    , item = item
    , note = Nothing
    , shop = Just { aisle = "baking", buyAs = item }
    }


{-| A recipe carrying every block, so a test that removes one is
testing the removal rather than the fixture.
-}
full : Recipe.Recipe
full =
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
    , gauges =
        [ { label = "Pan", value = "20 cm", note = Just "pale interior" }
        , { label = "Take it to", value = "175–180 °C", note = Nothing }
        ]
    , ingredients = [ { name = Nothing, items = [ ingredient "caster sugar" ] } ]
    , equipment = [ "Heavy 20 cm saucepan" ]
    , steps = [ { n = 1, text = "Warm the cream.", cue = Just "40 °C · HOLD", timer = Nothing } ]
    , watchpoints = [ "Past 190 °C it is bitter." ]
    , rescues = [ { symptom = "Grainy", recoverable = True, text = "Add water." } ]
    , keeps = [ "Fridge at 4 °C." ]
    , note = [ "Mum went by smell." ]
    }


rendered : Recipe.Recipe -> Maybe String -> Query.Single ()
rendered recipe active =
    Query.fromHtml
        (Page.Recipe.view
            { recipe = recipe
            , factor = Scale.one
            , onScale = always ()
            , form = Print.Sheet
            , onForm = always ()
            , prepCard = False
            , onPrepCard = ()
            , inList = False
            , onToggleList = ()
            , planner = noPlanner Plan.empty
            , origin = "https://delishh.test"
            , today = "2026-09-20"
            , active = active
            }
        )


plain : Query.Single ()
plain =
    rendered full Nothing


{-| The page with the recipe already on the shopping list.
-}
listed : Query.Single ()
listed =
    Query.fromHtml
        (Page.Recipe.view
            { recipe = full
            , factor = Scale.one
            , onScale = always ()
            , form = Print.Sheet
            , onForm = always ()
            , prepCard = False
            , onPrepCard = ()
            , inList = True
            , onToggleList = ()
            , planner = noPlanner Plan.empty
            , origin = "https://delishh.test"
            , today = "2026-09-20"
            , active = Nothing
            }
        )


{-| The day picker, closed, over the given week. -}
noPlanner : Plan.Plan -> Page.Recipe.Planner ()
noPlanner plan =
    { plan = plan
    , open = False
    , placed = Nothing
    , refused = Nothing
    , onOpen = ()
    , onDay = always ()
    , onLabel = always ()
    }


{-| The page with a given planner, everything else plain.
-}
planned : Page.Recipe.Planner () -> Query.Single ()
planned planner =
    Query.fromHtml
        (Page.Recipe.view
            { recipe = full
            , factor = Scale.one
            , onScale = always ()
            , form = Print.Sheet
            , onForm = always ()
            , prepCard = False
            , onPrepCard = ()
            , inList = False
            , onToggleList = ()
            , planner = planner
            , origin = "https://delishh.test"
            , today = "2026-09-20"
            , active = Nothing
            }
        )


{-| A week with this recipe on Wednesday and Friday, and someone
else's spaghetti on Sunday.
-}
aWeek : Plan.Plan
aWeek =
    Plan.empty
        |> Plan.set Wed (Plan.recipe full.slug full.title)
        |> Plan.set Fri (Plan.recipe full.slug full.title)
        |> Plan.set Sun (Plan.own "Spaghetti" |> Maybe.withDefault (Plan.recipe "x" "x"))


{-| Sunday holding five of someone else's meals.
-}
fullSunday : Plan.Plan
fullSunday =
    List.foldl
        (\_ p -> Plan.add Sun (Plan.recipe "x" "Toast") p |> Result.withDefault p)
        Plan.empty
        (List.range 1 5)


pickerDay : Int -> Query.Single () -> Query.Single ()
pickerDay i page =
    page
        |> Query.find [ Selector.class "plan-picker-set" ]
        |> Query.findAll [ Selector.class "plan-picker-day" ]
        |> Query.index i


{-| The nav's rows, in order, as their anchors. -}
navAnchors : Recipe.Recipe -> List String
navAnchors recipe =
    Page.Recipe.view
        { recipe = recipe
        , factor = Scale.one
        , onScale = always ()
        , form = Print.Sheet
        , onForm = always ()
        , prepCard = False
        , onPrepCard = ()
        , inList = False
        , onToggleList = ()
        , planner = noPlanner Plan.empty
        , origin = "https://delishh.test"
        , today = "2026-09-20"
        , active = Nothing
        }
        |> always (blocksOf recipe)


{-| Mirrors the view's own derivation, so the expectation below is a
statement about the recipe rather than a copy of the implementation.
-}
blocksOf : Recipe.Recipe -> List String
blocksOf r =
    List.filterMap identity
        [ maybeIf (not (List.isEmpty r.equipment)) "equipment"
        , maybeIf (not (List.isEmpty r.ingredients)) "ingredients"
        , maybeIf (not (List.isEmpty r.steps)) "steps"
        , maybeIf (not (List.isEmpty r.watchpoints)) "watchpoints"
        , maybeIf (not (List.isEmpty r.rescues)) "rescues"
        , maybeIf (not (List.isEmpty r.keeps)) "keeps"
        , maybeIf (not (List.isEmpty r.note)) "note"
        ]


maybeIf : Bool -> String -> Maybe String
maybeIf yes value =
    if yes then
        Just value

    else
        Nothing


suite : Test
suite =
    describe "the recipe page"
        [ describe "block order — DS-01 §06, amended 2026-09-20"
            [ test "Equipment precedes Ingredients in the document" <|
                \_ ->
                    -- In the DOM, not in a stylesheet. Mise en place
                    -- reads gear-first, and an order that exists only
                    -- on a wide screen is two orders to reason about.
                    plain
                        |> Query.findAll [ Selector.class "recipe-h" ]
                        |> Query.index 0
                        |> Query.has [ Selector.text "Equipment" ]
            , test "and Ingredients is the block after it" <|
                \_ ->
                    plain
                        |> Query.findAll [ Selector.class "recipe-h" ]
                        |> Query.index 1
                        |> Query.has [ Selector.text "Ingredients" ]
            ]
        , describe "the shopping control — DS-01 §04, amended 2026-09-22"
            [ test "the page offers a way onto the shopping list" <|
                \_ ->
                    plain |> Query.has [ Selector.class "lister-btn" ]
            , test "it says which way the press goes" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "lister-btn" ]
                        |> Query.has [ Selector.text "Add to list" ]
            , test "and says the other thing once the recipe is on the list" <|
                \_ ->
                    -- A control that read "Add" while the thing was
                    -- already added is a control you press twice.
                    listed
                        |> Query.find [ Selector.class "lister-btn" ]
                        |> Query.has [ Selector.text "On your list" ]
            , test "the state reaches a screen reader too, not only an eye" <|
                \_ ->
                    listed
                        |> Query.find [ Selector.class "lister-btn" ]
                        |> Query.has
                            [ Selector.attribute (Attr.attribute "aria-pressed" "true") ]
            , test "it is not the page's filled block" <|
                \_ ->
                    -- DS-01's COOK THIS amendment stakes its whole
                    -- reasoning on nothing else here being a fill, so
                    -- this must not become the second one.
                    listed
                        |> Query.find [ Selector.class "lister-btn" ]
                        |> Query.hasNot [ Selector.class "cook-enter" ]
            , test "it stands with the action, not with the settings" <|
                \_ ->
                    -- The row is split on what each control CHANGES:
                    -- the scale and the form change this document,
                    -- these two send something elsewhere.
                    plain
                        |> Query.find [ Selector.class "recipe-actions" ]
                        |> Query.has [ Selector.class "lister-btn" ]
            , test "the settings cluster keeps only the settings" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "recipe-settings" ]
                        |> Query.hasNot [ Selector.class "lister-btn" ]
            , test "the filled primary comes last, in the DOM and in tab order" <|
                \_ ->
                    -- You reach past the quieter control to get to the
                    -- loud one; a screen reader walks them the same way.
                    plain
                        |> Query.find [ Selector.class "recipe-actions" ]
                        |> Query.children []
                        |> Query.index -1
                        |> Query.has [ Selector.class "cook-enter" ]
            ]
        , describe "the plan control — docs/decisions.md"
            [ test "stands with the actions, before COOK THIS" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "recipe-actions" ]
                        |> Query.children []
                        |> Query.index 1
                        |> Query.has [ Selector.class "planner-btn" ]
            , test "says what it does when the recipe is not planned" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "planner-btn" ]
                        |> Query.has [ Selector.text "Add to plan" ]
            , test "says which days once it is, and is seated" <|
                \_ ->
                    planned (noPlanner aWeek)
                        |> Query.find [ Selector.class "planner-btn" ]
                        |> Query.has
                            [ Selector.text "Planned · Wed, Fri"
                            , Selector.class "is-seated"
                            ]
            , test "wears its own face, not the list's" <|
                \_ ->
                    -- Electric blue, set by `.planner-btn` in recipe.css. A
                    -- plan press that also carried the lister's class
                    -- would wear magenta and read as a second ADD TO
                    -- LIST at arm's length.
                    plain
                        |> Query.find [ Selector.class "planner-btn" ]
                        |> Query.hasNot [ Selector.class "lister-btn" ]
            , test "the picker is absent until asked for" <|
                \_ ->
                    plain |> Query.hasNot [ Selector.id "plan-picker" ]
            , test "and says so to a screen reader" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "planner-btn" ]
                        |> Query.has [ Selector.attribute (Attr.attribute "aria-expanded" "false") ]
            , test "open, it offers every day, Sunday first" <|
                \_ ->
                    planned (let p = noPlanner aWeek in { p | open = True })
                        |> Query.findAll [ Selector.class "plan-picker-day" ]
                        |> Query.count (Expect.equal 7)
            , test "a day holding this recipe is seated and pressed" <|
                \_ ->
                    planned (let p = noPlanner aWeek in { p | open = True })
                        |> pickerDay 3
                        |> Query.has
                            [ Selector.class "is-seated"
                            , Selector.attribute (Attr.attribute "aria-pressed" "true")
                            ]
            , test "a day holding another meal names it, so replacing is a choice" <|
                \_ ->
                    planned (let p = noPlanner aWeek in { p | open = True })
                        |> pickerDay 0
                        |> Query.has [ Selector.text "Spaghetti" ]
            , test "a day holding another meal offers to add after it, not to replace it" <|
                \_ ->
                    planned (let p = noPlanner aWeek in { p | open = True })
                        |> pickerDay 0
                        |> Query.has [ Selector.text "Sunday, holds Spaghetti. Press to add this after it" ]
            , test "a full day says so" <|
                \_ ->
                    planned (let p = noPlanner fullSunday in { p | open = True })
                        |> pickerDay 0
                        |> Query.has [ Selector.text "Full", Selector.class "is-full" ]
            , test "pressing a full day is answered in words" <|
                \_ ->
                    planned (let p = noPlanner fullSunday in { p | open = True, refused = Just Sun })
                        |> Query.has [ Selector.text "Sunday holds five. Five is a full day." ]
            , test "no label row until the recipe has just been put on a day" <|
                \_ ->
                    planned (let p = noPlanner aWeek in { p | open = True })
                        |> Query.hasNot [ Selector.class "plan-picker-labels" ]
            , test "placed, it offers the five words and None" <|
                \_ ->
                    planned (let p = noPlanner aWeek in { p | open = True, placed = Just Wed })
                        |> Query.findAll [ Selector.class "plan-picker-label" ]
                        |> Query.count (Expect.equal 6)
            , test "the recipe's own slot is marked, in words too" <|
                \_ ->
                    planned (let p = noPlanner aWeek in { p | open = True, placed = Just Wed })
                        |> Query.findAll [ Selector.class "is-declared" ]
                        |> Query.first
                        |> Query.has [ Selector.text "dessert", Selector.text ", this recipe's slot" ]
            , test "and nothing is chosen for the reader" <|
                \_ ->
                    -- Only None is seated: the entry has no label until
                    -- the reader gives it one. A dessert eaten at lunch
                    -- is lunch (§06, nothing is inferred).
                    planned (let p = noPlanner aWeek in { p | open = True, placed = Just Wed })
                        |> Query.findAll [ Selector.class "plan-picker-label", Selector.class "is-seated" ]
                        |> Expect.all
                            [ Query.count (Expect.equal 1)
                            , Query.first >> Query.has [ Selector.text "None" ]
                            ]
            ]
        , describe "the split"
            [ test "what you need and what you do are separate columns" <|
                \_ ->
                    plain
                        |> Expect.all
                            [ Query.has [ Selector.class "recipe-cols" ]
                            , Query.has [ Selector.class "recipe-side" ]
                            , Query.has [ Selector.class "recipe-main" ]
                            ]
            , test "the rail carries equipment and ingredients, and only those" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "recipe-side" ]
                        |> Query.findAll [ Selector.class "recipe-block" ]
                        |> Query.count (Expect.equal 2)
            , test "the steps are in the main column, not the rail" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "recipe-main" ]
                        |> Query.has [ Selector.id "steps" ]
            ]
        , describe "the side nav"
            [ test "stands outside the recipe, not inside the rail" <|
                \_ ->
                    -- It is chrome. Inside `.recipe-side` it read as
                    -- part of the ingredients rather than as
                    -- navigation, which is why it moved out.
                    plain
                        |> Query.find [ Selector.class "recipe-side" ]
                        |> Query.hasNot [ Selector.class "recipe-nav" ]
            , test "offers one row per block the recipe has" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "recipe-nav" ]
                        |> Query.findAll [ Selector.class "recipe-nav-link" ]
                        |> Query.count (Expect.equal (List.length (navAnchors full)))
            , test "never offers an anchor that resolves to nothing" <|
                \_ ->
                    let
                        noRescues =
                            { full | rescues = [], watchpoints = [] }
                    in
                    rendered noRescues Nothing
                        |> Query.find [ Selector.class "recipe-nav" ]
                        |> Expect.all
                            [ Query.hasNot [ Selector.attribute (Attr.href "#rescues") ]
                            , Query.hasNot [ Selector.attribute (Attr.href "#watchpoints") ]
                            , Query.has [ Selector.attribute (Attr.href "#equipment") ]
                            ]
            , test "every row points at a block the page actually renders" <|
                \_ ->
                    -- The anchors and the section ids come from two
                    -- different lists in the view; this is what holds
                    -- them together.
                    blocksOf full
                        |> List.map
                            (\anchor ->
                                plain |> Query.has [ Selector.id anchor ]
                            )
                        |> List.length
                        |> Expect.equal (List.length (blocksOf full))
            , test "it wears the page's method as its head" <|
                \_ ->
                    -- The acid's word, at the top of the nav — the
                    -- same mark the plate leads with.
                    plain
                        |> Query.find [ Selector.class "recipe-nav" ]
                        |> Query.has [ Selector.text "SUGAR WORK" ]
            , test "the prep card is never a destination" <|
                \_ ->
                    -- Furniture for paper, not reading matter.
                    plain
                        |> Query.find [ Selector.class "recipe-nav" ]
                        |> Query.hasNot [ Selector.attribute (Attr.href "#prep") ]
            ]
        , describe "the reading mark"
            [ test "marks the block the reader is inside" <|
                \_ ->
                    rendered full (Just "steps")
                        |> Query.find [ Selector.class "is-active" ]
                        |> Query.has [ Selector.text "Steps" ]
            , test "marks exactly one row" <|
                \_ ->
                    rendered full (Just "steps")
                        |> Query.findAll [ Selector.class "is-active" ]
                        |> Query.count (Expect.equal 1)
            , test "marks none before the port has reported" <|
                \_ ->
                    plain
                        |> Query.findAll [ Selector.class "is-active" ]
                        |> Query.count (Expect.equal 0)
            , test "an anchor the recipe does not have marks nothing" <|
                \_ ->
                    -- Navigation clears `active`, but a stale value
                    -- arriving mid-render must not mark a row at
                    -- random.
                    rendered full (Just "sec-colophon")
                        |> Query.findAll [ Selector.class "is-active" ]
                        |> Query.count (Expect.equal 0)
            , test "the marked row says so to a screen reader" <|
                \_ ->
                    -- The mark is a 3px bar and a shift to full ink.
                    -- Neither reaches a reader who is not looking at
                    -- it, which is what `aria-current` is for.
                    rendered full (Just "steps")
                        |> Query.find [ Selector.class "is-active" ]
                        |> Query.has
                            [ Selector.attribute (Attr.attribute "aria-current" "true") ]
            , test "aria-current is present or absent, never \"false\"" <|
                \_ ->
                    -- Absence IS the default. Spelling it out on the
                    -- six unmarked rows announces nothing, and gives
                    -- the attribute a value it can be wrong about.
                    rendered full (Just "steps")
                        |> Query.findAll
                            [ Selector.attribute (Attr.attribute "aria-current" "false") ]
                        |> Query.count (Expect.equal 0)
            ]
        , describe "the flavour meter — DS-01 §06, amended 2026-09-21"
            [ test "a stated level draws three cells with the level filled" <|
                \_ ->
                    -- sweet is authored at 3 in the fixture
                    plain
                        |> Query.find [ Selector.class "chip-meter" ]
                        |> Expect.all
                            [ Query.findAll [ Selector.class "chip-seg" ]
                                >> Query.count (Expect.equal 3)
                            , Query.findAll [ Selector.class "on" ]
                                >> Query.count (Expect.equal 3)
                            ]
            , test "the level reaches assistive tech as words, not cells" <|
                \_ ->
                    -- the cells are aria-hidden marks; "3 of 3" without
                    -- "defining" is a number with no meaning
                    plain
                        |> Query.find [ Selector.class "vh" ]
                        |> Query.has [ Selector.text "defining" ]
            , test "an unstated level draws no meter at all" <|
                \_ ->
                    -- never zero, never empty cells: absent is a
                    -- judgement not yet made (the dietary-flag rule)
                    rendered { full | flavor = [ { name = "sweet", level = Nothing } ] } Nothing
                        |> Query.hasNot [ Selector.class "chip-meter" ]
            , test "the chip wears its flavour's mark class" <|
                \_ ->
                    -- f-sweet is the hook the stencil hangs on; the
                    -- word stays in the chip either way
                    plain
                        |> Query.find [ Selector.class "f-sweet" ]
                        |> Query.has [ Selector.text "sweet" ]
            ]
        , describe "the gauge strip — DS-01 §06, amended 2026-09-21"
            [ test "renders one entry per authored gauge" <|
                \_ ->
                    plain
                        |> Query.findAll [ Selector.class "recipe-gauge" ]
                        |> Query.count (Expect.equal 2)
            , test "a gauge carries its label and its value" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "recipe-gauges" ]
                        |> Query.has
                            [ Selector.text "PAN"
                            , Selector.text "20 cm"
                            , Selector.text "175–180 °C"
                            ]
            , test "the note renders when there is one" <|
                \_ ->
                    plain
                        |> Query.find [ Selector.class "recipe-gauge-n" ]
                        |> Query.has [ Selector.text "pale interior" ]
            , test "a gauge with no note renders no note element" <|
                \_ ->
                    -- The second fixture gauge has none. One note
                    -- element for two gauges, not an empty span.
                    plain
                        |> Query.findAll [ Selector.class "recipe-gauge-n" ]
                        |> Query.count (Expect.equal 1)
            , test "no strip at all when the recipe has no gauges" <|
                \_ ->
                    -- An absent block is absent, never a heading over
                    -- blank space — and a strip of labels over nothing
                    -- is exactly that (DS-01 §06).
                    rendered { full | gauges = [] } Nothing
                        |> Query.findAll [ Selector.class "recipe-gauges" ]
                        |> Query.count (Expect.equal 0)
            ]
        , describe "the attribution — DS-01 §06, amended 2026-10-04"
            [ test "sits in the serial row, label and name" <|
                \_ ->
                    rendered { full | inspired = Just "The Corner Bakery" } Nothing
                        |> Query.find [ Selector.class "recipe-serial" ]
                        |> Query.find [ Selector.class "recipe-inspired" ]
                        |> Query.has
                            [ Selector.text "INSPIRED BY"
                            , Selector.text "THE CORNER BAKERY"
                            ]
            , test "nothing stands in for an absent one" <|
                \_ ->
                    -- No "original", no dash: the archive claims
                    -- authorship of nothing (§12).
                    plain
                        |> Query.findAll [ Selector.class "recipe-inspired" ]
                        |> Query.count (Expect.equal 0)
            ]
        ]
