module Print exposing (Form(..), all, className, fromSlug, label, note)

{-| The four printed forms — DS-01 §09.

**The sheet is designed to be destroyed.** Reprinting is the intended
lifecycle, not a failure, which is exactly why it must be cheap in
ink, small in pages, and traceable back to its current revision.

A form is chosen by the recipe's own `print:` frontmatter and can be
overridden by the reader before printing. It is carried to the
stylesheet as a class on the recipe wrapper and *nothing else* — the
whole of §09 is `src/print.css`, with no print-specific JavaScript
anywhere (§12). That is what keeps the two renderings of one markdown
file from becoming two documents.

`Prep` is absent from this type on purpose. It is supplemental and
prints *alongside* any of the three, so it is a toggle rather than a
form — a recipe never defaults to it, because a shopping list is not
a recipe.

-}


type Form
    = -- 1–2 pages. The workhorse.
      Sheet
      -- One page, dense, larger type. For a recipe you already know.
    | Card
      -- Up to 4 pages. Multi-component or multi-day.
    | Booklet


{-| Every form, in the order the picker offers them: shortest first,
because that is the order a reader decides in.
-}
all : List Form
all =
    [ Card, Sheet, Booklet ]


{-| The frontmatter value, as `scripts/vocabulary.ts` validates it.
An unrecognised value cannot reach here — the content build rejects it
— so the fallback is the workhorse rather than an error.
-}
fromSlug : String -> Form
fromSlug slug =
    case slug of
        "card" ->
            Card

        "booklet" ->
            Booklet

        _ ->
            Sheet


label : Form -> String
label form =
    case form of
        Sheet ->
            "Sheet"

        Card ->
            "Card"

        Booklet ->
            "Booklet"


{-| What the form is for, in the picker. Every control states its own
use: a reader should not have to print one to find out what it does
(DS-01 §2.5).
-}
note : Form -> String
note form =
    case form of
        Sheet ->
            "1–2 pages, everything"

        Card ->
            "One page, dense"

        Booklet ->
            "Up to 4, generous"


{-| The class `print.css` keys off.
-}
className : Form -> String
className form =
    case form of
        Sheet ->
            "form-sheet"

        Card ->
            "form-card"

        Booklet ->
            "form-booklet"
