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
import Cook
import Doc
import GroceryList
import Html exposing (Html, a, button, div, nav, span, text)
import Html.Attributes exposing (attribute, class, classList, href, id, type_)
import Html.Events exposing (onClick)
import Html.Keyed as Keyed
import Http
import Install
import Liner
import Json.Decode as D
import Json.Encode as E
import Page.About
import Page.Cook
import Page.DesignStandard
import Page.GroceryList
import Page.Plan
import Page.RestaurantRoulette
import Random
import Roulette exposing (Roulette)
import Page.Recipe
import Page.Shelf
import Plan exposing (Plan)
import Print
import Reach
import Recipe exposing (Recipe)
import Route exposing (Route)
import Scale
import Set exposing (Set)
import Shelf
import Task
import Time
import Url exposing (Url)
import Viewport


port saveTheme : String -> Cmd msg


{-| Write the shopping list back to this browser.

The second thing this product stores, and the only one with any
shape to it — the theme is a word. Out as an encoded value rather
than a string so the schema lives in `GroceryList.encode` beside the
decoder that has to agree with it; boot.js only stringifies.

It fails the way the theme fails: silently, into a list that holds
for the session. A shop is not the moment to learn that storage is
full.

-}
port saveList : E.Value -> Cmd msg


{-| Write the meal plan back to this browser — the third thing stored
(DS-01 §12), under its own key. The same shape of port as `saveList`,
for the same reason: the schema lives in `Plan.encode`, and boot.js
only stringifies. An empty week clears the key.
-}
port savePlan : E.Value -> Cmd msg


{-| Write the restaurant list back to this browser — the fourth thing
stored (DS-01 §12, amended 2026-09-28), under its own key. The same
shape as `savePlan`: the schema lives in `Roulette.encode`, boot.js
only stringifies, and an empty list clears the key.

`readRestaurants` is the caller the compiler can see. Elm drops an
unused port, and boot.js subscribing to one that is not there throws
at boot.

-}
port saveRestaurants : E.Value -> Cmd msg


{-| The shared picture, out: `{ do: "draw", gen, rows }` to draw the
week, `{ do: "share" }` or `{ do: "copy" }` to send what was drawn,
`{ do: "forget" }` to release it. One port for four verbs because all
four act on the one blob boot.js holds, and a port per verb would be
four places to keep in agreement about which blob that is.

boot.js draws, because a canvas has no Elm binding. It draws from
`Plan.toShare` alone — words and where they came from — so the
drawing never learns the plan's shape.
-}
port sharePlan : E.Value -> Cmd msg


{-| The picture, back: `{ gen, url, canShare, canCopy }` or
`{ gen, failed: true }`. `gen` is the draw it answers, so a picture
of a week that changed while it was drawing is dropped, not shown.
-}
port planPicture : (D.Value -> msg) -> Sub msg


{-| What a share or a copy actually did: shared, copied, refused,
unsupported, failed. Reported, never assumed (DS-01 §08's wake badge
rule).
-}
port planShared : (String -> msg) -> Sub msg


{-| Which section the reader is currently inside, reported by boot.js.

This is a port because `elm/browser` has no scroll subscription — it
offers resize, visibility, keys, clicks and animation frames, and
nothing for the one event a contents rail needs. The alternative was
polling `Browser.Dom.getViewport` every animation frame to answer a
question that changes a few times a minute.

-}
port sectionSeen : (String -> msg) -> Sub msg


{-| Ask the browser to hold the screen awake, or give the lock back.

Out through a port because `navigator.wakeLock` has no Elm binding,
and back through `wakeLockChanged` because **the answer matters**.
DS-01 §08 says hold the screen awake and say so on screen; a badge
that claims "held" on a browser that refused is the system lying
about its status, and the reader finds out when the screen goes black
with their hands covered in flour. boot.js reports what actually
happened, including the re-acquisition the spec forces after the tab
is hidden.

-}
port setWakeLock : Bool -> Cmd msg


port wakeLockChanged : (String -> msg) -> Sub msg


{-| The home-screen install (`docs/decisions.md`). `boot.js` holds
the browser's deferred install event and says what it can offer —
`prompt`, `share`, or `none` — whenever that changes: the event
arrives after load, and an install or a dismissal spends it.
`installApp` asks it to open the browser's dialog, from inside the
press, because the dialog is refused outside one.
-}
port installApp : () -> Cmd msg


port installOffered : (String -> msg) -> Sub msg


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
    { theme : Maybe String

    -- the date a printed sheet says it was pulled (DS-01 §09)
    , today : String

    -- the shopping list as it was stored, still a string. Decoded in
    -- `init`, where anything that will not decode becomes an empty
    -- list rather than a shell that does not boot
    , list : Maybe String

    -- the meal plan as it was stored, still a string. The same rule:
    -- what will not decode becomes an empty week
    , plan : Maybe String

    -- the restaurant list as it was stored, still a string. The same
    -- rule: what will not decode becomes an empty list
    , restaurants : Maybe String

    -- whether the reader asked for calm (`prefers-reduced-motion`),
    -- read once at boot. The reel is the one thing that consults it:
    -- under calm a spin settles at once, on the same answer
    , calm : Bool

    -- what this browser offers for a home-screen install at boot:
    -- "share" (Safari on iPhone and iPad) or "none". A prompt arrives
    -- later, on the installOffered port, if at all
    , install : String
    }


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

    -- the recipe being read, if the route is one. Keyed by nothing:
    -- arriving at a different recipe replaces it outright, because a
    -- stale document under a new address is the one thing worse than
    -- a spinner
    , recipe : Fetch Recipe

    -- the scale the reader set. Deliberately NOT in the URL: it is
    -- reset by any navigation, because a factor that survived from
    -- the last recipe would silently rescale this one. Mirroring it
    -- would mean `arrivalMirrors` and the echo handling that goes
    -- with it — worth doing when a shared scaled link is wanted,
    -- not before
    , factor : Scale.Factor

    -- which of the four print forms the reader has chosen, and
    -- whether the supplemental prep card rides along. Both are
    -- reset by navigation for the same reason the scale is: a form
    -- chosen for one recipe is not a preference about the next
    , form : Print.Form
    , prepCard : Bool

    -- where this document lives, for the printed footer's short URL.
    -- A sheet found in a drawer in three years should be able to say
    -- what it is and how out of date it is
    , origin : String
    , today : String

    -- the shelf: the index, what the reader has narrowed to, and
    -- which path tile is open. Filters are NOT in the URL — see the
    -- note on `arrivalMirrors`
    , index : Fetch Shelf.Index
    , filters : Shelf.Filters
    , openPath : Maybe Shelf.Path

    -- cook mode. `done` and `timer` are reset by navigation like
    -- every other page state; the SCALE is not held here at all — it
    -- rides in the URL, so entering cook mode cannot silently change
    -- the quantities (DS-01 §08)
    -- what to buy. The one piece of page state navigation does NOT
    -- reset, because it is not page state: it is the reader's, it
    -- outlives the tab, and a list that emptied itself when you
    -- opened the next recipe would be worse than no list
    , list : GroceryList.Model

    -- whether CLEAR THE LIST has been armed by a first press. A list
    -- is rebuilt by walking back through every recipe that made it,
    -- there is no undo, and the surface it lives on is read
    -- one-handed in a shop — so the second press is the confirmation
    , clearArmed : Bool

    -- the week. Like the list, it is the reader's rather than the
    -- page's, and no navigation resets it
    , plan : Plan

    -- the plan page's hand: the day a meal was lifted from, the day
    -- whose entry field is open and what is typed in it, and whether
    -- CLEAR THE WEEK is armed. Page state, so any navigation drops
    -- all three — a meal still held after you left the page would be
    -- set down by a press you made somewhere else
    , lifted : Maybe ( Plan.Day, Int )
    , planLabelOpen : Maybe ( Plan.Day, Int )
    , planEntry : Maybe Page.Plan.Entry
    , planClearArmed : Bool

    -- the recipe page's day picker: whether it is open, and the day a
    -- first press asked to replace. Reset by navigation for the same
    -- reason the print form is
    , pickerOpen : Bool
    , pickerPlaced : Maybe Plan.Day
    , pickerRefused : Maybe Plan.Day

    -- the shared picture, which draw it is waiting for, and what the
    -- last share or copy did. Dropped by any change to the week, the
    -- theme, or the route: a picture of last minute's week is a
    -- picture that lies
    , picture : Page.Plan.Picture
    , pictureGen : Int
    , pictureOutcome : Maybe Page.Plan.Outcome

    -- the restaurants. The reader's, like the list and the week: no
    -- navigation resets it
    , restaurants : Roulette

    -- the roulette page's hand: the spin, the entry field's text and
    -- why the last ADD was refused, the day the answer was put on or
    -- that was full, and whether CLEAR is armed. Page state, so any
    -- navigation drops all of it — a spin is a moment, not a record
    , spin : Roulette.Spin
    , rouletteEntry : String
    , rouletteRefusal : Maybe Roulette.Refusal
    , roulettePlaced : Maybe Plan.Day
    , rouletteRefused : Maybe Plan.Day
    , rouletteClearArmed : Bool
    , calm : Bool

    , done : Set Int
    , timer : Maybe Cook.Timer
    , now : Time.Posix
    , wake : Cook.Wake

    -- the home-screen install: what the browser offers, and whether
    -- the share-sheet sentence is showing. The sentence closes on any
    -- real navigation, like the menu
    , install : Install.Offer
    , installHelp : Bool
    }


{-| Something fetched over the network, in the three states a reader
can actually be in. No `NotAsked`: the fetch is issued by arriving at
the route, so there is no moment where the page exists and the request
does not.
-}
type Fetch a
    = Fetching
    | Fetched a
    | FetchFailed Reach.Failure


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        ( storedPlan, discardPlan ) =
            readPlan flags.plan

        ( storedRestaurants, discardRestaurants ) =
            readRestaurants flags.restaurants
    in
    ( { key = key
      , route = Route.fromUrl url
      , theme = themeFromFlag flags.theme
      , fragment = url.fragment
      , mirroring = False
      , active = Nothing
      , query = ""
      , menuOpen = False
      , recipe = Fetching
      , factor = factorFor (Route.fromUrl url) url
      , form = Print.Sheet
      , prepCard = False
      , origin = origin url
      , today = flags.today
      , index = Fetching
      , filters = Shelf.noFilters
      , openPath = Nothing
      , list =
            flags.list
                |> Maybe.andThen (D.decodeString GroceryList.decoder >> Result.toMaybe)
                |> Maybe.withDefault GroceryList.empty
      , clearArmed = False
      , plan = storedPlan
      , lifted = Nothing
      , planLabelOpen = Nothing
      , planEntry = Nothing
      , planClearArmed = False
      , pickerOpen = False
      , pickerPlaced = Nothing
      , pickerRefused = Nothing
      , picture = Page.Plan.NotMade
      , pictureGen = 0
      , pictureOutcome = Nothing
      , restaurants = storedRestaurants
      , spin = Roulette.Idle
      , rouletteEntry = ""
      , rouletteRefusal = Nothing
      , roulettePlaced = Nothing
      , rouletteRefused = Nothing
      , rouletteClearArmed = False
      , calm = flags.calm
      , done = Set.empty
      , timer = Nothing
      , now = Time.millisToPosix 0
      , wake = Cook.Off
      , install = Install.fromString flags.install
      , installHelp = False
      }
    , Cmd.batch
        [ routeCmd (Route.fromUrl url)
        , setWakeLock (isCooking (Route.fromUrl url))
        , discardPlan
        , discardRestaurants

        -- a cold load with a fragment (a shared deep link) still owes
        -- a jump — the browser cannot do it, because Elm renders
        -- after load
        , case url.fragment of
            Just anchor ->
                jumpTo anchor

            Nothing ->
                Cmd.none
        ]
    )


{-| Keep a changed list, and write it through. Every edit to the list
goes out in the same breath it happens, because the next thing the
reader does with a shopping list is close the tab and walk to a shop.
-}
store : Model -> ( Model, Cmd Msg )
store model =
    ( model, saveList (GroceryList.encode model.list) )


{-| Keep a changed plan, and write it through, as `store` does the list.
-}
storePlan : Model -> ( Model, Cmd Msg )
storePlan model =
    let
        ( dropped, forget ) =
            dropPicture model
    in
    ( dropped, Cmd.batch [ savePlan (Plan.encode model.plan), forget ] )


{-| Put a meal at the end of a day and close the field. A full day
cannot reach here — ADD is a sentence at five — but if it did, the
field stays open with the words still in it rather than losing them.
-}
addToDay : Plan.Day -> Plan.Meal -> Model -> ( Model, Cmd Msg )
addToDay day meal model =
    case Plan.add day meal model.plan of
        Ok plan ->
            storePlan { model | plan = plan, planEntry = Nothing }

        Err Plan.DayFull ->
            ( model, Cmd.none )


{-| Let go of the picture. Every change to the week comes through
`storePlan`, which calls this, so the preview can never show a week
the plan no longer holds. The generation moves even when nothing was
made, so a draw still in flight is ignored when it lands.
-}
dropPicture : Model -> ( Model, Cmd Msg )
dropPicture model =
    ( { model
        | picture = Page.Plan.NotMade
        , pictureGen = model.pictureGen + 1
        , pictureOutcome = Nothing
      }
    , case model.picture of
        Page.Plan.NotMade ->
            Cmd.none

        _ ->
            sharePlan (E.object [ ( "do", E.string "forget" ) ])
    )


{-| The stored week, and what to do about it.

DS-01 §12: _state that cannot be read back is discarded and the reader
starts empty._ Discarded means the key goes, not only that this load
ignores it — a value that fails once fails on every load, and a key
nobody can read is a thing kept about the reader that does nothing
for them. Writing the empty week clears it (boot.js removes the key
rather than storing `{}`).

Nothing stored, or a clean read, writes nothing.

-}
readPlan : Maybe String -> ( Plan, Cmd msg )
readPlan stored =
    case stored of
        Nothing ->
            ( Plan.empty, Cmd.none )

        Just raw ->
            case D.decodeString Plan.decoder raw of
                Ok plan ->
                    ( plan, Cmd.none )

                Err _ ->
                    ( Plan.empty, savePlan (Plan.encode Plan.empty) )


{-| The stored restaurants, and what to do about them — `readPlan`'s
rule, for the fourth key. This is also the caller `saveRestaurants`
needs to exist.
-}
readRestaurants : Maybe String -> ( Roulette, Cmd msg )
readRestaurants stored =
    case stored of
        Nothing ->
            ( Roulette.empty, Cmd.none )

        Just raw ->
            case D.decodeString Roulette.decoder raw of
                Ok restaurants ->
                    ( restaurants, Cmd.none )

                Err _ ->
                    ( Roulette.empty, saveRestaurants (Roulette.encode Roulette.empty) )


{-| Keep a changed restaurant list, and write it through, as `store`
does the list. A spin over the old list is dropped with it: the wheel
the reel was reading is not the wheel any more.
-}
storeRestaurants : Roulette -> Model -> ( Model, Cmd Msg )
storeRestaurants restaurants model =
    ( { model
        | restaurants = restaurants
        , spin = Roulette.Idle
        , roulettePlaced = Nothing
        , rouletteRefused = Nothing
      }
    , saveRestaurants (Roulette.encode restaurants)
    )


{-| boot.js's answer to a draw: which draw, and the picture or the
failure.
-}
pictureDecoder : D.Decoder ( Int, Page.Plan.Picture )
pictureDecoder =
    D.map2 Tuple.pair
        (D.field "gen" D.int)
        (D.oneOf
            [ D.field "failed" D.bool
                |> D.andThen
                    (\failed ->
                        if failed then
                            D.succeed Page.Plan.Unmade

                        else
                            D.fail "not a failure"
                    )
            , D.map3 (\url canShare canCopy -> Page.Plan.Made { url = url, canShare = canShare, canCopy = canCopy })
                (D.field "url" D.string)
                (D.field "canShare" D.bool)
                (D.field "canCopy" D.bool)
            ]
        )


{-| What arriving at a route costs in requests.

Every route but `Recipe` is already in the bundle — DS-01 is generated
into Elm at build time precisely so it needs no fetch (see
`scripts/build-docs.ts`). Recipes are a growing corpus and are fetched
one at a time.

The shopping list is the one page that fetches **nothing**: it is a
snapshot, taken when each recipe went on, so it renders in a shop
with no signal.

-}
routeCmd : Route -> Cmd Msg
routeCmd route =
    case route of
        Route.Recipe slug ->
            Http.get
                { url = Recipe.path slug
                , expect = Http.expectJson GotRecipe Recipe.decoder
                }

        Route.Cook slug ->
            Http.get
                { url = Recipe.path slug
                , expect = Http.expectJson GotRecipe Recipe.decoder
                }

        Route.Home ->
            fetchIndex

        -- The entry field searches the archive the shelf lists, so the
        -- plan asks for the same index. A failed fetch leaves the
        -- field working: a meal of your own needs nothing from it.
        Route.Plan ->
            fetchIndex

        _ ->
            Cmd.none


fetchIndex : Cmd Msg
fetchIndex =
    Http.get
        { url = "/content/index.json"
        , expect = Http.expectJson GotIndex Shelf.decoder
        }



-- UPDATE


type Msg
    = UrlChanged Url
    | LinkClicked Browser.UrlRequest
    | SetTheme Theme
    | SectionSeen String
    | QueryChanged String
    | ToggleMenu
    | GotRecipe (Result Http.Error Recipe)
    | SetFactor Scale.Factor
    | SetForm Print.Form
    | TogglePrepCard
    | GotIndex (Result Http.Error Shelf.Index)
    | ToggleInList
    | CheckItem String
    | RemoveFromList String
    | ClearList
    | PlanOpen Plan.Day
    | PlanInput String
    | PlanCancel
    | PlanKeep
    | PlanPick String String
    | PlanLift Plan.Day Int
    | PlanPlace Plan.Target
    | PlanRemove Plan.Day Int
    | PlanLabelOpen Plan.Day Int
    | PlanLabel Plan.Day Int (Maybe Plan.Slot)
    | PlanClear
    | PickerToggle
    | PickerDay Plan.Day
    | PickerLabel (Maybe Plan.Slot)
    | MakePicture
    | GotPicture D.Value
    | SharePicture
    | CopyPicture
    | PictureShared String
    | RouletteInput String
    | RouletteAdd
    | RouletteRemove String
    | RouletteSpin (Maybe String)
    | RouletteSpinAt (List String) Time.Posix
    | RouletteDay Plan.Day
    | RouletteClear
    | RouletteTick Time.Posix
    | OpenPath (Maybe Shelf.Path)
    | ToggleFacet Shelf.Path String
    | ShelfQuery String
    | ClearFilters
    | Stamp Int
    | StartTimer Int Int
    | TimerStarted Int Int Time.Posix
    | StopTimer
    | Tick Time.Posix
    | WakeChanged String
    | InstallOffered String
    | PressInstall
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
                        , installHelp = model.mirroring && model.installHelp
                        , active =
                            if arrived then
                                Nothing

                            else
                                model.active

                        -- a real navigation drops the previous
                        -- recipe and its scale. Keeping either would
                        -- render one recipe's quantities under
                        -- another's name for as long as the fetch
                        -- takes, which is a wrong page rather than a
                        -- slow one
                        , recipe =
                            if arrived then
                                Fetching

                            else
                                model.recipe
                        , factor =
                            if arrived then
                                factorFor route url

                            else
                                model.factor
                        , form =
                            if arrived then
                                Print.Sheet

                            else
                                model.form
                        , prepCard =
                            if arrived then
                                False

                            else
                                model.prepCard

                        -- The shelf resets too. A filter set for last
                        -- week's dinner is not a preference about
                        -- this visit, and a reader arriving at "/"
                        -- expecting the archive should see the
                        -- archive.
                        , filters =
                            if arrived then
                                Shelf.noFilters

                            else
                                model.filters
                        , openPath =
                            if arrived then
                                Nothing

                            else
                                model.openPath
                        -- The list itself survives navigation; the
                        -- ARMED state does not. Leaving the page and
                        -- coming back to find a live destructive
                        -- control is the one way this could go wrong
                        -- without anybody pressing it twice.
                        , clearArmed =
                            if arrived then
                                False

                            else
                                model.clearArmed
                        , lifted =
                            if arrived then
                                Nothing

                            else
                                model.lifted
                        , planEntry =
                            if arrived then
                                Nothing

                            else
                                model.planEntry
                        , planClearArmed =
                            if arrived then
                                False

                            else
                                model.planClearArmed
                        , pickerOpen =
                            if arrived then
                                False

                            else
                                model.pickerOpen
                        , planLabelOpen =
                            if arrived then
                                Nothing

                            else
                                model.planLabelOpen
                        , pickerPlaced =
                            if arrived then
                                Nothing

                            else
                                model.pickerPlaced
                        , pickerRefused =
                            if arrived then
                                Nothing

                            else
                                model.pickerRefused
                        , spin =
                            if arrived then
                                Roulette.Idle

                            else
                                model.spin
                        , rouletteEntry =
                            if arrived then
                                ""

                            else
                                model.rouletteEntry
                        , rouletteRefusal =
                            if arrived then
                                Nothing

                            else
                                model.rouletteRefusal
                        , roulettePlaced =
                            if arrived then
                                Nothing

                            else
                                model.roulettePlaced
                        , rouletteRefused =
                            if arrived then
                                Nothing

                            else
                                model.rouletteRefused
                        , rouletteClearArmed =
                            if arrived then
                                False

                            else
                                model.rouletteClearArmed
                        , done =
                            if arrived then
                                Set.empty

                            else
                                model.done
                        , timer =
                            if arrived then
                                Nothing

                            else
                                model.timer
                    }

                -- The picture is page state like the rest, and boot.js
                -- is told to let go of the blob behind it.
                ( settled, forget ) =
                    if arrived then
                        dropPicture updated

                    else
                        ( updated, Cmd.none )
            in
            ( -- an arrival on a mirroring route writes the URL back in
              -- the same batch, so the *next* UrlChanged is this
              -- shell's echo; anything else clears the flag
              { settled | mirroring = arrived && arrivalMirrors route }
            , Cmd.batch
                [ forget
                , if arrived then
                    routeCmd route

                  else
                    Cmd.none
                , if arrived then
                    setWakeLock (isCooking route)

                  else
                    Cmd.none
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
                ]
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
            -- The picture is drawn in the theme's colours, so a new
            -- theme is a new picture.
            let
                ( dropped, forget ) =
                    dropPicture model
            in
            ( { dropped | theme = theme }
            , Cmd.batch [ saveTheme (themeToString theme), forget ]
            )

        QueryChanged query ->
            ( { model | query = query }, Cmd.none )

        ToggleMenu ->
            ( { model | menuOpen = not model.menuOpen }, Cmd.none )

        GotRecipe (Ok recipe) ->
            -- The recipe's own `print:` field chooses the form it
            -- wants; the reader can still override it. A long-form
            -- recipe that defaults to the one-page card would be the
            -- schema saying something the page ignored.
            ( { model | recipe = Fetched recipe, form = Print.fromSlug recipe.print }
            , Cmd.none
            )

        GotRecipe (Err error) ->
            -- The raw error is not shown, but its reason is: "not in
            -- the archive" and "no signal" ask different things of a
            -- reader, and saying the first for both is a guess.
            ( { model | recipe = FetchFailed (Reach.fromHttp error) }, Cmd.none )

        SetFactor factor ->
            ( { model | factor = factor }, Cmd.none )

        SetForm form ->
            ( { model | form = form }, Cmd.none )

        ToggleInList ->
            -- The recipe has to be in hand: what goes on the list is a
            -- snapshot of its ingredients at the scale on screen, not
            -- a pointer to a document that may not be there when the
            -- list is read.
            case model.recipe of
                Fetched recipe ->
                    store
                        { model
                            | list =
                                GroceryList.toggle
                                    (GroceryList.fromRecipe model.factor recipe)
                                    model.list
                            , clearArmed = False
                        }

                _ ->
                    ( model, Cmd.none )

        CheckItem key ->
            -- Any other press disarms. Reaching for a row is the
            -- reader saying they were doing something else.
            store
                { model
                    | list = GroceryList.check key model.list
                    , clearArmed = False
                }

        RemoveFromList slug ->
            store
                { model
                    | list = GroceryList.remove slug model.list
                    , clearArmed = False
                }

        ClearList ->
            -- The arm-then-clear rule lives in `GroceryList`, where it
            -- is tested. This only decides that an arming press has
            -- nothing to write.
            let
                ( list, armed ) =
                    GroceryList.clearPress model.clearArmed model.list

                updated =
                    { model | list = list, clearArmed = armed }
            in
            if armed then
                ( updated, Cmd.none )

            else
                store updated

        PlanOpen day ->
            -- Opening a day drops anything held and disarms the clear:
            -- the reader has moved on to something else.
            ( { model
                | planEntry = Just { day = day, text = "" }
                , lifted = Nothing
                , planLabelOpen = Nothing
                , planClearArmed = False
              }
            , Task.attempt (\_ -> NoOp) (Dom.focus "plan-entry")
            )

        PlanInput typed ->
            ( { model | planEntry = Maybe.map (\e -> { e | text = typed }) model.planEntry }
            , Cmd.none
            )

        PlanCancel ->
            ( { model | planEntry = Nothing }, Cmd.none )

        PlanKeep ->
            -- Enter on a blank field does nothing, rather than closing:
            -- an own meal cannot be blank (`Plan.own`), and a field
            -- that vanished on Enter would look like it had kept
            -- something.
            case model.planEntry of
                Just entry ->
                    case Plan.own entry.text of
                        Just meal ->
                            addToDay entry.day meal model

                        Nothing ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        PlanPick slug title ->
            case model.planEntry of
                Just entry ->
                    addToDay entry.day (Plan.recipe slug title) model

                Nothing ->
                    ( model, Cmd.none )

        PlanLift day index ->
            ( { model
                | lifted = Just ( day, index )
                , planEntry = Nothing
                , planLabelOpen = Nothing
                , planClearArmed = False
              }
            , Cmd.none
            )

        PlanPlace target ->
            -- The move table lives in `Plan.moveEntry`, where it is
            -- tested. A full day refuses and the meal STAYS in the
            -- hand; the page never offers that press, so this is the
            -- second lock on the door.
            case model.lifted of
                Just from ->
                    case Plan.moveEntry from target model.plan of
                        Ok plan ->
                            storePlan { model | plan = plan, lifted = Nothing }

                        Err Plan.DayFull ->
                            ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        PlanRemove day index ->
            storePlan
                { model
                    | plan = Plan.remove day index model.plan
                    , planLabelOpen = Nothing
                    , planClearArmed = False
                }

        PlanLabelOpen day index ->
            ( { model
                | planLabelOpen =
                    if model.planLabelOpen == Just ( day, index ) then
                        Nothing

                    else
                        Just ( day, index )
                , planClearArmed = False
              }
            , Cmd.none
            )

        PlanLabel day index slot ->
            storePlan
                { model
                    | plan = Plan.label day index slot model.plan
                    , planLabelOpen = Nothing
                }

        PlanClear ->
            let
                ( plan, armed ) =
                    Plan.clearPress model.planClearArmed model.plan

                updated =
                    { model | plan = plan, planClearArmed = armed }
            in
            if armed then
                ( updated, Cmd.none )

            else
                storePlan updated

        PickerToggle ->
            ( { model | pickerOpen = not model.pickerOpen, pickerPlaced = Nothing, pickerRefused = Nothing }
            , Cmd.none
            )

        PickerDay day ->
            -- The recipe has to be in hand, as it does for the list:
            -- the plan keeps a snapshot of its title. The rule is
            -- `Plan.placeRecipe`: this recipe's day gives it up, any
            -- other takes it at the end, a full one refuses.
            case model.recipe of
                Fetched recipe ->
                    case Plan.placeRecipe (Plan.recipe recipe.slug recipe.title) day model.plan of
                        Ok plan ->
                            storePlan
                                { model
                                    | plan = plan
                                    , pickerRefused = Nothing
                                    , pickerPlaced =
                                        if List.member day (Plan.plannedOn recipe.slug plan) then
                                            Just day

                                        else
                                            Nothing
                                }

                        Err Plan.DayFull ->
                            ( { model | pickerRefused = Just day, pickerPlaced = Nothing }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        PickerLabel slot ->
            case ( model.recipe, model.pickerPlaced ) of
                ( Fetched recipe, Just day ) ->
                    case Plan.indexOn recipe.slug day model.plan of
                        Just index ->
                            storePlan { model | plan = Plan.label day index slot model.plan }

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        MakePicture ->
            let
                gen =
                    model.pictureGen + 1
            in
            ( { model | picture = Page.Plan.Making, pictureGen = gen, pictureOutcome = Nothing }
            , sharePlan
                (E.object
                    [ ( "do", E.string "draw" )
                    , ( "gen", E.int gen )
                    , ( "rows", Plan.toShare model.plan )
                    ]
                )
            )

        GotPicture value ->
            case D.decodeValue pictureDecoder value of
                Ok ( gen, picture ) ->
                    if gen == model.pictureGen && model.picture == Page.Plan.Making then
                        ( { model | picture = picture }, Cmd.none )

                    else
                        -- An answer to a draw nobody is waiting for.
                        -- boot.js already drops these itself; this is
                        -- the second lock on the same door, and it
                        -- sends nothing, because a "forget" here could
                        -- release the picture the page IS showing.
                        ( model, Cmd.none )

                Err _ ->
                    ( { model | picture = Page.Plan.Unmade }, Cmd.none )

        SharePicture ->
            ( { model | pictureOutcome = Nothing }
            , sharePlan (E.object [ ( "do", E.string "share" ) ])
            )

        CopyPicture ->
            ( { model | pictureOutcome = Nothing }
            , sharePlan (E.object [ ( "do", E.string "copy" ) ])
            )

        PictureShared word ->
            ( { model | pictureOutcome = Just (Page.Plan.outcomeFromString word) }, Cmd.none )

        RouletteInput typed ->
            ( { model | rouletteEntry = typed, rouletteRefusal = Nothing }, Cmd.none )

        RouletteAdd ->
            -- Enter on a blank field says so rather than closing:
            -- the field stays, with a sentence, and never looks like
            -- it kept something.
            case Roulette.add model.rouletteEntry model.restaurants of
                Ok restaurants ->
                    storeRestaurants restaurants
                        { model | rouletteEntry = "", rouletteRefusal = Nothing, rouletteClearArmed = False }

                Err why ->
                    ( { model | rouletteRefusal = Just why }, Cmd.none )

        RouletteRemove name ->
            storeRestaurants (Roulette.remove name model.restaurants)
                { model | rouletteClearArmed = False }

        RouletteSpin vetoed ->
            -- The answer is drawn at the press (DS-01 §10, the reel),
            -- and the instant is fetched first because the reel runs
            -- to an absolute end. The draw is seeded off that instant,
            -- which is what `Random.generate` would do with one more
            -- round trip through the runtime.
            case Roulette.wheel vetoed model.restaurants of
                [] ->
                    ( model, Cmd.none )

                wheel ->
                    ( { model | roulettePlaced = Nothing, rouletteRefused = Nothing, rouletteClearArmed = False }
                    , Task.perform (RouletteSpinAt wheel) Time.now
                    )

        RouletteSpinAt wheel now ->
            let
                ( index, _ ) =
                    Random.step
                        (Random.int 0 (List.length wheel - 1))
                        (Random.initialSeed (Time.posixToMillis now))
            in
            ( { model
                | spin = Roulette.start { calm = model.calm, wheel = wheel, index = index, now = now }
                , now = now
              }
            , Cmd.none
            )

        RouletteTick now ->
            ( { model | now = now, spin = Roulette.settle now model.spin }, Cmd.none )

        RouletteDay day ->
            -- The plan holds the name as typed, as an own meal, and
            -- does not learn it was a restaurant (docs/decisions.md).
            case model.spin of
                Roulette.Settled name ->
                    case Plan.own name of
                        Just meal ->
                            case Plan.add day meal model.plan of
                                Ok plan ->
                                    storePlan { model | plan = plan, roulettePlaced = Just day, rouletteRefused = Nothing }

                                Err Plan.DayFull ->
                                    ( { model | rouletteRefused = Just day, roulettePlaced = Nothing }, Cmd.none )

                        Nothing ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        RouletteClear ->
            -- Two presses, like the list and the week: the first arms,
            -- the second clears. Any other press on the page disarms.
            if model.rouletteClearArmed then
                storeRestaurants Roulette.empty { model | rouletteClearArmed = False }

            else
                ( { model | rouletteClearArmed = True }, Cmd.none )

        GotIndex (Ok index) ->
            ( { model | index = Fetched index }, Cmd.none )

        GotIndex (Err error) ->
            ( { model | index = FetchFailed (Reach.fromHttp error) }, Cmd.none )

        OpenPath p ->
            ( { model | openPath = p }, Cmd.none )

        ToggleFacet p value ->
            ( { model | filters = Shelf.toggle p value model.filters }, Cmd.none )

        ShelfQuery q ->
            ( { model | filters = (\f -> { f | query = q }) model.filters }, Cmd.none )

        Stamp n ->
            ( { model
                | done =
                    if Set.member n model.done then
                        Set.remove n model.done

                    else
                        Set.insert n model.done
              }
            , Cmd.none
            )

        StartTimer n seconds ->
            -- The current instant has to be fetched before the timer
            -- can exist: it counts to an absolute end, not down a
            -- decrementing counter, so a throttled background tab
            -- resumes correct instead of minutes behind.
            ( model, Task.perform (TimerStarted n seconds) Time.now )

        TimerStarted n seconds now ->
            ( { model | timer = Just (Cook.start n seconds now), now = now }
            , Cmd.none
            )

        StopTimer ->
            ( { model | timer = Nothing }, Cmd.none )

        Tick now ->
            ( { model | now = now }, Cmd.none )

        WakeChanged flag ->
            ( { model | wake = Cook.wakeFromFlag flag }, Cmd.none )

        InstallOffered word ->
            ( { model | install = Install.fromString word }, Cmd.none )

        PressInstall ->
            case model.install of
                Install.Prompt ->
                    ( model, installApp () )

                Install.ShareSheet ->
                    ( { model | installHelp = not model.installHelp }, Cmd.none )

                Install.NoOffer ->
                    ( model, Cmd.none )

        ClearFilters ->
            ( { model | filters = Shelf.clear model.filters, openPath = Nothing }
            , Cmd.none
            )

        TogglePrepCard ->
            ( { model | prepCard = not model.prepCard }, Cmd.none )

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


{-| The contents rail's active row, the wake-lock status — and the
step timer, **only while one is running**.

The rule this module has carried since the start: add a subscription
only when something on screen genuinely changes on its own. A timer
on a document that does not change is a battery cost with no reader,
which is exactly why `Time.every` is absent unless `model.timer` is
`Just`. A running duration is DS-01 §10's one sanctioned piece of
motion, and it stops being sanctioned the moment nothing is counting.

-}
subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ sectionSeen SectionSeen
        , wakeLockChanged WakeChanged

        -- The browser's install event arrives after load, on its own
        -- time, and an install or a dismissal spends it.
        , installOffered InstallOffered

        -- Both answer a press the reader made, and both arrive on
        -- their own time: a canvas encodes asynchronously, and a
        -- share sheet stays open as long as the reader leaves it.
        , planPicture GotPicture
        , planShared PictureShared
        , case model.timer of
            Just _ ->
                Time.every 1000 Tick

            Nothing ->
                Sub.none

        -- The reel, only while one runs (DS-01 §10, the reel). Each
        -- tick reads the clock; the frame shown is a function of it,
        -- and the tick past the end settles.
        , case model.spin of
            Roulette.Spinning _ ->
                Time.every 80 RouletteTick

            _ ->
                Sub.none
        ]


{-| The scale a route arrives at.

**Cook mode reads its factor off the address; everything else starts
at ×1.** That is what lets the scale be "set before you start"
(DS-01 §08) without the shell carrying it invisibly across a
navigation — a factor that survived a page change unseen is precisely
the silent rescaling `Scale` exists to prevent. It also makes a half
batch a thing you can bookmark.

-}
factorFor : Route -> Url -> Scale.Factor
factorFor route url =
    case route of
        Route.Cook _ ->
            Scale.fromString (Route.queryParam "scale" url)

        _ ->
            Scale.one


{-| Whether a route wants the screen held awake. Only one does.
-}
isCooking : Route -> Bool
isCooking route =
    case route of
        Route.Cook _ ->
            True

        _ ->
            False



-- URL-BACKED STATE


{-| Whether arriving on this route writes the URL back, and therefore
whether the `UrlChanged` that follows is this shell's own echo.

No route mirrors yet, and the shelf's filters are the first real
candidate — a narrowed archive is exactly the thing worth sharing.
They are deliberately left out for now, because mirroring carries a
contract this comment is the only record of: **a route that answers
True here MUST issue a `Nav.replaceUrl` on arrival.** If it does not,
`mirroring` stays set, and the next genuine navigation is mistaken
for this shell's own echo and never moves the reader. Arriving at the
shelf with no filters has no URL to write, so satisfying that
contract needs its own careful pass rather than a line added in
passing.

Leaving this as `False` for a route that *does* mirror makes its
every keystroke scroll the reader to the top of the page.

-}
arrivalMirrors : Route -> Bool
arrivalMirrors _ =
    False


{-| The scheme and host this document was served from, for the
printed footer's short URL. Taken from the boot URL rather than
hard-coded, so a local preview prints a local address and does not
claim to be the published one.
-}
origin : Url -> String
origin url =
    let
        scheme =
            case url.protocol of
                Url.Https ->
                    "https://"

                Url.Http ->
                    "http://"
    in
    scheme
        ++ url.host
        ++ Maybe.withDefault "" (Maybe.map (\p -> ":" ++ String.fromInt p) url.port_)


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
the site nav always, the contents rail when it is worn as the search
strip, and cook mode's header when that is the page. Measured rather
than hard-coded against the breakpoint, so this number cannot drift
from the CSS that produces it.

**Cook mode's header is sticky too**, and it is the tallest chrome in
the product. Left out, every anchor the cook rail offers would put its
step underneath the title and the scale badge — which is the one place
in the archive where landing on the wrong line has a pan attached to
it. `coveredHeight` answers zero when the element is not on the page,
so this costs the other routes nothing.

-}
stickyChromeHeight : Task.Task x Float
stickyChromeHeight =
    Task.map3 (\a b c -> a + b + c)
        (coveredHeight "site-nav")
        stripHeight
        (coveredHeight "cook-head")


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

        -- The backing paper, on every route but cook mode. Outside the
        -- keyed wrapper below on purpose: it is the constant the pages
        -- are laid on, and must survive a navigation.
        , if Liner.on model.route then
            Liner.view

          else
            text ""

        -- Keyed on the route, so a navigation unmounts the old leaf and
        -- mounts a fresh one — which is what lets `@starting-style` in
        -- sheet.css seat it. A filter, a query or a scale keeps the key
        -- and the leaf stays put (Liner.leafKey).
        , Keyed.node "div" [ class "leaves" ] [ ( Liner.leafKey model.route, page model ) ]
        ]
    }


page : Model -> Html Msg
page model =
        case model.route of
            Route.Home ->
                case model.index of
                    Fetching ->
                        Page.Shelf.viewLoading

                    FetchFailed failure ->
                        Page.Shelf.viewFailed failure

                    Fetched index ->
                        Page.Shelf.view
                            { index = index
                            , filters = model.filters
                            , openPath = model.openPath
                            , onOpen = OpenPath
                            , onToggle = ToggleFacet
                            , onQuery = ShelfQuery
                            , onClear = ClearFilters
                            , install = model.install
                            , installHelp = model.installHelp
                            , onInstall = PressInstall
                            }

            Route.ShoppingList ->
                Page.GroceryList.view
                    { list = model.list
                    , onCheck = CheckItem
                    , onRemove = RemoveFromList
                    , onClear = ClearList
                    , clearArmed = model.clearArmed
                    }

            Route.Plan ->
                Page.Plan.view
                    { plan = model.plan
                    , archive =
                        case model.index of
                            Fetching ->
                                Page.Plan.Opening

                            Fetched index ->
                                Page.Plan.Searchable index.recipes

                            FetchFailed _ ->
                                Page.Plan.Unsearchable
                    , lifted = model.lifted
                    , labelOpen = model.planLabelOpen
                    , entry = model.planEntry
                    , clearArmed = model.planClearArmed
                    , onOpen = PlanOpen
                    , onInput = PlanInput
                    , onCancel = PlanCancel
                    , onKeep = PlanKeep
                    , onPick = PlanPick
                    , onLift = PlanLift
                    , onPlace = PlanPlace
                    , onRemove = PlanRemove
                    , onLabelOpen = PlanLabelOpen
                    , onLabel = PlanLabel
                    , onClear = PlanClear
                    , picture = model.picture
                    , outcome = model.pictureOutcome
                    , onMake = MakePicture
                    , onShare = SharePicture
                    , onCopy = CopyPicture
                    }

            Route.RestaurantRoulette ->
                Page.RestaurantRoulette.view
                    { roulette = model.restaurants
                    , spin = model.spin
                    , now = model.now
                    , entry = model.rouletteEntry
                    , refusal = model.rouletteRefusal
                    , plan = model.plan
                    , placed = model.roulettePlaced
                    , refused = model.rouletteRefused
                    , clearArmed = model.rouletteClearArmed
                    , onInput = RouletteInput
                    , onAdd = RouletteAdd
                    , onRemove = RouletteRemove
                    , onSpin = RouletteSpin Nothing
                    , onVeto =
                        case model.spin of
                            Roulette.Settled name ->
                                RouletteSpin (Just name)

                            _ ->
                                RouletteSpin Nothing
                    , onDay = RouletteDay
                    , onClear = RouletteClear
                    }

            Route.About ->
                Page.About.view (chrome model)

            Route.DesignStandard ->
                Page.DesignStandard.view (chrome model)

            Route.Cook slug ->
                case model.recipe of
                    Fetching ->
                        Page.Recipe.viewLoading

                    FetchFailed failure ->
                        Page.Recipe.viewFailed failure slug

                    Fetched recipe ->
                        Page.Cook.view
                            { recipe = recipe

                            -- Off the URL, never inherited through
                            -- navigation: entering cook mode must not
                            -- be able to change the quantities.
                            , factor = model.factor
                            , done = model.done
                            , onStamp = Stamp
                            , timer = model.timer
                            , now = model.now
                            , onStartTimer = StartTimer
                            , onStopTimer = StopTimer
                            , wake = model.wake
                            , active = model.active
                            }

            Route.Recipe slug ->
                case model.recipe of
                    Fetching ->
                        Page.Recipe.viewLoading

                    FetchFailed failure ->
                        Page.Recipe.viewFailed failure slug

                    Fetched recipe ->
                        Page.Recipe.view
                            { recipe = recipe
                            , factor = model.factor
                            , onScale = SetFactor
                            , form = model.form
                            , onForm = SetForm
                            , prepCard = model.prepCard
                            , onPrepCard = TogglePrepCard
                            , inList = GroceryList.member slug model.list
                            , onToggleList = ToggleInList
                            , planner =
                                { plan = model.plan
                                , open = model.pickerOpen
                                , placed = model.pickerPlaced
                                , refused = model.pickerRefused
                                , onOpen = PickerToggle
                                , onDay = PickerDay
                                , onLabel = PickerLabel
                                }
                            , origin = model.origin
                            , today = model.today

                            -- The side nav's mark. Already tracked
                            -- for the documents' contents rail, and
                            -- already cleared on navigation.
                            , active = model.active
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
                , countedLink model.route Route.ShoppingList "Shopping List" ( "recipe", "recipes" ) (GroceryList.count model.list)
                , countedLink model.route Route.Plan "Meal Plan" ( "day", "days" ) (Plan.count model.plan)
                , countedLink model.route Route.RestaurantRoulette "Restaurant Roulette" ( "restaurant", "restaurants" ) (Roulette.count model.restaurants)
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


{-| A route wearing how much is on it: the shopping list's recipes,
the plan's days.

Three things the figure is not. It is **not an acid** — a count is a
quantity, and DS-01 §04 keeps acid off quantities wherever they fall,
including here. It is **not colour-only** — it is a number, and it
reads as one in the black-and-white bar of a printed page. And it is
**not a zero**: an empty list has nothing to report, and a badge
reading "0" is a heading over blank space (§06). Absent means empty,
which is the only thing it can mean.

The accessible name carries the word the figure stands for, because
"Shopping List 3" is not a sentence and a screen reader has no bar to
see it in. `Doc`'s rule that nothing is inferred applies to the ear
as much as the eye. The plan counts **days**, not meals: the figure
says how much of the week is covered.

-}
countedLink : Route -> Route -> String -> ( String, String ) -> Int -> Html msg
countedLink current target label ( one, many ) n =
    a
        (href (Route.toPath target)
            :: classList [ ( "active", current == target ) ]
            :: (if n > 0 then
                    [ attribute "aria-label"
                        (label
                            ++ ", "
                            ++ String.fromInt n
                            ++ " "
                            ++ (if n == 1 then
                                    one

                                else
                                    many
                               )
                        )
                    ]

                else
                    []
               )
        )
        (text label
            :: (if n > 0 then
                    [ span [ class "nav-count mono" ] [ text (String.fromInt n) ] ]

                else
                    []
               )
        )


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
