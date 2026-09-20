port module Main exposing (main)

{-| The TEA shell: URL wiring, the site nav, the theme control, page
dispatch — and the viewport.

**The shell owns the viewport.** `Browser.application` intercepts
every internal link click, including the contents rail's `#anchor`
jumps, so the browser's own scroll-to-fragment never happens; this
module re-implements it with `Browser.Dom`. `Viewport.actionFor`
decides *whether* to move; `jumpTo` decides *where*.

**Theme.** The shell owns the three-state preference (System / Light
/ Dark). The palette itself is pure CSS — `theme.css` reads
`prefers-color-scheme` and the `data-theme` attribute on `<html>`.
Elm owns only `<body>`, so applying the attribute and persisting the
choice is boot.js's job, reached through the `saveTheme` port;
"system" clears both, which hands control back to the media query and
to live OS changes.

**When a page's state belongs in the URL** (a form, a filter, a
setting worth sharing), mirror it with `Nav.replaceUrl` so the address
bar *is* the state and nothing has to be stored. Doing that means
`UrlChanged` must ask whether the *route* changed rather than
treating every URL change as a navigation: a replaced query is this
shell hearing its own echo, and must not scroll the page to the top
or re-read the form out from under the reader. The hooks are here and
wired — see `arrivalMirrors`, which currently answers False for every
route because no page mirrors yet.

-}

import Browser
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Doc
import Html exposing (Html, a, button, div, nav, span, text)
import Html.Attributes exposing (attribute, class, classList, href, id, type_)
import Html.Events exposing (onClick)
import Page.About
import Page.DesignStandard
import Page.Home
import Route exposing (Route)
import Task
import Url exposing (Url)
import Viewport


port saveTheme : String -> Cmd msg


{-| Which section the reader is currently inside, reported by boot.js.

This is a port because `elm/browser` has no scroll subscription — it
offers resize, visibility, keys, clicks and animation frames, and
nothing for the one event a contents rail needs. The alternative was
polling `Browser.Dom.getViewport` every animation frame to answer a
question that changes a few times a minute.

-}
port sectionSeen : (String -> msg) -> Sub msg


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- THEME


type Theme
    = System
    | Light
    | Dark


themeToString : Theme -> String
themeToString theme =
    case theme of
        System ->
            "system"

        Light ->
            "light"

        Dark ->
            "dark"


themeFromFlag : Maybe String -> Theme
themeFromFlag stored =
    case stored of
        Just "light" ->
            Light

        Just "dark" ->
            Dark

        _ ->
            System


themeLabel : Theme -> String
themeLabel theme =
    case theme of
        System ->
            "System"

        Light ->
            "Light"

        Dark ->
            "Dark"



-- MODEL


type alias Flags =
    { theme : Maybe String }


type alias Model =
    { key : Nav.Key
    , route : Route
    , theme : Theme

    -- whether the narrow layout's menu panel is open. Closed by any
    -- real navigation, because tapping a route is the last thing a
    -- reader wants to do inside it
    , menuOpen : Bool

    -- what the reader has typed into the rail's search box. Not in the
    -- URL: a search is a way of looking at a document rather than a
    -- part of it, and it should not survive the back button
    , query : String

    -- the section under the reader's eye, marked in the contents rail.
    -- Reported by boot.js through `sectionSeen`; cleared on navigation
    -- so a stale anchor cannot mark the wrong row on the next page
    , active : Maybe String

    -- the section the reader is parked on, so mirroring a form into
    -- the URL cannot silently drop their `#anchor`
    , fragment : Maybe String

    -- set whenever this shell writes the URL itself. The `UrlChanged`
    -- that comes back is an echo, not a navigation, and must not move
    -- the reader — see Viewport
    , mirroring : Bool
    }


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , route = Route.fromUrl url
      , theme = themeFromFlag flags.theme
      , fragment = url.fragment
      , mirroring = False
      , active = Nothing
      , query = ""
      , menuOpen = False
      }
      -- a cold load with a fragment (a shared deep link) still owes a
      -- jump — the browser cannot do it, because Elm renders after load
    , case url.fragment of
        Just anchor ->
            jumpTo anchor

        Nothing ->
            Cmd.none
    )



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | SetTheme Theme
    | SectionSeen String
    | QueryChanged String
    | ToggleMenu
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChanged url ->
            let
                route =
                    Route.fromUrl url

                -- a replaced query on the page you are already reading
                -- is not a navigation: it is this shell mirroring a
                -- form into the address bar
                arrived =
                    route /= model.route

                updated =
                    { model
                        | route = route
                        , fragment = url.fragment

                        -- any real navigation ends the search: the
                        -- reader has chosen where to go, and leaving
                        -- the query set would render the page they
                        -- arrived at as a result list too — with its
                        -- sections gone and the anchor they followed
                        -- pointing at nothing
                        , query =
                            if model.mirroring then
                                model.query

                            else
                                ""

                        -- and the menu shuts behind them
                        , menuOpen = model.mirroring && model.menuOpen
                        , active =
                            if arrived then
                                Nothing

                            else
                                model.active
                    }
            in
            ( -- an arrival on a mirroring route writes the URL back in
              -- the same batch, so the *next* UrlChanged is this
              -- shell's echo; anything else clears the flag
              { updated | mirroring = arrived && arrivalMirrors route }
            , case
                Viewport.actionFor
                    { mirroring = model.mirroring
                    , arrived = arrived
                    , fragment = url.fragment
                    }
              of
                Viewport.Stay ->
                    Cmd.none

                Viewport.ToTop ->
                    Task.perform (\_ -> NoOp) (Dom.setViewport 0 0)

                Viewport.ToAnchor anchor ->
                    jumpTo anchor
            )

        LinkClicked (Browser.Internal url) ->
            case Route.parse url of
                Just _ ->
                    -- push only; the model's route is set by UrlChanged coming back
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Nothing ->
                    -- Same origin but not a route: a static asset under
                    -- public/. `Browser.application` intercepts every
                    -- same-origin click, so pushing here would swap the
                    -- address bar and re-render the home page while the
                    -- file never loads. Hand it back to the browser.
                    ( model, Nav.load (Url.toString url) )

        LinkClicked (Browser.External href_) ->
            ( model, Nav.load href_ )

        SetTheme theme ->
            ( { model | theme = theme }, saveTheme (themeToString theme) )

        QueryChanged query ->
            ( { model | query = query }, Cmd.none )

        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        SectionSeen anchor ->
            ( { model
                | active =
                    if anchor == "" then
                        Nothing

                    else
                        Just anchor
              }
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )



-- SUBSCRIPTIONS


{-| The contents rail's active row, and nothing else.

Add a subscription here only when something on screen genuinely
changes on its own. A timer on a document that does not change is a
battery cost with no reader.

-}
subscriptions : Model -> Sub Msg
subscriptions _ =
    sectionSeen SectionSeen



-- URL-BACKED STATE


{-| Whether arriving on this route writes the URL back, and therefore
whether the `UrlChanged` that follows is this shell's own echo.

No route mirrors yet. When one does — a form, a filter, a setting
worth sharing — name it here and add its `Nav.replaceUrl` alongside
the viewport command in `UrlChanged`. Leaving this as `False` for a
route that *does* mirror makes its every keystroke scroll the reader
to the top of the page.

-}
arrivalMirrors : Route -> Bool
arrivalMirrors _ =
    False


{-| Scroll the window to an anchor. `Dom.getElement` reports
scene-relative coordinates, so the element's y IS the viewport offset —
less whatever the sticky chrome covers, or the section head lands
underneath it. A missing anchor resolves to a no-op, not a crash.
-}
jumpTo : String -> Cmd Msg
jumpTo anchor =
    Task.map2 (\info covered -> info.element.y - covered - jumpGap)
        (Dom.getElement anchor)
        stickyChromeHeight
        |> Task.andThen (Dom.setViewport 0)
        |> Task.attempt (\_ -> NoOp)


{-| Air between the sticky chrome and the section head it reveals.
-}
jumpGap : Float
jumpGap =
    8


{-| How much of the viewport top the sticky chrome covers right now:
the site nav always, plus the contents rail when it is worn as the
search strip. Measured rather than hard-coded against the breakpoint,
so this number cannot drift from the CSS that produces it.
-}
stickyChromeHeight : Task.Task x Float
stickyChromeHeight =
    Task.map2 (+) (coveredHeight "site-nav") stripHeight


{-| An element's height, or nothing covered if it isn't on the page.
-}
coveredHeight : String -> Task.Task x Float
coveredHeight domId =
    Dom.getElement domId
        |> Task.map (.element >> .height)
        |> Task.onError (\_ -> Task.succeed 0)


{-| The rail overlays the text only in its narrow form (≤60rem),
where it spans the viewport; as the desktop rail it holds the left
margin and covers nothing. Its width tells the two apart, which keeps
the breakpoint itself in the stylesheet where it belongs.
-}
stripHeight : Task.Task x Float
stripHeight =
    Dom.getElement "doc-toc"
        |> Task.map
            (\info ->
                if info.element.width > info.viewport.width * 0.9 then
                    info.element.height

                else
                    0
            )
        |> Task.onError (\_ -> Task.succeed 0)



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = Route.title model.route
    , body =
        [ siteNav model
        , case model.route of
            Route.Home ->
                Page.Home.view (chrome model)

            Route.About ->
                Page.About.view (chrome model)

            Route.DesignStandard ->
                Page.DesignStandard.view (chrome model)
        ]
    }


chrome : Model -> Doc.Chrome Msg
chrome model =
    { active = model.active
    , query = model.query
    , onQuery = QueryChanged
    }


siteNav : Model -> Html Msg
siteNav model =
    nav
        [ id "site-nav"
        , class "site-nav"
        , classList [ ( "menu-open", model.menuOpen ) ]
        ]
        [ span [ class "brand u" ] [ text "delishh" ]
        , menuToggle model.menuOpen
        , div [ id "nav-menu", class "nav-menu" ]
            [ div [ class "nav-links u" ]
                [ navLink model.route Route.Home "Home"
                , navLink model.route Route.DesignStandard "Standard"
                , navLink model.route Route.About "About"
                ]
            , themeControl model.theme
            ]
        ]


{-| The narrow layout's way in. Hidden entirely above 60rem, where the
menu is simply the bar.

The mark is three rules, the same vocabulary the rest of the document
is drawn in, and it does not change between states — the word beside
it does. Nothing morphs and nothing slides: the panel is either there
or it is not.

-}
menuToggle : Bool -> Html Msg
menuToggle open =
    button
        [ type_ "button"
        , class "nav-toggle u"
        , attribute "aria-expanded"
            (if open then
                "true"

             else
                "false"
            )
        , attribute "aria-controls" "nav-menu"
        , onClick ToggleMenu
        ]
        [ span [ class "nav-toggle-mark", attribute "aria-hidden" "true" ] []
        , text
            (if open then
                "Close"

             else
                "Menu"
            )
        ]


navLink : Route -> Route -> String -> Html msg
navLink current target label =
    a
        [ href (Route.toPath target)
        , classList [ ( "active", current == target ) ]
        ]
        [ text label ]


themeControl : Theme -> Html Msg
themeControl current =
    div
        [ class "theme-control"
        , attribute "role" "group"
        , attribute "aria-label" "Theme"
        ]
        (List.map (themeButton current) [ System, Light, Dark ])


themeButton : Theme -> Theme -> Html Msg
themeButton current theme =
    button
        [ type_ "button"
        , class "theme-btn u"
        , classList [ ( "active", theme == current ) ]
        , attribute "aria-pressed"
            (if theme == current then
                "true"

             else
                "false"
            )
        , onClick (SetTheme theme)
        ]
        [ text (themeLabel theme) ]
