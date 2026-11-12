# VIVUM Plants — Build-out plan

A living plan that turns PRD v1.3 into buildable features. We discuss each feature before
building it; the outcome of each discussion is recorded under the feature (and in
[prd_decisions.md](prd_decisions.md) when it settles a product question).

Order follows PRD §31 (foundation → shared domain → flows → clients → connected → pilot),
adjusted for what already exists. **Agreed order (2026-11-10):** foundation B03–B06 first, then the
seller domain (Phase 3) before the collector domain (Phase 2), because the pilot scenario is
seller-led. Each feature ships with its flag(s) (§28), help topic
(HM02), tests and a CHANGELOG entry, and a WHATS_NEW entry if users would notice it.

**Status:** Done · Partial · Next · Planned · Discussing

## Phase 1 — Foundation

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B01 | Accounts, sign-up, email verification, two-step sign-in | §3, D33–D34 | — | Done |
| B02 | Sellers, memberships, roles, Action Policy | SO01, SO02, D35 | B01 | Done (no member management UI) |
| B03 | Feature flag registry and capability service | §28 FF01–FF04 | B01 | Done (entitlements stubbed until B07; audit via B04) |
| B04 | Audit log: operator changes and views, flag changes, account security events | PR08, FF04, O14 | B03 | Done |
| B05 | Consent records, terms and privacy acceptance, Privacy settings | PR02, PR03, PR04, ST06, D15 | B01 | Done |
| B06 | Seller and staff invites, onboarding (invite-only), Sell home and Members | SO02, SO03, D17, D58–D63 | B02, B04 | Done |
| B07 | Seller billing modes: Pilot, Comp, Paid (Paystack later) | SB01–SB03, D21, D64–D67 | B06 | Done (Paystack later) |
| B08 | Account export and deletion | §26 export, PR05, PR07, OF01 store rules | B01 | Done |
| B09 | Help manual skeleton and contextual links | HM01, HM02 | B03 | Done |

## Phase 2 — Seller domain (built before the collector domain)

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B19 | Stock items, lots and the stock ledger (plant-record link added with B10) | SE01, SE02, SE04 | B02 | Planned |
| B20 | Listings and sale cards (share/download) | SE03, SE07, SE08 | B19 | Planned |
| B21 | Buyers, aliases and phone verification | BY01–BY03 | B02 | Planned |
| B22 | Orders, holds, cancellations, returns | SE05, SE06 | B19, B21 | Planned |
| B23 | Manual payments and receipts / VAT invoices | PY03 manual, RC01, D08 | B22 | Planned |
| B24 | CSV stock import with preview | IM01, IM02 | B19 | Planned |
| B25 | Live sale sessions, auctions, Quick Claim, backup bidder | LS01–LS04, D14 | B22 | Planned |
| B26 | Sale Closeout | SC01, SC02 | B25 | Planned |
| B27 | Packing checklist and parcel slips; pickup and manual tracking | PK01, PK02, SH (manual) | B22 | Planned |
| B28 | Plant requests, offers and Wanted List | RQ01, RQ02, WL01 | B19, B21 | Planned |
| B29 | Seller business profile and standard branding | BR01 | B02 | Planned |
| B30 | Buyer links (order, tracking, receipt) | WB01 | B22, B23 | Planned |
| B31 | Care sheets, care packs, PDF, QR labels (seller-written templates until the library, B18, exists) | CP01, CP02, QR01 | B22 | Planned |
| B32 | Copy to collection from a care pack (after the collector domain) | CP03, BY04 | B31, B10 | Planned |
| B33 | Plant Sitter | PS01, PS02 | B14 | Planned |

## Phase 3 — Collector domain

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B10 | Plant records, acquisition, status, photos, search | PL01–PL04, UX01, OF02, OF03, D80–D87 | B03 | Done |
| B11 | Environments, occupants, measurements | EN01–EN03, PL05, D88–D95 | B10 | Done |
| B12 | Substrate ingredients and versioned recipes, scaling | SU01–SU05 | B10 | Planned |
| B13 | Care events and quick care entry | CA01, UX02, PL04 | B10 | Planned |
| B14 | Reminders, schedules and Today inbox | CA02–CA05 | B13 | Planned |
| B15 | Shared environment maintenance | EN04 | B11, B14 | Planned |
| B16 | Purchased tissue culture: groups, splits, stages | PL06, TC01–TC05 | B10, B14 | Planned |
| B17 | Guidance settings and new-plant defaults | ST01–ST05 | B10, B05 | Planned |
| B18 | Built-in library profiles (~50 species) and suggestions | GU01, GU03, D10, D29 | B14, B17 | Planned |

## Phase 4 — Clients and notifications

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B34 | Notifications: in-app, email digest, web push | NT01, NT02, NT04 | B14 | Planned |
| B35 | PWA install and offline care logging | OF02 | B13 | Planned |
| B36 | Hotwire Native iOS and Android apps, native push | OF01, D12, D27 | B34 | Planned |

## Phase 5 — Connected flows (each behind a pilot flag)

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B37 | AI care suggestions | GU02, GU04, AI01–AI04, D23, D24 | B18, B05 | Planned |
| B38 | WhatsApp connection and outbound templates | WA01, WA03, WA04, NT03, D22 | B21 | Planned |
| B39 | WhatsApp DM claims and request capture (AI extraction) | WA02, RQ01, AI02 | B38, B25, B28 | Planned |
| B40 | Bob Pay checkout | PY01, PY02 | B23, B30 | Planned |
| B41 | Yoco checkout | PY01, PY02, O6 | B40 | Planned |
| B42 | Bob Go shipping | SH01, SH02 | B27 | Planned |
| B43 | Paystack seller subscriptions and paid branding | SB01, SB02, BR02 | B07, B29 | Planned |

## Phase 6 — Pilot

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B44 | Pilot readiness: POPIA review, app store review, production deploy, rollout | §31 step 6, D25–D27 | all pilot features | Planned |

---

## Feature discussions

Each feature gets a section here when we discuss it: scope for this iteration, decisions,
what is deferred, and the acceptance tests it must pass.

### B03 Feature flags — discussed 2026-11-10

**Scope**
- Flipper with the Active Record adapter stores flag state; flipper-ui is mounted at
  `/madmin/flags`, behind the same check as Madmin (operator, verified, two-step sign-in).
- A code-owned registry (`config/features.yml` or a Ruby registry) lists every PRD §28 key with
  its domain, initial state (core, pilot, roadmap), `implemented` (false until built),
  dependencies, owner and off behaviour. All ~90 keys are registered now.
- One capability service (`Capabilities.enabled?(key, user:, seller:)`) is the only way code asks
  about a feature, in controllers, views, jobs and callbacks. It checks, in order: registered and
  implemented → emergency stop → Flipper (global, seller, user) → dependencies → entitlement
  (stub until B07) → then the caller's Action Policy check. Unknown or unimplemented keys deny.
- Targeting: global on/off, per seller business, per user account. No percentage rollouts.
- CI: a test fails if code references an unregistered key or the registry and Flipper disagree;
  each implemented key gets enabled and disabled tests as its feature is built.
- Flag changes are recorded by the audit log (B04) via Flipper's instrumentation.

**Deferred:** entitlement checks (B07), percentage rollouts, flag-specific help topics (B09).

**Acceptance:** AT30 (server-side gating, reconciliation after writes disabled), plus: an
unknown key denies; an unimplemented key denies even if enabled in Flipper; a hidden button's
URL is refused when its flag is off; a seller-targeted flag is on for that seller only.

### B04 Audit log — discussed 2026-11-10

**Scope**
- One append-only `audit_events` table: actor (user, or none for system/anonymous), action
  (e.g. `madmin.update`, `flag.enable_actor`, `session.failed`), target (polymorphic type and
  id, or a flag key), changes (before/after JSON, secrets filtered), optional reason, IP
  address, user agent, request id, time. Written synchronously through one `Audit.record` API.
- Events recorded:
  - **Operator changes in Madmin:** create, update and delete of every resource, with
    filtered before/after values.
  - **Operator record views:** an operator opening a Madmin index or record (PR08 access).
  - **Flag changes:** every enable, disable, actor add/remove in `/madmin/flags`, captured
    from Flipper's instrumentation with the operator from the session.
  - **Account security:** sign-in, failed sign-in (attempted email, IP), sign-out, password
    reset requested and completed, two-step on and off, backup codes replaced and used,
    email verified.
- Operators read the log in Madmin (read-only, filter by actor, action and target).
- Tamper resistance: PostgreSQL triggers reject UPDATE, and DELETE of rows younger than
  2 years.
- Retention: 2 years, purged by a daily Solid Queue recurring job. To confirm with the
  attorney (O13).

**Decisions:** custom table rather than paper_trail or audited; personal data minimised
(D53: actor id only, email fingerprints, field names instead of values for personal fields); flag-change reasons optional
until we build our own flag screens (Flipper's console has no reason field).

**Deferred:** required reasons for flag changes; export of audit events; seller-facing
activity history (stock movements and order changes keep their own records, SE02).

**Acceptance:** an operator edit, view and flag change each create one event naming the
operator; a failed sign-in records the attempted email and IP; audit rows can't be updated
or deleted early; secrets (password digests, TOTP secrets, codes) never appear in changes;
non-operators can't read the log.

### B05 Consents — discussed and built 2026-11-10

**Scope**
- **Purposes:** terms of use, privacy notice, email marketing (off by default, PR04), AI
  processing (required before any AI request, D15), WhatsApp reminders (NT03).
- **Records:** an append-only `consent_records` table: user, purpose, version of the text
  agreed to, granted or withdrawn, source (sign-up, settings, in context, re-acceptance), IP,
  user agent, time. The current state is the latest record per purpose; withdrawing adds a
  record rather than editing one. Records are deleted with the account (unlike the audit log).
- **Legal text:** draft v0 terms of use and privacy notice in plain language, marked "Draft
  for the pilot, pending legal review", served as public pages (`/legal/terms`,
  `/legal/privacy`). Versions are code-owned; publishing a new version makes everyone accept
  again. The privacy notice names the audit log's IP and browser data (D53) and the AI and
  WhatsApp processors (PR06).
- **When asked:** terms and privacy acceptance (required) and the marketing opt-in on the
  sign-up form; AI and WhatsApp asked in context when those features arrive (B37, B38); all
  of them viewable and changeable on a **Settings → Privacy** page.
- **Existing accounts:** anyone without acceptance of the current terms and privacy versions
  sees an acceptance page before using the app (including the seeded admin).
- **Flags:** `privacy.consents` becomes implemented. Terms acceptance and the Privacy page are
  privacy controls, so they are never switched off by a flag.

**Deferred:** buyer consents per seller (with B21), the data subject request tools
(`privacy.dsr`, B08), WhatsApp phone number capture (B38), consent wording for AI providers
once models are chosen per use case (B37).

**Acceptance:** sign-up without accepting terms and privacy fails; a new terms version sends
existing users to re-accept; withdrawing marketing or AI consent takes effect at once and is
recorded as a new record; consent history shows who, what version, when and where; withdrawing
is as easy as granting (one action on the Privacy page).

### B06 Seller and staff invites — discussed and built 2026-11-10

**Scope**
- **One invite model** for both kinds: email, seller (or business name for a new seller),
  role, inviter, token, expiry (14 days), accepted/revoked timestamps. Accepting needs an
  account whose email matches the invite (D58); a mismatched account is told to sign in with
  the invited address.
- **Seller invites (SO03, D17):** operators create them in Madmin with email and business
  name, and can resend (new link, old one void) or revoke. Accepting asks the owner to confirm
  the business name and accept the **seller terms** (draft v0 with the operator agreement,
  `/legal/seller-terms`, a versioned `seller_terms` consent, D60), then creates the seller and
  the owner membership. Owners already must use two-step sign-in, so acceptance leads to
  enrolment if it isn't on.
- **Staff invites (SO02, D61):** owners invite by email and role from **Sell → Members**,
  change roles, remove members, and resend or revoke pending invites. Owners may invite or
  promote owners; the last owner can't be removed or demoted. Removal takes effect on the
  member's next request (memberships are looked up per request).
- **Delivery (D59):** invite email through Resend, plus a copy-link button for WhatsApp.
- **Sell area (D63):** a Sell nav item shown only to members, a Sell home page (business
  name, your role, what's coming) and the Members page. Gated by `seller.workspace`,
  `seller.invites` and `seller.members`, all marked implemented.
- **Audit:** invite created, resent, revoked and accepted; role changed; member removed.
  Emails are not stored in audit details (D53).
- **Policies:** `InvitePolicy` and `MembershipPolicy` — only owners manage members.

**Deferred:** business profile with legal name, VAT and contacts (BR01, B19+), self-serve
seller sign-up (roadmap), billing mode on new sellers (B07 sets Pilot on Pro).

**Acceptance (AT32):** an uninvited account can't open Sell; an expired, revoked or
already-used invite can't be accepted; an invite can't be accepted by a different email; a
seller invite creates exactly one seller and owner membership and records seller terms
acceptance; a manager or host/packer can't manage members; the last owner can't be removed or
demoted; a removed member loses access on their next request.

### B07 Seller billing modes — discussed and built 2026-11-11

**Scope**
- **Plans (D65):** `plans` table (key, name, monthly price in cents ZAR, member limit, photo
  limit, AI extractions per month, entitlements such as `paid_branding`, active). Seeded with
  Starter and Pro; editable in Madmin.
- **Billing on the seller (SB03, D64):** mode (`pilot`, `comp`, `paid`), plan, optional end
  date. New sellers from invites start in Pilot on Pro (D25). Operators change mode, plan and
  end date in Madmin with a **required reason**; each change is audited with operator, old
  and new values and reason. `paid` can't be chosen until Paystack exists.
- **Entitlements (SB02, D66):** `Capabilities.entitled?` checks the seller's plan, so
  `seller.paid_branding` needs Pro. Enabling a flag never grants an entitlement.
- **Member limit (D66):** members plus pending staff invites can't exceed the plan's limit;
  the Members page shows "3 of 5" and blocks new invites at the limit. Existing members are
  never removed if a plan shrinks.
- **Plan status:** Sell home shows mode, plan and end date to all members; owners see the
  limits.
- **End date (D67):** once passed, owners see a banner asking them to choose a paid plan
  (with "coming soon" until Paystack) and Madmin flags the seller as ended. No access is lost.

**Deferred:** Paystack checkout, subscriptions, webhooks, grace periods and read-only mode
(SB01, SB02, own item); photo and AI limit enforcement (with B19+ and B37); collector billing
(never charged).

**Acceptance:** a comp seller on Pro can use paid branding with no Paystack record; a Starter
seller can't; only operators change billing mode and every change is audited with a reason;
inviting beyond the member limit fails; an ended free period shows the prompt without
removing access; Paid can't be selected yet.


### B08 Account export and deletion — discussed and built 2026-11-11

**Scope**
- **Data requests log (PR05, D72):** one `data_requests` table (user, kind: export, deletion,
  access, correction, objection, other; message; status; due date 30 days after the request;
  outcome; handled by; completed at). Operators work open requests in Madmin, with an overdue
  scope; every status change is audited.
- **Export (§26, D68):** Settings → Account → "Export my data" queues a job that writes a
  JSON zip to private storage: profile, preferences, memberships, consents, invites sent and
  received, referrals and notifications. Each domain adds a section through one exporter
  registry as it ships (plants, photos, setups and so on). The email links to a signed
  download that expires in 7 days; only one export runs at a time.
- **Deletion (PR07, D69–D71, D73):** Settings → Account → "Delete account" asks for the
  password and two-step code if on, explains the 30 days, and refuses if the user is the last
  owner of any seller. Confirming deactivates the account, ends all sessions and sends an
  email. Signing in within 30 days offers "Cancel deletion"; after that a daily job purges:
  personal fields wiped, sessions, backup codes, notifications, referrals, memberships,
  pending invites and attachments removed; the row stays as an anonymised tombstone.
  Consent records are purged after 2 years with the audit log.
- **Privacy requests form (D72):** Settings → Privacy, kind plus message; confirmation email.
- **Public page (D73):** `/account-deletion` explains how to delete an account and what is
  kept.
- Flags `account.export`, `account.deletion` and `privacy.dsr` marked implemented.

**Deferred:** buyer requests (`privacy.buyer_dsr`, with B21); backup expiry (90 days) is a
hosting setting, not code; per-domain export sections arrive with each domain.

**Acceptance:** an export zip contains the user's records and no one else's; the link
expires after 7 days; a deleted account can't be used, its sessions end at once, and signing
in within 30 days can cancel; after 30 days personal data is gone and audit events show
"Deleted user #id"; the last owner of a seller can't delete their account; every request has
a logged outcome and a due date.

### B09 Help manual and What's new — discussed and built 2026-11-11

**Scope**
- **Topics (D74):** `app/help/<id>.md` with front matter (id, title, audience, capabilities,
  prerequisites, keywords, reviewed, reviewed_digest). A `HelpTopic` loader parses and
  caches them; Redcarpet renders the body (safe HTML, heading anchors).
- **Manual (HM01, D75):** public `/help` (search plus topics grouped by audience) and
  `/help/:id`, mobile-friendly, in a help layout that shows the app shell when signed in.
  Only topics whose capabilities are live for the viewer are listed or reachable. Search
  ranks title, then keywords, then text.
- **First topics:** cover what exists: signing up and verifying, two-step sign-in, privacy
  and consents, exporting and deleting your account, accepting an invite, Sell home,
  members and invites, plans. The PRD search terms for later features (MINE, backup
  bidder, closeout and so on) arrive with those features.
- **Contextual links (D78):** a `help_link("topic-id", anchor:)` helper rendering a small
  Help link beside page headings, added to the existing pages.
- **Screenshots (D78):** headless Chrome system tests under `test/system/help`, one per
  topic that needs images, saving phone and desktop PNGs to `app/assets/images/help`;
  `bin/rails help:screenshots` runs them. Topics embed them with captions.
- **Release check (HM02, D76, D77):** a test that every implemented capability not marked
  internal has a topic; `bin/rails "help:review[id]"` stamps the date and digest; in
  production, Flipper global or percentage enables are refused for a capability whose
  topic isn't reviewed, with the reason shown in the flag console (actor enables and
  disables pass).
- **What's new (D79):** `/whats-new` renders WHATS_NEW.md; `users.whats_new_seen_at` drives a
  dot on the sidebar link until the user opens it.
- Flags `help.manual` and `help.contextual` marked implemented.

**Deferred:** topics for features not built yet (each feature adds its own); translations;
a help side sheet (links open the page for now).

**Acceptance:** a signed-out visitor can search and read live topics; a topic for a
capability that's off is neither listed nor reachable, but is for a user it's enabled for;
search for a keyword finds its topic; CI fails when an implemented capability has no
topic; a global enable of a capability with an unreviewed or edited topic is refused in
production while an actor enable works; screenshots regenerate from the task; What's new
shows a dot until opened.

**Built notes:** the production guard is a Flipper adapter wrapper (`lib/flag_release_guard.rb`),
so it also covers enables from a Rails console; `FlagConsoleContext` turns a refusal into the
console's error message. `using-help` covers both help flags. All eight first topics start
unreviewed: review them with `bin/rails "help:review[id]"` before enabling their flags
globally in production. The dot uses dated `## YYYY-MM-DD` headings in WHATS_NEW.md, so until
the first dated release it shows only for users who have never opened the page.

### B10 Plant records — discussed and built 2026-11-11

**Scope**
- **Plants (PL01, D80, D81, D87):** `plants` owned by a user: record number (P-0001 per
  collection, never reused), display name (required), botanical name, cultivar, common name,
  nickname, growing context (indoor, terrarium, paludarium, aquatic, outdoor; required),
  TC origin (yes/no), origin note, quantity (default 1, non-negative), notes. Unknown
  identity and duplicate names allowed; renaming keeps the record number and history. The
  library profile link waits for B18.
- **Acquisition (PL02):** `acquisitions` (date, source, cost in cents with ISO currency,
  default ZAR, order reference, quantity, arrival notes), one per plant for now and shaped to
  cover several plants for purchase groups (B16). Cost optional; no market value.
- **Status (PL03):** active, quarantined, lost, sold, gifted, archived, with a dated
  `plant_status_changes` history (effective date, reason) shown on the timeline. Inactive
  plants leave the active collection; "stop reminders" hooks in with B14.
- **Timeline and observations (PL04, D82):** `care_events` (plant, kind `observation`, note,
  event date and time, entered at, idempotency key unique per user). Photos attach to a plant
  or an event with caption and taken-on date; one cover photo per plant.
- **Photos (OF03, D83):** Active Storage on local disk (Kamal volume in production), resized
  to 2560 px with EXIF location stripped, thumbnail variants; 500-photo cap per collector with
  warnings at 80% and 100%; at the cap new uploads are refused and the typed note is kept;
  deleting photos frees quota.
- **Collection and search (UX01, D85):** grid and list, search over names, nickname, record
  number and tags (PostgreSQL, trigram); filters for context, status and TC origin
  (environment and care due arrive with B11 and B14); empty state with "Add a plant".
- **Tags (D85):** free text, suggested from the collector's own tags.
- **Deletion (D86):** archive first; permanent delete after a warning with counts.
- **Offline (OF02, D84):** service worker caching the collection list and plant pages for
  offline reading; observations and photos queued offline (IndexedDB) with a client-generated
  idempotency key, shown as queued, synced once.
- **Account data:** export sections and `purge!` wiping for plants, events and photos (B08).
- **Help and flags:** topics for the collection, adding a plant, observations and photos,
  and offline use; flags `collection.plants`, `collection.acquisition`, `collection.media`
  and `collection.search` marked implemented.

**Deferred:** library profile link (B18); environments, setups and location filter (B11);
other care event kinds (B13); reminders and the "stop reminders" offer (B14); purchase groups
and splits (B16); a photo bucket (after the pilot); native camera bridge (with the native apps).

**Acceptance:** an unknown plant saves with only a name and context; renaming keeps the
record number, photos and history; a gift saves without a price and a price keeps its
currency; archiving hides a plant from the active collection but keeps its timeline;
yesterday's observation sorts before today's; two Monstera records of the same cultivar are
found separately; an upload at the cap is refused with the note kept; an observation saved
offline and synced twice creates one event; a deleted account's plants and photos are gone.

**Built notes:** search is a plain ILIKE scan rather than a trigram index; personal
collections are small, so an index can wait until it's needed. Photos are converted to JPEG
(HEIC isn't accepted; phone browsers usually send JPEG). Offline reading is a network-first
service worker limited to `/plants` and `/plants/:id`, plus assets and thumbnails; the
browser-pane preview can't register service workers, so offline behaviour is tested in
headless Chrome (in CI). Chrome's offline emulation doesn't reach service-worker fetches,
so the test checks the saved cache rather than reading a page offline. The app time zone is
now Africa/Johannesburg until accounts get their own. Help topics: `collection`,
`adding-a-plant`, `observations-and-photos`, `working-offline`, reviewed 2026-11-11.

### B11 Environments, occupants and measurements — discussed 2026-11-11, built 2026-11-12

**Scope**
- **Environments (EN01, D88):** `environments` owned by a user: name and type required (room or
  shelf, grow cabinet, terrarium, paludarium, aquarium, acclimatisation container, outdoor
  bed), notes, dimensions in cm, volume in litres, status active or archived. One level; no
  nesting. Index and detail pages with current occupants, latest measurements and photos.
- **Occupants and moves (EN03, D91, D93):** `environment_assignments` (plant, environment,
  started on, ended on) with at most one open assignment per plant. Move one plant from its
  page or several from the environment page with one date; unassign allowed. When the
  environment type implies a different growing context (room, shelf, cabinet → indoor;
  terrarium; paludarium; aquarium → aquatic; outdoor bed → outdoor; acclimatisation container
  → no suggestion), the form offers to update the plant's context.
- **Plant setup (PL05, D89):** `plant_setups` (plant, started on, container, size with unit,
  watering method) with one current setup and history; recipe version added in B12. Plant
  page shows the current environment and setup.
- **Timeline (D92):** moves and setup changes write `movement` and `setup` care events on the
  plant timeline; each event shows the environment and setup current on its date.
- **Measurements (EN02, D90):** `measurements` (environment, metric, value, unit, measured at,
  source, idempotency key). Fixed metrics offered by type — land: air temperature °C,
  humidity %, light hours, light (lux or PPFD); aquarium: water temperature °C, pH, GH °dH,
  KH °dH, light hours, CO2 note; paludarium: both — plus `custom_metrics` per user (name,
  unit). A reading saves several values at one time; blanks are not stored. Latest value per
  metric with its date on the environment page, and a dated history list.
- **Photos, offline and filters (D94):** environment photos through the existing `photos`
  table, counted in the 500-photo cap; service worker caches `/environments` pages; offline
  measurements queue in IndexedDB and sync once; collection filter by environment.
- **Deletion (D95):** archive keeps history and hides the environment from pickers;
  permanent delete only when it has never had a plant, after a warning with counts.
- **Account data:** export sections for environments, assignments, setups, measurements and
  custom metrics; `purge!` removes them.
- **Help and flags:** topics for environments and moving plants, and for measurements;
  `collection.environments` and `collection.measurements` marked implemented.

**Deferred:** recipe version on setups (B12); environment maintenance tasks and events
(B15, EN04); measurements in AI guidance (B37, EN05); imperial units (B17); charts of
measurements over time; nested environments.

**Acceptance:** a tank saves with only name and type; a moved plant shows only in the new
environment's current occupants and both appear in its history; moving three plants from the
environment page records one date for all; an indoor plant moved into an aquarium is offered
the aquatic context and keeps indoor if declined; repotting changes the current setup while
earlier events still show the earlier setup; a blank humidity stays unknown, never zero; every
stored value shows its unit, date and source; a measurement saved offline and synced twice
creates one reading; an environment that has held a plant can be archived but not deleted.

**Built notes:** a reading is a `measurements` row with one `measurement_values` row per
metric filled in, so several values share one time and source. Light is two fixed metrics
(lux and PPFD). Range checks only catch typing slips (humidity 650), not poor conditions.
Custom metrics are shared across all of a collector's environments. Archiving refuses an
environment with plants still in it rather than moving them out silently. The offline form
controller is now generic (`offline-form`), and the IndexedDB store was renamed, which drops
anything queued by the B10 build (development only). Help topics `environments` and
`measurements` are new; `working-offline` and `observations-and-photos` changed, so all four
need review.
