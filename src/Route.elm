module Route exposing (Route(..), fromUrl, parse, queryParam, title, toPath, withQuery)

{-| Client routes. Pure: no Cmd, no ports — fully unit-testable
(`tests/RouteTests.elm`).

Adding a route here means adding a line to `public/_redirects`, by
name. That friction is deliberate: a wildcard rule makes Cloudflare
Pages answer every missing hashed asset with index.html as 200
text/html, and `public/_headers` then pins that mistake for a year.

`Recipe` and `Cook` are the routes that cannot be named — its slug is content,
not a route, and adding a recipe must not mean editing a redirect
file. It takes a wildcard SCOPED to `/recipe/*`, which is safe for the
same reason the bare `/*` is not: hashed assets live under `/assets/`
and never under `/recipe/`, so nothing but a recipe address can fall
into it.

-}

import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), Parser, oneOf, s, string, top)


type Route
    = -- the front page
      Home
      -- what this is and who made it
    | About
      -- DS-01, the aesthetic contract
    | DesignStandard
      -- one recipe, by its slug — the filename under content/recipes
    | Recipe String
      -- the same recipe at arm's length, with a pan on the heat
    | Cook String


{-| The address of a page. Lowercase, hyphenated.
-}
toPath : Route -> String
toPath route =
    case route of
        Home ->
            "/"

        About ->
            "/about"

        DesignStandard ->
            "/design-standard"

        Recipe slug ->
            "/recipe/" ++ slug

        Cook slug ->
            "/recipe/" ++ slug ++ "/cook"


{-| The document title. `Browser.application` owns the title, so
`index.html`'s `<title>` is only what shows before Elm boots — the
home page's title matches it so the swap is invisible.
-}
title : Route -> String
title route =
    case route of
        Home ->
            "DELISHH"

        About ->
            "DELISHH — ABOUT"

        DesignStandard ->
            "DELISHH — DESIGN STANDARD"

        Recipe slug ->
            -- The slug, not the recipe's title: the shell titles the
            -- document before the fetch resolves, and a tab that reads
            -- "Loading" while you hunt through twenty of them is worse
            -- than one that reads the address you asked for.
            "DELISHH — " ++ String.toUpper (String.replace "-" " " slug)

        Cook slug ->
            "DELISHH — COOK — " ++ String.toUpper (String.replace "-" " " slug)


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home top
        , Parser.map About (s "about")
        , Parser.map DesignStandard (s "design-standard")
        , Parser.map Cook (s "recipe" </> string </> s "cook")
        , Parser.map Recipe (s "recipe" </> string)
        ]


{-| Read a route off a URL, or `Nothing` if the path is not one of
ours.

The shell needs the honest answer, not the fallback: a same-origin
link that is _not_ a route is a static asset (a PDF under
`/downloads`, say), and `Browser.application` intercepts its click
like any other. Told `Nothing`, the shell hands the click back to the
browser instead of pushing a URL that would silently re-render the
home page.

-}
parse : Url -> Maybe Route
parse url =
    Parser.parse parser url


{-| Read a route off a URL. Unknown paths fall back to the front page
rather than erroring — the right behaviour for an address typed or
shared by hand. Use `parse` when the difference matters.
-}
fromUrl : Url -> Route
fromUrl url =
    parse url
        |> Maybe.withDefault Home


{-| One query parameter, decoded — for any page whose state lives in
the address bar rather than in this browser.

Hand-rolled rather than `Url.Parser.Query`, which only reads a query
as part of parsing a whole URL: the shell needs the parameters off a
URL it has already routed. The last `=` is not special (values are
rejoined), and a value that fails to decode reads as empty rather
than absent.

-}
queryParam : String -> Url -> Maybe String
queryParam key url =
    url.query
        |> Maybe.map (String.split "&")
        |> Maybe.withDefault []
        |> List.filterMap (matchParam key)
        |> List.head


matchParam : String -> String -> Maybe String
matchParam key raw =
    case String.split "=" raw of
        k :: rest ->
            if k == key then
                Just (Maybe.withDefault "" (Url.percentDecode (String.join "=" rest)))

            else
                Nothing

        [] ->
            Nothing


{-| A route's address carrying state. Empty values are dropped, so a
half-filled form produces a clean URL rather than `?a=&b=`.
-}
withQuery : Route -> List ( String, String ) -> String
withQuery route params =
    case List.filter (\( _, v ) -> v /= "") params of
        [] ->
            toPath route

        kept ->
            toPath route
                ++ "?"
                ++ String.join "&"
                    (List.map (\( k, v ) -> k ++ "=" ++ Url.percentEncode v) kept)
