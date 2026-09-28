module ReachTests exposing (suite)

import Expect
import Http
import Reach exposing (Failure(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Reach.fromHttp"
        [ test "a 404 is a recipe the archive does not have" <|
            \_ -> Reach.fromHttp (Http.BadStatus 404) |> Expect.equal Missing
        , test "the worker's 503 is a recipe this device has not kept" <|
            \_ -> Reach.fromHttp (Http.BadStatus 503) |> Expect.equal Unkept
        , test "no network and no worker is unreachable, never missing" <|
            \_ -> Reach.fromHttp Http.NetworkError |> Expect.equal Unreachable
        , test "a timeout is unreachable" <|
            \_ -> Reach.fromHttp Http.Timeout |> Expect.equal Unreachable
        , test "a body that will not decode is broken, never missing" <|
            \_ -> Reach.fromHttp (Http.BadBody "x") |> Expect.equal Broken
        , test "a server fault is broken" <|
            \_ -> Reach.fromHttp (Http.BadStatus 500) |> Expect.equal Broken
        ]
