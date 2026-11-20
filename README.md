# VIVUM Plant Codex

A South African plant collection and seller operations platform. Collectors record their plants, growing setups and care. Sellers manage stock, run WhatsApp group auctions and DM claims, take payment through their own provider, pack, ship and hand over care packs. One account can do both.

- Product requirements: [docs/VIVUM_Plant_Codex_PRD_v1_3.md](docs/VIVUM_Plant_Codex_PRD_v1_3.md)
- Decision log: [docs/prd_decisions.md](docs/prd_decisions.md)
- Technical changelog: [CHANGELOG.md](CHANGELOG.md)
- User-facing release notes (for the future What's new page): [WHATS_NEW.md](WHATS_NEW.md)

Update `CHANGELOG.md` with every change, and `WHATS_NEW.md` whenever users would notice it.

## Stack

- Ruby 4.0.7 (`.ruby-version`), Rails 8.1
- PostgreSQL 18
- Hotwire (Turbo, Stimulus) with importmap; PWA and Hotwire Native clients planned
- Tailwind CSS v4 (`tailwindcss-rails`, standalone CLI, no Node) with BasecoatUI 0.3.11 components, themed to the [VIVUM Labs Design System](https://claude.ai/artifact/MhirAvmvZEph7unauXUNjM)
- Solid Queue (jobs), Solid Cache, Solid Cable in development and production, each in its own database (`*_cache`, `*_queue`, `*_cable`). Jobs run inside Puma in development; in production when `SOLID_QUEUE_IN_PUMA` is set, or via `bin/jobs`. Tests use the in-process test adapters.
- Action Text with Lexxy for rich text; Active Storage for uploads
- Kamal for deployment
- Installed for upcoming features (not used yet): RubyLLM with the `anthropic` and `openai` gems (keys from `ai.*` credentials, `config/initializers/ruby_llm.rb`), caxlsx and roo (Excel/CSV import and export), Redcarpet (Markdown), Prawn and prawn-table (PDFs), pdf-reader and docx (text from uploaded documents)
- Node.js, only for the Herb linter and formatter (run via `npx`)

## Getting started

Make sure PostgreSQL is running locally, then:

```sh
bin/setup
```

This installs gems, prepares the database and starts the server at http://localhost:3001 (set `PORT` to change it). Use `bin/setup --skip-server` to set up without starting it, and `bin/dev` to start it later. `bin/dev` runs the web server (with the job worker inside Puma) and the Tailwind watcher via `Procfile.dev`.

Emails (verification, password reset) are not sent in development; preview them at http://localhost:3001/rails/mailers. Production sends through [Resend](https://resend.com).

`bin/setup` also runs the seeds, which create your platform operator account from `user.admin_email` and `user.admin_password` in credentials (`bin/rails db:seed` to run them on their own). The account is created once and its password is never overwritten. You'll be asked to set up two-step sign-in the first time you sign in.

## Credentials

Edit with `bin/rails credentials:edit`.

| Key | Used for |
|---|---|
| `active_record_encryption.*` | Encrypting TOTP secrets in production (see below) |
| `user.admin_email`, `user.admin_password` | Seeded platform operator account |
| `resend.api_key` | Email delivery in production |
| `mailer_from` | From address on all emails, e.g. `VIVUM <hello@your-domain>` (must be a domain verified in Resend) |
| `db.password` | Production database password (`VIVUM_PLANTS_DATABASE_PASSWORD` overrides it) |
| `ai.anthropic_api_key`, `ai.openai_api_key` | RubyLLM (AI features not built yet) |
| `support_email` | Not used yet |

## Styling

- Stylesheet: `app/assets/tailwind/application.css` imports Tailwind and Basecoat (`vendor/stylesheets/basecoat.css`, vendored unchanged), then sets the VIVUM tokens, fonts and overrides. Tailwind builds it to `app/assets/builds/tailwind.css` (git-ignored).
- Components: use Basecoat classes (`btn`, `btn-outline`, `card`, `alert`, `badge`, `form`) and the `vv-` brand classes (`vv-h1`–`vv-h4`, `vv-kicker`, `vv-lead`, `vv-caption`, `vv-bg-*`, `vv-rule-organic`). Utilities like `bg-forest`, `text-moss`, `font-display` come from the palette.
- Layouts: `application` (sidebar on desktop, bottom nav on mobile, once signed in) and `auth` (brand panel plus form) for sign-in, sign-up, password, verification and two-step pages. Navigation items live in `app/views/shared/_nav_items.html.erb`.
- Brand assets: fonts in `app/assets/fonts`, icon in `public/icon.svg` and `public/icon.png`.
- Contrast: moss and cork fail 4.5:1 as text on linen, so kickers and italic heading words use forest on light backgrounds and moss only on deep.

## Authentication and authorisation

- **Sign-in:** Rails 8 authentication generator, extended with sign-up and email verification. Sessions are stored in the `sessions` table.
- **Two-step sign-in:** TOTP via `rotp`, with 10 single-use backup codes. Required for platform operators and seller owners; optional for everyone else.
- **Sellers:** a `Seller` business has `Membership`s with a role of `owner`, `manager` or `host_packer`. Each session records the seller it acts for; the membership is looked up on every request, so removing a member revokes access immediately.
- **Authorisation:** [Action Policy](https://actionpolicy.evilmartians.io). Policies receive the `user` and the current `membership`. Every controller action must call `authorize!` or opt out with `skip_verify_authorized`.

## Management area

[Madmin](https://github.com/excid3/madmin) at `/madmin`, for platform operators only. Visitors must be signed in, verified, a platform operator and enrolled in two-step sign-in; anyone else gets a 404. Resources live in `app/madmin/resources`. TOTP secrets and backup codes are never shown, and sessions and notifications are read-only.

## Feature flags

Every product capability has a key in `config/features.yml` (PRD §28): its domain, state (core, pilot, roadmap), whether it is implemented, its dependencies and any paid entitlement. [Flipper](https://www.flippercloud.io) stores which flags are on.

- **Checking a flag:** use `Capabilities.enabled?("seller.stock", user:, seller:)`, `requires_capability "seller.stock"` in a controller (404 when off) or `capability?("seller.stock")` in a view. Never call Flipper directly.
- **Rules:** unknown and unimplemented keys are always off; dependencies must be on for the same user and seller; paid entitlements deny until billing exists. Authorisation still runs after the flag check.
- **Console:** `/madmin/flags` (operators with two-step sign-in only). Turn a flag on for everyone, a seller (`Seller;3`) or a user (`User;12`). Disabling clears every target and acts as the emergency stop. Flags can't be created or deleted there.
- **Adding a feature:** add its key to `config/features.yml` (CI fails if code uses an unregistered key), set `implemented: true` when it ships, then run `bin/rails capabilities:sync` (also run by the seeds). In development, sync switches on implemented core flags.
- **Tests:** Flipper uses an in-memory store per test; enable flags with `Flipper.enable` or `Flipper.enable_actor`.

## Audit log

Every operator view and change in Madmin, every flag change, and account security events (sign-ins, failed sign-ins, sign-outs, password resets, email verification, two-step sign-in changes) are written to `audit_events` (D49–D52).

- **Recording:** `Audit.record("action.name", target: record, details: {...})`. The actor (stored as an id) and request details (IP, user agent, request id) come from `Current`.
- **Personal data (D53):** never put names, emails, phones or addresses in `details`. Use `Audit.email_fingerprint(email)` for a keyed hash that can be matched but not reversed. Madmin changes record field names only, with values just for the non-personal fields in `AUDITED_VALUES`; deletes record type and id; searches record that a search happened. `Audit::SECRET_PATTERNS` strips secrets as a backstop. IP address and user agent are kept for security investigations.
- **Protection:** PostgreSQL triggers (managed with `fx`, see `db/functions` and `db/triggers`) reject updates and any delete younger than 2 years. `PurgeAuditEventsJob` deletes older events daily at 03:00 (`config/recurring.yml`).
- **Reading:** operators open **Audit Events** in `/madmin` (read-only; viewing it is audited too).
- **Flag changes** are captured from Flipper's instrumentation; `FlagConsoleContext` tells the console who the operator is.

## Invites and the Sell area

Sellers join by invitation (SO03, D58–D63).

- **Seller invites:** operators create them in `/madmin` → Invitations with an email and business name, then resend, revoke or copy the link. Accepting creates the business and the owner membership.
- **Staff invites:** owners invite by email and role from Sell → Members, and change roles or remove members there. A business always keeps one owner (`Membership#last_owner?`).
- **Links** are signed tokens (`generates_token_for :acceptance`), not stored. They only work for a verified account with the invited email, expire after 14 days, and stop working once resent, revoked or used.
- **Owners** must accept the seller terms (`seller_terms` consent) and use two-step sign-in; both are enforced on their next request.
- **Flags:** `seller.workspace` (Sell area), `seller.members` (Members page and staff invites) and `seller.invites` (invite links). In development `bin/rails db:seed` turns them on; in production switch them on in `/madmin/flags`.

## Plans and billing

Seller billing (SB01–SB03, D64–D67). Paystack isn't built yet, so nobody is charged.

- **Plans** live in the `plans` table (Starter, Pro; `bin/rails db:seed` creates them). Operators edit prices (in cents) and limits in `/madmin` → Plans.
- **Seller billing** is `billing_mode` (pilot, comp; paid is blocked until Paystack), `plan` and an optional `free_until`. New sellers start in Pilot on Pro. Changing any of these in Madmin needs an audit reason, which is stored on the audit event.
- **Entitlements:** a capability's `entitlement:` in `config/features.yml` must be a boolean column on `plans`; `Capabilities.enabled?` checks it against the seller's plan.
- **Member limit:** members plus pending staff invites can't exceed `plan.member_limit`.
- **Ended free periods** show owners a notice on Sell and appear under the "Free period ended" scope in Madmin → Sellers. Access isn't reduced.

## Export, deletion and privacy requests

Data subject rights for account holders (§26, PR05, PR07, D68–D73). Never behind a feature flag.

- **Requests log:** every request is a `DataRequest` (kinds: export, deletion, access, correction, objection, other) with a 30-day `due_on` and an outcome. Operators work them in `/madmin` → Data requests (Open and Overdue scopes); closing one needs an outcome and records who handled it. Log requests that arrive by email with New.
- **Export:** Settings → Account → Export my data runs `ExportAccountJob`, which builds a zip from `AccountExport::SECTIONS` and emails a link valid for 7 days. **When a new domain ships, add its section there**: this user's data only, never other people's personal data.
- **Deletion:** `user.request_deletion!` switches the account off and ends its sessions; the `require_active_account` gate sends a signed-in pending account to "Keep my account" (`cancel_deletion!`). After 30 days `PrivacyHousekeepingJob` (daily, `config/recurring.yml`) calls `purge!`, which leaves an anonymised tombstone row. **When a new domain ships, wipe its personal data in `User::Deletable#purge!`.** The last owner of a seller can't delete their account.
- **Never hard-delete users:** audit events, consent records and requests point at the id. Madmin has no user destroy.
- Public help for app stores: `/account-deletion`.

## Consents

Consents live in `consent_records`, one row per grant or withdrawal; the latest row per purpose is the current choice (PR03, D54–D57).

- **Purposes and versions:** `ConsentRecord::PURPOSES` (terms and privacy for everyone, seller_terms for owners, then marketing_email, ai_processing and whatsapp_reminders). Bump a purpose's version when its wording changes: older grants stop counting. Bumping terms or privacy sends everyone to the acceptance page on their next request.
- **API:** `user.consented_to?(:ai_processing)`, `user.record_consent!(:marketing_email, granted: false, source: "settings")`. Check `consented_to?` before any AI request or WhatsApp send.
- **Gate:** `Authentication#require_current_consents` runs after email verification and two-step enrolment; skip it with `allow_without_current_consents` only for pages a user needs before accepting.
- **Pages:** `/legal/terms` and `/legal/privacy` (draft v0, pending legal review; text in `app/views/legal`), and Settings → Privacy at `/settings/privacy`. These are privacy controls and are never behind a feature flag.
- Records outlive a deleted account as proof of consent, for the audit retention period (2 years, D70); they are not in the audit log.

## Notifications

[Noticed](https://github.com/excid3/noticed) stores notifications in `noticed_events` and `noticed_notifications` (`user.notifications`). No notifiers exist yet; delivery channels from the PRD (email, native push, web push, WhatsApp) are added per notifier as features need them.

## Referrals

[Refer](https://github.com/excid3/refer) tracks who referred whom. Any link with `?ref=CODE` stores the code in a 30-day cookie, and sign-up credits the code's owner (`user.referral_codes`, `user.referrals`, `user.referrer`). Visit tracking is off (`config/initializers/refer.rb`) so no click data is stored. Nothing creates codes or rewards yet.

## Encryption keys

TOTP secrets use Active Record encryption.

- **Development and test** use fixed, non-secret keys in `config/environments/development.rb` and `test.rb`.
- **Production** reads keys from credentials. Generate them once and add the output to credentials:

  ```sh
  bin/rails db:encryption:init
  bin/rails credentials:edit
  ```

## Seller stock

Sell → Stock (B19, SE01, SE02, SE04, D155–D163). Everything belongs to a seller and is loaded through `authorized_scope(StockItem.all)` (the seller the session acts for), so another seller's stock is a 404.

- **Quantities** are never stored on `StockItem`. `Stock::Ledger` is the only writer: each change locks the item, then its `StockBalance` rows, writes one `StockMovement` and the balance together, and refuses negatives (also a check constraint), saleable below what's held, a specimen above one, and a second hold on a specimen. Movements are read-only once saved; correct a mistake with another movement.
- **Availability** is saleable − current holds (`StockHold.current`: active and not past its expiry). `ExpireStockHoldsJob` (every 5 minutes, `config/recurring.yml`) records expiries once.
- **Roles** live in `StockItemPolicy` (`manage_stock?` for owners and managers; `handle?` for any member; `see_prices?`).
- **Collection link:** `Stock::Transfer.from_plant!` creates a linked specimen and sets the plant to `moved_to_stock`; `Stock::Ledger#fulfil!` marks a linked plant sold; `#to_collection!` reverses a transfer for the member who made it.

- **Listings** (B20) never hold stock: `Listing#available` reads the item's availability. `SaleCard::Renderer` draws cards with libvips text (Pango); the Docker image needs `fonts-dejavu-core`. On macOS, libvips text uses CoreText, which crashes in forked processes, so `test/test_helper.rb` swaps in a stand-in for text inside forked test workers; CI on Linux renders real text.
- **Buyers** (B21) belong to one seller; phones are stored in E.164 (`PhoneNumber.normalise`, unique per seller) and `Buyer.search` matches any format. Aliases link to a buyer only by hand. `BuyerVerification` stores a token digest; `/v/:token` is public. `Buyer#erase!` keeps an anonymised row and rewrites the buyer's hold and movement text to "Deleted buyer". Host/packers never see contacts (`BuyerPolicy#see_contacts?`).
- **Orders** (B22) change only through `Order::Reserving` (`add_line!`, `change_quantity!`, `change_price!`, `remove_line!`, `reserve!`, `cancel!`, `fulfil!`), which locks the order and then its stock items in id order and calls `Stock::Ledger`. Each reserved line has its own stock hold, labelled with the order number; those holds can't be changed from the stock page. Payment state stays `unpaid` until B23.

## Collection

Collectors' plant records, environments, substrates, care, reminders, environment maintenance, tissue culture, guidance settings and the library (B10–B18, PL01–PL06, EN01–EN04, SU01–SU05, TC01–TC05, CA01–CA05, UX01, UX02, OF02, OF03, ST01–ST04, GU01, GU03, D80–D154). Plants, environments and recipes belong to one user only; controllers load them through `Current.user.plants`, `Current.user.environments` and `Current.user.recipes`, so another user's record is a 404.

- **Records:** `Plant` (record number `P-0001` from `users.last_plant_number`, never reused), `Acquisition` (cost in cents, original currency), `PlantStatusChange` (history), `CareEvent` (the timeline), `Photo`.
- **Environments:** `Environment` (fixed kinds, no nesting; archive, or delete only if it never held a plant), `EnvironmentAssignment` (dated stays; one open stay per plant, enforced by a partial unique index), `PlantSetup` (pot, size, watering from a date). `Plant::Placement#move_to!` and `#change_setup!` write the record plus a `movement` or `setup` care event; `#setting_on(date)` gives the environment and setup on a date. Moving into a type that implies another growing context offers to change it (`EnvironmentAssignment#context_offer?`).
- **Substrates:** `Ingredient` is built-in (no user, a `key`) or personal. Built-ins come from `db/seeds/ingredients.yml` through `Ingredient.sync_built_ins!`, which `db:seed` runs; never rename a key, and **run `bin/rails db:seed` on deploy** so file changes reach production. `Recipe` has numbered `RecipeVersion`s with `RecipeComponent`s. `Recipe#build_revision` decides whether a save edits the current version (no setup uses it) or makes the next one; `PlantSetup#recipe_version` points at an exact version. `Recipe::Scale` and `scale_controller.js` share the rounding rule. Public share links (`/r/:token`) use `SharedRecipesController` and the `public` layout.
- **Care:** `CareEvent` kinds are observations, logged care (`CareEvent::LOGGED_KINDS`) and the `movement`/`setup` events placement writes. `CareEvent::DETAILS` lists which detail columns each kind keeps. `Plant::Placement#repot!` saves a repot and its new setup together. `CareLogsController` logs for several plants, one event per plant with the key `"<key>:<plant id>"`. `CareEvent.latest_by_plant` feeds the last-care summary and the collection's watering line.
- **Reminders:** `CareSchedule` has at most one open `CareTask` (partial unique index); completing or skipping makes the next with `CareSchedule#next_due_after`. `CareTask#complete!` logs a linked `CareEvent`; a `CareEvent` created by hand completes `CareTask.completable_by(event)`, and destroying it calls `CareTask#reopen!`. `Plant#change_status!` pauses and resumes schedules. Today is `HomeController#show`. Requests run in `users.time_zone` (`ApplicationController#use_time_zone`), saved from the browser's `time_zone` cookie the first time.
- **Maintenance:** `EnvironmentEvent` is one entry per environment; `EnvironmentEventPlant` links the plants present on its date (relinked when the date changes). `Plant#timeline` reads them through `maintenance_events`. A `CareSchedule` or `CareTask` belongs to a plant or an environment (check constraint); the reminder controllers share `SubjectSchedules` and `SubjectSchedulePausing`, with views in `app/views/schedules`. `Environment#archive!` and `#restore!` pause and resume its reminders.
- **Tissue culture:** a TC purchase is an `Acquisition` with `tissue_culture: true`, created by `TissueCulture::Purchase` with one plant per plantlet; it isn't removed with its last plant. `Plant::TissueCulture` holds `change_stage!` (writes a `stage` event) and `split!` (`split_from`, `splitting` events). TC checks are `inspection` events with tick columns. `TissueCulture::Suggestions` is the code-owned table of stage reminders; schedules made from it have `origin: "tc_stage"`.
- **Guidance settings:** `GuidanceRevision` rows are the account's defaults, only ever added; `User#guidance_defaults` is the newest. Each plant copies the switches and revision on create (`Plant::Guidance`), and only changes them when edited or when the collector applies newer defaults. The AI switch is stored but hidden until `care.ai_guidance`.
- **Library:** `LibraryProfile` with no owner is a platform profile, published through `LibraryProfileVersion`s that operators manage at `/madmin/library_profiles` (publishing mirrors the version onto the profile row, which collectors read and copy). A user's profiles are their own copies or blank profiles; plants link only to those. `LibraryProfile::PlantSuggestions` works out a plant's pending suggested reminders; accepted ones are `CareSchedule`s with `origin: "library"` and `library_synced_at`. Sample platform profiles are seeded in development only (`db/seeds/library_samples.rb`); production profiles are published in Madmin.
- **Readings:** `Measurement` (one reading: time, source, idempotency key) with `MeasurementValue`s; fixed metrics and units in `Measurement::METRICS`, plus per-user `CustomMetric`s. Blank fields aren't stored.
- **Photos:** `Photo.build_from_upload` processes with libvips before storing (upright, 2560 px, metadata and location stripped, JPEG); originals are never kept. A photo belongs to a plant or an environment. Collectors can keep 500 (`Photo::COLLECTOR_LIMIT`). Stored with Active Storage on disk (`storage/`, the `vivum_plants_storage` Kamal volume in production). **Back up that volume**: photos aren't in the database.
- **Offline:** `app/views/pwa/service-worker.js` caches Today, collection, plant, environment, recipe and ingredient pages (network first), assets and photo thumbnails, nothing else. The `offline-form` Stimulus controller queues a form (observations, care, readings, Today's Done, Skip and Snooze) in IndexedDB when offline; `offline_sync` (on `<body>` when signed in) sends it with its idempotency key, so a resend never saves twice. The sign-in page clears cached pages. Bump `VERSION` in the worker to drop old caches. Tests: `bin/rails test test/system/offline_test.rb`.
- **New domain data:** add export sections in `AccountExport` and wiping in `User::Deletable#purge!` (done for plants, events, photos, environments, setups, readings, ingredients, recipes, guidance revisions and library profiles).

## Help manual and What's new

The public manual at `/help` (HM01, HM02, D74–D79). Topics are Markdown files in `app/help`, written in the same change as their feature.

- **A topic:** `app/help/<id>.md` with front matter: `id`, `title`, `summary`, `audience` (everyone, collector, seller), `capabilities` (keys from `config/features.yml`), `prerequisites`, `keywords` (search terms readers use, e.g. "MINE"). A topic shows only when all its capabilities are on for the reader; topics with none always show.
- **Shipping a feature:** CI fails while an implemented capability has no topic (mark operator-only tools `internal: true` in `config/features.yml`). Add a `help_link "topic-id"` (optionally `anchor: "heading-id"`) beside the page heading; a test checks each link's topic and heading exist.
- **Screenshots:** write `![Caption](name)` in a topic and add a capture to `test/system/help/screenshots_test.rb`, then run `bin/rails help:screenshots` (headless Chrome, not part of CI). It saves `app/assets/images/help/<name>-phone.png` and `-desktop.png`; check and commit them.
- **Review before release:** `bin/rails help:status` lists review state; after reading a topic, `bin/rails "help:review[topic-id]"` stamps `reviewed` and a digest of its text. Any later edit voids the review. In production, enabling a capability for everyone or a percentage in `/madmin/flags` is refused until its topics are reviewed (`FlagReleaseGuard`); enabling it for a user or seller, and turning anything off, always work.
- **What's new:** `/whats-new` renders `WHATS_NEW.md`. Signed-in users see a dot on the link until they open it after the newest `## YYYY-MM-DD` entry.

## Tests and checks

Run the full local CI (setup, style, security, architecture, tests):

```sh
bin/ci
```

Or individually:

| Check | Command |
|---|---|
| Tests | `bin/rails test` |
| Help screenshots | `bin/rails help:screenshots` (system tests, headless Chrome) |
| Offline behaviour | `bin/rails test test/system/offline_observation_test.rb` (headless Chrome, in CI) |
| Ruby style | `bin/rubocop` |
| HTML+ERB lint | `bundle exec herb lint` |
| HTML+ERB format | `bundle exec herb format --check` (fix with `bundle exec herb format`) |
| Architecture boundaries | `bundle exec archspec check` (rules in `Archspec.rb`) |
| Security | `bin/brakeman`, `bin/bundler-audit`, `bin/importmap audit` |

GitHub Actions runs the same checks on every push to `main` and every pull request (`.github/workflows/ci.yml`).

A git `pre-push` hook (`.githooks/pre-push`) runs Brakeman, bundler-audit (with a fresh advisory database) and importmap audit before every push, and blocks the push if any fails. `bin/setup` installs it with `git config core.hooksPath .githooks`. Skip it once with `git push --no-verify`.

## Deployment

Production runs at https://plants.vivumlabs.co.za. Kamal (`config/deploy.yml`) serves that host through kamal-proxy with a Let's Encrypt certificate; Rails assumes SSL from the proxy, forces HTTPS and only accepts that host (except `/up`). The server address and image registry in `config/deploy.yml` are still placeholders, and the production database is not set up yet. Production needs `RAILS_MASTER_KEY` and the credentials above.
