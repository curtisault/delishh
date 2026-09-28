# delishh meal planner — implementation plan

> Companion to `docs/design-standard.md` (DS-01 Revision 2) and
> `docs/delishh-redesign.md`. Created 2026-09-27. This doc owns the
> planner's *sequence and scope*; DS-01 owns look, feel and voice,
> and where the planner needs the standard to move, the amendment is
> named below and DS-01 gets the dated clause. When the two disagree,
> DS-01 governs.

## What it is

A week, Sunday to Saturday, with one meal on each day. A meal is
either a recipe from the archive or a name you typed — *Spaghetti*
on Wednesday, without the archive having a spaghetti. The week is
kept in this browser like the shopping list is, and it leaves the
browser one way: as a picture, made on the page, small enough to
send to anyone and read on their phone without opening anything.

It is the fourth surface. The shelf is for choosing, the page is for
cooking, the list is for the shop; the plan is for the *week* — read
on a Sunday evening deciding, and again on a Tuesday remembering.
Like the list it runs quiet.

## Decision log

Ruled 2026-09-27, at the planner's framing:

| Decision | Ruling | Rejected alternatives |
|----------|--------|----------------------|
| The shape of a week | **Seven days, one meal each, Sunday first.** A day holds a meal or nothing. No named slots: the planner never says *dinner*, because saying it would make a Sunday brunch a lie, and one cell a day is what keeps the picture phone-sized | A list per day (the picture grows with what you add, and "compact" stops being a property of the design); breakfast/lunch/dinner from the slot vocabulary (a 7×3 grid, wide on a phone, and most of it empty most weeks) |
| The week is undated | **Days are names, not dates.** The plan is a rolling template — *this week*, whichever week you are in — and clearing it is how it becomes next week. Nothing in the product reads a clock without a subscription (§10), and a dated week would need to know when a week ends | A start date in the plan (a "next week" button, a clock, and a picture that says a date the sender may not mean); auto-clearing on Sunday (the archive deciding you have eaten) |
| Two kinds of meal | **`Recipe` and `Own`.** A recipe meal is a slug with a snapshot of its title, and links to its page; an own meal is the words you typed and nothing else. Neither is ever inferred from the other: typing *donuts* does not silently become the donuts recipe. The one entry field serves both — type, and if the archive has a match you may pick it, or keep what you typed | A recipe-only planner (the reason the feature exists is the meal that is not in the archive yet); free text that auto-links to a recipe on a name match (inference, banned) |
| Where it lives | **A third `localStorage` key, `delishh-plan`**, beside the theme and the list, written through a `savePlan` port and read back as a flag. Named in the colophon and DS-01 §12 (amendment below). It fails the way the list fails: silently, into a plan that holds for the session | The URL (`?p=…`): a link that works is attractive, but own meals make the address long, the shell would need `arrivalMirrors` and echo handling for a page that mirrors, and "nothing about a reader leaves their browser" would acquire a footnote |
| How it is shared | **A PNG, drawn in the browser.** `boot.js` draws the week onto a canvas from the plan data Elm hands it over a port, and the reader gets the file three ways, in order of what the browser can do: the share sheet (`navigator.share` with a file), the clipboard (`ClipboardItem`), a download. The picture is previewed on the page **as the very file** that will be shared — one renderer, and what you see is what they get | A share *view* the reader screenshots themselves (no image code at all, but "easy" then depends on knowing your phone's screenshot chord, and a screenshot carries the browser chrome); rendering the page's own DOM through an SVG `foreignObject` (needs every font and rule inlined, and Safari taints the canvas — the one place "anyone" would fail is the one this feature is for); a screenshot library (a full second layout engine, for seven lines of text) |
| Where the picture's colours come from | **Read off the tokens at draw time.** `boot.js` resolves `--ink`, `--surface`, `--rule`, `--accent` and the `--font-*` stacks with `getComputedStyle` on `<html>`, and waits on `document.fonts` for the four voices before drawing. `theme.css` stays the only place a hex lives; the raw-hex rule holds in `boot.js` as everywhere else. The card takes the theme the reader is in, and the preview shows them so | Hard-coded colours in the drawing code (the second copy of the palette that `contrast_test.ts` exists to forbid); always drawing in the lit palette (would mean resolving tokens for a theme the document is not wearing — a detached element cannot see `:root[data-theme]`) |
| How meals move | **Pick up, then place.** Tap a meal to lift it; tap a day to set it down. An empty day takes it, a full day swaps, the same day puts it back, and any navigation drops it. One mechanism for thumb, mouse and keyboard, every target at the 2.75rem floor (§12), nothing behind a gesture. A lifted meal is **seated** — the press dress's held-down state (2026-09-23) — and says ", lifted" to a screen reader | HTML5 drag and drop (does not fire on touch without a polyfill, so it is two mechanisms to keep in agreement, and the second is this one anyway); earlier/later arrows only (Sunday to Saturday is six presses) |
| What the picture is for | **Reading, not cooking.** Day and meal, in the display and procedure voices, and a mark that says where it came from. No quantities, no times, no facets: a picture cannot be scaled, tapped or filtered, and furniture that does nothing in a photograph is ink spent on nothing. A recipe meal carries no URL either — a link in a picture is a thing to type by hand | Recipe cards on the picture (photos, times, chips — the shelf, rendered to a bitmap); QR codes to each recipe (the archive claiming the receiver wants to cook it) |

## DS-01 amendments this plan needs

Each becomes a dated clause in `design-standard.md` when its phase
lands; they are listed here so the standard moves once, deliberately.

- **§12 Hard constraints — "Nothing about a reader leaves their
  browser."** *Two things are stored* becomes *three*: the lighting,
  the shopping list, **and the week they planned**. The sentence
  that follows already covers the new key: either may fail to save,
  and state that cannot be read back is discarded. The colophon's
  matching paragraph (`docs/about.md` §01) grows the same clause, and
  a test holds the two counts to `boot.js`'s key list.
- **§12 — "Fast on a phone in a kitchen. The acid layer is CSS and
  SVG, never image payloads."** A clarifying sentence: an image the
  reader *makes* is not a payload the site *ships*. The PNG is
  output, drawn on request, never fetched.
- **§04 Colour — the surfaces.** The shopping list was added as "a
  third surface" on 2026-09-22 and takes `--page-*` marks. The plan
  is a fourth, in the same register: quiet, `--page-*` only, volt on
  the one actionable thing per view. On the picture volt lands on
  the wordmark and nowhere else — one acid, and never on a quantity,
  though there are none.
- **§10 Motion.** Nothing new. A lifted meal changes shape, not
  position; days do not slide to make room. The register stays zero
  on this surface, for the reason the list's does: a week
  rearranging itself under a thumb is hostile.

## The data

`src/Plan.elm`, pure, in the shape `GroceryList.elm` set:

```elm
type Day = Sun | Mon | Tue | Wed | Thu | Fri | Sat   -- in this order, always

type Meal
    = Recipe { slug : String, title : String }   -- title is a snapshot
    | Own String                                  -- exactly what was typed, trimmed

type alias Plan   -- seven days, each held or empty
```

- `days : List Day` is the one place the order is written.
- `set : Day -> Meal -> Plan -> Plan`, `clear : Day -> Plan -> Plan`,
  `move : Day -> Day -> Plan -> Plan` (empty target takes, full
  target swaps, same day is identity), `clearAll`.
- `encode` / `decoder`, and the decoder is total: a stored value
  that will not decode becomes an empty week, never a shell that does
  not boot — the same ruling `boot.js` already makes for the list.
- `Own ""` cannot be constructed: an own meal is trimmed and a blank
  is a `clear`.
- `toShare : Plan -> E.Value` — what the picture is drawn from: seven
  `{ day, meal, source }` rows, `source` being `"archive"` or
  `"own"`, so the drawing code never learns what a slug is.

## The pages and the presses

- **`/plan`** — `Route.Plan`, a line in `public/_redirects`, a
  variant in `RouteTests`' round trip, title `DELISHH — MEAL PLAN`.
  A leaf like every route but cook mode; `Liner.on` needs no change.
  A nav link after Shopping List, carrying the count of planned days
  in its label the way the list link carries its count.
- **The week.** Seven rows, Sunday first, each a press. Row anatomy:
  the day in the display voice, the meal in the procedure voice, and
  for a recipe meal a small mark that it is one and a link to its
  page. An empty day says nothing — not *empty*, not a dashed box —
  because absent is absent (§06). At ≥60rem the seven sit in one
  column still: a week is read down.
- **Adding to a day.** Press an empty day and the row opens an entry
  field. Typing narrows the archive's index with the shelf's own
  `Shelf.matchesQuery` — the same needles, so the same matches — and
  offers up to five as presses under the field. **A press on a match
  sets a recipe meal; Enter, or the KEEP "SPAGHETTI" press, sets an
  own meal with the words as typed.** One field, two outcomes, and
  the reader always chooses which. The index is the shelf's
  `Fetch Shelf.Index`, already in the shell; the plan page shares it.
- **From a recipe page.** ADD TO PLAN beside ADD TO LIST, in the same
  dress. It opens the seven days as presses; a day already holding a
  meal says so on the press and is replaced on confirmation. A recipe
  already planned reads PLANNED · WED and pressing it offers to move
  or remove. Seated when planned, like ADD TO LIST when added.
- **Moving.** Above. `lifted : Maybe Day` lives in the shell like
  `clearArmed` does, so leaving the page drops it.
- **Removing.** Each held row has a REMOVE press; the week has CLEAR
  THE WEEK, armed by a first press exactly as the list's clear is.
  Clearing the last meal removes the storage key, as the list does.
- **The picture.** A MAKE THE PICTURE press sends `toShare` out
  through `sharePlan`. `boot.js` draws and answers on `planPicture`
  with an object URL, which Elm shows as the preview beside three
  presses that exist only when the browser can honour them: SHARE
  (`navigator.canShare({ files })`), COPY (`ClipboardItem` with
  `image/png`), and SAVE, a plain `<a download>` on the blob URL that
  needs no JavaScript at all. Each reports what actually happened
  through `planShared` — `shared` / `copied` / `saved` / `refused`
  (the reader dismissed the sheet) / `unsupported` — and each reaches
  the reader as its own sentence, because "Shared" on a browser that
  refused is the wake badge's lie all over again. A new plan
  invalidates the preview; the object URL is revoked when replaced.

## The picture itself

Drawn by `boot.js`, from data, into a canvas at `devicePixelRatio`
so it is crisp on the phone it is read on.

- **Portrait, 1080 × (masthead + 7 rows) logical pixels** — a single
  phone screen with nothing to scroll. Landscape was rejected: it
  would arrive as a thumbnail in every chat client.
- **Masthead:** the wordmark in the display voice, volt. Nothing
  else — no date (the week is undated), no URL (a link in a picture).
- **Rows:** day in the display voice at the left, meal in the
  procedure voice, a hairline in `--rule` between rows. A recipe meal
  carries a small `ARCHIVE` word in the data voice; an own meal
  carries nothing. An empty day draws its name and a blank — a
  receiver should see that Thursday is open, and the absence is the
  information.
- **Ink discipline:** `--ink` on `--surface`, `--rule` for lines,
  volt for the wordmark only. Contrast is whatever the theme's
  already-checked pairs give, because those are the values read.
- **Type:** `document.fonts.load()` for each of the four voices at
  the sizes used, awaited before the first stroke; a face that will
  not load falls to its stack, which is what the page would do.
- **Long names wrap** to a second line at most and the row grows;
  nothing is ever ellipsised, because a clipped meal is a broken
  picture (§12, dense but never broken). Past two lines the font
  steps down one size rather than the text being cut.

## Phases

### Phase 1 — the data and the store ✅ done 2026-09-27

- [x] `src/Plan.elm` — days, meals, set / clear / move / clearAll,
      encode / decoder, `toShare`. `Meal` is **opaque**: `recipe` and
      `own` build one, `describe` reads one back as a name and a
      `Source`, and `own` answers `Nothing` for a blank — so a blank
      own meal cannot exist rather than being checked for.
- [x] `tests/PlanTests.elm` — 24 tests: the move table (empty, full,
      same day, and lifting an empty day, which clears nothing), the
      blank-own rule, the encode round trip, a first-planner stored
      value kept verbatim for the expansion, the malformed-store
      refusals, and a `toShare` that never carries a slug.
- [x] `savePlan` port, `PLAN_KEY` in `boot.js`, the `plan` flag; the
      shell holds `plan : Plan` beside `list`, reset by nothing.
- [x] `docs/about.md` §01 and DS-01 §12: two → three, and the
      payload clarification. `scripts/storage_test.ts` holds both
      documents' count to the keys `boot.js` declares, and forbids a
      literal key passed straight to `localStorage`.

**The port needed a caller before it had a page.** Elm drops an
unused port from the compiled output, and `boot.js` subscribing to a
`savePlan` that is not there throws at boot — the whole site, not
the planner. Phase 1 has no press that writes a plan, so the first
caller is DS-01 §12's own rule, made literal: a stored week that
will not decode is **discarded**, and discarded means the key goes
(`Main.readPlan`), not only that this load ignores it. A value that
fails once fails on every load, and a key nobody can read is a thing
kept about the reader that does nothing for them. Verified in the
production bundle.

**A consequence to know before the expansion ships.** The first
planner's decoder refuses a day stored as an array, so a browser that
rolls back from the expansion to this build loses its week. Deploys
only move forward, so this is accepted, not fixed.

### Phase 2 — the page ✅ done 2026-09-27

- [x] `Route.Plan`, `_redirects`, `RouteTests`, the nav link with its
      count. The list's link and the plan's are now one function,
      `Main.countedLink`; the plan counts **days**, not meals.
- [x] `src/Page/Plan.elm` + `src/plan.css` — the seven rows, the
      entry field with the shelf's matching, the day presses, REMOVE,
      the armed CLEAR THE WEEK. The plan route fetches the shelf's
      index; a failed fetch leaves the field keeping words.
- [x] Pick up and place, seated while lifted, dropped by navigation.
- [x] ADD TO PLAN on the recipe page with its day picker and its
      PLANNED · DAY state.
- [x] `tests/PlanPageTests.elm` — 30 rendered-view tests, and 10 more
      for the plan control in `RecipePageTests`.
- [x] `CLAUDE.md` doc map: `src/Plan.elm`, both planner docs,
      `storage_test.ts`, and the three easy-to-undo rules.
- [x] DS-01 §04 amendment 2026-09-27: the fourth surface.

**The picker toggles; it does not "offer to move or remove".** The
plan above said a planned recipe's press would offer a move or a
removal. Built, that is two menus for one fact. Each day press is a
toggle instead (`Plan.placeRecipe`): a day with this recipe takes it
off, an empty day takes it, another meal asks once and then
replaces. Moving is off one day and onto another, and a recipe may be
on two days, which the label shows (`PLANNED · SUN, WED`).

**While a meal is lifted, every row is one press.** REMOVE and CLEAR
THE WEEK are gone until it is set down, because a row that was both a
place to land and a destructive button puts the latter under a thumb
aiming for the former.

**KEEP is sentence case.** Every other press is uppercase. KEEP
quotes the reader's words back, and "KEEP “SPAGHETTI”" misquoted
them — found in the browser, not by a test.

**The day column is held by hand on held rows.** An empty day is a
slab with a 1px edge and inner padding; a held day is not a press, so
its name sat 12px left of every empty day's. `.plan-row` now gives
both the slab's width and inset. Measured after the fix: every day
name starts at the same pixel.

**Verified in a real browser** against `deno task build` at 1280 and
375 wide: an empty week, a match picked, a typed meal kept with
Enter, a lift and swap, a reload that kept the week, the recipe
page's arm, replace, and toggle, and no sideways scroll at 375.
**Not verified:** a screen reader in use (the accessible names were
read off the accessibility tree), and touch on a real phone.

### Phase 3 — the picture ✅ built 2026-09-27 · real-device pass outstanding

- [x] `sharePlan` (out) / `planPicture` / `planShared` (in); the
      drawing in `boot.js`, tokens and faces resolved at draw time,
      fonts awaited with the text they will draw.
- [x] The preview and the conditional presses; the honest outcome
      sentence; object URLs revoked when replaced or dropped.
- [x] `scripts/share_test.ts` — no raw hex and no family spelled in
      `boot.js`, every token the picture reads declared in
      `theme.css`, every text pair it draws checked in
      `contrast_test.ts`, share and copy called before anything is
      awaited, and no `beforeprint`. A misspelled token was tried and
      fails two of them.
- [x] `tests/PlanPageTests.elm` — 14 more: when the picture is and is
      not offered, the preview as the file, the alt text naming empty
      days, SAVE always, SHARE and COPY only where the browser can,
      and each outcome's sentence.
- [ ] **A real-device pass.** Not done, and it needs a human with a
      phone: the share sheet on iOS Safari and Android Chrome, and
      whether a share still counts as inside the press once it has
      gone through Elm's update and a port.

**Where the build differs from the plan above, and why:**

- **The wordmark is the stencil's pair, not volt on the ground.**
  Volt on the lit ground is 1.06:1; the wordmark would have been the
  one thing on the picture nobody could read. The masthead is the
  site bar instead — `--stencil-mark` on `--stencil-bg`, checked in
  both themes. It *is* volt in the lit theme; after dark it inverts
  to frost and the darkened cut, as the bar does.
- **1080 device pixels, not 1080 × `devicePixelRatio`.** 1080 is
  already a phone screen's width in device pixels. Multiplying again
  drew a 3240-pixel file for a 390-point screen.
- **Rows are ruled in `--rule-soft`**, the hairline the page uses
  between days, not `--rule`. The picture is a view of the page.
- **One port out, four verbs** (`draw`, `share`, `copy`, `forget`),
  because all four act on the one blob `boot.js` holds.
- **SAVE reports nothing.** It is a plain download link. The page
  cannot know whether the file landed, and "Saved" would be a guess.
- **A draw is numbered.** The shell sends a generation with every
  draw and moves it on every change to the week, the theme, or the
  route. `boot.js` discards any draw that is not the one wanted, so a
  late answer can never replace or release the picture on screen.
  The first version had the shell send `forget` on a stale answer,
  which would have released the newer picture the page was showing.
- **Hidden while a day is open**, as well as while a meal is lifted,
  so MAKE THE PICTURE never stands beside KEEP as a second volt.

**Verified in a real browser** against `deno task build`: a six-day
week with a three-line meal drew at 1080 × 1273, all three voices
loaded, the long meal stepped down and wrapped with nothing cut, the
empty day drawn open. Switching to dark dropped the preview and
released its blob; the redraw came out in the dark palette. This
desktop browser offered COPY and SAVE and no SHARE, which is right
for it, and a real click on COPY reported "Copied."

## Built with the expansion in mind

`docs/meal-planner-expansion.md` (2026-09-27, unscheduled) grows a
day from one meal to five, optionally labelled from the slot
vocabulary. It is not built until this planner has been used for
real weeks. Three seams cost nothing now and everything later, so
the first implementation keeps them:

- **Pages never learn the plan's shape.** Every read and write goes
  through `Plan`'s API — `set`, `clear`, `move`, `toShare` — so a
  day becoming a list touches `Plan` and the presses, not the shell.
- **The decoder is total, and the stored shape is the version.** No
  `version:` field. The expansion reads this planner's object-per-day
  as a list of one, by shape.
- **`boot.js` draws from `toShare` alone.** It knows rows and words,
  never slugs or days' internals, so the drawing changes when the
  shape it is handed changes, and not before.

## Open items

- **The week onto the list.** Every planned recipe onto the shopping
  list in one press — the two stores already speak the same slug.
  Not built until the planner has been used for a few weeks; the
  question is whether the list wants *this week's* recipes or the
  recipes you have not yet bought for, and only use answers it.
- **A dated week.** If "which week is this picture for" turns out to
  be asked, the answer is a caption the *sender* types onto the
  picture, never a date the archive computes. The undated ruling
  stands until then.
- **Own meals that later become recipes.** When *Spaghetti* gets
  written up, the plan does not know. It should not: it holds what
  was typed. A future entry-field nicety could say "the archive now
  has this" and offer the swap, on the reader's press.
- **The picture in the lit palette regardless of theme.** Deferred
  with the ruling above. If dark-mode readers turn out to want a
  paper-coloured card, the route is a second token read against a
  `data-theme="light"` document the drawing code owns, not a second
  palette in `boot.js`.
