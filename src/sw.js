// The service worker: public/_headers' cache policy, carried onto the
// device. docs/installable.md is the plan; this is the whole of it.
//
// NOT bundled. `deno task content` copies this file to public/sw.js
// with BUILD substituted, so every build is a worker that differs
// byte-for-byte — which is what makes a browser install the new one.
// Edit this file, never public/sw.js (gitignored).
//
// The policy mirrors _headers line for line, and must keep doing so:
//
//   /assets/*, /fonts/*   immutable by name → cache-first. A cached
//                         copy of a hashed or content-stable file is
//                         never wrong.
//   everything else       revalidates at the edge → network-first,
//                         the cache only when the network fails. An
//                         edited recipe is seen on the next open with
//                         a connection, the same promise the edge
//                         makes. /content/* is NEVER cache-first:
//                         that inversion is how the archive would
//                         disagree with itself in the reader's hand,
//                         and scripts/pwa_test.ts forbids it.
//   navigations           network-first; offline, the cached shell.
//                         This is _redirects done on the device, so
//                         Route.elm reads the address unchanged.
//
// What it does not do, deliberately: no update prompt, no push, no
// background sync, no timer with the app closed. See the plan.

const BUILD = '__BUILD__'
const CACHE = `delishh-archive-${BUILD}`

/** The shell's key. Every client route is index.html at the edge, so
 * one copy answers them all. */
const SHELL = '/'

const IMMUTABLE = ['/assets/', '/fonts/']

/** Every URL the shell needs to boot with no network: the page, and
 * the hashed bundle and fonts it names. Read out of the page and its
 * stylesheets rather than listed, because the names are Vite's and
 * change every build. */
async function shellUrls() {
  const page = await (await fetch(SHELL, { cache: 'no-cache' })).text()
  const urls = new Set([SHELL, '/manifest.webmanifest'])
  for (const [, url] of page.matchAll(/(?:src|href)="(\/(?:assets|fonts|icons)\/[^"]+)"/g)) {
    urls.add(url)
  }
  for (const css of [...urls].filter((u) => u.endsWith('.css'))) {
    const sheet = await (await fetch(css)).text()
    for (const [, url] of sheet.matchAll(/url\(['"]?(\/fonts\/[^'")]+)['"]?\)/g)) {
      urls.add(url)
    }
  }
  return [...urls]
}

/** The whole archive: the index, then every recipe it lists. Best-
 * effort and one at a time — a failure part-way keeps the recipes it
 * reached, and nothing waits on it but the install itself. Photos
 * are not fetched here: DS-01 §12 says lazily, and a pre-fetch of
 * every photograph is the opposite of lazy. */
async function keepArchive(cache) {
  try {
    const response = await fetch('/content/index.json', { cache: 'no-cache' })
    if (!response.ok) return
    await cache.put('/content/index.json', response.clone())
    const { recipes } = await response.json()
    for (const { slug } of recipes) {
      try {
        await cache.add(`/content/recipes/${slug}.json`)
      } catch (_) {
        // skipped: it will be kept the first time it is opened
      }
    }
  } catch (_) {
    // no archive this time; the shell alone still opens
  }
}

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE)
      // The shell must succeed — a worker that cannot boot the site
      // offline is not worth installing, and the old one stays.
      await cache.addAll(await shellUrls())
      await keepArchive(cache)
      await self.skipWaiting()
    })(),
  )
})

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      // One cache, this build's. Anything else is an old build's
      // hashed assets, and they only accumulate.
      for (const name of await caches.keys()) {
        if (name !== CACHE) await caches.delete(name)
      }
      await self.clients.claim()
    })(),
  )
})

async function cacheFirst(request) {
  const cached = await caches.match(request)
  if (cached) return cached
  const response = await fetch(request)
  if (response.ok) (await caches.open(CACHE)).put(request, response.clone())
  return response
}

async function networkFirst(request, key = request) {
  try {
    const response = await fetch(request)
    if (response.ok) (await caches.open(CACHE)).put(key, response.clone())
    return response
  } catch (error) {
    const cached = await caches.match(key)
    if (cached) return cached
    throw error
  }
}

self.addEventListener('fetch', (event) => {
  const { request } = event
  const url = new URL(request.url)
  if (request.method !== 'GET' || url.origin !== self.location.origin) return

  if (request.mode === 'navigate') {
    // An ok navigation is the shell (every route rewrites to it); a
    // 404 is not ok and is never kept under the shell's key.
    event.respondWith(networkFirst(request, SHELL))
  } else if (IMMUTABLE.some((prefix) => url.pathname.startsWith(prefix))) {
    event.respondWith(cacheFirst(request))
  } else {
    event.respondWith(networkFirst(request))
  }
})
