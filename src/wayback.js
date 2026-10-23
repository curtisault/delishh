// The way back (docs/decisions.md, 2026-10-21): the recipe page's
// BACK and cook mode's EXIT go back through history when a page of
// this archive is behind them, and follow their own address when not.
//
// `history.back()` alone is wrong here. Every side-nav anchor is a
// pushed entry, so BACK after reading three blocks would walk up the
// same recipe a section at a time; and a recipe opened from a link in
// a message has nothing of ours behind it, so back would leave the
// app. Only the browser knows what is behind an entry, and it will
// not say — so every entry this shell pushes carries the answer in its
// own state: how many steps back the nearest *different page* is, or
// 0 for none. A page is the path and the query; a fragment is a place
// on one. The count rides in the entry, so it is right whichever way
// the reader arrived at it and survives a reload.

/** How far back the nearest different page is, from an entry's state. */
export const stepsBehind = (state) =>
  state && Number.isInteger(state.behind) && state.behind > 0 ? state.behind : 0

/**
 * The count a pushed entry carries. A new page has the page it was
 * pushed from one step behind it; a new place on the same page has
 * whatever that page had, one step further — and nothing, if that
 * page had nothing.
 */
export function behindOnPush(state, fromPage, toPage) {
  if (fromPage !== toPage) return 1
  const n = stepsBehind(state)
  return n > 0 ? n + 1 : 0
}

const pageOf = (url, base) => {
  const u = new URL(url, base)
  return u.pathname + u.search
}

/**
 * Stamp every entry the shell writes. Elm's `Nav.pushUrl` and
 * `replaceUrl` call these with an empty state it never reads back, so
 * the state is ours to fill. A landing entry, which nobody pushed,
 * keeps the browser's `null`: nothing of ours is behind it.
 */
export function keepTheWayBack(history, location) {
  const push = history.pushState.bind(history)
  const replace = history.replaceState.bind(history)
  history.pushState = (_state, title, url) =>
    push(
      { behind: behindOnPush(history.state, pageOf(location.href, location.href), pageOf(url, location.href)) },
      title,
      url,
    )
  history.replaceState = (_state, title, url) =>
    replace({ behind: stepsBehind(history.state) }, title, url)
}

/**
 * A press on a way-back link. Plain left clicks only: a reader asking
 * for a new tab gets the link's own address, which is what a new tab
 * can open. Captured before Elm's own handler on the link, which would
 * otherwise push the address as a new entry.
 */
export function followTheWayBack(document, history) {
  document.addEventListener(
    'click',
    (e) => {
      const link = e.target instanceof Element ? e.target.closest('[data-way-back]') : null
      if (!link || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return
      const n = stepsBehind(history.state)
      if (n === 0) return
      e.preventDefault()
      e.stopPropagation()
      history.go(-n)
    },
    true,
  )
}
