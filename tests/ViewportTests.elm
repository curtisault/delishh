module ViewportTests exposing (suite)

{-| The whole table, because this guard is easy to get half-right.

The two failures it exists to prevent: no guard at all, so every URL
change scrolls to the top — including a page mirroring a keystroke
into the address bar; and a guard on the scroll-to-top that forgets
the anchor jump, so a control click re-runs whatever fragment the URL
happens to be carrying.

-}

import Expect
import Test exposing (Test, describe, test)
import Viewport exposing (Action(..))


at : Bool -> Bool -> Maybe String -> Action
at mirroring arrived fragment =
    Viewport.actionFor
        { mirroring = mirroring, arrived = arrived, fragment = fragment }


suite : Test
suite =
    describe "Viewport.actionFor"
        [ describe "a real navigation"
            [ test "a new page starts at the top" <|
                \_ -> at False True Nothing |> Expect.equal ToTop
            , test "unless it names a section" <|
                \_ -> at False True (Just "sec-what") |> Expect.equal (ToAnchor "sec-what")
            ]
        , describe "a fragment on the page you are already reading"
            [ test "jumps — this is what a rail link is" <|
                \_ -> at False False (Just "sec-format") |> Expect.equal (ToAnchor "sec-format")
            , test "and without one, nothing moves" <|
                \_ -> at False False Nothing |> Expect.equal Stay
            ]
        , describe "the shell's own echo moves nobody"
            [ test "not to the top" <|
                \_ -> at True True Nothing |> Expect.equal Stay
            , test "and not to an anchor the URL is still carrying" <|
                -- a rail click leaves `#sec-format` in the URL; every
                -- later control click would re-jump to it
                \_ -> at True False (Just "sec-format") |> Expect.equal Stay
            , test "even on arrival, when the shell writes the URL back" <|
                \_ -> at True True (Just "sec-what") |> Expect.equal Stay
            ]
        ]
