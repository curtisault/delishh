module Roulette exposing
    ( Refusal(..)
    , Roulette
    , Spin(..)
    , add
    , count
    , decoder
    , duration
    , empty
    , encode
    , isEmpty
    , names
    , remove
    , settle
    , showing
    , start
    , wheel
    )

{-| Restaurant Roulette — the list of places, and the spin.
`docs/decisions.md`, ruled 2026-09-28.

**Pure.** No `Html`, no `Cmd`, no ports, the split `Plan` and
`GroceryList` run on. The shell draws the random index and reads the
clock; this decides what is true given both.

**The domain is a restaurant**, never a recipe. Nothing here knows
the archive exists.

Three things this refuses to do:

  - **Weight the wheel.** A name entered twice is refused, ignoring
    case, because two "Thai Palace" is a wheel that lands there twice
    as often while the page says every place is even.
  - **Decide during the reel.** The answer is the index the shell
    drew at the press; the reel is a readout of it, and reading none
    of it loses nothing (DS-01 §10, the reel).
  - **Remember a spin.** Nothing about what came up is kept. A veto is
    a wheel without one name, for one spin, and that name is back in
    the wheel next time.

-}

import Json.Decode as D exposing (Decoder)
import Json.Encode as E
import Time



-- THE LIST


{-| The restaurants, in the order they were entered. Never sorted: it
is the reader's list.
-}
type Roulette
    = Roulette (List String)


empty : Roulette
empty =
    Roulette []


names : Roulette -> List String
names (Roulette list) =
    list


count : Roulette -> Int
count (Roulette list) =
    List.length list


isEmpty : Roulette -> Bool
isEmpty (Roulette list) =
    List.isEmpty list


{-| Why a name was not added. Each reaches the reader as its own
sentence; a field that silently did nothing would look like it kept
something.
-}
type Refusal
    = Blank
    | Duplicate String


{-| Add a name at the end. Trimmed; blank refused; a name already on
the list, ignoring case, refused with the spelling that is there.
-}
add : String -> Roulette -> Result Refusal Roulette
add typed (Roulette list) =
    case String.trim typed of
        "" ->
            Err Blank

        name ->
            case List.filter (\n -> String.toLower n == String.toLower name) list of
                existing :: _ ->
                    Err (Duplicate existing)

                [] ->
                    Ok (Roulette (list ++ [ name ]))


{-| Take a name off, by its exact spelling.
-}
remove : String -> Roulette -> Roulette
remove name (Roulette list) =
    Roulette (List.filter (\n -> n /= name) list)


{-| The names a spin runs over: every one, or every one but the
vetoed. The shell draws its index over this list's length.
-}
wheel : Maybe String -> Roulette -> List String
wheel vetoed (Roulette list) =
    case vetoed of
        Just name ->
            List.filter (\n -> n /= name) list

        Nothing ->
            list



-- THE SPIN


{-| A spin, as the page sees it.

`Spinning` carries the wheel it runs over — a snapshot, so a name
removed mid-reel does not shift the answer — the index it will land
on, and the instants it started and ends. `Settled` is the name that
came up.

-}
type Spin
    = Idle
    | Spinning
        { wheel : List String
        , answer : Int
        , from : Time.Posix
        , until : Time.Posix
        }
    | Settled String


{-| How long a reel runs, in milliseconds.
-}
duration : Int
duration =
    2400


{-| Begin a spin over a wheel, given the index the shell drew, the
instant, and whether the reader asked for calm.

  - an empty wheel is nothing to spin: `Idle`
  - one name, or a reader who asked for calm, is `Settled` at once —
    the same answer a reel would have landed on
  - otherwise the reel runs to an absolute end

An index outside the wheel is brought inside it rather than trusted:
the shell draws over the wheel's length, but a wrong index is a
wrong dinner, not a crash.

-}
start : { calm : Bool, wheel : List String, index : Int, now : Time.Posix } -> Spin
start args =
    case args.wheel of
        [] ->
            Idle

        [ only ] ->
            Settled only

        many ->
            let
                answer =
                    modBy (List.length many) (max 0 args.index)
            in
            if args.calm then
                Settled (nameAt answer many)

            else
                Spinning
                    { wheel = many
                    , answer = answer
                    , from = args.now
                    , until = Time.millisToPosix (Time.posixToMillis args.now + duration)
                    }


{-| The name on the reel at this instant, or the settled name.

A pure function of the clock: elapsed time runs through an ease-out
onto a count of steps around the wheel, arranged so the last step is
the answer and the step before it is not. A tab that was hidden shows
the answer on its first frame back rather than replaying the reel.

-}
showing : Time.Posix -> Spin -> Maybe String
showing now spin =
    case spin of
        Idle ->
            Nothing

        Settled name ->
            Just name

        Spinning s ->
            let
                n =
                    List.length s.wheel

                elapsed =
                    Time.posixToMillis now - Time.posixToMillis s.from

                total =
                    steps n

                step =
                    if elapsed >= duration then
                        total

                    else if elapsed <= 0 then
                        0

                    else
                        floor (easeOut (toFloat elapsed / toFloat duration) * toFloat total)
            in
            Just (nameAt (modBy n (s.answer - total + step)) s.wheel)


{-| The tick: a reel past its end is settled. Anything else is left
as it was.
-}
settle : Time.Posix -> Spin -> Spin
settle now spin =
    case spin of
        Spinning s ->
            if Time.posixToMillis now >= Time.posixToMillis s.until then
                Settled (nameAt s.answer s.wheel)

            else
                spin

        _ ->
            spin


{-| How many names the reel shows end to end: a few turns of the
wheel, and never so few that the reel is a flicker.
-}
steps : Int -> Int
steps n =
    max 16 (4 * n)


{-| Fast, then slower: a quadratic ease-out.

Quadratic, not cubic, because the reel is discrete. A cubic spends
its last quarter on less than one step, which on screen is a 650 ms
hold on the name before the answer and then a cut; a quadratic holds
it for about 350 ms, which reads as the wheel clicking into place
rather than sticking.

-}
easeOut : Float -> Float
easeOut p =
    1 - (1 - p) ^ 2


nameAt : Int -> List String -> String
nameAt index list =
    list
        |> List.drop index
        |> List.head
        |> Maybe.withDefault ""



-- STORAGE


{-| The list as it is stored: an array of names. Nothing else — no
spin, no history — because nothing else is the reader's.
-}
encode : Roulette -> E.Value
encode (Roulette list) =
    E.list E.string list


{-| Anything that is not an array of strings fails whole, and the
shell discards it (DS-01 §12: state that cannot be read back is
discarded and the reader starts empty).
-}
decoder : Decoder Roulette
decoder =
    D.list D.string
        |> D.map (List.filter (\n -> String.trim n /= ""))
        |> D.map Roulette
