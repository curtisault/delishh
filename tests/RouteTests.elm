module RouteTests exposing (suite)

import Expect
import Route exposing (Route(..))
import Test exposing (Test, describe, test)
import Url


urlAt : String -> Url.Url
urlAt path =
    { protocol = Url.Https
    , host = "example.test"
    , port_ = Nothing
    , path = path
    , query = Nothing
    , fragment = Nothing
    }


urlWith : String -> String -> Url.Url
urlWith path query =
    { protocol = Url.Https
    , host = "example.test"
    , port_ = Nothing
    , path = path
    , query = Just query
    , fragment = Nothing
    }


suite : Test
suite =
    describe "Route"
        [ describe "fromUrl"
            [ test "root is the front page" <|
                \_ -> Route.fromUrl (urlAt "/") |> Expect.equal Home
            , test "/about is the colophon" <|
                \_ -> Route.fromUrl (urlAt "/about") |> Expect.equal About
            , test "a route still parses with a query attached" <|
                \_ -> Route.fromUrl (urlWith "/about" "ref=card") |> Expect.equal About
            , test "unknown paths fall back to the front page" <|
                \_ -> Route.fromUrl (urlAt "/no-such-page") |> Expect.equal Home
            ]
        , describe "parse tells routes from static assets"
            -- the shell branches on this: a same-origin link that is not a
            -- route must be handed back to the browser, or Browser.application
            -- swallows the click and the file never downloads
            [ test "a downloadable asset is not a route" <|
                \_ -> Route.parse (urlAt "/downloads/handout.pdf") |> Expect.equal Nothing
            , test "fromUrl still falls back for that same path" <|
                \_ -> Route.fromUrl (urlAt "/downloads/handout.pdf") |> Expect.equal Home
            , test "real routes still parse" <|
                \_ -> Route.parse (urlAt "/about") |> Expect.equal (Just About)
            ]
        , describe "toPath round-trips through fromUrl"
            (List.map
                (\route ->
                    test (Route.title route) <|
                        \_ ->
                            Route.fromUrl (urlAt (Route.toPath route))
                                |> Expect.equal route
                )
                -- every Route variant belongs here; the compiler cannot
                -- check a hand-written list, so adding a route means
                -- adding it below as well, AND adding a line to
                -- public/_redirects
                [ Home
                , About
                , DesignStandard
                , ShoppingList
                , Plan
                , Recipe "salted-caramel"
                , Cook "salted-caramel"
                ]
            )
        , describe "cook mode is its own address"
            [ test "reads the slug off the path" <|
                \_ ->
                    Route.fromUrl (urlAt "/recipe/salted-caramel/cook")
                        |> Expect.equal (Cook "salted-caramel")
            , test "the recipe and its cook view are different routes" <|
                \_ ->
                    -- `s "recipe" </> string` must not swallow the
                    -- third segment, or /cook would render the
                    -- document with "salted-caramel/cook" as a slug.
                    Route.fromUrl (urlAt "/recipe/salted-caramel")
                        |> Expect.notEqual (Cook "salted-caramel")
            , test "the scale rides in the query, not the path" <|
                \_ ->
                    Route.withQuery (Cook "salted-caramel") [ ( "scale", "1.5" ) ]
                        |> Expect.equal "/recipe/salted-caramel/cook?scale=1.5"
            , test "an unscaled cook link carries no query at all" <|
                \_ ->
                    Route.withQuery (Cook "salted-caramel") [ ( "scale", "" ) ]
                        |> Expect.equal "/recipe/salted-caramel/cook"
            ]
        , describe "a recipe route carries its slug"
            [ test "reads the slug off the path" <|
                \_ ->
                    Route.fromUrl (urlAt "/recipe/salted-caramel")
                        |> Expect.equal (Recipe "salted-caramel")
            , test "a bare /recipe is not a route" <|
                \_ ->
                    -- It has no slug to fetch, so it must fall back
                    -- rather than request /content/recipes/.json
                    Route.parse (urlAt "/recipe")
                        |> Expect.equal Nothing
            , test "a deeper path under /recipe is not a route either" <|
                \_ ->
                    Route.parse (urlAt "/recipe/a/b")
                        |> Expect.equal Nothing
            , test "the title is the slug, not a loading state" <|
                \_ ->
                    -- The shell titles the document before the fetch
                    -- resolves; a tab reading "Loading" while you hunt
                    -- through twenty of them is worse than one reading
                    -- the address you asked for.
                    Route.title (Recipe "salted-caramel")
                        |> Expect.equal "DELISHH — SALTED CARAMEL"
            ]
        , describe "queryParam reads a page's state off a URL"
            [ test "finds a parameter" <|
                \_ ->
                    Route.queryParam "sort" (urlWith "/about" "q=salt&sort=new")
                        |> Expect.equal (Just "new")
            , test "decodes the value" <|
                \_ ->
                    Route.queryParam "q" (urlWith "/about" "q=sea%20salt")
                        |> Expect.equal (Just "sea salt")
            , test "an absent parameter is Nothing, not empty" <|
                -- worth keeping distinct: absent keeps whatever the
                -- form already holds, empty clears it
                \_ ->
                    Route.queryParam "q" (urlWith "/about" "sort=new")
                        |> Expect.equal Nothing
            , test "no query at all is Nothing" <|
                \_ -> Route.queryParam "q" (urlAt "/about") |> Expect.equal Nothing
            , test "an empty value reads as empty" <|
                \_ ->
                    Route.queryParam "q" (urlWith "/about" "q=")
                        |> Expect.equal (Just "")
            , test "a key that only prefixes another is not a match" <|
                \_ ->
                    Route.queryParam "q" (urlWith "/about" "query=yes")
                        |> Expect.equal Nothing
            ]
        , describe "withQuery builds the shareable address"
            [ test "carries the state" <|
                \_ ->
                    Route.withQuery About [ ( "q", "sea salt" ), ( "sort", "new" ) ]
                        |> Expect.equal "/about?q=sea%20salt&sort=new"
            , test "drops empty values rather than writing ?q=" <|
                \_ ->
                    Route.withQuery About [ ( "q", "" ), ( "sort", "new" ) ]
                        |> Expect.equal "/about?sort=new"
            , test "with nothing to carry it is just the path" <|
                \_ -> Route.withQuery About [ ( "q", "" ) ] |> Expect.equal "/about"
            , test "round-trips back through queryParam" <|
                \_ ->
                    Route.withQuery About [ ( "q", "sea salt" ) ]
                        |> (++) "https://example.test"
                        |> Url.fromString
                        |> Maybe.andThen (Route.queryParam "q")
                        |> Expect.equal (Just "sea salt")
            ]
        ]
