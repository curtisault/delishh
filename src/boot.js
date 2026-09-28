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
import './plan.css'
import './print.css'
import { Elm } from './Main.elm'

const THEME_KEY = 'delishh-theme'
const LIST_KEY = 'delishh-list'
const PLAN_KEY = 'delishh-plan'

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

// The meal plan, read raw for the same reason the list is.
let storedPlan = null
try {
  storedPlan = localStorage.getItem(PLAN_KEY)
} catch (_) {
  // storage unavailable: start with an empty week
}

const app = Elm.Main.init({
  flags: {
    theme: storedTheme,
    list: storedList,
    plan: storedPlan,
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

// The system bar of an installed app (and of Chrome on Android) takes
// its colour from the theme-color metas in index.html, which follow
// the OS lighting through their media queries. A lighting chosen on
// the page has to reach them too, or a dark page sits under a light
// bar. So an explicit choice paints both metas with the computed
// --stencil-bg — read, never written here, like every colour in this
// file — and "system" puts back the media and content index.html
// shipped.
const statusBars = [...document.querySelectorAll('meta[name="theme-color"]')].map(
  (meta) => ({ meta, media: meta.getAttribute('media'), content: meta.content }),
)

function paintStatusBar() {
  const chosen = document.documentElement.dataset.theme
  const bar = getComputedStyle(document.documentElement)
    .getPropertyValue('--stencil-bg')
    .trim()
  for (const { meta, media, content } of statusBars) {
    if (chosen && bar) {
      meta.removeAttribute('media')
      meta.content = bar
    } else {
      if (media) meta.setAttribute('media', media)
      meta.content = content
    }
  }
}
paintStatusBar()

app.ports.saveTheme.subscribe((theme) => {
  if (theme === 'light' || theme === 'dark') {
    document.documentElement.dataset.theme = theme
  } else {
    delete document.documentElement.dataset.theme
  }
  paintStatusBar()
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

app.ports.savePlan.subscribe((plan) => {
  try {
    // An empty week clears the key, as an empty list does: the
    // colophon says clearing the plan removes it, and `{}` stored
    // would make that a lie. This is also how the shell discards a
    // stored week it could not read.
    if (plan && Object.keys(plan).length > 0) {
      localStorage.setItem(PLAN_KEY, JSON.stringify(plan))
    } else {
      localStorage.removeItem(PLAN_KEY)
    }
  } catch (_) {
    // storage full or unavailable: the week holds for this session
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

// The meal plan's picture — docs/meal-planner.md, Phase 3.
//
// Elm hands over words and where they came from (Plan.toShare); this
// draws them onto a canvas and holds the one PNG that SHARE, COPY and
// SAVE all hand on. The page previews that same blob, so what the
// reader sees is what the receiver gets.
//
// NO COLOUR AND NO FAMILY IS WRITTEN HERE. Every colour is a theme.css
// token read off <html> at draw time, and every face is a --font-*
// stack, so theme.css stays the only place a hex lives and fonts.css
// the only place a family is spelled. `share_test.ts` holds both, and
// holds every token named below to theme.css: a misspelled token
// resolves to an empty string, and the canvas would silently draw it
// black. That is also why `token` throws on an empty answer — a
// picture that cannot be drawn honestly is reported as not drawn.

const PICTURE = {
  width: 1080, // a phone screen's width in device pixels
  pad: 72,
  band: 176, // the stencil masthead
  wordmark: 64,
  day: 30,
  meal: [46, 38, 32], // stepped down, never cut
  mark: 22, // ARCHIVE and the label, the data voice
  rowPad: 40,
  lead: 1.2,
  gap: 48, // between the day column and the meal
  between: 22, // between two meals on one day
  // One phone screen. Past it the meals' type steps down once, then
  // twice; past that the card grows taller, because a meal cut off a
  // picture is a broken picture (§12) and a taller card is only a
  // scroll. A week of one meal a day never comes near it, which is
  // what keeps that week's picture the first planner's, pixel for
  // pixel (docs/meal-planner-expansion.md, Phase 3).
  budget: 1920,
  steps: [1, 0.85, 0.72],
}

let picture = null // { url, blob, file }
// The draw the page is waiting for. A draw that finishes after the
// week changed (or after a newer draw began) is revoked on arrival and
// never reported, so a late answer can never replace, or release, the
// picture the page is showing.
let wantedDraw = null

function token(style, name) {
  const value = style.getPropertyValue(name).replace(/\s+/g, ' ').trim()
  if (!value) throw new Error(`theme token ${name} did not resolve`)
  return value
}

function forgetPicture() {
  if (picture) URL.revokeObjectURL(picture.url)
  picture = null
}

// Words onto lines no wider than `max`. A single word wider than the
// column breaks by character: a meal is never clipped and never
// ellipsised (§12, dense but never broken).
function wrap(ctx, text, max) {
  const lines = []
  let line = ''
  for (const word of text.split(/\s+/).filter(Boolean)) {
    const next = line ? `${line} ${word}` : word
    if (!line || ctx.measureText(next).width <= max) {
      line = next
    } else {
      lines.push(line)
      line = word
    }
  }
  if (line) lines.push(line)
  return lines.flatMap((l) => {
    if (ctx.measureText(l).width <= max) return [l]
    const broken = []
    let part = ''
    for (const ch of l) {
      if (part && ctx.measureText(part + ch).width > max) {
        broken.push(part)
        part = ch
      } else {
        part += ch
      }
    }
    if (part) broken.push(part)
    return broken
  })
}

async function drawPicture(rows) {
  const style = getComputedStyle(document.documentElement)
  const ink = {
    ground: token(style, '--surface'),
    tx: token(style, '--tx'),
    dim: token(style, '--tx-dim'),
    rule: token(style, '--rule-soft'),
    band: token(style, '--stencil-bg'),
    mark: token(style, '--stencil-mark'),
  }
  const face = {
    display: `700 ${token(style, '--font-display')}`,
    body: `500 ${token(style, '--font-body')}`,
    data: `400 ${token(style, '--font-data')}`,
  }
  const font = (voice, size) => {
    const [weight, ...stack] = face[voice].split(' ')
    return `${weight} ${size}px ${stack.join(' ')}`
  }

  // Every face at every size used, with the text it will draw, awaited
  // before the first stroke — so the latin-ext cut loads when a meal
  // needs it. A face that will not load falls to its stack, which is
  // what the page would do too.
  const meals = rows.flatMap((r) => r.meals)
  const words = meals.map((m) => m.meal).join(' ')
  const marks = ['ARCHIVE', ...meals.map((m) => (m.label || '').toUpperCase())].join(' ')
  try {
    await Promise.all([
      document.fonts.load(font('display', PICTURE.wordmark), 'DELISHH'),
      document.fonts.load(font('display', PICTURE.day), rows.map((r) => r.day.toUpperCase()).join('')),
      ...PICTURE.meal.map((size) => document.fonts.load(font('body', size), words || 'a')),
      document.fonts.load(font('data', PICTURE.mark), marks),
    ])
  } catch (_) {
    // fall through to the stack
  }

  const canvas = document.createElement('canvas')
  canvas.width = PICTURE.width
  const ctx = canvas.getContext('2d')

  // The day column is as wide as its longest name, so WEDNESDAY never
  // pushes a meal out of line with Monday's.
  ctx.font = font('display', PICTURE.day)
  const dayWidth = Math.max(...rows.map((r) => ctx.measureText(r.day.toUpperCase()).width))
  const mealX = PICTURE.pad + dayWidth + PICTURE.gap

  // A meal's mark: its label and where it came from, `LUNCH · ARCHIVE`,
  // or one, or neither. Measured per meal, since a label is a word of
  // its own width; for a meal with no label it is exactly the first
  // planner's ARCHIVE.
  const markOf = (m) =>
    [m.label ? m.label.toUpperCase() : null, m.source === 'archive' ? 'ARCHIVE' : null]
      .filter(Boolean)
      .join(' · ')

  // Lay out before drawing: the canvas's height is the sum of its rows,
  // and setting a canvas's height clears it. Laid out at each step of
  // the budget until one fits, or the last.
  const layOut = (step) => {
    const laid = rows.map((row) => {
      const entries = row.meals.map((m) => {
        const mark = markOf(m)
        ctx.font = font('data', PICTURE.mark)
        const markWidth = mark ? ctx.measureText(mark).width : 0
        const room = PICTURE.width - PICTURE.pad - mealX - (mark ? markWidth + 32 : 0)
        let size = PICTURE.meal[0] * step
        let lines = []
        for (const base of PICTURE.meal) {
          size = base * step
          ctx.font = font('body', size)
          lines = wrap(ctx, m.meal, room)
          if (lines.length <= 2) break
        }
        return { mark, size, lines, height: lines.length * size * PICTURE.lead }
      })
      // An empty day is one line tall at the first size, as it was.
      const first = entries[0] ? entries[0].size : PICTURE.meal[0] * step
      const body = entries.length
        ? entries.reduce((sum, e) => sum + e.height, 0) + PICTURE.between * step * (entries.length - 1)
        : first * PICTURE.lead
      return { day: row.day, entries, first, height: PICTURE.rowPad * 2 + body }
    })
    const height = PICTURE.band + laid.reduce((sum, r) => sum + r.height, 0) + PICTURE.pad / 2
    return { laid, height, step }
  }
  let layout = layOut(PICTURE.steps[0])
  for (const step of PICTURE.steps.slice(1)) {
    if (layout.height <= PICTURE.budget) break
    layout = layOut(step)
  }
  canvas.height = layout.height

  ctx.fillStyle = ink.ground
  ctx.fillRect(0, 0, canvas.width, canvas.height)

  // The masthead: the wordmark in the stencil's mark colour on the
  // stencil field — the site bar's pair, checked in both themes by
  // contrast_test.ts. Volt on the bare ground would be 1.06:1.
  ctx.fillStyle = ink.band
  ctx.fillRect(0, 0, canvas.width, PICTURE.band)
  ctx.fillStyle = ink.mark
  ctx.font = font('display', PICTURE.wordmark)
  ctx.textBaseline = 'middle'
  ctx.fillText('DELISHH', PICTURE.pad, PICTURE.band / 2)

  ctx.textBaseline = 'alphabetic'
  let y = PICTURE.band
  layout.laid.forEach((row, i) => {
    if (i > 0) {
      ctx.fillStyle = ink.rule
      ctx.fillRect(PICTURE.pad, y, canvas.width - PICTURE.pad * 2, 2)
    }
    // The day's name sits on its first meal's first line.
    const baseline = y + PICTURE.rowPad + row.first * 0.95
    ctx.fillStyle = ink.tx
    ctx.font = font('display', PICTURE.day)
    ctx.fillText(row.day.toUpperCase(), PICTURE.pad, baseline)

    let top = y + PICTURE.rowPad
    row.entries.forEach((entry) => {
      const line = top + entry.size * 0.95
      ctx.fillStyle = ink.tx
      ctx.font = font('body', entry.size)
      entry.lines.forEach((text, n) => {
        ctx.fillText(text, mealX, line + n * entry.size * PICTURE.lead)
      })
      if (entry.mark) {
        ctx.fillStyle = ink.dim
        ctx.font = font('data', PICTURE.mark)
        ctx.textAlign = 'right'
        ctx.fillText(entry.mark, canvas.width - PICTURE.pad, line)
        ctx.textAlign = 'left'
      }
      top += entry.height + PICTURE.between * layout.step
    })
    y += row.height
  })

  const blob = await new Promise((resolve, reject) =>
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error('no blob'))), 'image/png'),
  )
  const file = new File([blob], 'delishh-week.png', { type: 'image/png' })
  return { url: URL.createObjectURL(blob), blob, file }
}

async function sharePicture() {
  if (!picture) return 'failed'
  if (!navigator.canShare || !navigator.canShare({ files: [picture.file] })) return 'unsupported'
  try {
    await navigator.share({ files: [picture.file], title: 'The week' })
    return 'shared'
  } catch (err) {
    // AbortError is the reader closing the sheet; NotAllowedError is
    // the browser deciding the press was too long ago. Neither is a
    // share, and both are the reader's to know.
    return err && (err.name === 'AbortError' || err.name === 'NotAllowedError') ? 'refused' : 'failed'
  }
}

async function copyPicture() {
  if (!picture) return 'failed'
  if (!navigator.clipboard || !navigator.clipboard.write || !window.ClipboardItem) return 'unsupported'
  try {
    await navigator.clipboard.write([new ClipboardItem({ 'image/png': picture.blob })])
    return 'copied'
  } catch (err) {
    return err && err.name === 'NotAllowedError' ? 'refused' : 'failed'
  }
}

app.ports.sharePlan.subscribe(async (req) => {
  switch (req.do) {
    case 'draw': {
      wantedDraw = req.gen
      try {
        const made = await drawPicture(req.rows)
        if (req.gen !== wantedDraw) {
          URL.revokeObjectURL(made.url)
          break
        }
        forgetPicture()
        picture = made
        app.ports.planPicture.send({
          gen: req.gen,
          url: picture.url,
          canShare: !!(navigator.canShare && navigator.canShare({ files: [picture.file] })),
          canCopy: !!(navigator.clipboard && navigator.clipboard.write && window.ClipboardItem),
        })
      } catch (_) {
        if (req.gen === wantedDraw) app.ports.planPicture.send({ gen: req.gen, failed: true })
      }
      break
    }
    // Share and copy are called with no await before them, so they
    // stay inside the press that asked for them — Safari refuses both
    // outside a user gesture, and that is why the picture is made on
    // one press and sent on another.
    case 'share':
      app.ports.planShared.send(await sharePicture())
      break
    case 'copy':
      app.ports.planShared.send(await copyPicture())
      break
    case 'forget':
      wantedDraw = null
      forgetPicture()
      break
  }
})

// The service worker (docs/installable.md). Registered last, after
// everything the page needs is running, and only in a production
// build: in dev it would cache Vite's unhashed modules and fight HMR.
// A browser without the API boots exactly as it did before there was
// one. src/sw.js is the policy; public/sw.js is generated from it.
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(() => {
    // not installed: the site is fetched, as it always was
  })
}
