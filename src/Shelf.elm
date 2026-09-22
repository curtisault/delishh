module Shelf exposing
    ( Filters
    , Index
    , Path(..)
    , Keeps
    , Summary
    , Verdict(..)
    , active
    , clear
    , decoder
    , facetValues
    , facetsOf
    , judge
    , marks
    , nearestByTime
    , noFilters
    , path
    , pathLabel
    , pathNote
    , pathNoun
    , paths
    , ranked
    , toggle
    , vocabularyFor
    )

{-| The shelf — DS-01 §07.

`Flavor` rides on the summary so the rows can draw the meter, but
filtering matches on the *word* alone: a filter chip is
vocabulary-level, and "spicy at least 2" is a filter nobody has
asked for yet.

**The loud half of the product.** Browsing is where you choose what to
cook, and the interface treats that as the fun part; this module is
the machinery underneath it.

Two rules from §07 shape everything here, and both are refusals:

  - **Filters narrow; they never silently hide.** An excluded recipe
    stays on the page, tagged with the filter that excluded it. A
    result that simply vanishes teaches you to distrust your own
    archive — you cannot tell "nothing matches" from "I mis-set
    something three clicks ago". So `judge` returns a `Verdict` that
    carries the reasons, never a filtered list.
  - **Active time and total time are different facets and both are
    shown.** A twelve-hour cure is not a twenty-minute recipe, and
    collapsing the two is the most common lie in recipe software.

Pure and fully testable: no `Html`, no `Cmd`. The view decides what a
tile looks like; this decides what is true.

-}

import Flavor exposing (Flavor)
import Json.Decode as D exposing (Decoder)
import Set exposing (Set)



-- THE INDEX


{-| One recipe as the shelf needs it — everything a filter, a sort or
a row can ask for, and nothing a recipe page would want. The build
writes this separately from the full documents so the shelf loads one
small file rather than the whole corpus.
-}
type alias Summary =
    { slug : String
    , title : String
    , tested : String
    , active : Int
    , total : Int
    , slot : List String
    , course : String
    , flavor : List Flavor
    , method : String
    , effort : String
    , dietary : List String
    , cuisine : List String
    , keepsFor : Maybe Keeps
    }


{-| How long it keeps, and where — the row's last column. Carried
whole because the place is not optional: most of this archive states
a freezer life, and a bare duration at the end of a row reads as a
claim about the dish in a fridge.
-}
type alias Keeps =
    { where_ : String, amount : Int, unit : String }


type alias Index =
    { vocabulary : List ( Path, List String )
    , recipes : List Summary
    }



-- THE FOUR PATHS


{-| The four ways in — DS-01 §07. Each answers a different question,
and the tiles are the loudest surface in the product because choosing
is the enjoyable part.
-}
type Path
    = ByMeal
    | ByFlavor
    | ByEffort
    | ByNeeds


paths : List Path
paths =
    [ ByMeal, ByFlavor, ByEffort, ByNeeds ]


pathLabel : Path -> String
pathLabel p =
    case p of
        ByMeal ->
            "By meal"

        ByFlavor ->
            "By flavour"

        ByEffort ->
            "By effort"

        ByNeeds ->
            "By needs"


{-| The path's facet as a bare noun, for prose that already supplies
the preposition. `pathLabel` reads "By flavour" on a tile, which makes
"Hidden by By flavour" in a lockout tag — the two want different
words, so they get them.
-}
pathNoun : Path -> String
pathNoun p =
    case p of
        ByMeal ->
            "meal"

        ByFlavor ->
            "flavour"

        ByEffort ->
            "effort"

        ByNeeds ->
            "needs"


{-| The question the path answers. Every tile states its own use, so
nobody has to press one to find out what it does (DS-01 §2.5).
-}
pathNote : Path -> String
pathNote p =
    case p of
        ByMeal ->
            "What's for dinner?"

        ByFlavor ->
            "Sweet, spicy, or both"

        ByEffort ->
            "What am I up for?"

        ByNeeds ->
            "Gluten-free, and make it Thai"


{-| Which facet a path filters on. One facet each, deliberately: a
path that filtered on two would be a path you cannot reason about.
-}
path : Path -> String
path p =
    case p of
        ByMeal ->
            "slot"

        ByFlavor ->
            "flavor"

        ByEffort ->
            "effort"

        ByNeeds ->
            "dietary"


{-| A recipe's own values for a path's facet.
-}
facetsOf : Path -> Summary -> List String
facetsOf p recipe =
    case p of
        ByMeal ->
            recipe.slot

        ByFlavor ->
            List.map .name recipe.flavor

        ByEffort ->
            [ recipe.effort ]

        ByNeeds ->
            recipe.dietary



-- FILTERS


{-| What the reader has narrowed to. A path with an empty set is a
path they have not used — never "match nothing".
-}
type alias Filters =
    { meal : Set String
    , flavor : Set String
    , effort : Set String
    , needs : Set String
    , query : String
    }


noFilters : Filters
noFilters =
    { meal = Set.empty
    , flavor = Set.empty
    , effort = Set.empty
    , needs = Set.empty
    , query = ""
    }


clear : Filters -> Filters
clear _ =
    noFilters


selected : Path -> Filters -> Set String
selected p filters =
    case p of
        ByMeal ->
            filters.meal

        ByFlavor ->
            filters.flavor

        ByEffort ->
            filters.effort

        ByNeeds ->
            filters.needs


{-| Turn one facet value on or off. Selecting within a path composes
with every other path (DS-01 §07).
-}
toggle : Path -> String -> Filters -> Filters
toggle p value filters =
    let
        flip set =
            if Set.member value set then
                Set.remove value set

            else
                Set.insert value set
    in
    case p of
        ByMeal ->
            { filters | meal = flip filters.meal }

        ByFlavor ->
            { filters | flavor = flip filters.flavor }

        ByEffort ->
            { filters | effort = flip filters.effort }

        ByNeeds ->
            { filters | needs = flip filters.needs }


{-| What the reader has selected within one path.
-}
facetValues : Path -> Filters -> List String
facetValues p filters =
    Set.toList (selected p filters)


{-| The chips a path offers, straight from the vocabulary the content
build validates against. A chip the corpus can never match is a filter
that always returns nothing.
-}
vocabularyFor : Path -> Index -> List String
vocabularyFor p index =
    index.vocabulary
        |> List.filter (\( key, _ ) -> key == p)
        |> List.head
        |> Maybe.map Tuple.second
        |> Maybe.withDefault []


{-| Every path the reader has actually narrowed on, with its values —
what the active-filter bar renders, and what a "clear" button undoes.
-}
active : Filters -> List ( Path, List String )
active filters =
    paths
        |> List.map (\p -> ( p, Set.toList (selected p filters) ))
        |> List.filter (\( _, values ) -> not (List.isEmpty values))



-- JUDGING


{-| Whether a recipe survives the filters, and if not, which ones
excluded it.

**`Excluded` carries its reasons because the row stays on the page.**
Lockout tags, not disappearance — a silently-vanished result is how a
reader learns to distrust the archive (DS-01 §07).

-}
type Verdict
    = Shown
    | Excluded (List Path)


judge : Filters -> Summary -> Verdict
judge filters recipe =
    let
        -- A path with nothing selected excludes nothing. A path with
        -- selections keeps a recipe that carries ANY of them, so
        -- "sweet or salty" widens where "sweet and spicy" across two
        -- paths narrows.
        fails p =
            let
                wanted =
                    selected p filters
            in
            not (Set.isEmpty wanted)
                && not (List.any (\v -> Set.member v wanted) (facetsOf p recipe))

        failed =
            List.filter fails paths
    in
    if not (matchesQuery filters.query recipe) then
        -- The query is not a path and gets no tag: a reader who is
        -- typing can see why the list is shrinking.
        Excluded []

    else if List.isEmpty failed then
        Shown

    else
        Excluded failed


{-| Every word of a query has to match, so a second word narrows
rather than widens — the same rule the site search uses. Matched
against the title and every facet, because "vegan" is a thing people
type into a search box as readily as they click it.
-}
matchesQuery : String -> Summary -> Bool
matchesQuery query recipe =
    let
        haystack =
            String.toLower
                (String.join " "
                    (recipe.title
                        :: recipe.method
                        :: recipe.effort
                        :: recipe.course
                        :: recipe.slot
                        ++ List.map .name recipe.flavor
                        ++ recipe.dietary
                        ++ recipe.cuisine
                    )
                )
    in
    List.all (\needle -> String.contains needle haystack) (needles query)


{-| The words a query actually searches on. A single letter is
dropped, because one character matches most of the archive and the
list would shrink to nothing on the way to a second letter.
-}
needles : String -> List String
needles query =
    query
        |> String.toLower
        |> String.words
        |> List.filter (\w -> String.length w > 1)


{-| One piece of displayed text, cut into runs, each flagged with
whether the query put it there. `[ ( "Caram", True ), ( "el, salted",
False ) ]`.

**It reads the same `needles` the judgement does**, which is the
whole point of it living here rather than in the view: a mark derived
from a second notion of "matches" would underline letters the filter
did not act on, and the reader would be looking at a lie about their
own query.

Two refusals:

  - An empty query marks nothing. It returns the text as one
    unflagged run, never a list of characters.
  - If lowercasing changes the text's *length* — a thing a handful of
    scripts do — nothing is marked at all. The offsets come from the
    folded copy and are read off the original, so a shift would put
    the fill on the wrong letters. Marking nothing is wrong in a way
    a reader can see through; marking the wrong letters is not.

-}
marks : String -> String -> List ( String, Bool )
marks query text =
    let
        folded =
            String.toLower text

        hits =
            needles query
                |> List.concatMap
                    (\n ->
                        String.indexes n folded
                            |> List.map (\i -> ( i, i + String.length n ))
                    )

        covered i =
            List.any (\( from, to ) -> i >= from && i < to) hits

        run ( char, on ) acc =
            case acc of
                ( soFar, flag ) :: rest ->
                    if flag == on then
                        ( soFar ++ String.fromChar char, flag ) :: rest

                    else
                        ( String.fromChar char, on ) :: acc

                [] ->
                    [ ( String.fromChar char, on ) ]
    in
    if List.isEmpty hits || String.length folded /= String.length text then
        if String.isEmpty text then
            []

        else
            [ ( text, False ) ]

    else
        String.toList text
            |> List.indexedMap (\i char -> ( char, covered i ))
            |> List.foldl run []
            |> List.reverse



-- ORDER


{-| The shelf's order: **last tested first.** The archive's own
working order is more useful than the dictionary's (DS-01 §07) — what
you cooked recently is what you are most likely to cook again, and a
recipe you have not tested in two years should look like one.

Shown rows come before excluded ones, so the list reads as results
with their lockouts beneath rather than a grid with holes in it.

-}
ranked : Filters -> List Summary -> List ( Summary, Verdict )
ranked filters recipes =
    recipes
        |> List.map (\r -> ( r, judge filters r ))
        |> List.sortWith
            (\( a, va ) ( b, vb ) ->
                case ( va, vb ) of
                    ( Shown, Excluded _ ) ->
                        LT

                    ( Excluded _, Shown ) ->
                        GT

                    _ ->
                        compare b.tested a.tested
            )


{-| The nearest recipe by total time, for the zero-result state.

**A dead end is a design failure, not an edge case** (DS-01 §07), so
"nothing matches" always comes with somewhere to go. Nearest by time
because time is the facet a reader is most often willing to bend:
they will cook something else tonight, but not something that takes
four hours.

-}
nearestByTime : Filters -> List Summary -> Maybe Summary
nearestByTime filters recipes =
    let
        -- The bar a reader has implicitly set: the fastest thing that
        -- would have matched had the other paths not excluded it.
        wanted =
            recipes
                |> List.filter (\r -> matchesQuery filters.query r)
                |> List.map .total
                |> List.minimum
                |> Maybe.withDefault 0
    in
    recipes
        |> List.sortBy (\r -> abs (r.total - wanted))
        |> List.head



-- DECODING


keepsDecoder : Decoder Keeps
keepsDecoder =
    D.map3 Keeps
        (D.field "where" D.string)
        (D.field "amount" D.int)
        (D.field "unit" D.string)


decoder : Decoder Index
decoder =
    D.map2 Index
        (D.field "vocabulary" vocabularyDecoder)
        (D.field "recipes" (D.list summaryDecoder))


{-| The vocabulary travels with the index so the tiles offer exactly
what `scripts/vocabulary.ts` allows — a chip the corpus can never
match is a filter that always returns nothing.
-}
vocabularyDecoder : Decoder (List ( Path, List String ))
vocabularyDecoder =
    D.map4
        (\meal flavor effort needs ->
            [ ( ByMeal, meal )
            , ( ByFlavor, flavor )
            , ( ByEffort, effort )
            , ( ByNeeds, needs )
            ]
        )
        (D.field "slot" (D.list D.string))
        (D.field "flavor" (D.list D.string))
        (D.field "effort" (D.list D.string))
        (D.field "dietary" (D.list D.string))


summaryDecoder : Decoder Summary
summaryDecoder =
    let
        field name dec =
            D.map2 (|>) (D.field name dec)
    in
    D.succeed Summary
        |> field "slug" D.string
        |> field "title" D.string
        |> field "tested" D.string
        |> field "time" (D.field "active" D.int)
        |> field "time" (D.field "total" D.int)
        |> field "slot" (D.list D.string)
        |> field "course" D.string
        |> field "flavor" (D.list Flavor.decoder)
        |> field "method" D.string
        |> field "effort" D.string
        |> field "dietary" (D.list D.string)
        |> field "cuisine" (D.list D.string)
        |> field "keepsFor" (D.nullable keepsDecoder)
