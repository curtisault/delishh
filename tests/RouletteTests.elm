module RouletteTests exposing (suite)

{-| Restaurant Roulette, the pure part — `docs/decisions.md`, ruled
2026-09-28.

Three things a page that looked right could still get wrong: a wheel
weighted by a name entered twice, a reel that arrives at the answer
early or lands somewhere else, and a reader who asked for calm being
handed a different dinner from the one the reel would have shown.

-}

import Expect
import Json.Decode as D
import Json.Encode as E
import Roulette exposing (Refusal(..), Spin(..))
import Test exposing (Test, describe, test)
import Time


three : Roulette.Roulette
three =
    Roulette.empty
        |> Roulette.add "Thai Palace"
        |> Result.andThen (Roulette.add "Il Forno")
        |> Result.andThen (Roulette.add "Burger Barn")
        |> Result.withDefault Roulette.empty


at : Int -> Time.Posix
at ms =
    Time.millisToPosix ms


spinOver : List String -> Int -> Spin
spinOver wheel index =
    Roulette.start { calm = False, wheel = wheel, index = index, now = at 1000 }


suite : Test
suite =
    describe "Roulette"
        [ describe "the list"
            [ test "adds at the end, trimmed" <|
                \_ ->
                    Roulette.add "  Sushi Go " three
                        |> Result.map Roulette.names
                        |> Expect.equal (Ok [ "Thai Palace", "Il Forno", "Burger Barn", "Sushi Go" ])
            , test "refuses blank" <|
                \_ ->
                    Roulette.add "   " three
                        |> Expect.equal (Err Blank)
            , test "refuses a duplicate ignoring case, naming the spelling that is there" <|
                \_ ->
                    Roulette.add "thai palace" three
                        |> Expect.equal (Err (Duplicate "Thai Palace"))
            , test "keeps entry order" <|
                \_ ->
                    Roulette.names three
                        |> Expect.equal [ "Thai Palace", "Il Forno", "Burger Barn" ]
            , test "removes by name" <|
                \_ ->
                    Roulette.remove "Il Forno" three
                        |> Roulette.names
                        |> Expect.equal [ "Thai Palace", "Burger Barn" ]
            , test "removing the last leaves it empty" <|
                \_ ->
                    Roulette.empty
                        |> Roulette.add "Solo"
                        |> Result.withDefault Roulette.empty
                        |> Roulette.remove "Solo"
                        |> Roulette.isEmpty
                        |> Expect.equal True
            , test "counts" <|
                \_ -> Roulette.count three |> Expect.equal 3
            ]
        , describe "storage"
            [ test "encode then decode is identity" <|
                \_ ->
                    Roulette.encode three
                        |> D.decodeValue Roulette.decoder
                        |> Result.map Roulette.names
                        |> Expect.equal (Ok (Roulette.names three))
            , test "an empty list encodes as an empty array, which boot.js turns into no key" <|
                \_ ->
                    Roulette.encode Roulette.empty
                        |> E.encode 0
                        |> Expect.equal "[]"
            , test "anything but an array of strings fails to decode" <|
                \_ ->
                    D.decodeString Roulette.decoder "{\"names\":[\"x\"]}"
                        |> Result.toMaybe
                        |> Expect.equal Nothing
            , test "a stored blank is dropped on the way in" <|
                \_ ->
                    D.decodeString Roulette.decoder "[\"A\", \"  \", \"B\"]"
                        |> Result.map Roulette.names
                        |> Expect.equal (Ok [ "A", "B" ])
            ]
        , describe "the wheel"
            [ test "is every name" <|
                \_ ->
                    Roulette.wheel Nothing three
                        |> Expect.equal (Roulette.names three)
            , test "a veto takes one name out" <|
                \_ ->
                    Roulette.wheel (Just "Il Forno") three
                        |> Expect.equal [ "Thai Palace", "Burger Barn" ]
            , test "a veto over two names leaves the other" <|
                \_ ->
                    Roulette.remove "Burger Barn" three
                        |> Roulette.wheel (Just "Thai Palace")
                        |> Expect.equal [ "Il Forno" ]
            , test "a veto over one name leaves nothing to spin" <|
                \_ ->
                    Roulette.empty
                        |> Roulette.add "Solo"
                        |> Result.withDefault Roulette.empty
                        |> Roulette.wheel (Just "Solo")
                        |> Expect.equal []
            ]
        , describe "start"
            [ test "an empty wheel is nothing to spin" <|
                \_ ->
                    spinOver [] 0 |> Expect.equal Idle
            , test "one name settles at once" <|
                \_ ->
                    spinOver [ "Solo" ] 0 |> Expect.equal (Settled "Solo")
            , test "under calm, the same answer lands at once" <|
                \_ ->
                    Roulette.start { calm = True, wheel = Roulette.names three, index = 1, now = at 1000 }
                        |> Expect.equal (Settled "Il Forno")
            , test "otherwise it runs to an absolute end" <|
                \_ ->
                    case spinOver (Roulette.names three) 2 of
                        Spinning s ->
                            Expect.equal (Time.posixToMillis s.until - Time.posixToMillis s.from) Roulette.duration

                        _ ->
                            Expect.fail "expected a reel"
            , test "an index outside the wheel is brought inside it" <|
                \_ ->
                    spinOver (Roulette.names three) 7
                        |> Roulette.settle (at 100000)
                        |> Expect.equal (Settled "Il Forno")
            ]
        , describe "the reel"
            [ test "shows some name before the end" <|
                \_ ->
                    spinOver (Roulette.names three) 2
                        |> Roulette.showing (at 1400)
                        |> Maybe.map (\n -> List.member n (Roulette.names three))
                        |> Expect.equal (Just True)
            , test "shows the answer at the end" <|
                \_ ->
                    spinOver (Roulette.names three) 2
                        |> Roulette.showing (at (1000 + Roulette.duration))
                        |> Expect.equal (Just "Burger Barn")
            , test "shows the answer after the end, however late" <|
                \_ ->
                    spinOver (Roulette.names three) 0
                        |> Roulette.showing (at 999999)
                        |> Expect.equal (Just "Thai Palace")
            , test "is not on the answer just before the end — it lands, it does not arrive early" <|
                \_ ->
                    spinOver (Roulette.names three) 2
                        |> Roulette.showing (at (1000 + Roulette.duration - 40))
                        |> Expect.notEqual (Just "Burger Barn")
            , test "shows the first frame at the start" <|
                \_ ->
                    spinOver (Roulette.names three) 2
                        |> Roulette.showing (at 1000)
                        |> Maybe.map (\n -> List.member n (Roulette.names three))
                        |> Expect.equal (Just True)
            , test "a settled spin shows its name" <|
                \_ ->
                    Roulette.showing (at 0) (Settled "Il Forno")
                        |> Expect.equal (Just "Il Forno")
            , test "idle shows nothing" <|
                \_ ->
                    Roulette.showing (at 0) Idle |> Expect.equal Nothing
            ]
        , describe "settle"
            [ test "before the end, the reel is left running" <|
                \_ ->
                    let
                        spin =
                            spinOver (Roulette.names three) 1
                    in
                    Roulette.settle (at 2000) spin |> Expect.equal spin
            , test "at the end, it is the answer" <|
                \_ ->
                    spinOver (Roulette.names three) 1
                        |> Roulette.settle (at (1000 + Roulette.duration))
                        |> Expect.equal (Settled "Il Forno")
            , test "settling agrees with the last frame shown" <|
                \_ ->
                    let
                        spin =
                            spinOver (Roulette.names three) 0

                        end =
                            at (1000 + Roulette.duration)
                    in
                    Roulette.settle end spin
                        |> Roulette.showing end
                        |> Expect.equal (Roulette.showing end spin)
            , test "settled and idle are left alone" <|
                \_ ->
                    [ Settled "x", Idle ]
                        |> List.map (Roulette.settle (at 5))
                        |> Expect.equal [ Settled "x", Idle ]
            ]
        ]
