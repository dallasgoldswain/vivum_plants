// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "trix"
import "@rails/actiontext"

// Offline reading and queued observations (OF02, D84).
if ("serviceWorker" in navigator) navigator.serviceWorker.register("/service-worker.js", { scope: "/" })

// The browser's timezone, so due dates follow the collector's day (D117).
try {
  const zone = Intl.DateTimeFormat().resolvedOptions().timeZone
  if (zone) document.cookie = `time_zone=${encodeURIComponent(zone)}; path=/; max-age=31536000; SameSite=Lax`
} catch {}
