module Viewport exposing (Action(..), actionFor)

{-| Whether a URL change should move the reader, and where to.

Three things change the URL here and only one of them is a
navigation:

1.  a real navigation — a nav link, a rail link, a shared address;
2.  a fragment jump within the page;
3.  **the shell mirroring a control into the address bar** — any page
    whose state lives in the URL rather than in this browser.

The third is an echo. `Browser.application` reports it through
`onUrlChange` exactly like the other two, and treating it like them
yanks the reader up the page on every click of a control: the URL
still carries the `#anchor` they arrived on, so each echo re-runs that
jump, and §01 is the top of the document.

Pure, and separated out precisely because the guard is easy to get
half-right: guarding the scroll-to-top and forgetting the anchor jump
is the classic way. `ViewportTests` holds the whole table.

Nothing in this project mirrors yet (`Main.arrivalMirrors` answers
False for every route). This module and its tests are here so that the
first page that does mirror inherits a decision that is already right,
rather than re-deriving it inline.

-}


type Action
    = -- leave the reader where they are
      Stay
      -- a new page starts at the top, like a page load
    | ToTop
      -- a fragment: put this anchor under the sticky chrome
    | ToAnchor String


{-| `mirroring` is the shell's own echo — nothing it produces has
moved the reader, so nothing about it should move them either.
-}
actionFor : { mirroring : Bool, arrived : Bool, fragment : Maybe String } -> Action
actionFor context =
    if context.mirroring then
        Stay

    else
        case context.fragment of
            Just anchor ->
                ToAnchor anchor

            Nothing ->
                if context.arrived then
                    ToTop

                else
                    Stay
