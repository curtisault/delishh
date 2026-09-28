module Reach exposing (Failure(..), fromHttp)

{-| Why a fetch from the archive failed, in the terms a reader can act on.

The pages used to say one thing for every failure — _nothing in the
archive is filed under this_ — which was true of a mistyped address and
false of a kitchen with no signal. That is the page inferring the
reason on the reader's behalf, and a sentence that is sometimes false
is one the reader learns to ignore. So the reason is read off the
error, and each reason gets its own sentence.

The service worker (`src/sw.js`) is what makes `Unkept` knowable: with
no network and no kept copy it answers a `/content/*` request with a
`503`, and nothing else on a static host does. Without a worker the
same situation arrives as a plain network failure, and reads as
`Unreachable`.

-}

import Http


type Failure
    = Missing -- the archive answered: no such file
    | Unkept -- no connection, and no copy kept on this device
    | Unreachable -- no connection, and no worker to ask
    | Broken -- the archive answered, with something that is not a recipe


fromHttp : Http.Error -> Failure
fromHttp error =
    case error of
        Http.BadStatus 404 ->
            Missing

        Http.BadStatus 503 ->
            Unkept

        Http.NetworkError ->
            Unreachable

        Http.Timeout ->
            Unreachable

        _ ->
            Broken
