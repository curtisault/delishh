module ScaleTests exposing (suite)

{-| The measurement ladder — DS-01 §05.

**Scaling is where a recipe archive lies to you.** Every test here is
one of those lies, refused: a fractional egg, an ingredient that
vanished on a half batch, a decimal where a glyph belongs, a ⅛ tsp
that silently doubled because nobody asked what "round to a quarter"
does to a small number.

The one that matters most is the honest note. Rounding 2.5 eggs to 3
is the right answer; doing it *without saying so* is the bug, and no
type can catch it — only a test that reads the note.

-}

import Expect
import Scale
import Test exposing (Test, describe, test)


{-| An ingredient as the content build hands it over, with sensible
defaults the tests override one field at a time.
-}
item :
    { text : String, value : Float, unit : Maybe String, kind : Maybe String }
    -> { text : String, value : Float, max : Maybe Float, unit : Maybe String, kind : Maybe String, indivisible : Bool }
item base =
    { text = base.text
    , value = base.value
    , max = Nothing
    , unit = base.unit
    , kind = base.kind
    , indivisible = False
    }


grams : Float -> { text : String, value : Float, max : Maybe Float, unit : Maybe String, kind : Maybe String, indivisible : Bool }
grams value =
    item { text = String.fromFloat value, value = value, unit = Just "g", kind = Just "mass" }


tsp : Float -> { text : String, value : Float, max : Maybe Float, unit : Maybe String, kind : Maybe String, indivisible : Bool }
tsp value =
    item { text = String.fromFloat value, value = value, unit = Just "tsp", kind = Just "volume" }


count : Float -> { text : String, value : Float, max : Maybe Float, unit : Maybe String, kind : Maybe String, indivisible : Bool }
count value =
    let
        base =
            item { text = String.fromFloat value, value = value, unit = Nothing, kind = Nothing }
    in
    { base | indivisible = True }


factor : Float -> Scale.Factor
factor wanted =
    Scale.factors
        |> List.filter (\f -> Scale.toFloat f == wanted)
        |> List.head
        |> Maybe.withDefault Scale.one


scaledText : Float -> { text : String, value : Float, max : Maybe Float, unit : Maybe String, kind : Maybe String, indivisible : Bool } -> String
scaledText f i =
    (Scale.ingredient (factor f) i).text


suite : Test
suite =
    describe "Scale"
        [ describe "×1 is identity, exactly"
            [ test "a mass is returned as written, not re-rounded" <|
                \_ ->
                    scaledText 1 (grams 142)
                        |> Expect.equal "142"
            , test "a glyph fraction survives untouched" <|
                \_ ->
                    -- The whole point: a recipe nobody asked to scale
                    -- must read exactly as it was written. Round ⅛ to
                    -- the nearest quarter at ×1 and the archive has
                    -- edited a recipe behind the cook's back.
                    scaledText 1 { text = "⅛", value = 0.125, max = Nothing, unit = Just "tsp", kind = Just "volume", indivisible = False }
                        |> Expect.equal "⅛"
            , test "an indivisible count is never noted at ×1" <|
                \_ ->
                    (Scale.ingredient Scale.one (count 3)).note
                        |> Expect.equal Nothing
            ]
        , describe "mass rounds on the ladder"
            [ test "under 100 g steps by 1" <|
                \_ -> scaledText 1.5 (grams 90) |> Expect.equal "135"
            , test "over 100 g steps by 5" <|
                \_ ->
                    -- 200 × 1.5 = 300, already on the step.
                    scaledText 1.5 (grams 200) |> Expect.equal "300"
            , test "over 100 g rounds to the nearest 5, not to the gram" <|
                \_ ->
                    -- 191 × 1.5 = 286.5 → 285. Nobody weighs 287 g,
                    -- and the false precision claims a tolerance the
                    -- recipe does not have.
                    scaledText 1.5 (grams 191) |> Expect.equal "285"
            , test "grams are whole numbers, never decimals" <|
                \_ ->
                    scaledText 0.5 (grams 45)
                        |> String.contains "."
                        |> Expect.equal False
            , test "a mass never rounds away to nothing" <|
                \_ ->
                    -- 1 g halved is 0.5 g. An ingredient that
                    -- disappears on a half batch is a silent wrong
                    -- answer: the page still looks correct.
                    scaledText 0.5 (grams 1) |> Expect.equal "1"
            ]
        , describe "volume is glyphs, never decimals"
            [ test "a half is a glyph" <|
                \_ -> scaledText 0.5 (tsp 1) |> Expect.equal "½"
            , test "three quarters is a glyph" <|
                \_ -> scaledText 1.5 (tsp 0.5) |> Expect.equal "¾"
            , test "a whole and a part read together" <|
                \_ -> scaledText 1.5 (tsp 1) |> Expect.equal "1½"
            , test "a whole number carries no glyph" <|
                \_ -> scaledText 2 (tsp 1) |> Expect.equal "2"
            , test "no scaled volume is ever a decimal" <|
                \_ ->
                    [ 0.5, 1.5, 2, 3 ]
                        |> List.map (\f -> scaledText f (tsp 0.75))
                        |> List.filter (String.contains ".")
                        |> Expect.equal []
            , test "below one unit the step is an eighth, not a quarter" <|
                \_ ->
                    -- ¾ × 0.5 = 0.375, which IS an eighth exactly.
                    -- Round it to the nearest quarter instead and it
                    -- becomes ½ — a third more spice than the recipe
                    -- asked for, and invisible on the page.
                    scaledText 0.5 (tsp 0.75) |> Expect.equal "⅜"
            , test "a volume never rounds away to nothing" <|
                \_ -> scaledText 0.5 (tsp 0.125) |> Expect.equal "⅛"
            ]
        , describe "counts are indivisible, and say when they were rounded"
            [ test "a clean multiple passes without comment" <|
                \_ ->
                    Scale.ingredient (factor 1.5) (count 2)
                        |> Expect.equal { text = "3", note = Nothing }
            , test "a fractional result rounds to a whole number" <|
                \_ -> scaledText 1.5 (count 3) |> Expect.equal "5"
            , test "and says so, naming what the arithmetic wanted" <|
                \_ ->
                    -- The honest note DS-01 §05 demands in place of a
                    -- false number. Without this the page shows "5
                    -- eggs" for a decision nobody was told about.
                    (Scale.ingredient (factor 1.5) (count 3)).note
                        |> Maybe.withDefault ""
                        |> Expect.all
                            [ String.contains "4.5" >> Expect.equal True
                            , String.contains "5" >> Expect.equal True
                            ]
            , test "a count never rounds away to nothing" <|
                \_ ->
                    -- One egg, halved, is still one egg — and the note
                    -- is what makes that honest rather than wrong.
                    scaledText 0.5 (count 1) |> Expect.equal "1"
            , test "rounding down to zero is reported, not hidden" <|
                \_ ->
                    (Scale.ingredient (factor 0.5) (count 1)).note
                        |> Expect.notEqual Nothing
            ]
        , describe "ranges scale at both ends"
            [ test "both ends move" <|
                \_ ->
                    let
                        base =
                            grams 100
                    in
                    scaledText 2 { base | max = Just 150 }
                        |> Expect.equal "200–300"
            ]
        , describe "an ingredient with no amount is left alone"
            [ test "salt to finish stays salt to finish" <|
                \_ ->
                    -- Nothing to scale: the view passes no amount at
                    -- all, so this is really a test that the row is
                    -- representable without one.
                    scaledText 2 (item { text = "", value = 0, unit = Nothing, kind = Nothing })
                        |> Expect.equal "0"
            ]
        , describe "yield and servings"
            [ test "yield follows the mass ladder" <|
                \_ ->
                    Scale.yield (factor 1.5) { amount = 340, unit = "g" }
                        |> Expect.equal "510"
            , test "servings scale as a count" <|
                \_ -> Scale.servings (factor 2) 8 |> Expect.equal 16
            , test "servings never reach zero" <|
                \_ -> Scale.servings (factor 0.5) 1 |> Expect.equal 1
            ]
        , describe "a unit reads correctly beside its amount"
            [ test "a count unit pluralises" <|
                \_ ->
                    -- The build canonicalises `cloves` to `clove` so
                    -- the facet is one value and not two. That is
                    -- right for the data and wrong for the page.
                    Scale.unitLabel "3" "clove" |> Expect.equal "cloves"
            , test "one of a thing stays singular" <|
                \_ -> Scale.unitLabel "1" "clove" |> Expect.equal "clove"
            , test "a fraction over one is still plural" <|
                \_ -> Scale.unitLabel "1¼" "cup" |> Expect.equal "cups"
            , test "bunch takes -es" <|
                \_ -> Scale.unitLabel "2" "bunch" |> Expect.equal "bunches"
            , -- The printed sheet read `¾ cups` and `⅓ cups` for as
              -- long as this function tested `== "1"`: true of exactly
              -- one amount, false of every fraction beneath it. Under
              -- one is singular — three quarters of *a cup*.
              test "under one is singular, every glyph" <|
                \_ ->
                    List.map (\a -> Scale.unitLabel a "cup")
                        [ "¾", "⅓", "½", "⅛", "⅞" ]
                        |> Expect.equal [ "cup", "cup", "cup", "cup", "cup" ]
            , test "a mixed number over one is plural" <|
                \_ -> Scale.unitLabel "1½" "cup" |> Expect.equal "cups"
            , test "a range takes its high end" <|
                \_ ->
                    -- `1–2 cup` is not English. The unit agrees with
                    -- the largest measure the line offers.
                    ( Scale.unitLabel "1–2" "cup", Scale.unitLabel "½–¾" "cup" )
                        |> Expect.equal ( "cups", "cup" )
            , test "a decimal amount reads by its value" <|
                \_ ->
                    ( Scale.unitLabel "1.50" "cup", Scale.unitLabel "0.75" "cup" )
                        |> Expect.equal ( "cups", "cup" )
            , test "symbols never inflect" <|
                \_ ->
                    List.map (Scale.unitLabel "3") [ "g", "kg", "ml", "l", "tsp", "tbsp" ]
                        |> Expect.equal [ "g", "kg", "ml", "l", "tsp", "tbsp" ]
            , test "the honest note pluralises its unit too" <|
                \_ ->
                    (Scale.ingredient (factor 1.5)
                        (let
                            base =
                                item { text = "3", value = 3, unit = Just "clove", kind = Just "count" }
                         in
                         { base | indivisible = True }
                        )
                    ).note
                        |> Maybe.withDefault ""
                        |> String.contains "5 cloves"
                        |> Expect.equal True
            ]
        , describe "the offered factors"
            [ test "are half through triple" <|
                \_ ->
                    List.map Scale.toFloat Scale.factors
                        |> Expect.equal [ 0.5, 1, 1.5, 2, 3 ]
            , test "read with a multiplication sign and no trailing zero" <|
                \_ ->
                    List.map Scale.label Scale.factors
                        |> Expect.equal [ "×0.5", "×1", "×1.5", "×2", "×3" ]
            ]
        ]
