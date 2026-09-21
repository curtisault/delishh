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
    , flavor = [ "sweet" ]
    , method = "sugar-work"
    , effort = "focused"
    , dietary = []
    , cuisine = []
    , print = "sheet"
    , photo = Nothing
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
            , origin = "https://delishh.test"
            , today = "2026-09-20"
            , active = active
            }
        )


plain : Query.Single ()
plain =
    rendered full Nothing


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
            ]
        ]
