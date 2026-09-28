# delishh, installable — the web app on a home screen

> Companion to `docs/design-standard.md` (DS-01 Revision 2) and
> `docs/delishh-redesign.md`. Created 2026-09-28. **Nothing here is
> ruled yet**: the decision log below lists what has to be decided
> and what is recommended, and stays that way until a ruling is
> dated. This doc owns the install's *sequence and scope*; DS-01
> owns look, feel and voice, and where the install needs the standard
> to move, the amendment is named below and DS-01 gets the dated
> clause. When the two disagree, DS-01 governs.

## What it is

The same site, kept on the phone. An icon on the home screen that
opens the archive full-screen, and a copy of the archive on the
device so that a recipe opens in a kitchen with no signal, and cook
mode runs there. No store, no wrapper, no second codebase: a web
manifest, a service worker, and the cache policy `public/_headers`
already states, carried onto the device.

It is not a new surface. Nothing is drawn differently installed; the
shelf is as loud, the page as quiet, and the printed sheet is the
same sheet. What changes is that the network stops being a
precondition for reading.

## Where it stands

What is already true, read out of the code on 2026-09-28:

- No manifest, no service worker, no icons.
- Everything else an installed app leans on exists: breakpoints in
  rem and no device detection, four self-hosted faces, the wake lock
  in cook mode, the share sheet on the plan's picture, three named
  `localStorage` keys.
- The whole archive is small. `public/content` is 252 KB of
  generated JSON, `public/fonts` is 224 KB; with the hashed bundle
  the entire product caches in about a megabyte.
- `public/photos` does not exist and no recipe names a photo, so a
  photo policy is a sentence here, not work.
- `public/_headers` already says what a cache should believe:
  `/assets/*` and `/fonts/*` immutable, `/`, `/index.html` and
  `/content/*` revalidate on every request. The worker mirrors that
  policy; it does not get a second one.
- `_redirects` answers a client route with `index.html` at the edge.
  Offline there is no edge, so the worker has to give the same
  answer, or a home-screen launch that lands on `/plan` is a blank
  page.

## Decision log

Open, as of 2026-09-28. Each row is ruled by replacing *Open* with a
date and moving the rejected route to the last column.

| Decision | Status and recommendation | Alternatives |
|----------|---------------------------|--------------|
| Is the offline archive a "thing stored"? | **Open.** DS-01 §12 and the colophon promise *three things are stored, all named*, and `scripts/storage_test.ts` holds that number to `boot.js`'s key list. A Cache Storage copy of the archive is not *about the reader*, but it is bytes on their device that clearing site data removes. Recommended: name it in both documents as its own sentence, distinct from the three keys — *a copy of the archive is kept so it opens without a connection* — and teach the test to hold the worker's cache name the way it holds the keys, so a renamed or second cache cannot arrive unnamed | Counting it as a fourth key (it is not one, and the colophon would then describe the archive as something kept *about* the reader); saying nothing (the statement that lags the code is the one a reader believes) |
| What is kept offline | **Open.** Recommended: **the whole archive**, fetched best-effort after the worker activates, never blocking anything. At 252 KB there is no reason a recipe you have not yet opened should fail in the kitchen, and "only what you have opened" is a rule the reader cannot see and would have to discover by failing | Only what has been opened (smaller, but the failure is invisible until it matters); shipping the corpus in the bundle (the reason recipes are fetched and not compiled in — a growing corpus does not belong in the bundle) |
| Display mode | **Open.** Recommended: **`standalone`**, no browser chrome. Note what it costs: the cook-mode scale *rides in the URL and is bookmarkable*, and there is no URL bar to bookmark from. The scale is still set on the page before entering cook mode, so nothing is lost but the bookmark | `minimal-ui` (keeps a URL bar on Android; iOS ignores the value and behaves as standalone anyway, so it is two behaviours for one word); `browser` (an icon that opens a tab — not an install) |
| The icon | **Open.** The icon is a surface, and §04 says one acid dominates per surface. This is a colour ruling, not a build detail. Recommended: the wordmark's letterform on a stencil field, volt as the one acid, with a maskable variant that keeps the mark inside the safe zone. Two sizes drawn by hand, never a screenshot | A photograph (the acid layer is never image payloads); three acids (never three) |
| Update behaviour | **Open.** Recommended: **no prompt in the first cut.** The worker takes over immediately (`skipWaiting`, `clients.claim`) and navigations are network-first, so the next open is the current build when online. An *a newer archive is ready* banner needs a new incoming port and a subscription, and the shell's rule is one subscription unless something on screen genuinely changes on its own | A reload banner (the port and the subscription, for a site whose builds are minutes apart at most); a worker that waits for every tab to close (the classic stale-for-days failure) |

## DS-01 amendments this plan needs

Each becomes a dated clause in `design-standard.md` when its phase
lands; they are listed here so the standard moves once, deliberately.

- **§12 Hard constraints — "Nothing about a reader leaves their
  browser."** Depending on the first ruling above, a sentence naming
  the archive copy beside the three keys, and the same sentence in
  the colophon's *What is kept about you* (`docs/about.md`). The
  existing clause already covers the failure mode: a cache that
  cannot be written degrades to the site as it is today, fetched.
- **§12 — "Fast on a phone in a kitchen."** A clause: *the archive
  opens without a connection once it has been opened with one.* This
  is the promise the install makes, and it belongs with the
  performance bar it extends.
- **§12 — "Printing is pure CSS."** Possibly nothing. See the
  standalone-print check in Phase 6: if a home-screen app on iOS has
  no route to print without a button that calls `window.print()`,
  the clause needs a sentence saying a button that *opens the
  dialog* is not a second renderer, and `print_test.ts` needs
  re-scoping to match. Not amended until the check has been done on
  a phone.
- **§04 Colour.** The icon's ruling, dated, if it names an acid.
- **§10 Motion.** Nothing. An install changes no motion.

## Phases

### Phase 1 — the manifest, the icons, the head

- `manifest.webmanifest`: name, `short_name`, `start_url: "/"`,
  `scope: "/"`, `display` per the ruling, `background_color`,
  `theme_color`, and the icons: an SVG, a maskable variant, and a
  512 px PNG for Android's splash.
- **Where its hexes come from.** Raw hex outside `theme.css` is a
  bug, and a manifest is hex literals. Recommended: **generate it**
  in `deno task content`, a `scripts/build-manifest.ts` that reads
  the two tokens it needs out of `theme.css` and writes
  `public/manifest.webmanifest`, gitignored like `public/content`.
  The alternative — hand-write it and hold it to `theme.css` by
  test, the way `contrast_test.ts` holds the comments — is what
  `public/404.html` already does, and one hand copy of the palette
  is enough.
- `index.html`: `<link rel="manifest">`; `<link rel="apple-touch-icon">`,
  because iOS reads that and not the manifest's icons; and two
  `<meta name="theme-color">` with `media="(prefers-color-scheme: …)"`
  so the status bar follows the theme. Those two metas are the one
  place a hex has to sit in HTML; they are held to `theme.css` by
  the test in Phase 4.
- `public/404.html` links the manifest too. An install begun from a
  mistyped address should still know what it is.
- `public/_headers`: the manifest revalidates (`max-age=0,
  must-revalidate`), for the same reason `index.html` does — it is
  unhashed and changes.
- `_redirects` is untouched.

### Phase 2 — the service worker

- **Source at `src/sw.js`, generated to `public/sw.js`.** A small
  `scripts/build-sw.ts`, run inside `deno task content`, copies the
  source with a build stamp substituted into one constant. That is
  the pipeline's existing shape — a source the author edits, a
  generated file nobody does — and it gives every deploy a worker
  that differs byte-for-byte, which is what makes a browser install
  the new one. `public/sw.js` is gitignored.
- **Not `vite-plugin-pwa`.** It is npm plus Workbox plus generated
  code, an unproven fit under Deno, and it would be the one part of
  this product that nobody hand-wrote and no test reads. The worker
  this site needs is under a hundred lines.
- **Policy, mirroring `_headers` line for line:**
  - `/assets/*` and `/fonts/*`: cache-first. They are immutable by
    name, so a cached copy is never wrong.
  - `/content/*`, `/`, `/index.html`: network-first, cache fallback.
    An edited recipe is seen on the next open with a connection,
    the same promise the edge makes.
  - Any navigation: network-first; offline, the cached
    `/index.html`. This is `_redirects` done on the device, so
    `Route.elm` reads the address and works unchanged. An unknown
    slug offline gets the shell, then the recipe page's own failure
    sentence — the same as it would online.
  - One cache, named with the build stamp. On activate, every cache
    not bearing the current stamp is deleted, so hashed assets from
    old builds do not accumulate.
  - Never a `/content/*` request served cache-first. A test forbids
    it, because it is the one policy inversion that makes the
    archive disagree with itself in the reader's hand.
- **Registration at the foot of `boot.js`**, after `Elm.Main.init`,
  wrapped so a browser without the API boots exactly as today.
  `print_test.ts` reads `boot.js` for `beforeprint`, `afterprint`,
  `window.print` and `matchMedia('print` — registration trips none
  of them, and must keep not doing so.
- `public/_headers`: `/sw.js` revalidates. Browsers cap a worker
  script's cache at a day regardless; `max-age=0` is the honest
  statement of what the file is.
- **Pre-caching the archive** (per the ruling): after activate, read
  `/content/index.json` and fetch each recipe it lists into the
  cache, one at a time, best-effort. It never blocks a page, never
  reports progress, and a failure part-way leaves the recipes it
  reached — which then open offline — and nothing else.
- Photos, when they arrive: cached as opened, never pre-fetched.
  §12 says *at most one photograph per recipe, lazily loaded*, and
  a pre-fetch of every photo is the opposite of lazy.
- **Out of this phase, named so it does not drift in:** an update
  banner (see the log), push notifications, background sync, a
  timer that fires with the app closed, persisted step stamps
  (`CLAUDE.md`, *Not yet in force*), any analytics. The wake lock
  is already the reason you should not be reloading mid-cook.

### Phase 3 — offline honesty

- The shelf's failure sentence today is *The index could not be
  fetched. A reload usually settles it.* Offline, a reload settles
  nothing, and a sentence that is sometimes false is one the reader
  learns to ignore. With the whole archive pre-cached this state is
  rare, but rare is not never, and nothing is ever inferred on the
  reader's behalf — including the reason a fetch failed.
- Two routes; recommended the second:
  - Drop the second sentence. Honest, and says nothing.
  - **The worker answers an unreachable, uncached `/content/*`
    request with a synthetic `503` and a small JSON body.** Elm's
    `Http.Error` then distinguishes *the archive cannot be reached
    and this recipe was never kept here* (`BadStatus 503`) from a
    real server fault (`BadStatus 500`) and a plain network failure
    (`NetworkError`, which is what a browser without the worker
    still gets). One branch in `Main.elm`, one sentence each on the
    shelf and the recipe page, in the voice of §11.
- Cook mode needs nothing: it is reached from a recipe already
  loaded, and its timer counts to an absolute end with no network
  in the loop.

### Phase 4 — the tests and CI

- **`scripts/pwa_test.ts`**, in the house style, one test a rule:
  - the manifest parses, `start_url` and `scope` are `/`, and
    `display` is the ruled value;
  - every icon the manifest names exists on disk;
  - `index.html` and `public/404.html` link the manifest, and
    `index.html` carries the `apple-touch-icon`;
  - every hex in the manifest and in the `theme-color` metas equals
    a token's value in `theme.css`, read the way `contrast_test.ts`
    reads them;
  - `_headers` carries revalidate rules for `/sw.js` and the
    manifest;
  - `src/sw.js` declares exactly one cache name and it includes the
    stamp placeholder;
  - the worker never matches `/content/` inside its cache-first
    branch.
- **`scripts/storage_test.ts`** extended per the first ruling: the
  cache name the worker declares is the one the colophon and §12
  name.
- **`.github/workflows/deploy.yml`** gains two lines beside the
  existing 404 / wildcard / content guards: `dist/sw.js` and
  `dist/manifest.webmanifest` are present. A build that lost either
  would install as the site did before, silently.
- `print_test.ts` is unchanged unless Phase 6 says otherwise.

### Phase 5 — the documents

- DS-01 §12, the amendments above, dated.
- `docs/about.md`, *What is kept about you*, the matching sentence.
- `CLAUDE.md`: a row in the doc map for `src/sw.js` (*the cache
  policy of `_headers`, carried onto the device; never cache-first
  for content*), and the `content` task's description grows the two
  new generated files.
- This document's decision log, with the rulings dated and the
  rejected routes moved.

### Phase 6 — by hand, on a phone

No static read establishes any of these; they need a device, and
the plan is not done until they have been done.

- Install from Safari on iOS and from Chrome on Android. Launch from
  the home screen. Turn on airplane mode. Open the shelf, a recipe
  you have opened before, one you have not, cook mode, the list, the
  plan.
- **Print from the installed app on iOS.** A home-screen app has no
  browser chrome, so there may be no route to the print dialog
  without a control that calls `window.print()`, which
  `print_test.ts` forbids in `boot.js` today. Establish the fact
  first; the §12 amendment above waits on it.
- The wake lock holds inside the installed app (iOS 16.4 and later
  should; earlier does not, and the badge must say *refused* or
  *unsupported* rather than *held*).
- The status bar takes the theme's colour in both themes, and
  switching the theme on the page changes it.
- 200 % zoom and a raised system font inside the installed app:
  nothing clips, nothing overlaps (§12, the never-broken bar).
- Deploy a change, reopen the app online, confirm the change is
  there without a second reload. Reopen offline, confirm it still
  opens.

## Open items

- **A reload banner.** If the no-prompt ruling turns out to leave
  readers on a stale build in practice — it should not, with
  network-first navigations — the route is one incoming port
  (`updateReady`), one sentence in the site bar, one press. It would
  be the shell's second subscription, and it should earn that.
- **Step stamps across a reload.** Unchanged by this plan and still
  in `CLAUDE.md`'s *Not yet in force*. An installed app makes an
  accidental close slightly more likely than a tab did; if that is
  observed, the answer is the port and storage key already described
  there, not anything in the worker.
- **A store listing.** Android can wrap an installed web app as a
  Trusted Web Activity with no change to this code. Not planned;
  noted so the option is not forgotten when someone asks.
- **The corpus outgrowing the pre-cache.** At a megabyte the
  whole-archive ruling is obviously right. At fifty it is not, and
  the line is a judgement to make when the size is real, not a
  threshold to pick now.
