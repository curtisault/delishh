module Search exposing (Entry, address, curated, index, run)

{-| The cross-document search index.

`Doc` renders whatever this returns; it does not know how a hit was
found. Keeping the index here — rather than inside a page — is what
lets one box in the contents rail search every document on the site,
which is the whole reason search is chrome and not a page feature
(`Doc.Chrome`).

**The index is written by hand, on purpose.** Elm cannot walk a
`List (Html msg)` to extract text, so a derived index would mean
either a build step or a parallel data model for every page. A hand
index costs one entry per section, and in exchange a `blurb` can say
what a section is *for* rather than repeating its first sentence.

**`terms` are words the section really says; `aliases` are words it
never does.** The alias is the whole point of curating — "privacy" is
what a reader types looking for a colophon that only ever says
"analytics". `tests/SearchTests.elm` holds both halves to the rendered
pages in both directions, because the moment an alias turns out to be
in the prose it is not an alias, it is a term, and the distinction has
stopped meaning anything.

Entries carry their own `path`, so a hit can cross documents: the
address is a real route plus a fragment, not a bare anchor. That is
also why `address` exists rather than callers concatenating — the day
a document moves, it moves here.

-}


{-| One searchable place on the site.

  - `page` — the document it lives on, shown as the hit's kicker
  - `label` — the section title, shown as the hit
  - `blurb` — one line of what the section is for
  - `path` / `anchor` — where the hit goes
  - `terms` — words the section's own prose uses
  - `aliases` — words it does not, that a reader would still type

-}
type alias Entry =
    { page : String
    , label : String
    , blurb : String
    , path : String
    , anchor : String
    , terms : List String
    , aliases : List String
    }


{-| A hit's address: the document's route, then the section's anchor.
-}
address : Entry -> String
address hit =
    hit.path ++ "#" ++ hit.anchor


{-| What `run` searches. Separate from `curated` so a future derived
source — a generated recipe index, say — can be appended here without
the hand-written half losing its name or its tests.
-}
index : List Entry
index =
    curated


{-| Every word of a query has to match, so a second word narrows the
result list rather than widening it.

Single characters are dropped before matching: a reader mid-word has
typed a stray letter, and treating it as a required term would empty
the results under their hands. Deliberately not fuzzy and not ranked —
the corpus is three documents, and cleverness here would only be a way
to get "print" wrong.

-}
run : String -> List Entry
run query =
    case terms_ query of
        [] ->
            []

        needles ->
            List.filter (matchesAll needles) index


terms_ : String -> List String
terms_ query =
    query
        |> String.toLower
        |> String.words
        |> List.filter (\word -> String.length word > 1)


matchesAll : List String -> Entry -> Bool
matchesAll needles entry =
    let
        haystack =
            String.toLower
                (String.join " "
                    (entry.label :: entry.blurb :: entry.terms ++ entry.aliases)
                )
    in
    List.all (\needle -> String.contains needle haystack) needles


{-| Every searchable section on the site, in page order. A section
without an entry is a section nobody can find, so adding one to a page
means adding it here.
-}
curated : List Entry
curated =
    [ { page = "DELISHH"
      , label = "What this is"
      , blurb = "The scaffold, and what the document format frames"
      , path = "/"
      , anchor = "sec-what"
      , terms = [ "scaffold", "masthead", "clause" ]
      , aliases = [ "boilerplate", "skeleton" ]
      }
    , { page = "DELISHH"
      , label = "The format"
      , blurb = "Where the boundary falls between Doc and a page"
      , path = "/"
      , anchor = "sec-format"
      , terms = [ "numbering", "rail", "kicker" ]
      , aliases = [ "layout", "wireframe" ]
      }
    , { page = "ABOUT"
      , label = "Who made it"
      , blurb = "The author, and who to ask about the rest"
      , path = "/about"
      , anchor = "sec-who"
      , terms = [ "author", "responsible" ]
      , aliases = [ "contact", "credits" ]
      }
    , { page = "ABOUT"
      , label = "Colophon"
      , blurb = "The type and the tooling, and what is never kept about a reader"
      , path = "/about"
      , anchor = "sec-colophon"
      , terms = [ "Archivo", "analytics", "Vite" ]
      , aliases = [ "privacy", "tracking" ]
      }
    , ds "Scope" "Which file owns which rule, and the amendment-first law" "sec-scope"
        [ "amendment", "silently" ]
        [ "changelog" ]
    , ds "The premise" "The in-fiction issuer, and the inversion that retargets the register" "sec-premise"
        [ "institution", "inversion", "deadpan" ]
        [ "mascot" ]
    , ds "Pillars" "The six, and the wear clause that keeps the screen immaculate" "sec-pillars"
        [ "placard", "cosplay" ]
        [ "skeuomorphic" ]
    , ds "References" "What the look is taken from, and what it refuses to be" "sec-refs"
        [ "HACCP", "vaporwave", "farmhouse" ]
        [ "pinterest" ]
    , ds "Colour" "An acid names a physical process; the light and dark strata" "sec-color"
        [ "sourdough", "magenta", "stratum" ]
        [ "hue", "swatch" ]
    , ds "Type" "The four voices, and how a quantity is set on the page" "sec-type"
        [ "ladder", "tabular", "fractional" ]
        [ "kerning", "ligature" ]
    , ds "The document" "The ten blocks, in the one order every recipe wears" "sec-document"
        [ "halftone", "specimen", "materials" ]
        [ "nutrition" ]
    , ds "The index" "A manifest rather than a gallery; filters tag instead of hiding" "sec-index"
        [ "manifest", "retrieval", "lockout" ]
        [ "pagination" ]
    , ds "Cook mode" "The arm's-length constraint: wet hands, bad light, a pan on the heat" "sec-cook"
        [ "greasy", "awake", "pointer" ]
        [ "voice", "dictation" ]
    , ds "Print" "The issued sheet: the ink budget, the break law, traceability" "sec-print"
        [ "toner", "photocopy", "knockout" ]
        [ "pdf" ]
    , ds "Motion" "The register opens empty, and the one exception that earned a line" "sec-motion"
        [ "ambient", "jelly", "timer" ]
        [ "parallax", "carousel" ]
    , ds "Lexicon" "The banned and approved word fields, enforced in the test suite" "sec-lexicon"
        [ "vocabulary", "linter", "foolproof" ]
        [ "thesaurus" ]
    , ds "Hard constraints" "The bars that are never waived, at any density" "sec-constraints"
        [ "WCAG", "JavaScript" ]
        [ "lighthouse" ]
    , ds "Governance" "Dated amendments, benching, and the first five things to build" "sec-governance"
        [ "bench", "token" ]
        [ "roadmap" ]
    ]


{-| A DS-01 section. The page and path are the same for all fourteen,
and repeating them eighteen lines apart is how one of them ends up
wrong.
-}
ds : String -> String -> String -> List String -> List String -> Entry
ds label blurb anchor terms aliases =
    { page = "DS-01"
    , label = label
    , blurb = blurb
    , path = "/design-standard"
    , anchor = anchor
    , terms = terms
    , aliases = aliases
    }
