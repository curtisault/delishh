module Scale exposing
    ( Factor
    , Scaled
    , amount
    , factors
    , ingredient
    , label
    , one
    , servings
    , fromString
    , toFloat
    , toString
    , unitLabel
    , yield
    )

{-| The measurement ladder — DS-01 §05.

**Scaling is where a recipe archive lies to you, and this module is
the refusal.** Multiply four eggs by 1.5 and the arithmetic says six;
multiply three by 1.5 and it says 4.5, which is not a thing you can
put in a bowl. Most recipe software rounds that silently and hands you
a number that is wrong in a way you cannot see. Here, a rounding that
changed the answer says so.

The rules, ruled once and applied per unit:

  - **Mass is authoritative.** Grams are whole numbers; above 100 g
    they round to the nearest 5, because nobody weighs 287 g and the
    false precision suggests a tolerance the recipe does not have.
  - **Volume is a convenience**, and its fractions are glyphs — ¾, not
    0.75. Quarters at or above one unit, eighths below it: a quarter
    is the working granularity of a spoon, but rounding ⅛ tsp up to ¼
    doubles a spice.
  - **Counts are indivisible.** An egg, a can, a clove. These round to
    a whole number and **carry a note saying what the arithmetic
    actually wanted**, which is the honest half of the feature.
  - **Nothing ever rounds to zero.** An ingredient that vanishes when
    you halve a recipe is the worst failure available here, because
    the page still looks correct.

**×1 is identity, exactly.** Not "multiply by one and round" — the
original text is returned verbatim, so a recipe written with ⅛ tsp
still reads ⅛ tsp when nobody asked for it to change.

-}

-- FACTORS


{-| A scale factor. Opaque so the view cannot invent ×1.37 — the
offered set is a design decision (DS-01 §08: scaling is set before you
start), not a free-form number field.
-}
type Factor
    = Factor Float


{-| The factors offered, smallest first. Half a recipe through three
times it; past that you are cooking a different dish with different
equipment, and the archive should not pretend otherwise.
-}
factors : List Factor
factors =
    List.map Factor [ 0.5, 1, 1.5, 2, 3 ]


one : Factor
one =
    Factor 1


toFloat : Factor -> Float
toFloat (Factor f) =
    f


{-| A factor as it rides in a URL, and back.

Cook mode reads its scale off the address rather than inheriting it
through navigation: the scale is set before you start (DS-01 §08), and
a factor that survived a page change invisibly is exactly the silent
rescaling this module exists to prevent. An unrecognised value is ×1 —
the build's own vocabulary discipline, applied to a query string.

-}
toString : Factor -> String
toString (Factor f) =
    String.fromFloat f


fromString : Maybe String -> Factor
fromString raw =
    raw
        |> Maybe.andThen String.toFloat
        |> Maybe.andThen
            (\wanted ->
                factors
                    |> List.filter (\(Factor f) -> f == wanted)
                    |> List.head
            )
        |> Maybe.withDefault one


{-| How a factor is written wherever it appears — and it appears
permanently once it is not ×1, because a scaled recipe that does not
say it is scaled is dangerous (DS-01 §08).
-}
label : Factor -> String
label (Factor f) =
    let
        trimmed =
            if f == Basics.toFloat (round f) then
                String.fromInt (round f)

            else
                String.fromFloat f
    in
    "×" ++ trimmed



-- UNITS


{-| A unit as it should read beside a given amount.

The content build canonicalises count units to the singular so that
`cloves` and `clove` are one facet and not two
(`scripts/vocabulary.ts`). That is right for the data and wrong for
the page: "3 clove garlic" is not English, and scaling makes it worse
because the amount changes under a unit that cannot.

Symbols never inflect — `2 g`, `3 tsp`. Words do.

**A word inflects above one, not away from one.** The first version of
this tested `amountText == "1"`, which is true of exactly one amount
and false of every fraction below it, so the sheet read `¾ cups` and
`⅓ cups`. Under one is singular in English — you have three quarters
of *a cup* — so the question the unit is asking is "is this more than
one", and it has to be asked of the amount's value rather than of its
spelling.

-}
unitLabel : String -> String -> String
unitLabel amountText unit =
    if not (List.member unit plurals) || not (exceedsOne amountText) then
        unit

    else if unit == "bunch" then
        "bunches"

    else
        unit ++ "s"


{-| The units that are words rather than symbols. `cup` is here and
`tsp` is not, which is exactly how a recipe reads them aloud.
-}
plurals : List String
plurals =
    [ "clove", "can", "sprig", "head", "stick", "sheet", "bunch", "slice", "cup" ]


{-| Whether an amount, as it was rendered, reads as more than one.

**A range judges by its high end.** `1–2 cups` is right and `1–2 cup`
is not: the unit agrees with the largest measure the line offers, the
same way English does when you read it aloud.

-}
exceedsOne : String -> Bool
exceedsOne amountText =
    magnitude (highEnd amountText) > 1


{-| The upper end of a range, or the whole string when it is not one.
-}
highEnd : String -> String
highEnd amountText =
    String.split "–" amountText
        |> List.reverse
        |> List.head
        |> Maybe.withDefault amountText


{-| The numeric value of an amount as rendered: `1½` is 1.5, `¾` is
0.75, `440` is 440.

Not a parser for arbitrary text — it reads exactly the two shapes this
module emits (a decimal run, optionally followed by one fraction
glyph) and answers 0 for anything else, which lands on singular. A
unit with no number in front of it has no plural to take.

-}
magnitude : String -> Float
magnitude amountText =
    let
        trimmed =
            String.trim amountText

        digits =
            String.filter (\c -> Char.isDigit c || c == '.') trimmed
    in
    Maybe.withDefault 0 (String.toFloat digits)
        + (String.toList trimmed
            |> List.filterMap glyphValue
            |> List.head
            |> Maybe.withDefault 0
          )


{-| The fraction glyphs of DS-01 §05, as values. The list is
`scripts/vocabulary.ts`'s `FRACTIONS` — the build writes these and
this reads them, so a glyph added there and not here reads as zero
and takes the singular, which is wrong but never wildly wrong.
-}
glyphValue : Char -> Maybe Float
glyphValue c =
    case c of
        '½' ->
            Just 0.5

        '⅓' ->
            Just (1 / 3)

        '⅔' ->
            Just (2 / 3)

        '¼' ->
            Just 0.25

        '¾' ->
            Just 0.75

        '⅕' ->
            Just 0.2

        '⅖' ->
            Just 0.4

        '⅗' ->
            Just 0.6

        '⅘' ->
            Just 0.8

        '⅙' ->
            Just (1 / 6)

        '⅚' ->
            Just (5 / 6)

        '⅛' ->
            Just 0.125

        '⅜' ->
            Just 0.375

        '⅝' ->
            Just 0.625

        '⅞' ->
            Just 0.875

        _ ->
            Nothing



-- THE RESULT


{-| One scaled quantity: what to show, and what the showing cost.

`note` is present only when rounding changed the answer — an
indivisible count that the arithmetic wanted a fraction of. It is the
sentence DS-01 §05 demands in place of a false number.

-}
type alias Scaled =
    { text : String
    , note : Maybe String
    }



-- SCALING ONE INGREDIENT


{-| Scale one ingredient's amount.

Takes the amount exactly as the markdown wrote it (`text`), its parsed
value, the unit's kind, and whether the unit is indivisible — all of
which the content build has already worked out (`scripts/recipe.ts`),
so nothing is re-derived from prose here.

-}
ingredient :
    Factor
    ->
        { text : String
        , value : Float
        , max : Maybe Float
        , unit : Maybe String
        , kind : Maybe String
        , indivisible : Bool
        }
    -> Scaled
ingredient (Factor f) item =
    if f == 1 then
        -- Identity. Not "×1 and round" — a recipe nobody asked to
        -- scale must read exactly as it was written.
        { text = item.text, note = Nothing }

    else
        case item.max of
            Just high ->
                -- A range scales at both ends and reports whichever
                -- end had something to admit.
                let
                    low_ =
                        scaleOne f item item.value

                    high_ =
                        scaleOne f item high
                in
                { text = low_.text ++ "–" ++ high_.text
                , note =
                    case ( low_.note, high_.note ) of
                        ( Just n, _ ) ->
                            Just n

                        ( Nothing, n ) ->
                            n
                }

            Nothing ->
                scaleOne f item item.value


scaleOne :
    Float
    -> { a | unit : Maybe String, kind : Maybe String, indivisible : Bool }
    -> Float
    -> Scaled
scaleOne f item value =
    let
        exact =
            value * f
    in
    if item.indivisible then
        countOf f item exact

    else
        case ( item.kind, item.unit ) of
            ( Just "mass", Just "g" ) ->
                { text = String.fromInt (roundedMass exact), note = Nothing }

            ( Just "volume", Just "ml" ) ->
                { text = String.fromInt (roundedMass exact), note = Nothing }

            ( Just "mass", _ ) ->
                -- kg. Decimals are permitted for mass (DS-01 §05); two
                -- places is a gram, which is as fine as a kitchen
                -- scale reads.
                { text = decimals 2 exact, note = Nothing }

            ( Just "volume", Just "l" ) ->
                { text = decimals 2 exact, note = Nothing }

            ( Just "volume", _ ) ->
                -- Spoons and cups: glyph fractions, never decimals.
                { text = fraction exact, note = Nothing }

            _ ->
                { text = decimals 2 exact, note = Nothing }


{-| An indivisible count: eggs, cans, cloves.

Rounds to a whole number and says so when the arithmetic wanted
otherwise. The note names the number the multiplication actually
produced, because "3 eggs" on a ×1.25 of two eggs is a decision
somebody made on your behalf and you are entitled to know.

-}
countOf : Float -> { a | unit : Maybe String } -> Float -> Scaled
countOf f item exact =
    let
        whole =
            max 1 (round exact)

        honest =
            abs (exact - Basics.toFloat whole) < 0.001
    in
    { text = String.fromInt whole
    , note =
        if honest then
            Nothing

        else
            Just
                (String.concat
                    [ "×"
                    , decimals 2 f
                    , " wants "
                    , decimals 2 exact
                    , " — rounded to "
                    , String.fromInt whole
                    , Maybe.withDefault ""
                        (Maybe.map
                            (\u -> " " ++ unitLabel (String.fromInt whole) u)
                            item.unit
                        )
                    , "."
                    ]
                )
    }



-- ROUNDING


{-| Grams and millilitres. Above 100 the ladder steps to 5, because a
scaled 287 g claims a precision the recipe never had; below it every
gram counts and the step is 1. Never zero: an ingredient that vanishes
on a half batch is a silent wrong answer.
-}
roundedMass : Float -> Int
roundedMass value =
    if value > 100 then
        max 1 (round (value / 5) * 5)

    else
        max 1 (round value)


{-| Volume as a glyph fraction.

Quarters at or above one unit — the working granularity of a measuring
spoon. Eighths below it, because rounding ⅛ tsp to ¼ doubles a spice
and the error is invisible on the page.

-}
fraction : Float -> String
fraction value =
    let
        step =
            if value >= 1 then
                4

            else
                8

        units =
            max 1 (round (value * Basics.toFloat step))

        whole =
            units // step

        part =
            units - (whole * step)

        glyph =
            case ( part, step ) of
                ( 0, _ ) ->
                    ""

                ( 1, 8 ) ->
                    "⅛"

                ( 2, 8 ) ->
                    "¼"

                ( 3, 8 ) ->
                    "⅜"

                ( 4, 8 ) ->
                    "½"

                ( 5, 8 ) ->
                    "⅝"

                ( 6, 8 ) ->
                    "¾"

                ( 7, 8 ) ->
                    "⅞"

                ( 1, _ ) ->
                    "¼"

                ( 2, _ ) ->
                    "½"

                ( 3, _ ) ->
                    "¾"

                _ ->
                    ""
    in
    if whole == 0 then
        -- `units` is floored at 1, so this is never an empty string.
        glyph

    else if glyph == "" then
        String.fromInt whole

    else
        String.fromInt whole ++ glyph


{-| A decimal with trailing zeros cut: `1.50` reads as `1.5`, `2.00`
as `2`. Tabular figures do not need padding to line up.
-}
decimals : Int -> Float -> String
decimals places value =
    let
        power =
            Basics.toFloat (10 ^ places)

        rounded =
            Basics.toFloat (round (value * power)) / power
    in
    if rounded == Basics.toFloat (round rounded) then
        String.fromInt (round rounded)

    else
        String.fromFloat rounded



-- YIELD


{-| The yield, scaled. Mass and volume follow the same ladder as an
ingredient; anything else is a plain count.
-}
yield : Factor -> { amount : Float, unit : String } -> String
yield (Factor f) y =
    if f == 1 then
        decimals 2 y.amount

    else
        case y.unit of
            "g" ->
                String.fromInt (roundedMass (y.amount * f))

            "ml" ->
                String.fromInt (roundedMass (y.amount * f))

            _ ->
                decimals 2 (y.amount * f)


{-| Servings scale as a count and are never zero — but unlike an egg a
serving is a soft number, so a fractional result rounds without
comment rather than claiming a precision the word "serving" does not
carry.
-}
servings : Factor -> Int -> Int
servings (Factor f) n =
    max 1 (round (Basics.toFloat n * f))


{-| A bare amount, for anywhere a quantity is shown outside an
ingredient row.
-}
amount : Factor -> Float -> String
amount (Factor f) value =
    decimals 2 (value * f)
