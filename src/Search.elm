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

**The front page is not in here, and that is not an oversight.** `/`
is the shelf now, and a shelf is not a prose document: it has no
numbered sections to address and wears no `Doc` chrome to search from.
It carries its own search, over recipes rather than over sections —
a different index answering a different question.
-}
curated : List Entry
curated =
    [ { page = "ABOUT"
      , label = "What this is"
      , blurb = "A personal archive rather than a publication, and who to ask"
      , path = "/about"
      , anchor = "sec-who"
      , terms = [ "archive", "markdown", "author" ]
      , aliases = [ "contact", "credits" ]
      }
    , { page = "ABOUT"
      , label = "Colophon"
      , blurb = "The four voices, the tooling, and what is never kept about a reader"
      , path = "/about"
      , anchor = "sec-colophon"
      , terms = [ "Archivo", "analytics", "tracking" ]
      , aliases = [ "privacy", "cookies" ]
      }
    , ds "Scope" "Which file owns which rule, and the amendment-first law" "sec-scope"
        [ "amendment", "silently", "Enforcement" ]
        [ "changelog", "roadmap" ]
    , ds "Premise" "Loud shelf, quiet page, ink sheet — the split everything follows from" "sec-premise"
        [ "sticker", "notebook", "serial" ]
        [ "mascot", "brand" ]
    , ds "Pillars" "The six claims, and what each one forbids" "sec-pillars"
        [ "cosplay", "silk-screened", "gloss" ]
        [ "skeuomorphic", "flourish" ]
    , ds "References" "What the look is taken from, and what it refuses to be" "sec-refs"
        [ "vaporwave", "farmhouse", "grotesk" ]
        [ "pinterest", "moodboard" ]
    , ds "Colour" "Where acid runs loud, and where it narrows to a physical state" "sec-color"
        [ "confetti", "volt", "contrast" ]
        [ "hue", "swatch" ]
    , ds "Type" "The four voices, and how a quantity is set on the page" "sec-type"
        [ "glyph", "tabular", "authoritative" ]
        [ "kerning", "ligature" ]
    , ds "The document" "One markdown file, its frontmatter schema, and the nine blocks" "sec-document"
        [ "halftone", "frontmatter", "placeholder" ]
        [ "nutrition", "database" ]
    , ds "Browse" "Four ways in, and filters that tag instead of hiding" "sec-browse"
        [ "scannable", "dictionary", "facet" ]
        [ "pagination", "carousel" ]
    , ds "Cook mode" "The arm's-length constraint: wet hands, bad light, a pan on the heat" "sec-cook"
        [ "awake", "pointer", "stamp" ]
        [ "dictation", "timer" ]
    , ds "Print" "Black ink, four templates, and a footer that knows what it is" "sec-print"
        [ "knockout", "booklet", "laser" ]
        [ "pdf", "typst" ]
    , ds "Motion" "Playful on the shelf, still on the page, ambient nowhere" "sec-motion"
        [ "ambient", "detent", "overshoot" ]
        [ "parallax", "carousel" ]
    , ds "Voice" "Warm where it sells nothing, exact where it counts" "sec-voice"
        [ "register", "engagement", "exempt" ]
        [ "thesaurus", "grammar" ]
    , ds "Hard constraints" "The bars that are never waived, at any density" "sec-constraints"
        [ "WCAG", "zoom", "self-hosted" ]
        [ "lighthouse", "audit" ]
    , ds "Governance" "Dated amendments, benching, and the first five things to build" "sec-governance"
        [ "bench", "amendment", "token" ]
        [ "roadmap", "sprint" ]
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
