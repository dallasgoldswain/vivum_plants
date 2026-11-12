// Offline reading for the collection (OF02, D84, D94). Collection, plant and environment
// pages are fetched from the network first and fall back to the last copy; assets and photo
// thumbnails are cached once. Nothing else is cached: no seller, payment, order or account pages.
const VERSION = "v1"
const PAGES = `vivum-pages-${VERSION}`
const ASSETS = `vivum-assets-${VERSION}`
const COLLECTION_PAGE = /^\/(plants|environments|recipes|ingredients)(\/\d+)?\/?$/

self.addEventListener("install", () => self.skipWaiting())

self.addEventListener("activate", (event) => {
  event.waitUntil((async () => {
    const keep = [PAGES, ASSETS]
    for (const key of await caches.keys()) if (!keep.includes(key)) await caches.delete(key)
    await self.clients.claim()
  })())
})

self.addEventListener("fetch", (event) => {
  const request = event.request
  if (request.method !== "GET") return
  const url = new URL(request.url)
  if (url.origin !== self.location.origin) return

  if (url.pathname.startsWith("/assets/") || url.pathname.startsWith("/rails/active_storage/representations/")) {
    event.respondWith(cacheFirst(request))
  } else if (COLLECTION_PAGE.test(url.pathname) && (request.headers.get("Accept") || "").includes("text/html")) {
    event.respondWith(networkFirst(request))
  }
})

async function cacheFirst(request) {
  const cache = await caches.open(ASSETS)
  const cached = await cache.match(request)
  if (cached) return cached
  const response = await fetch(request)
  if (response.ok) cache.put(request, response.clone())
  return response
}

async function networkFirst(request) {
  const cache = await caches.open(PAGES)
  try {
    const response = await fetch(request)
    if (response.ok && !response.redirected) cache.put(request, response.clone())
    return response
  } catch {
    const cached = (await cache.match(request)) || (await cache.match(request, { ignoreSearch: true }))
    return cached || new Response(OFFLINE_PAGE, { headers: { "Content-Type": "text/html; charset=utf-8" } })
  }
}

const OFFLINE_PAGE = `<!doctype html><html lang="en-ZA"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Offline · VIVUM Plants</title><body style="font-family:system-ui,sans-serif;padding:2rem;background:#F5F3EE;color:#2B2B2A">
<h1>You're offline</h1><p>This page hasn't been saved on this device yet. Pages you've opened in your collection are available offline.</p></body></html>`
