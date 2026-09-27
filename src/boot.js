// Boot: styles first (tokens -> components), then the Elm app.
// Browser.application owns the whole <body> and reads the URL itself —
// there is no mount node to hand it.
//
// The theme attribute lives on <html>. Elm owns only <body>, so the
// shell cannot reach it directly — it goes out through the saveTheme
// port and this file applies it.
import './theme.css'
import './fonts.css'
import './sheet.css'
import './shelf.css'
import './recipe.css'
import './cook.css'
import './list.css'
import './print.css'
import { Elm } from './Main.elm'

const THEME_KEY = 'delishh-theme'
const LIST_KEY = 'delishh-list'

// Apply the stored preference BEFORE Elm boots — the page must never
// flash the wrong theme. "system" is represented by absence: no
// attribute, no stored key, the prefers-color-scheme query governs.
let storedTheme = null
try {
  storedTheme = localStorage.getItem(THEME_KEY)
} catch (_) {
  // storage unavailable: fall through as system
}
if (storedTheme === 'light' || storedTheme === 'dark') {
  document.documentElement.dataset.theme = storedTheme
}

// The shopping list, read raw. Elm decodes it, because the schema
// belongs beside the encoder that writes it — and because anything
// that will not decode has to become an empty list rather than a
// shell that does not boot, which is a decision, not a parse.
let storedList = null
try {
  storedList = localStorage.getItem(LIST_KEY)
} catch (_) {
  // storage unavailable: start empty, and say nothing
}

const app = Elm.Main.init({
  flags: {
    theme: storedTheme,
    list: storedList,
    // The date a printed sheet says it was pulled (DS-01 §09). Elm
    // cannot read a clock without a subscription, and a document does
    // not need one ticking — this is the load date, which for a page
    // opened in order to print it IS the print date.
    today: new Date().toLocaleDateString('en-CA'),
  },
})

// The screen wake lock — DS-01 §08.
//
// Elm asks for it and is TOLD WHAT HAPPENED, because the badge on
// screen says which. A page that claims "screen held" on a browser
// that refused is lying about its status, and the reader finds out
// when the screen goes black with their hands covered in flour.
//
// The spec releases the lock whenever the document is hidden, so it
// has to be re-taken when the tab comes back — otherwise the lock
// silently stops working the first time you check a message.
let wakeLock = null
let wakeWanted = false

const reportWake = (state) => app.ports.wakeLockChanged.send(state)

async function takeWakeLock() {
  if (!('wakeLock' in navigator)) return reportWake('unsupported')
  try {
    wakeLock = await navigator.wakeLock.request('screen')
    wakeLock.addEventListener('release', () => {
      wakeLock = null
      if (!wakeWanted) reportWake('off')
    })
    reportWake('held')
  } catch {
    // No user gesture, battery saver, an insecure origin — the
    // reasons differ and the consequence does not.
    wakeLock = null
    reportWake('refused')
  }
}

app.ports.setWakeLock.subscribe(async (want) => {
  wakeWanted = want
  if (want) {
    await takeWakeLock()
  } else {
    if (wakeLock) await wakeLock.release()
    wakeLock = null
    reportWake('off')
  }
})

document.addEventListener('visibilitychange', () => {
  if (wakeWanted && wakeLock === null && document.visibilityState === 'visible') {
    takeWakeLock()
  }
})

app.ports.saveTheme.subscribe((theme) => {
  if (theme === 'light' || theme === 'dark') {
    document.documentElement.dataset.theme = theme
  } else {
    delete document.documentElement.dataset.theme
  }
  try {
    if (theme === 'light' || theme === 'dark') {
      localStorage.setItem(THEME_KEY, theme)
    } else {
      localStorage.removeItem(THEME_KEY)
    }
  } catch (_) {
    // storage full or unavailable: the attribute still applied, so the
    // choice holds for this session even if it can't persist
  }
})

app.ports.saveList.subscribe((list) => {
  try {
    // An empty list clears the key rather than storing an empty one.
    // The colophon says taking the last recipe off clears it, and a
    // key holding `{"contributions":[]}` would make that a lie.
    if (list && list.contributions && list.contributions.length > 0) {
      localStorage.setItem(LIST_KEY, JSON.stringify(list))
    } else {
      localStorage.removeItem(LIST_KEY)
    }
  } catch (_) {
    // storage full or unavailable: the list holds for this session,
    // the same degradation the theme takes. A shop is not the moment
    // to learn that storage is full.
  }
})

// ---- the contents rail's active row ----
//
// Elm has no scroll subscription (elm/browser offers resize,
// visibility, keys, clicks and animation frames — nothing for scroll),
// so which section the reader is inside is computed here and sent in
// through the `sectionSeen` port.
//
// The rule: the last section whose top has passed the reading line, a
// third of the way down the viewport. Deliberately NOT a copy of
// Main.jumpTo's sticky-chrome measurement — this is "what am I
// reading", not "where must I scroll to", and a second copy of that
// arithmetic in another language is a number that would drift.
const READING_LINE = 0.3

let lastSeen = null
let queued = false

// A CLICKED ROW IS WHERE THE READER IS. The reading line is a guess
// about scrolling, and after a jump it guesses wrong three ways on the
// recipe page: Equipment and Ingredients sit in the sticky NEED rail
// beside Steps, so the DO column's block always wins the line; a short
// block (Watchpoints) lands with the next one already over the line;
// and a late one (Rescues, Keeps) cannot be scrolled to the top at
// all, so the at-bottom rule hands the mark to the Note. Each marked a
// row the reader did not choose.
//
// So a click on an in-page anchor names the section outright, and the
// guess is held off until the reader moves the page by hand — the
// scroll Main.jumpTo performs is ours, not theirs, and says nothing
// about what they are reading.
let pinned = null

document.addEventListener(
  'click',
  (event) => {
    const link = event.target.closest?.('a[href*="#"]')
    if (!link || link.pathname !== location.pathname || !link.hash) return
    const id = decodeURIComponent(link.hash.slice(1))
    if (!document.getElementById(id)) return
    pinned = id
    lastSeen = id
    app.ports.sectionSeen.send(id)
  },
  // capture: Browser.application handles the click on the way down
  // and the pin must be set before the jump it causes
  true,
)

// Releasing reads nothing by itself: the scroll that follows does. A
// pointerdown that turns out to be another row's click is re-pinned
// before any scroll arrives.
const release = () => {
  pinned = null
}
// The reader's own hand. pointerdown precedes the click that may pin
// a new row, and a scrollbar drag starts with one. Only keys that
// scroll count — Tab moving focus down the rail is not a new place.
const SCROLL_KEYS = new Set([
  ' ', 'ArrowUp', 'ArrowDown', 'PageUp', 'PageDown', 'Home', 'End',
])
for (const type of ['wheel', 'touchmove', 'pointerdown']) {
  addEventListener(type, release, { passive: true, capture: true })
}
addEventListener(
  'keydown',
  (event) => {
    if (SCROLL_KEYS.has(event.key)) release()
  },
  { passive: true, capture: true },
)

function readSection() {
  queued = false
  if (pinned !== null) {
    // the pinned section left the page (a navigation): stop holding it
    if (document.getElementById(pinned)) return
    pinned = null
  }
  // The document pages' sections, and the recipe page's blocks — the
  // recipe rail marks the block you are reading the same way the
  // contents rail marks a section.
  //
  // Zero-height sections are skipped rather than special-cased by
  // name: the recipe's prep card is display:none until asked for, and
  // a hidden element's rect puts its top at 0 — permanently "past the
  // reading line", which would pin the rail to a block nobody can
  // see.
  //
  // Cook mode adds `li[id]`, because its finest-grained thing to be
  // inside is a step, and a step is a list item. The rail marks which
  // step you are on the same way the others mark a section.
  const sections = [
    ...document.querySelectorAll(
      '.sheet section[id], .recipe section[id], ' +
        '.cook-layout section[id], .cook-layout li[id]',
    ),
  ].filter((section) => section.getBoundingClientRect().height > 0)
  if (!sections.length) {
    lastSeen = null
    return
  }

  const line = window.innerHeight * READING_LINE
  let seen = sections[0].id
  for (const section of sections) {
    if (section.getBoundingClientRect().top <= line) seen = section.id
  }

  // a final section shorter than the reading line would never become
  // active on its own, however far you scrolled
  const atBottom =
    window.innerHeight + window.scrollY >=
    document.documentElement.scrollHeight - 2
  if (atBottom) seen = sections[sections.length - 1].id

  if (seen !== lastSeen) {
    lastSeen = seen
    app.ports.sectionSeen.send(seen)
  }
}

function scheduleRead() {
  if (queued) return
  queued = true
  requestAnimationFrame(readSection)
}

addEventListener('scroll', scheduleRead, { passive: true })
addEventListener('resize', scheduleRead)

// Elm renders asynchronously and a route change fires no scroll event,
// so the DOM itself is the signal that the section list may have
// changed. The handler only schedules one rAF read, and that read
// sends nothing when the answer is unchanged — which is what makes
// this cheap enough to point at the whole body.
new MutationObserver(scheduleRead).observe(document.body, {
  childList: true,
  subtree: true,
})

scheduleRead()
