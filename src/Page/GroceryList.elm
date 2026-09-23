module Page.GroceryList exposing (Config, view)

{-| The shopping list — DS-01 §04, amended 2026-09-22.

**A third surface, and it runs quiet.** §01 splits the product into a
loud shelf and a calm page; this is neither, because it is read
neither while choosing nor while cooking. It is carried into a shop
and read one-handed beside a trolley, so it takes the procedure
register: `--page-*` marks only, volt on the one actionable thing,
and quantities in ink like every other quantity in the archive.

Like the shelf and the recipe page, **it does not wear `Doc`**: there
is nothing here to number and nothing to cite.

Three things that are decisions rather than details:

  - **In the cart is a shape.** A ticked row fills its box against
    the outlined boxes of everything still to buy — the cook rail's
    filled-against-outlined glance (§08), drawn with the printed prep
    sheet's box rather than a character, because a glyph checkbox is
    a font dependency (§09). The strikethrough is decoration on top
    of that and of the words ", in cart"; it is never the only
    carrier (§12).
  - **Ticked rows sink, and stay legible.** They go to one group at
    the bottom rather than vanishing, because you will look down to
    check whether you already got the butter. This is the shelf's
    lockout treatment, not cook mode's stamp. Nothing animates on the
    way: the motion register is zero (§10), and a list rearranging
    itself under a thumb in a shop would be hostile.
  - **A ticked row keeps its quantity.** It is the number you check
    against the trolley at the till.

-}

import GroceryList exposing (Line)
import Html exposing (Html, a, button, div, h1, h2, li, p, section, span, text, ul)
import Html.Attributes exposing (attribute, class, classList, href, id)
import Html.Events exposing (onClick)
import Route


type alias Config msg =
    { list : GroceryList.Model
    , onCheck : String -> msg
    }


view : Config msg -> Html msg
view config =
    let
        { toBuy, inCart } =
            GroceryList.lines config.list
    in
    div [ class "list-layout" ]
        [ div [ class "shopping-list" ]
            (if GroceryList.isEmpty config.list then
                [ masthead "Nothing on it yet.", empty ]

             else
                masthead (remaining (List.length (List.concatMap .items toBuy)))
                    :: sources config
                    :: List.map (aisle config) toBuy
                    ++ [ cart config inCart ]
            )
        ]


masthead : String -> Html msg
masthead standfirst =
    div [ class "list-plate" ]
        [ h1 [ class "list-title" ] [ text "Shopping list" ]
        , p [ class "list-standfirst" ] [ text standfirst ]
        ]


{-| The count is what is **left**, not what is on the list.

A standfirst that kept saying "32 things to buy" while half of them sat
in the cart would be the page disagreeing with itself two inches
further down, and the number you glance at in a shop is the one that
says whether you can leave.

-}
remaining : Int -> String
remaining n =
    case n of
        0 ->
            "Everything is in the cart."

        1 ->
            "One thing left to buy."

        _ ->
            String.fromInt n ++ " things left to buy."


{-| A dead end is a design failure: the empty state says where the
list comes from and offers the way there.
-}
empty : Html msg
empty =
    section [ class "list-empty" ]
        [ p []
            [ text "Open a recipe and press "
            , span [ class "u" ] [ text "Add to list" ]
            , text ". What it needs lands here, and two recipes wanting "
            , text "the same thing make one line."
            ]
        , p []
            [ a [ class "list-back u", href (Route.toPath Route.Home) ]
                [ text "Back to the shelf" ]
            ]
        ]


{-| What the list is made of.

Named rather than counted, because "3 recipes" is not something you
can act on and a title you did not mean to add is. The scale rides
beside each one: the list is a sum, and the only way to read where a
number came from is to see what went into it.

-}
sources : Config msg -> Html msg
sources config =
    section [ class "list-sources" ]
        [ h2 [ class "list-h u" ] [ text "From" ]
        , ul [ class "list-source-set" ]
            (GroceryList.contributions config.list
                |> List.map
                    (\c ->
                        li [ class "list-source" ]
                            [ a
                                [ class "list-source-link"
                                , href (Route.toPath (Route.Recipe c.slug))
                                ]
                                [ text c.title ]
                            , if c.factor == 1 then
                                text ""

                              else
                                span [ class "list-source-scale u" ]
                                    [ text ("×" ++ scaleLabel c.factor) ]
                            ]
                    )
            )
        ]


{-| `×1.5`, without a trailing zero. `Scale.label` would do this, but
a stored factor is a plain number by then and reconstructing a
`Scale.Factor` to ask it would be a round trip through a type that
only exists to bound what the reader may choose.
-}
scaleLabel : Float -> String
scaleLabel factor =
    if factor == toFloat (round factor) then
        String.fromInt (round factor)

    else
        String.fromFloat factor


aisle : Config msg -> { aisle : String, label : String, items : List Line } -> Html msg
aisle config group =
    section [ id ("aisle-" ++ group.aisle), class "list-aisle" ]
        [ h2 [ class "list-h u" ] [ text group.label ]
        , ul [ class "list-set" ] (List.map (row config) group.items)
        ]


{-| Everything already picked up, in one group at the end.

One group rather than one per aisle: the aisles are a route through a
shop, and what is in the trolley is behind you.

-}
cart : Config msg -> List Line -> Html msg
cart config items =
    if List.isEmpty items then
        text ""

    else
        section [ id "in-cart", class "list-aisle is-cart" ]
            [ h2 [ class "list-h u" ] [ text "In cart" ]
            , ul [ class "list-set" ] (List.map (row config) items)
            ]


row : Config msg -> Line -> Html msg
row config line =
    li [ class "list-row", classList [ ( "is-cart", line.checked ) ] ]
        [ button
            [ attribute "type" "button"
            , class "list-tick"
            , attribute "aria-pressed"
                (if line.checked then
                    "true"

                 else
                    "false"
                )
            , onClick (config.onCheck line.key)
            ]
            [ span [ class "list-box", attribute "aria-hidden" "true" ] []
            , span [ class "list-name" ] [ text line.name ]
            , if String.isEmpty line.quantity then
                text ""

              else
                span [ class "list-qty" ] [ text line.quantity ]

            -- The fill says "in cart" to an eye; this says it to a
            -- screen reader. Neither is the only carrier (§04).
            , if line.checked then
                span [ class "vh" ] [ text ", in cart" ]

              else
                text ""
            ]
        ]
