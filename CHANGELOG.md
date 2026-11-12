# Changelog

Technical changes to VIVUM Plants, for developers and operators. The user-facing
release notes for the in-app What's new page live in [WHATS_NEW.md](WHATS_NEW.md).

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are dated
releases (`YYYY.MM.DD`) once the app is deployed; until then everything sits under
Unreleased. Reference PRD requirement or decision IDs (e.g. SO02, D35) where they apply.

## [Unreleased]

### Added

- Rails 8.1 application on Ruby 4.0 and PostgreSQL 18, with Solid Queue, Solid Cache and
  Solid Cable each in their own database in development and production; jobs run inside
  Puma in development (D41).
- Authentication from the Rails 8 generator, extended with sign-up, email verification and
  database-stored sessions; passwords of at least 12 characters (D33).
- Two-step sign-in with TOTP (`rotp`) and 10 single-use, hashed backup codes; required for
  platform operators and seller owners. TOTP secrets use Active Record encryption (D34).
- `Seller` and `Membership` models with owner, manager and host_packer roles; sessions
  record the seller they act for and re-check membership on every request (SO01, SO02).
- Action Policy authorisation with user and membership context, `verify_authorized` on
  every controller, and `SellerPolicy` and `MembershipPolicy` (D35, D36).
- Madmin operator area at `/madmin`, restricted to operators with two-step sign-in;
  sessions and notifications read-only, TOTP secrets and backup codes hidden (D37).
- Noticed tables and `user.notifications`; no notifiers yet (D38).
- Refer referral tracking: `?ref=` cookie for 30 days, credited on sign-up, visit
  tracking off (D40).
- Admin seed from `user.admin_email` and `user.admin_password` credentials
  (`User.ensure_platform_operator!`).
- Email delivery through Resend in production; from address from `mailer_from` (D39).
- Tailwind CSS v4 with BasecoatUI 0.3.11 themed to the VIVUM Labs Design System; app shell
  (desktop sidebar, mobile bottom nav) and auth layout; brand fonts and icon (D42, D43).
- Action Text with Lexxy, and Active Storage.
- Gems installed for upcoming work: RubyLLM with `anthropic` and `openai`, caxlsx, roo,
  Redcarpet, Prawn, prawn-table, pdf-reader, docx (D44).
- Checks: ArchSpec architecture rules, Herb HTML+ERB lint and format, alongside RuboCop,
  Brakeman, bundler-audit and importmap audit, in `bin/ci` and GitHub Actions.
- Feature flags (B03): Flipper with the Active Record adapter, a code-owned registry of
  all 103 PRD capabilities in `config/features.yml`, `Capabilities.enabled?` implementing
  FF01's evaluation order, `requires_capability` / `capability?` helpers, the flag console
  at `/madmin/flags` behind `OperatorConstraint`, and `bin/rails capabilities:sync`
  (D46–D48).
- Audit log (B04): append-only `audit_events` with `Audit.record`; Madmin views and changes,
  flag changes (Flipper instrumentation, `FlagConsoleContext`) and account security events;
  PostgreSQL triggers via `fx` block updates and early deletes; `PurgeAuditEventsJob` purges
  after 2 years; read-only Audit Events in Madmin (D49–D52).
- Audit log keeps personal data to a minimum (D53): actor stored as an id only
  (`actor_email` column removed), attempted emails stored as HMAC fingerprints, Madmin
  changes recorded by field name with values only for allowlisted non-personal fields,
  deletes and searches recorded without record contents or search text.
- Consents (B05): append-only `consent_records` (latest record per purpose is current,
  versions code-owned in `ConsentRecord::PURPOSES`, deleted with the account) and
  `User::Consentable`; terms and privacy acceptance required on sign-up with an optional
  marketing opt-in; `require_current_consents` sends anyone without the current versions to
  `/consent_acceptance/new`; draft v0 terms and privacy notice at `/legal/terms` and
  `/legal/privacy`; Settings → Privacy (`/settings/privacy`) with one-action grant and
  withdraw and the full history; `privacy.consents` marked implemented (D54–D57).
- Seller and staff invites (B06): `Invitation` (seller and staff kinds, 14-day expiry,
  signed acceptance tokens voided by resend or revoke, accepted only by the invited verified
  email); operator seller invites in Madmin with resend, revoke and copy-link;
  `InvitationMailer`; invite page and acceptance that create the seller and owner membership
  and record the new `seller_terms` consent (owners must hold the current version); Sell area
  (`/sell`) with Members page for owners to invite, resend, cancel, change roles and remove;
  last-owner guard on `Membership`; `InvitationPolicy`; draft v0 seller terms with the POPIA
  operator agreement at `/legal/seller-terms`; `seller.workspace`, `seller.members` and
  `seller.invites` marked implemented; invitation and membership changes audited (D58–D63).
- Seller billing modes (B07): `plans` table seeded with Starter and Pro (prices, member,
  photo and AI limits, `paid_branding` entitlement column), editable in Madmin; sellers get
  `billing_mode` (pilot, comp, paid — paid blocked until Paystack), `plan` (Pro by default)
  and `free_until`; operator billing changes need `audit_reason`, stored as the audit
  event's reason; `Capabilities.entitled?` checks the seller's plan; staff invites respect
  the plan's member limit (members plus pending invites); Sell home shows the plan, owners
  see limits and an end-of-free-period notice; Madmin scope for ended free periods
  (D64–D67).
- Account export and deletion (B08): `data_requests` log for every data subject request
  (export, deletion, access, correction, objection, other) with a 30-day due date, outcome
  and handler, worked in Madmin with open and overdue scopes (PR05, D72). Settings → Account
  queues `ExportAccountJob`, which zips one JSON file per `AccountExport::SECTIONS` entry
  into private Active Storage and emails a 7-day signed download link (§26, D68). Deletion
  re-checks the password and two-step code, is refused for the last owner of a seller, ends
  every session and starts 30 days' grace; signing in offers "Keep my account"
  (`require_active_account` gate). `PrivacyHousekeepingJob` (daily) purges due accounts to
  an anonymised tombstone (`users.deleted_at`, no email, password or two-step secrets;
  "Deleted user #id" in Madmin), expires exports after 7 days and drops tombstones' consent
  records after the audit retention (PR07, D69–D71). Privacy request form on Settings →
  Privacy, public `/account-deletion` help page, `PrivacyMailer` emails, Madmin can no
  longer destroy users (D73). `rubyzip` added to the Gemfile.
- Help manual and What's new (B09): Markdown topics in `app/help` with front matter
  (audience, capabilities, prerequisites, keywords) loaded by `HelpTopic` and rendered by
  Redcarpet with escaped HTML and heading anchors; public `/help` with in-memory search
  (title, then keywords, then text) and `/help/:id`, listing only topics whose capabilities are
  live for the viewer (HM01, D74, D75). Eight first topics with phone and desktop
  screenshots from headless Chrome system tests (`bin/rails help:screenshots`, not in CI).
  `help_link` beside page headings (D78). Release check (HM02, D76, D77): a test fails when an
  implemented capability not marked `internal` has no topic; `bin/rails "help:review[id]"`
  stamps `reviewed` and a digest of the text; `FlagReleaseGuard` (production only) refuses
  global and percentage enables until the topic is reviewed, shown in the flag console.
  `/whats-new` renders WHATS_NEW.md, with `users.whats_new_seen_at` driving a dot on the link
  (D79). `help.manual` and `help.contextual` marked implemented.
- Plant records (B10): `plants` in a personal collection (D87) with a per-collection record
  number (`P-0001`, from `users.last_plant_number`, never reused, D81), five growing contexts
  (D80), TC origin, quantity, free-text tags (D85) and notes; `acquisitions` with cost in cents
  and its original currency (PL02); `plant_status_changes` history with effective date and
  reason (PL03); the `care_events` timeline with observations first and a unique per-user
  idempotency key (D82); `photos` processed on upload with libvips (upright, 2560 px long
  edge, all metadata including location stripped, JPEG), thumb and large variants, first photo
  as cover, 500-photo collector cap with warnings from 80% (OF03, D83). Collection grid and
  list with search over names, nickname, tags and record number and filters for context,
  status, TC origin and tag (UX01); permanent delete behind a warning with counts (D86).
  Offline (OF02, D84): service worker at `/service-worker.js` caches collection and plant
  pages network-first plus assets and thumbnails; observations queue in IndexedDB when
  offline and sync once via the idempotency key; the sign-in page clears cached pages.
  Plants, observations and photo files added to the account export; `purge!` removes them.
  Four help topics with screenshots; `collection.plants`, `collection.search`,
  `collection.media` and `collection.acquisition` marked implemented. App time zone set to
  Africa/Johannesburg. CI runs the offline system test in headless Chrome.
- Environments (B11): `environments` (seven fixed kinds, no nesting, optional dimensions,
  volume and photos, active or archived; EN01, D88); `environment_assignments` with dated
  stays and one open stay per plant (partial unique index), moves from the plant page or
  several plants from the environment page (EN03, D93); `plant_setups` for container, size and
  watering method from a date (PL05, D89). Moves and setup changes write `movement` and
  `setup` care events, and observations show the environment and setup on their date (D92).
  Moving into a type that implies another growing context offers to change it, once per stay
  (D91). `measurements` and `measurement_values` hold readings with unit, time and source;
  fixed metrics per kind in `Measurement::METRICS`, per-user `custom_metrics`, blanks never
  stored, range checks for typing slips (EN02, D90). Archive needs an empty environment;
  permanent delete only for one that never held a plant (D95). Photos belong to a plant or an
  environment (`photos_one_subject` check). Collection filter by environment; environment
  pages cached offline and readings queued offline through a generic `offline-form`
  controller (IndexedDB store renamed to `queue`, D94). Export sections and purge for all of
  it. Help topics `environments` and `measurements`; `collection.environments` and
  `collection.measurements` marked implemented. Shared `PhotoManaging` controller concern and
  `photos/_section` partial for plant and environment photos.
- Substrates (B12): `ingredients`, either built-in (no user, a `key`, synced from
  `db/seeds/ingredients.yml` by `Ingredient.sync_built_ins!` in `db:seed`, 42 entries,
  removed entries archived) or personal (generic or branded with a manufacturer); category,
  low/medium/high water retention and aeration labelled as guidance, particle size range in mm
  (SU01, D96, D97). Built-ins can't be edited; "Copy to mine" makes a personal copy.
  `recipes` with numbered `recipe_versions` (parts or percent, draft or ready) and
  `recipe_components`; a % version must total 100% to be ready; an unused version is edited
  in place and a change to a version a setup uses saves the next number (SU02, SU04, D98,
  D99). `Recipe::Scale` and `scale_controller.js` round each component to 50 mL (25 mL under
  1 L) and show the rounded total (SU03). `plant_setups.recipe_version_id` (restrict) with a
  picker of the newest ready version of each active recipe; the recipe page lists plants per
  version, current and past (D100). Archive used recipes and ingredients, delete unused ones
  (D101). Public share link at `/r/:token` (revocable, `noindex`, no notes or plants, needs
  the owner's `substrate.share`) on a new `public` layout; recipe search by name and
  ingredient, context and use filters; recipe and ingredient pages cached offline (D102).
  Export sections `ingredients` and `recipes`, setups export their recipe version, `purge!`
  removes them. Help topics `ingredients` and `recipes`; `substrate.ingredients`,
  `substrate.recipes`, `substrate.scaling` and `substrate.share` marked implemented. Browser
  tests for offline scaling and the recipe form in `offline_test.rb`.
- Git `pre-push` hook (`.githooks/pre-push`, installed by `bin/setup`) running Brakeman,
  bundler-audit with `--update`, and importmap audit before each push.
- Docs: PRD v1.3 and the decision log (D01–D44).

### Fixed

- Editing a plant or an environment was refused ("You don't have access to that"): Action
  Policy has no default `edit?` rule. `PlantPolicy` (and so `EnvironmentPolicy` and
  `RecipePolicy`) now aliases `edit?` to `update?`, with tests for both edit pages.

- Layout `<body>` offline-sync attributes rewritten for the Herb rule against ERB output in
  attribute position.

### Configuration

- Production domain `plants.vivumlabs.co.za`: host allowlist (except `/up`), `assume_ssl`,
  `force_ssl`, mailer link host, and Kamal proxy with Let's Encrypt (D32).
- Development runs on port 3001; `bin/dev` starts web and the Tailwind watcher via
  `Procfile.dev`.
- Production database password from `VIVUM_PLANTS_DATABASE_PASSWORD` or `db.password` in
  credentials.
- Fixed, non-secret Active Record encryption keys for development and test only; production
  keys must be added to credentials.
- `code` added to filtered log parameters.

### Not done yet

- Kamal server address and image registry are placeholders; production database not set up.
- Operator audit log for Madmin changes (O14).
- Production Active Record encryption keys in credentials.
