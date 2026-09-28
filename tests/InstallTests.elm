module InstallTests exposing (suite)

import Expect
import Install exposing (Offer(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Install.fromString"
        [ test "the browser's own dialog" <|
            \_ -> Install.fromString "prompt" |> Expect.equal Prompt
        , test "a home screen reached through the share sheet" <|
            \_ -> Install.fromString "share" |> Expect.equal ShareSheet
        , test "installed, or nothing to offer" <|
            \_ -> Install.fromString "none" |> Expect.equal NoOffer
        , test "an unknown word draws no press" <|
            \_ -> Install.fromString "maybe" |> Expect.equal NoOffer
        ]
