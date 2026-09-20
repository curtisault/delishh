module Page.DesignStandard exposing (view)

{-| DS-01 — the aesthetic contract for delishh.

The prose of record is `docs/design-standard.md`; this module is that
document rendered through the house chrome (`Doc`). A self-contained
copy is also published at `/design-standard.html` — that one is a
frozen artifact with its fonts inlined, kept so the standard can be
read and shared without the app booting. **When they disagree, the
markdown governs.**

**Section numbers are positional.** `Doc` numbers sections from their
order in this list, so §10 is print because print is tenth. Reordering
this list renumbers the document and silently repoints every in-prose
`§` — grep for it before moving anything, and keep `Search.index` in
step with the anchors.

-}

import Doc
import Html exposing (Html, code, div, h3, li, p, span, strong, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (class)



-- THE DOCUMENT


view : Doc.Chrome msg -> Html msg
view chrome =
    Doc.view (doc chrome)


doc : Doc.Chrome msg -> Doc.Config msg
doc chrome =
    { tag = "DS-01"
    , kicker = "PROOFWORKS CULINARY STANDARDS"
    , rev = "REV 1"
    , revDate = "2026-09-19"
    , titleLines = [ "The design", "standard" ]
    , standfirst = "A recipe archive — browse, search, filter, print — built in the acid-Y2K institutional idiom. This document owns look, feel and voice; where a mechanic and the aesthetic disagree, we redesign the mechanic's presentation, never the aesthetic."
    , sections =
        [ scope
        , premise
        , pillars
        , references
        , colour
        , typography
        , document
        , index
        , cookMode
        , print
        , motion
        , lexicon
        , constraints
        , governance
        ]
    , footNote =
        [ text "PROOFWORKS CULINARY STANDARDS is an in-fiction issuer and nothing else — not the name of this site, this repository, or this domain. Derived from CRYOVAULT, DESIGN-REQUIREMENTS §§1–12." ]
    , chrome = chrome
    }



-- 01


scope : Doc.Section msg
scope =
    { anchor = "sec-scope"
    , tocLabel = "Scope"
    , title = "Scope, and what to put in which file"
    , intent = "Which file owns which rule"
    , body =
        Doc.Clauses
            [ para
                [ t "This standard covers a single-operator recipe archive: a place to keep recipes, find them again, and print them. It is derived from the cryovault aesthetic — "
                , b "acid-Y2K graphic realism: flat, printed-looking vector graphics applied with total confidence to a grounded, physical world"
                , t " — and it inherits that project's discipline wholesale while replacing its subject and its affect."
                ]
            , div []
                [ para [ t "Codify it as separate documents with clean ownership, because a single DESIGN.md always collapses into a pile of unenforceable opinions. The split below is what keeps a rule findable a year later." ]
                , grid
                    [ ( "File", "Owns" ) ]
                    [ ( "DECISIONS.md", "Every ruled mechanic, constant and formula, newest-first dated timeline; dated amendment blocks override the prose beneath them" )
                    , ( "docs/design-standard.md", "Look, feel, voice, colour, type, motion — this document" )
                    , ( "DESIGN-PRINCIPLES.md", "Layout and structure, independent of dressing" )
                    , ( "PRINT.md", "The issued sheet: ink budget, break law, traceability" )
                    , ( "RECIPE-SCHEMA.md", "The ten blocks as a data contract, required vs. optional" )
                    , ( "LEXICON.md", "Controlled vocabulary — word fields, canonical units, surface grammars. Enforced in CI" )
                    ]
                ]
            , para
                [ b "If build reality contradicts a decided rule, write the dated amendment first and change the code second."
                , t " Never diverge silently. This one rule is worth more than any styling decision in the document."
                ]
            ]
    }



-- 02


premise : Doc.Section msg
premise =
    { anchor = "sec-premise"
    , tocLabel = "The premise"
    , title = "The premise, and the inversion that makes it work"
    , intent = "Why there is an institution at all"
    , body =
        Doc.Clauses
            [ para
                [ b "The one-line vibe: "
                , t "a test kitchen's issuing office — clinical, acid-bright, and completely certain — where every recipe is a controlled document, and the only warm thing on the page is your own handwriting."
                ]
            , div []
                [ h3 [] [ text "The institution" ]
                , para
                    [ t "Give the archive an in-fiction issuer whose voice the interface speaks in. This standard uses "
                    , b "PROOFWORKS CULINARY STANDARDS"
                    , t " — proof as in dough, as in a printer's proof, as in proven — under the mark «NOTHING LEAVES UNTESTED». Pick your own; the requirement is that one exists."
                    ]
                , why "The aesthetic's whole thesis is institutional branding that outlived the institution. Without an institution, the placards and serial plates are cosplay — you are just putting hazard stripes on a lasagna. The fiction costs one paragraph and then pays for every string in the product, because you never again have to decide what tone an empty state takes."
                , para
                    [ b "The issuer is an in-fiction company only."
                    , t " It is not the name of the site, the repository, or the domain — those are delishh. The moment the two collapse, the joke becomes a brand and the brand stops being funny."
                    ]
                ]
            , div []
                [ h3 [] [ text "The inversion" ]
                , para
                    [ t "Cryovault runs the flat institutional register toward dread — the horror is in the mundanity, and a line like "
                    , mono "ANOMALOUS READ ACTIVITY ACKNOWLEDGED. NO ACTION REQUIRED."
                    , t " is doing the work of a jump scare. A recipe archive runs the identical machinery toward the opposite end, and this single move is what keeps the aesthetic from being creepy about dinner."
                    ]
                , para
                    [ b "Clinical menace becomes clinical care."
                    , t " A kitchen that documents its own failures, states the temperature it actually means, and admits which revision was too pale is not being cold — it is being more generous than any recipe blog has ever been. Every formal device survives the translation. Only the affect is retargeted."
                    ]
                , para
                    [ t "And the register earns the archive's one human voice. Because the system is deadpan everywhere else, a note in a serif, in sentence case, in the first person lands with a force it could never have on a page that was already chatty. "
                    , b "The institutional voice is the setup; your handwriting is the payoff."
                    , t " Protect that ratio; it is the emotional engine of the whole design."
                    ]
                ]
            ]
    }



-- 03


pillars : Doc.Section msg
pillars =
    { anchor = "sec-pillars"
    , tocLabel = "Pillars"
    , title = "Design pillars"
    , intent = "Six, and the wear clause"
    , body =
        Doc.Clauses
            [ pillar "Graphic realism"
                [ t "Every element reads as a "
                , b "printed or silk-screened artifact"
                , t ": a jar label, a spec plate, a safety placard, a shipping tag, a tamper seal, a nutrition panel. Flat colour, hard edges, no bevels, no soft shadows. Depth comes from layering and overlap, never from lighting. If it could not plausibly be screen-printed onto a stainless bench, it does not belong."
                ]
            , pillar "Acid on cold neutral"
                [ t "The field is cold and neutral; the signal is acid, at roughly "
                , b "90% neutral to 10% accent"
                , t ". Acid is applied like tape or warning paint, never ambient. When everything glows, nothing does. This is a genuine discipline problem for a food site, where the instinct is to make the food the colour — resist it: the food supplies warmth, in one photograph per document (§7), and the interface stays cold around it."
                ]
            , pillar "Clinical care"
                [ t "The tone is a test kitchen's internal documentation: precise, procedural, unhurried, and entirely unsentimental about what goes wrong. The UI never raises its voice and never sells. "
                , mono "PAST 190 °C IT DOES NOT COME BACK."
                ]
            , pillar "The recipe is an object"
                [ t "A recipe is not a post and not a card in a feed. It is a "
                , b "controlled document"
                , t " with a serial, a revision number, a tested-on date, a yield, and a revision history. It can be superseded. It can be reissued. Treat it with the gravity of a part drawing and the interface writes itself."
                ]
            , pillar "Objects inform you of their use"
                [ t "The verb is stenciled on the thing. A step states its own temperature and its own doneness cue on its own line — no tooltip, no hover, no “see notes below”. A filter chip states what it excludes. A pan is named with its diameter and its material because those change the result. "
                , b "If an element needs external explanation, its design has failed."
                ]
            , div []
                [ h3 [] [ text "Designed, never broken — and the wear clause" ]
                , para [ t "The interface is immaculate by intent and stays immaculate. No simulated coffee rings, no torn-paper edges, no distressed textures, no “vintage recipe card”. That is nostalgia cosplay and it is the single most common failure mode of recipe-site design." ]
                , why "The screen never ages. The sheet does. Wear is real or it is not present — and the printout is where this system lets reality in. Your kitchen supplies the stains; the software's job is to look like the day it was issued and to reprint on demand."
                ]
            ]
    }



-- 04


references : Doc.Section msg
references =
    { anchor = "sec-refs"
    , tocLabel = "References"
    , title = "Reference points, and the anti-references"
    , intent = "What to take, what we are not"
    , body =
        Doc.Panel
            [ grid
                [ ( "Source", "What to take" ) ]
                [ ( "Test-kitchen documentation", "The procedural voice, stated tolerances, and the published failure mode — a recipe as a tested procedure rather than an anecdote" )
                , ( "Food-safety placards & HACCP", "Critical limits, hold temperatures, the flat affect of a rule that exists because someone got hurt" )
                , ( "Industrial food labelling", "Nutrition panels, allergen declarations, lot codes, date stamps — dense typographic tables that are legally obliged to be legible" )
                , ( "Spice-jar and seed-catalogue labels", "Small-format type discipline; a whole taxonomy fitting on 40 mm" )
                , ( "The Designers Republic / Wipeout", "Fake institutions treated with real brand discipline; aggressive grotesk typography" )
                , ( "Y2K hardware & software", "Translucent plastics as colour reference only; chunky progress bars; installer-layout density" )
                ]
            , h3 [] [ text "Explicitly not" ]
            , bullets
                [ [ b "Not a food blog."
                  , t " No origin story above the fold, no SEO preamble, no “jump to recipe” button — which exists only to apologise for a layout that should not have been built."
                  ]
                , [ b "Not rustic farmhouse."
                  , t " No kraft paper, twine, chalkboard, reclaimed wood, or handwriting fonts. Warmth comes from the content, not the texture."
                  ]
                , [ b "Not dark-moody restaurant photography."
                  , t " Our light is laboratory light and the photograph is a record, not a seduction."
                  ]
                , [ b "Not a minimal Scandinavian recipe app."
                  , t " Our spareness is the result of a density discipline, not the whole idea. Eight type sizes on one surface is allowed if every one of them means something."
                  ]
                , [ b "Not vaporwave, and never ironic."
                  , t " The institution believes in itself completely."
                  ]
                ]
            ]
    }



-- 05


colour : Doc.Section msg
colour =
    { anchor = "sec-color"
    , tocLabel = "Colour"
    , title = "Colour — an acid names a physical process"
    , intent = "The rule that decides whether this transfers"
    , body =
        Doc.Clauses
            [ para
                [ t "In cryovault an accent colour names a currency; the colour carries information, which is why the palette never reads as decoration. Port the "
                , em_ "rule"
                , t ", not the mapping. "
                , b "Each acid names a thermal or biological state of the food."
                , t " Not a cuisine, not a category, not a meal slot. The instant you colour-code “Italian” against “Thai”, the system is decoration again and the discipline is gone."
                ]
            , div []
                [ grid
                    [ ( "Token", "Names" ) ]
                    [ ( "--acid-volt #B9EE00", "THE ACTIONABLE — the primary verb, the active step, the scale control, the print button. One per surface, and it is the loudest thing there" )
                    , ( "--acid-cyan #00C8DC", "COLD CHAIN — chill, freeze, cure, set, raw, hold at 4 °C" )
                    , ( "--acid-orange #FF6A00", "HEAT AND HAZARD — fry, sear, sugar work, smoke point, hot fat, anything that burns you" )
                    , ( "--acid-mag #FF2E88", "LIVE — ferment, culture, proof, brine, anything where something is alive in the jar" )
                    ]
                , why "Magenta is the anomaly colour in the source project — “something woke up”. A sourdough starter is literally that. This is the mapping that confirmed the translation was real rather than clever: the food world supplies a true referent for every accent the game invented."
                ]
            , bullets
                [ [ b "One acid dominates per surface; a second may cameo; never three."
                  , t " A recipe document takes the acid of its dominant method."
                  ]
                , [ b "Acid never lands on a quantity."
                  , t " Amounts, temperatures and times are set in ink or frost — the dazzle lives in the labels and the structure, never in the data. This is the rule that makes a dense page trustworthy."
                  ]
                , [ b "Information is never colour-only."
                  , t " A thermal class carries its word as well as its mark. Required for colour-blind readers, and it is also exactly what makes the black-and-white printout work (§10) — one rule, two payoffs."
                  ]
                , [ b "Frost and ice live in the neutral family"
                  , t " (white-cyan), so acid always reads as human-applied marking rather than as the food itself."
                  ]
                ]
            , div []
                [ h3 [] [ text "Light and dark are strata, not themes" ]
                , para
                    [ t "Cryovault darkens its field as the player descends, swapping text and accent tokens per stratum. There is no descent here, so "
                    , b "re-host that machinery on the viewer's colour scheme"
                    , t ": light is the lit surface — clinical armour-plastic with ink text; dark is the deep stratum — near-black with acid at full strength. The token names and the swap mechanism are identical; only the trigger changed."
                    ]
                , para
                    [ b "Volt-on-light fails contrast at text size."
                    , t " On a light field, acid appears as blocks and fills with ink text — never as small coloured type. Mint darkened text variants ("
                    , mono "--volt-tx #3E5200"
                    , t ", "
                    , mono "--cyan-tx #05555F"
                    , t ", "
                    , mono "--orange-tx #8C3200"
                    , t ", "
                    , mono "--mag-tx #9C0B4A"
                    , t ") for the cases that need coloured words, and verify every pair at 4.5:1."
                    ]
                ]
            ]
    }



-- 06


typography : Doc.Section msg
typography =
    { anchor = "sec-type"
    , tocLabel = "Type"
    , title = "Type, and the measurement ladder"
    , intent = "Four voices; how a number is set"
    , body =
        Doc.Clauses
            [ div []
                [ para [ t "Four voices, strictly cast. A glyph's typeface tells you what kind of information it is, every time." ]
                , grid
                    [ ( "Voice", "Used for" ) ]
                    [ ( "Display — Archivo Expanded 700", "Plates, titles, section stencils" )
                    , ( "Procedure — Inter 500", "Every word you read while cooking" )
                    , ( "Data — JetBrains Mono 400/700", "Every number that means something" )
                    , ( "Human — Instrument Serif 400", "Your notes, and nothing else" )
                    ]
                , para
                    [ t "Two deliberate changes from the source casting. First, "
                    , b "the body voice is promoted"
                    , t " — invisible micro-copy in the game, but here it carries procedure read at arm's length in bad light with wet hands, so it is chosen for legibility at distance and given real size. Second, "
                    , b "the human voice is promoted too"
                    , t " — rare-by-contract in the game, recurrent here; its contract changes from “rare” to never used for procedure. The game's fifth voice is cut: a fifth voice is a cost, and this product has nothing for it to say."
                    ]
                , para
                    [ t "Repo note: "
                    , mono "public/fonts/"
                    , t " currently ships Archivo Expanded and JetBrains Mono only. Inter and Instrument Serif must be added, with their OFL files, before this section is fully in force."
                    ]
                ]
            , div []
                [ h3 [] [ text "The measurement ladder" ]
                , para [ t "Quantities need as much specification as colour does, and almost no recipe site has any. Rule the ladder once and enforce it in code." ]
                , bullets
                    [ [ b "Mass is authoritative; volume is a convenience"
                      , t " and is printed second, dimmed. Grams as integers; no 142.5 g."
                      ]
                    , [ b "Fractions are glyphs"
                      , t " (¾ tsp), never decimals, for volume. Decimals are for mass and temperature only."
                      ]
                    , [ b "Scaling rounds per unit"
                      , t " — to 5 g above 100 g, to ¼ tsp, to whole grinds — and never produces a fractional egg, can, or clove. When it would, the system emits a note instead: "
                      , mono "SCALED ×1.5 — USE 2 EGGS, HOLD BACK 20 g OF THE WHITE."
                      , t " An honest note beats a false number."
                      ]
                    , [ b "Temperatures are dual and consistently ordered"
                      , t " (180 °C / 356 °F), authoritative unit first."
                      ]
                    , [ b "The clock is never alone."
                      , t " Every duration carries its tell: "
                      , mono "6–9 MIN · UNTIL THE EDGES RUN CLEAR"
                      , t ". Time is the least reliable variable in any kitchen, and a recipe that gives only a number is withholding the thing you actually need."
                      ]
                    , [ b "Tabular numerals everywhere"
                      , t ", and a running timer must never shift layout by a pixel as it counts."
                      ]
                    ]
                ]
            ]
    }



-- 07


document : Doc.Section msg
document =
    { anchor = "sec-document"
    , tocLabel = "The document"
    , title = "The recipe document — ten blocks, fixed order"
    , intent = "The schema everything else is a view of"
    , body =
        Doc.Clauses
            [ div []
                [ para [ t "A controlled document has a fixed form. Every recipe carries the same blocks in the same order, so you learn where to look exactly once and never hunt again. Blocks may be empty; they may not be reordered." ]
                , grid
                    [ ( "Block", "Carries" ) ]
                    [ ( "01 Title plate", "Name, serial, revision, tested-on date, yield, active and total time, thermal class" )
                    , ( "02 Specimen plate", "One photograph. One." )
                    , ( "03 Bill of materials", "Ingredients, grouped by sub-preparation, mass-first, scalable" )
                    , ( "04 Equipment", "Named with the dimensions and materials that change the result" )
                    , ( "05 Procedure", "Numbered steps, each with its own tell" )
                    , ( "06 Tolerances", "The critical limits — the temperatures and states that decide success" )
                    , ( "07 Failure modes", "What goes wrong, what causes it, whether it can be saved" )
                    , ( "08 Holding & storage", "Keeps, freezes, reheats — the cold chain" )
                    , ( "09 The note", "Yours. Serif, sentence case, first person, unedited" )
                    , ( "10 Revision history", "What changed and when" )
                    ]
                ]
            , para
                [ b "Above the fold is the bill of materials, not prose."
                , t " A returning cook needs quantities; a first-time cook needs to know what to buy. Neither needs a paragraph. The note is at the bottom on purpose — it is the reward for having read the document, not the introduction to it."
                ]
            , para [ t "Blocks 06 and 07 are the ones conventional recipe sites omit, and they are the reason to build this at all. A published failure mode is the highest-value sentence in any recipe. The worked example is SPEC 0047, SALTED CARAMEL, in docs/design-standard.md — build it first and keep it as the bench specimen forever." ]
            , pillar "The photograph"
                [ t "One per document, treated as a "
                , b "record photograph"
                , t " — a specimen plate, not a glamour shot. Clamp it into the cold neutral family or render it as a coarse halftone: dither is already in the motif vocabulary, it keeps the payload tiny, and it stops a warm photo from blowing the 90/10 acid budget on its own. If a recipe has no photograph the plate is absent — never a placeholder, never a grey box."
                ]
            ]
    }



-- 08


index : Doc.Section msg
index =
    { anchor = "sec-index"
    , tocLabel = "The index"
    , title = "The index — a manifest, not a gallery"
    , intent = "Browse, search, filter"
    , body =
        Doc.Clauses
            [ para
                [ b "The index is a dense ledger of rows, not a grid of photographs."
                , t " A photo grid optimises for discovery-by-appetite, which is what you want when selling recipes to strangers. A personal archive is used for retrieval — you already know the thing exists and you want it in four seconds — and retrieval wants scannable text. The photographs live on the documents, one each, where they are evidence."
                ]
            , bullets
                [ [ b "Filters narrow; they never hide the reason."
                  , t " An excluded recipe stays on the page, tagged with the filter that excluded it. Lockout tags, not disappearance — a silently-vanished result teaches you to distrust your own archive."
                  ]
                , [ b "Search is a query line"
                  , t ", monospace, focused on load. Matches are knocked out as ink blocks, not washed in yellow."
                  ]
                , [ b "The facets come from the document blocks"
                  , t " (§7), which is why the schema is worth writing first: thermal class, active time, total elapsed including holds, equipment required, keeps or freezes, provenance."
                  ]
                , [ b "Active time and total elapsed are different facets and both are shown."
                  , t " A twelve-hour cure is not a twenty-minute recipe, and collapsing the two is the most common lie in recipe software."
                  ]
                , [ b "Default sort is last tested"
                  , t ", not alphabetical. The archive's own working order is more useful than the dictionary's."
                  ]
                , [ b "Zero results is designed copy with an action"
                  , t ", in voice: "
                  , mono "NO RECORDS MATCH. NEAREST BY TIME ▸"
                  , t ". A dead end is a design failure, not an edge case."
                  ]
                ]
            ]
    }



-- 09


cookMode : Doc.Section msg
cookMode =
    { anchor = "sec-cook"
    , tocLabel = "Cook mode"
    , title = "Cook mode — the arm's-length constraint"
    , intent = "Wet hands, bad light, a pan on the heat"
    , body =
        Doc.Clauses
            [ para [ t "Reading a recipe while cooking is a different activity from browsing one, and it imposes constraints no other screen in the product has: you are two to three feet away, your hands are wet or greasy or full, the light is bad, and you are under time pressure with something on the heat." ]
            , bullets
                [ [ b "Body type at 20px equivalent or larger"
                  , t ", and the step number larger again. This is the one place the type scale steps up rather than down."
                  ]
                , [ b "No hover-only information, anywhere."
                  , t " There may be no pointer at all, and if there is one it is attached to a dirty hand. Everything a step needs is printed on the step."
                  ]
                , [ b "Steps stamp when complete; they never grey out."
                  , t " A completed step must stay fully legible — you will re-read it to check what you already did. Tagged, not disabled."
                  ]
                , [ b "Tap targets at 2.75rem minimum", t ", scaling with text." ]
                , [ b "Hold the screen awake"
                  , t " while cook mode is open, and say so on screen. Silent power management is a system lying about its status."
                  ]
                , [ b "Scaling is set before you start and displayed permanently"
                  , t " in the header. A scaled document that does not say it is scaled is dangerous."
                  ]
                ]
            ]
    }



-- 10


print : Doc.Section msg
print =
    { anchor = "sec-print"
    , tocLabel = "Print"
    , title = "Print — the issued sheet"
    , intent = "The aesthetic's native output"
    , body =
        Doc.Clauses
            [ why "This is not a concession to an old habit. The entire aesthetic is built out of printed artifacts — decals, placards, serial plates, registration marks — and a recipe archive is one of the very few products whose users genuinely print. Everything the style already believes about paper finally gets to be literally true. Design the sheet first and let the screen be the proof of it."
            , div []
                [ h3 [] [ text "The format" ]
                , bullets
                    [ [ b "One sheet, portrait."
                      , t " If a recipe cannot fit, that is a signal about the recipe, not about the paper. Where it must break: never between a heading and its table, never inside a step, never orphan the failure modes."
                      ]
                    , [ b "Margins in physical units", t ", sized for the sheet to be handled at the edge and for a clip to hold it." ]
                    , [ b "Body at 11pt minimum, step numbers at 14pt"
                      , t " — larger than the screen, because the sheet sits on a counter and you are standing."
                      ]
                    ]
                ]
            , div []
                [ h3 [] [ text "Ink discipline" ]
                , bullets
                    [ [ b "Black plus one screen tint. That is the whole budget."
                      , t " Acid does not survive a monochrome laser and wastes colour toner on a page that will be thrown away. A volt fill becomes a 100% black block with knockout text; hazard bands become 45° hatching; the thermal class prints as a reversed word."
                      ]
                    , [ b "No reversed body type."
                      , t " Knockout survives on a heading and fills into an unreadable smear at 9pt after one photocopy."
                      ]
                    , [ b "The photograph prints as a coarse halftone or not at all."
                      , t " A 300-dpi photo on a home laser is a grey smear that eats the toner budget."
                      ]
                    ]
                ]
            , div []
                [ h3 [] [ text "Traceability — the fiction paying rent" ]
                , para
                    [ t "The footer carries the serial, the revision, the scale factor it was printed at, the date it was pulled, and a short URL with a data matrix. "
                    , b "A sheet found in a drawer in three years should be able to tell you what it is and how out of date it is."
                    , t " This is the single most useful thing the institutional conceit produces, and no food blog has ever done it."
                    ]
                , para
                    [ b "The sheet is designed to be destroyed."
                    , t " Reprinting is the intended lifecycle, not a failure — which is exactly why it must be cheap in ink, one page, and traceable back to its current revision. It also resolves the wear clause (§3.6) cleanly: the software never simulates wear, because the real artifact is out there getting ruined properly."
                    ]
                ]
            ]
    }



-- 11


motion : Doc.Section msg
motion =
    { anchor = "sec-motion"
    , tocLabel = "Motion"
    , title = "Motion — the register opens empty"
    , intent = "Adopt the mechanism, not the movers"
    , body =
        Doc.Clauses
            [ para
                [ t "Cryovault governs motion with a numbered register: every piece of ambient movement needs its own dated entry written before it ships, and a retired entry banks no permission for the next one. "
                , b "Adopt the mechanism; start the list at zero."
                , t " A game wants ambience. A reference document read with a hot pan in one hand wants to hold absolutely still. The marquees, the drifting rails, the breathing glow — none of it ports, and saying so explicitly is worth more than any of it."
                ]
            , bullets
                [ [ b "Zero ambient motion.", t " Nothing loops, drifts, breathes, or pulses." ]
                , [ b "Sanctioned exception 01 — the step timer."
                  , t " A running duration is functional readout, not decoration: the number is the information, so it is allowed to change. Tabular numerals, and it must not shift layout by a pixel as it counts."
                  ]
                , [ b "State changes the user caused"
                  , t " may transition — under 150 ms, stepped easing, no springs, no bounce, no overshoot. Machinery indexing, not jelly."
                  ]
                , [ b "Calm mode kills everything site-wide"
                  , t " and prefers-reduced-motion implies calm. New motion is authored inside "
                  , mono "@media (prefers-reduced-motion: no-preference)"
                  , t " so reduced-motion users never have motion defined at all, rather than merely overridden."
                  ]
                ]
            ]
    }



-- 12


lexicon : Doc.Section msg
lexicon =
    { anchor = "sec-lexicon"
    , tocLabel = "Lexicon"
    , title = "Lexicon — the controlled vocabulary"
    , intent = "The highest-leverage rule, and the fastest to erode"
    , body =
        Doc.Clauses
            [ div []
                [ para [ t "Put the word rules in their own file and enforce them in CI. Of everything in this standard the vocabulary is the highest-leverage and the fastest to erode, because copy is written in a hurry and nobody reviews a tooltip." ]
                , grid
                    [ ( "Banned", "Because" ) ]
                    [ ( "delicious, yummy, perfect, amazing", "Enthusiasm substituted for information. The document does not have opinions about whether you will enjoy it" )
                    , ( "game-changer, crowd-pleaser, the best ___ ever", "Marketing register. The institution does not sell" )
                    , ( "simply, just, easy, foolproof", "They minimise a difficulty the reader is currently having. “Simply” has never once helped anyone" )
                    , ( "toss, whip up, throw together", "Imprecise verbs where the procedure needs a real one" )
                    , ( "Emoji; exclamation marks in system voice", "Wrong register, and they break the type casting" )
                    , ( "The origin-story preamble", "The note block exists for exactly this, at the bottom, where it is a reward" )
                    ]
                ]
            , div []
                [ h3 [] [ text "The approved field, and the grammars" ]
                , para [ t "Procedural verbs with defined meanings (fold, beat, swirl, render, slake); tolerances; tells; failure modes; holds. Canonical unit spellings, fixed once. Surface grammars, fixed once and reused everywhere:" ]
                , para
                    [ mono "SPEC 0047 // REV 3 // TESTED 2026-03-11"
                    , t " · "
                    , mono "YIELD 340 g // 8 SERVINGS"
                    , t " · "
                    , mono "HOLD 4 °C // KEEPS 14 D"
                    ]
                ]
            , bullets
                [ [ b "The note is exempt entirely."
                  , t " First person, sentence case, feeling, digression — all permitted, none edited toward house voice. The linter does not read it. Sanding down the one human voice on the page to match the machine would destroy the thing the design exists to frame."
                  ]
                , [ b "The system never lies about status."
                  , t " “Ready in 20 minutes” on a recipe with an overnight cure is a lie even though every individual number is true. Total elapsed always includes holds. The company is deadpan; it is not dishonest."
                  ]
                ]
            ]
    }



-- 13


constraints : Doc.Section msg
constraints =
    { anchor = "sec-constraints"
    , tocLabel = "Constraints"
    , title = "Hard constraints — never waived"
    , intent = "The bars that hold at any density"
    , body =
        Doc.Panel
            [ bullets
                [ [ b "Dense but never broken.", t " No overlapping text, no clipped quantities, no unreadable state, at any density." ]
                , [ b "WCAG AA for all functional text", t ", measured on its actual background, in both themes. Bold is not legible; contrast is." ]
                , [ b "Information is never carried by colour alone", t ", on screen or on paper." ]
                , [ b "≤ 3 Hz flashing; calm mode; prefers-reduced-motion respected." ]
                , [ b "User text scaling respected"
                  , t " — no px font sizes, breakpoints in rem, and the never-broken bar holds at 200% zoom and at a raised browser default font. Two different mechanisms; both must work."
                  ]
                , [ b "Reading and printing work with JavaScript off."
                  , t " A recipe is a document. Scaling and cook mode may be enhancements; the text, the quantities, and the print stylesheet may not be."
                  ]
                , [ b "Fast on a phone in a kitchen."
                  , t " The acid layer is CSS and SVG, never image payloads; at most one photograph per document, lazily loaded."
                  ]
                , [ b "Self-hosted assets only."
                  , t " No font CDNs, no third-party analytics on a document you may want to read in ten years."
                  ]
                ]
            ]
    }



-- 14


governance : Doc.Section msg
governance =
    { anchor = "sec-governance"
    , tocLabel = "Governance"
    , title = "Governance, and where to start"
    , intent = "How the standard survives the build"
    , body =
        Doc.Clauses
            [ bullets
                [ [ b "Amendments are dated blocks, not rewrites."
                  , t " A new ruling is appended with its date and overrides the prose beneath it. The superseded reasoning stays readable, because “why did we stop doing it that way” is the question you will actually have."
                  ]
                , [ b "Bench alternatives, then rule from the bench."
                  , t " Build three candidate treatments side by side on identical content behind a flag, look at them, pick one, and record what the two rejected ones were. Deciding from a description is how you end up with the thing you already imagined."
                  ]
                , [ b "Constants live in one file"
                  , t " — tokens for colour and type, and a single module for anything that is a rule rather than a rendering. Retune there and nowhere else."
                  ]
                , [ b "The word linter runs in the test suite", t ", not in a review checklist." ]
                ]
            , div []
                [ h3 [] [ text "The first five things to build" ]
                , bullets
                    [ [ b "The token file.", t " Both themes, all four acids, every text variant, with the measured contrast ratios in a comment beside each pair." ]
                    , [ b "The recipe schema.", t " Ten blocks, fixed order, required vs. optional. Everything else in the product is a view of this." ]
                    , [ b "One real recipe, end to end.", t " SPEC 0047. A hard one, with genuine tolerances and failure modes. It is the bench specimen forever." ]
                    , [ b "The print stylesheet", t " — before the browse page, not after. If the sheet is right, the screen has very little left to get wrong." ]
                    , [ b "The lexicon and its linter", t ", while the corpus is small enough that fixing every violation takes an afternoon." ]
                    ]
                ]
            ]
    }



-- BUILDING BLOCKS
--
-- Local to this page on purpose. The moment one of these is wanted by
-- a second document it moves to a shared module — but a helper that
-- lives in `Doc` is a helper `Doc` has to have an opinion about, and
-- `Doc` frames documents rather than styling their insides.


t : String -> Html msg
t =
    text


b : String -> Html msg
b copy =
    strong [] [ text copy ]


em_ : String -> Html msg
em_ copy =
    Html.em [] [ text copy ]


mono : String -> Html msg
mono copy =
    code [ class "mono" ] [ text copy ]


para : List (Html msg) -> Html msg
para =
    p []


bullets : List (List (Html msg)) -> Html msg
bullets items =
    ul [ class "doc-list" ] (List.map (li []) items)


{-| The rationale voice: the serif aside that says why a rule exists.
Sentence case, and the one place on the page the system stops giving
orders.
-}
why : String -> Html msg
why copy =
    p [ class "doc-why" ] [ text copy ]


{-| A pillar: its own subhead, then the claim.
-}
pillar : String -> List (Html msg) -> Html msg
pillar title copy =
    div []
        [ h3 [] [ text title ]
        , p [] copy
        ]


{-| A two-column reference table. Wide content scrolls in its own
container so the sheet never scrolls sideways.
-}
grid : List ( String, String ) -> List ( String, String ) -> Html msg
grid headers rows =
    div [ class "doc-scroller" ]
        [ table [ class "doc-grid" ]
            [ thead []
                (List.map
                    (\( left, right ) ->
                        tr []
                            [ th [ class "u" ] [ text left ]
                            , th [ class "u" ] [ text right ]
                            ]
                    )
                    headers
                )
            , tbody []
                (List.map
                    (\( left, right ) ->
                        tr []
                            [ td [] [ span [ class "mono" ] [ text left ] ]
                            , td [] [ text right ]
                            ]
                    )
                    rows
                )
            ]
        ]
