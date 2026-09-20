module Cook exposing
    ( Timer
    , Wake(..)
    , clock
    , expired
    , remaining
    , start
    , wakeFromFlag
    , wakeNotice
    , wakeIsHonest
    )

{-| Cook mode's two pieces of live state — DS-01 §08, §10.

**The timer is the only sanctioned motion in the product.** §10 opens
the motion register at zero and keeps it there: nothing loops, drifts,
breathes or pulses. A running duration is the one exception, and it
earns it by being *functional readout* — the number IS the
information, so it is allowed to change. Tabular numerals, and it must
not shift layout by a pixel as it counts.

**It counts to an absolute end time, not down a decrementing
counter.** A counter that ticks once a second is wrong the moment the
browser throttles a background tab, and a kitchen timer that silently
loses four minutes is worse than no timer at all.

**It does not make a sound**, and that is a design position rather
than a missing feature. The whole standard says the colour is the
tell, not the clock (§05) — so the timer says when to *start looking*,
and hands you back the step's own doneness cue when it expires. An
alarm would be the archive claiming to know something it does not.

-}

import Time



-- THE TIMER


{-| A running duration: which step owns it, and when it ends.

One at a time, deliberately. You are cooking one step; two competing
countdowns is a thing to manage rather than a thing that helps.

-}
type alias Timer =
    { step : Int
    , endsAt : Time.Posix
    }


{-| Start a timer of `seconds` for a step, given the current instant.
-}
start : Int -> Int -> Time.Posix -> Timer
start step seconds now =
    { step = step
    , endsAt = Time.millisToPosix (Time.posixToMillis now + (seconds * 1000))
    }


{-| Seconds left, never below zero. Derived from the clock rather than
accumulated, so a throttled tab resumes correct instead of behind.
-}
remaining : Time.Posix -> Timer -> Int
remaining now timer =
    max 0 ((Time.posixToMillis timer.endsAt - Time.posixToMillis now) // 1000)


expired : Time.Posix -> Timer -> Bool
expired now timer =
    remaining now timer == 0


{-| `M:SS`, and **the width never changes**: minutes are not padded
but seconds always are, so the only character that can appear or
vanish is a tens-of-minutes digit at the far left. A timer that
reflows the step it sits in would be motion the register never
granted (§10).
-}
clock : Int -> String
clock seconds =
    String.fromInt (seconds // 60)
        ++ ":"
        ++ String.padLeft 2 '0' (String.fromInt (modBy 60 seconds))



-- THE WAKE LOCK


{-| Whether the screen is actually being held awake.

**Every case here is reported honestly**, which is the entire point.
DS-01 §08 says hold the screen awake and *say so on screen*; a badge
that reads "screen held" on a browser with no wake lock is the system
lying about its status, and the reader finds out when the screen goes
black with their hands covered in flour.

-}
type Wake
    = -- cook mode is not open, or the lock was given up
      Off
      -- genuinely held
    | Held
      -- this browser has no wake lock at all
    | Unsupported
      -- the browser has one and would not give it (no gesture,
      -- battery saver, an insecure origin)
    | Refused


wakeFromFlag : String -> Wake
wakeFromFlag flag =
    case flag of
        "held" ->
            Held

        "unsupported" ->
            Unsupported

        "refused" ->
            Refused

        _ ->
            Off


{-| What the badge says. Never "screen held" unless it is.
-}
wakeNotice : Wake -> String
wakeNotice wake =
    case wake of
        Held ->
            "Screen held awake"

        Unsupported ->
            "Screen will sleep — this browser has no wake lock"

        Refused ->
            "Screen will sleep — the browser refused the wake lock"

        Off ->
            "Screen will sleep"


{-| Whether the notice is good news. The view styles the two
differently, and **carries the word either way** — a badge that
signalled only by colour would fail the one rule that has no
exceptions (§04).
-}
wakeIsHonest : Wake -> Bool
wakeIsHonest wake =
    wake == Held
