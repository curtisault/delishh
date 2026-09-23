module Liner exposing (leafKey, on, view)

{-| The backing paper, and the leaf laid on it (DS-01 §04, amended
2026-09-23).

Every page but cook mode is a **leaf** — a flat sheet with a kiss-cut
edge — laid on a **liner**: the release paper of a sticker sheet,
printed with the archive's name on the diagonal the way real ones
are. The liner is fixed to the viewport, so scrolling drags the leaf
across it under your hand, and it also drifts along its own rows on
its own — the one sanctioned ambient motion in the product (§10,
amended 2026-09-23), everywhere the paper is.

This module is the one place that decides which routes get the liner,
so that decision is a pure function with a test rather than a
condition somewhere in the shell's view. Cook mode is the exception:
it is the stillest surface in the product, read at arm's length with
a pan on the heat, and it gets neither the paper nor the landing.

-}

import Html exposing (Html, div)
import Html.Attributes exposing (attribute, class)
import Route exposing (Route(..))


{-| Whether a route is laid on the liner. Only cook mode is not.
-}
on : Route -> Bool
on route =
    case route of
        Cook _ ->
            False

        _ ->
            True


{-| The identity of a page's leaf, for the shell's keyed wrapper.

A new key is a new sheet: `Main.view` keys the page on this, so a
route change unmounts the old leaf and mounts a fresh one, and
`sheet.css`'s `@starting-style` gets to seat it. Anything that is not
a new page — a filter, a query, the scale — keeps the key, and the
leaf stays put.

-}
leafKey : Route -> String
leafKey route =
    case route of
        Home ->
            "home"

        About ->
            "about"

        DesignStandard ->
            "standard"

        Recipe slug ->
            "recipe/" ++ slug

        Cook slug ->
            "cook/" ++ slug

        ShoppingList ->
            "list"


{-| The liner. Rows of the archive's name, set by `sheet.css` — the
words are CSS generated content rather than text nodes, so they are
not found by find-in-page, not selected by a drag, and not read by a
screen reader (the whole thing is `aria-hidden` besides). Ninety rows
is enough to cover a 4K portrait viewport at the liner's rotation;
the rows cost nothing because they hold nothing.
-}
view : Html msg
view =
    div [ class "liner", attribute "aria-hidden" "true" ]
        [ div [ class "liner-rows" ]
            (List.repeat 90 (div [ class "liner-row" ] []))
        ]
