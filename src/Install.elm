module Install exposing (Offer(..), fromString)

{-| What this browser can do about putting the archive on a home screen
(`docs/decisions.md`).

Read off the browser's own capabilities, never its name: `boot.js`
reports what it found, and there is no user-agent sniffing anywhere in
the product. Three answers, because there are three different things a
reader can be offered:

  - `Prompt` — the browser handed over its install dialog
    (`beforeinstallprompt`: Chrome, Edge, Android). The press opens it.
  - `ShareSheet` — the browser can add the site to a home screen but
    has no API for it (Safari on iPhone and iPad, recognised by
    `navigator.standalone`, which only those expose). The press says
    where the browser keeps the command.
  - `NoOffer` — already installed, or a browser that cannot install.
    **No press at all**: a control that does nothing is worse than none.

-}


type Offer
    = NoOffer
    | Prompt
    | ShareSheet


{-| boot.js's word for the offer. Anything unrecognised is no offer:
a press is only drawn for something that will actually happen.
-}
fromString : String -> Offer
fromString word =
    case word of
        "prompt" ->
            Prompt

        "share" ->
            ShareSheet

        _ ->
            NoOffer
