// Observations saved while offline (OF02, D84), kept in IndexedDB until they are sent.
// Each item carries the signed-in user's id, so it is only ever sent for that account.
const DB_NAME = "vivum-offline"
const STORE = "observations"
export const QUEUE_CHANGED = "offline-queue:changed"

function open() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1)
    request.onupgradeneeded = () => request.result.createObjectStore(STORE, { keyPath: "key" })
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
  })
}

async function run(mode, action) {
  const db = await open()
  return new Promise((resolve, reject) => {
    const transaction = db.transaction(STORE, mode)
    const result = action(transaction.objectStore(STORE))
    transaction.oncomplete = () => resolve(result.result)
    transaction.onerror = () => reject(transaction.error)
  })
}

export const queue = {
  add: (item) => run("readwrite", (store) => store.put(item)).then(changed),
  all: () => run("readonly", (store) => store.getAll()),
  update: (item) => run("readwrite", (store) => store.put(item)).then(changed),
  remove: (key) => run("readwrite", (store) => store.delete(key)).then(changed)
}

function changed() {
  window.dispatchEvent(new CustomEvent(QUEUE_CHANGED))
}

export function csrfToken() {
  return document.querySelector("meta[name=csrf-token]")?.content
}

// Sends one queued observation. Resolves "sent", "rejected" (the server refused it) or
// "offline" (try again later). The idempotency key means a resend never saves twice.
export async function send(item) {
  const body = new FormData()
  body.append("care_event[idempotency_key]", item.key)
  body.append("care_event[note]", item.note || "")
  body.append("care_event[occurred_at]", item.occurredAt || "")
  for (const file of item.files || []) body.append("care_event[photos][]", file, file.name)

  let response
  try {
    response = await fetch(item.url, { method: "POST", body, credentials: "same-origin", headers: { Accept: "application/json", "X-CSRF-Token": csrfToken() } })
  } catch {
    return { result: "offline" }
  }
  const data = await response.json().catch(() => ({}))
  if (response.ok) return { result: "sent", data }
  if (response.status === 422 && data.errors) return { result: "rejected", errors: data.errors }
  return { result: "offline" }
}
