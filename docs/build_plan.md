# VIVUM Plants — Build-out plan

A living plan that turns PRD v1.3 into buildable features. We discuss each feature before
building it; the outcome of each discussion is recorded under the feature (and in
[prd_decisions.md](prd_decisions.md) when it settles a product question).

Order follows PRD §31 (foundation → shared domain → flows → clients → connected → pilot),
adjusted for what already exists. **Agreed order (2026-11-10):** foundation B03–B06 first, then the
seller domain (Phase 3) before the collector domain (Phase 2), because the pilot scenario is
seller-led. Each feature ships with its flag(s) (§28), help topic
(HM02), tests and a CHANGELOG entry, and a WHATS_NEW entry if users would notice it.

**Status:** Done · Partial · Next · Planned · Discussing · After pilot

**Re-scope (2026-11-27, D239–D249):** the pilot is for one- or two-person sellers who sell
through WhatsApp, so the simplest flow that works wins. Remaining pilot order: B27 To ship
list → B29 business profile → B30 buyer links → B45 WhatsApp message links → B46
paste-to-claims → B28 requests and Wanted List → B34 notifications → B35 PWA install → B44
pilot readiness. Batches marked "After pilot" wait for feedback from real sellers.

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
| B19 | Stock items, locations, holds and the stock ledger, with the collection link | SE01, SE02, SE04, D155–D163 | B02 | Done |
| B20 | Listings and sale cards (share/download) | SE03, SE07, SE08, D164–D170 | B19 | Done |
| B21 | Buyers, aliases and phone verification | BY01–BY03, D171–D178 | B02 | Done |
| B22 | Orders, holds and cancellations | SE05, SE06, D179–D188 | B19, B21 | Done |
| B23 | Manual payments, returns and receipts / VAT invoices | PY03 manual, RC01, D08, D189–D198 | B22 | Done |
| B24 | CSV stock import with preview | IM01, IM02, D199–D208 | B19 | Done |
| B25 | Live sale sessions, auctions, Quick Claim, backup bidder | LS01–LS04, D14, D209–D218 | B22 | Done |
| B26 | Sale Closeout | SC01, SC02, D219–D228 | B25 | Done |
| B27 | To ship list, order slips, pickup and manual tracking | PK01, PK02, SH (manual), D240–D244 | B22 | Done (re-scoped, D229–D238 superseded) |
| B28 | Plant requests, offers and Wanted List | RQ01, RQ02, WL01 | B19, B21 | Planned |
| B29 | Seller business profile and standard branding | BR01 | B02 | Planned |
| B30 | Buyer links (order, tracking, receipt, EFT details) | WB01, D247 | B22, B23 | Planned |
| B31 | Care sheets, care packs, PDF, QR labels (seller-written templates until the library, B18, exists) | CP01, CP02, QR01 | B22 | After pilot (D248) |
| B32 | Copy to collection from a care pack (after the collector domain) | CP03, BY04 | B31, B10 | After pilot (D248, D249) |
| B33 | Plant Sitter | PS01, PS02 | B14 | After pilot (D249) |
| B45 | WhatsApp message links (wa.me, pre-filled) | WA03 (lite), D245 | B30 | Planned |
| B46 | Paste-to-claims from WhatsApp group comments | LS02, D246 | B25 | Planned |

## Phase 3 — Collector domain

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B10 | Plant records, acquisition, status, photos, search | PL01–PL04, UX01, OF02, OF03, D80–D87 | B03 | Done |
| B11 | Environments, occupants, measurements | EN01–EN03, PL05, D88–D95 | B10 | Done |
| B12 | Substrate ingredients and versioned recipes, scaling | SU01–SU05, D96–D102 | B10 | Done |
| B13 | Care events and quick care entry | CA01, UX02, PL04, D103–D110 | B10 | Done |
| B14 | Reminders, schedules and Today inbox | CA02–CA05, PL03, D111–D120 | B13 | Done |
| B15 | Shared environment maintenance | EN04, D121–D126 | B11, B14 | Done |
| B16 | Purchased tissue culture: groups, splits, stages | PL06, TC01–TC05, D127–D134 | B10, B14 | Done |
| B17 | Guidance settings and new-plant defaults | ST01–ST05, D135–D140 | B10, B05 | Done (units, notification preferences and AI stop deferred) |
| B18 | Library profiles: platform and personal libraries, suggestions | GU01, GU03, D10, D29, D141–D154 | B14, B17 | Done (launch profiles and seller libraries to come) |

## Phase 4 — Clients and notifications

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B34 | Notifications: in-app, email digest, web push | NT01, NT02, NT04 | B14 | Planned |
| B35 | PWA install and offline care logging | OF02, D249 | B13 | Planned (PWA install in pilot; offline care logging after pilot) |
| B36 | Hotwire Native iOS and Android apps, native push | OF01, D12, D27 | B34 | After pilot (D248) |

## Phase 5 — Connected flows (each behind a pilot flag)

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B37 | AI care suggestions | GU02, GU04, AI01–AI04, D23, D24 | B18, B05 | After pilot (D249) |
| B38 | WhatsApp connection and outbound templates | WA01, WA03, WA04, NT03, D22 | B21 | After pilot (D245) |
| B39 | WhatsApp DM claims and request capture (AI extraction) | WA02, RQ01, AI02 | B38, B25, B28 | After pilot (replaced by B46, D246) |
| B40 | Bob Pay checkout | PY01, PY02 | B23, B30 | After pilot (D247) |
| B41 | Yoco checkout | PY01, PY02, O6 | B40 | After pilot (D247) |
| B42 | Bob Go shipping | SH01, SH02 | B27 | After pilot (D248) |
| B43 | Paystack seller subscriptions and paid branding | SB01, SB02, BR02 | B07, B29 | After pilot (D248) |

## Phase 6 — Pilot

| ID | Feature | PRD | Depends on | Status |
|---|---|---|---|---|
| B44 | Pilot readiness: POPIA review, production deploy, rollout (app store review moves with B36) | §31 step 6, D25–D27, D248 | all pilot features | Planned |

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
(B15, EN04); measurements in AI guidance (B37, EN05); imperial units (after the pilot, D135); charts of
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
`measurements` are new; `working-offline` and `observations-and-photos` changed; all four
reviewed 2026-11-12.

### B12 Substrate ingredients and versioned recipes, scaling — discussed and built 2026-11-12

**Scope**
- **Ingredients (SU01, D96, D97):** `ingredients` that are either built-in (no user, seeded
  from `db/seeds/ingredients.yml`, about 40 generic entries, not editable) or personal (owned
  by a user, generic or branded with manufacturer and product name). Fields: name, category
  (fixed list), water retention and aeration (low, medium, high), particle size min and max
  in mm, intended use, preparation, source, notes; status active or archived. "Copy to
  personal" turns a built-in into an editable personal ingredient. Qualitative properties
  show a "guidance" label.
- **Recipes and versions (SU02, SU04, D98, D99):** `recipes` (user, name, growing contexts,
  source, private notes, status active or archived, share token) with `recipe_versions`
  (number, basis parts or percent, state draft or ready, notes) and `recipe_components`
  (version, ingredient, quantity). Parts show % equivalents; a % version must total 100%
  before it's ready. A ready version that no setup uses is edited in place; changing a used
  version saves the next version. Single-material substrates are one-ingredient recipes.
- **Scaling (SU03, D98):** target volume in L or mL; each component rounded to the nearest
  50 mL (25 mL under 1 L) with the rounded total shown. Done in a Stimulus controller (works
  offline), with the same rule in a Ruby class that the tests check against AT09.
- **Assigning (PL05, D100):** `plant_setups` gains `recipe_version_id`; the setup form offers
  the latest ready version of each active recipe. Setup timeline events show recipe and
  version. The recipe page lists plants on each version, current and past.
- **Sharing (D102):** a recipe's public link (`/r/:token`) shows the current ready version
  with the scaler, without notes or plants; the collector can turn the link off or make a new
  one. No sign-in, no indexing.
- **Search, offline and deletion (SU05, D101, D102):** recipe list search by name and
  ingredient, filters for growing context and current or past use; service worker caches
  recipe and ingredient pages. Used recipes and personal ingredients archive; unused ones
  delete after a warning.
- **Account data:** export sections for ingredients (personal), recipes, versions and
  components; setups export their recipe version; `purge!` removes them.
- **Help and flags:** topics for ingredients, and for recipes, versions and scaling;
  `substrate.ingredients`, `substrate.recipes`, `substrate.scaling` and `substrate.share`
  marked implemented.

**Deferred:** built-in recipes (with the library, B18); repot as a care event with recipe
choice (B13); bulk assignment from the recipe page; weight-based recipes and cups or scoops;
ingredient stock and cost (excluded by the PRD); recipes in care packs (B31).

**Acceptance:** 2 bark : 1 perlite : 1 coir shows 50/25/25%; a % recipe at 95% can't be
marked ready; 2:1:1 scaled to 4 L gives 2 L / 1 L / 1 L; a plant on v1 stays on v1 after v2 is
saved, and its earlier setup events still show v1; a branded ingredient keeps its
manufacturer and is distinct from the generic one; built-ins can't be edited but can be
copied; a used recipe can be archived but not deleted; a shared link opens signed out,
shows no notes, and stops working once revoked.

**Built notes:** 42 built-in ingredients. They reach a database through `db:seed`, which the
production deploy (B44) must run, since `db:prepare` only seeds a new database. Recipes are
reached from a **Substrates** button on the collection page, like Environments. The recipe
form saves as a draft or as ready; the version number shows above the recipe name. The
public link page has its own `public` layout with `noindex`. While testing, the plant and
environment edit pages turned out to be refused since B10 (Action Policy has no default
`edit?` rule); fixed in `PlantPolicy` with tests. Dev-server pages weren't clicked through,
because the only development account has two-step sign-in; headless Chrome tests cover
scaling offline and the recipe form, and there's a recipe screenshot. Help topics
`ingredients` and `recipes` need review.

### B13 Care events and quick care entry — discussed and built 2026-11-12

**Scope**
- **Kinds and details (CA01, D104, D105):** `care_events` gains the kinds watering, feeding,
  repotting, pruning, treatment, inspection and custom, plus optional detail columns: amount
  with unit, watering method, product, dose with unit, strength, treatment target and custom
  label. Products, targets and custom labels are free text, suggested from the collector's
  earlier entries. A note is optional for the new kinds; observations still need a note or a
  photo.
- **Quick entry (UX02, D103):** a row of care buttons on the plant page. Water saves at once,
  with Undo and "Add details"; the other kinds open a short sheet with all fields optional and
  the date defaulting to now.
- **Repotting (D106):** the repot sheet prefills container, size and recipe version from the
  current setup. Saving creates one repotting event and a new dated setup in one transaction,
  shown as one timeline entry.
- **Several plants (D107):** "Log care" from the environment page (checkboxes for plants
  there) and from selected plants in the collection list; one event per plant, idempotent per
  plant under one client key.
- **Editing and deleting (D108):** edit or delete any care event or observation; movement and
  setup events stay read-only.
- **Last care (D109):** a summary of the latest event of each main kind on the plant page;
  days since last watering on the collection list, with a "not watered in N+ days" filter; a
  kind filter on the plant timeline.
- **Offline (OF02, D110):** every kind queues offline with an idempotency key and syncs once.
- **Account data and help:** the export includes the new event details; a help topic for
  logging care; `care.logs` marked implemented.

**Deferred:** the Today route and linking events to tasks (B14); stage-change events (B16);
product records, doses per pot volume, and saved custom kinds; care-due filters (B14).

**Acceptance:** tapping Water saves one watering event without a form; a feeding saved with
no details is saved; a care log saved offline and synced twice creates one event (OF02); a
repot into a new container with Aroid mix v2 shows one timeline entry and makes that the
current setup; watering five plants from an environment creates five events, and a retry
creates no more; yesterday's watering sorts before today's observation in the timeline
order by date (PL04); editing an event's date re-sorts the timeline; the collection filter
"not watered in 7+ days" finds a plant last watered 8 days ago and not one watered 2 days
ago.

**Built notes:** The care forms are native `<dialog>`s opened with invoker commands
(`commandfor`), so they need no JavaScript and work from the offline-cached plant page. One
`amount`/`amount_unit` pair serves a watering's volume and a feed or treatment dose, with
units by kind. A repot that made a setup keeps its date and can't be deleted (the setup would
be left behind); changing its setup goes through **Where it grows**. A repot with no pot, size
or substrate is a plain log. Several-plant logging leaves out repots, since each plant gets its
own setup. The "not watered in N+ days" filter counts plants never watered. The several-plant
page isn't cached offline, but a form already open there queues like the others. Dev-server
pages weren't clicked through, because the only development account has two-step sign-in;
headless Chrome tests cover watering and feeding offline and Undo, and the plant screenshot
now shows the Log care card. Help topic `logging-care` needs review.

### B14 Reminders, schedules and Today inbox — discussed and built 2026-11-12

**Scope**
- **Schedules (CA02, D112, D117):** `care_schedules` (user, plant, kind or custom label,
  once or every N days, weeks or months, `after_completion` or `fixed`, start date, active,
  paused or ended) and `care_tasks` (schedule, plant, due date, snoozed until, state, a
  manual-date flag, completed or skipped at, linked care event, idempotency key). A
  `Schedule#next_due` rule in Ruby covers both modes, keeps weekdays and clamps months, and a
  preview shows the next five dates. `users.time_zone`, detected from the browser and editable
  in account settings; due dates are computed in it.
- **Occurrences (CA03, D118):** one open task per schedule; completing or skipping creates the
  next. Overdue and due are derived from the date. Editing a schedule recalculates the open
  task unless its date was changed by hand.
- **Plant page (D112, D120):** a Reminders card listing schedules with their next date, a form
  to add one with the date preview, the duplicate check (keep both or replace), edit, pause
  and end. After logging care, the saved notice offers "Repeat this every…" prefilled with the
  kind. Several-plant setup from the environment page and the collection.
- **Today (CA04, D111, D115, D116):** the home page becomes Today and the nav item is renamed.
  Tasks are grouped by kind with overdue, today and the next 7 days; Done per task or per
  group (or ticked plants), Done with details, Skip, Snooze (tomorrow, 3 days, a date). Invites
  and seller cards stay below.
- **Completing (CA01, D113, D114):** Done logs a linked care event (`care_events.care_task_id`);
  logging care of the same kind completes an open task that's overdue, due today or due in the
  next 2 days, and Undo reverses both. Idempotent per task.
- **Inactive plants (PL03, D119):** inactive statuses pause schedules and cancel open tasks;
  restoring resumes from today.
- **Offline (OF02, D120):** the service worker caches Today; Done, Skip and Snooze queue with
  an idempotency key.
- **Account data and help:** export sections for schedules and tasks; `purge!` removes them;
  help topics for reminders and Today; `care.reminders` marked implemented.

**Deferred:** notifications, preferred times and quiet hours (B34); environment maintenance
tasks (B15); TC stage reminders (B16); library and AI suggestions and their merge, replace or
keep flow (B18 and later); shared schedules covering several plants; times of day.

**Acceptance (AT07):** a 7-day after-completion schedule done on 10 Nov is next due 17 Nov;
a fixed weekly schedule completed late keeps its weekday; a monthly schedule from 31 Jan is
next due 28 Feb (or 29 in a leap year); skipping logs no care and creates the next task; an
overdue recurring schedule shows one task, not a stack; snoozing hides it until the chosen
day and keeps the original due date; completing a watering task creates one event, and a
retry creates no second (CA01); tapping Water on a plant with a watering task due tomorrow
completes it; Done on "Water · 5 plants" logs five events; marking a plant sold pauses its
schedules and restoring it creates no past tasks; editing a schedule leaves a hand-changed due
date alone; with notifications off, tasks still appear in Today (CA04).

**Built notes:** Today replaces the home page only while `care.reminders` is on; otherwise
home is unchanged. Done on Today ticks every plant in a group by default; untick to leave one
out. A task's checkboxes sit outside its group's form (the `form` attribute), so Skip and
Snooze can be forms of their own. Undo of the care that completed a task reopens it and
removes the task made after it, unless that one was moved or snoozed since. A one-off
reminder ends when done. Resuming a fixed reminder picks the first calendar date from today;
an after-completion one is due today. Setting up and editing reminders needs a connection;
Done, Skip and Snooze queue offline. The timezone is saved from the browser on the first
signed-in request and changed under Account. Dev-server pages weren't clicked through,
because the only development account has two-step sign-in; headless Chrome tests cover Today
offline and the date preview, and there's a Today screenshot. Help topics `reminders` and
`today` need review.

### B15 Shared environment maintenance — discussed and built 2026-11-13

**Scope**
- **Maintenance events (EN04, D121–D123):** `environment_events` (user, environment, kind or
  custom label, when, note, optional amount with unit and product, idempotency key, photos),
  with `environment_event_plants` linking the plants present at that time. Kinds: water
  change, top-up, filter clean, dosing, substrate vacuum, glass clean, misting check,
  ventilation check, equipment check, light check, custom. The environment type decides which
  kinds show first.
- **Logging (D122):** a Log maintenance card on the environment page with buttons opening
  short `<dialog>` forms, all fields optional; Undo and "Add details" after saving; "Add a
  reading" after a water change. Edit and delete.
- **Plant timelines (D124):** each plant's timeline includes the maintenance it was present
  for, labelled with the environment; the kind filter gains "Environment care".
- **Reminders (D125):** `care_schedules` and `care_tasks` belong to a plant or an environment
  (exactly one); Done on an environment task logs one environment event. Today shows an
  Environments group above plant care. Archiving pauses, restoring resumes.
- **Offline, history and data (D126):** the environment page lists maintenance with a kind
  filter; logging and Today actions queue offline; export section and deletion warnings;
  help topic `environment-maintenance`; `care.shared_maintenance` marked implemented.

**Deferred:** maintenance for several environments at once; equipment records and their
service history; dosing schedules calculated from tank volume.

**Acceptance (EN04):** one water change in a tank with three plants creates one environment
event linked to those three plants, and no plant care events; a plant moved out last week
isn't linked; each linked plant's timeline shows "Water change in 60 cm tank"; deleting the
event removes it from those timelines; a weekly water-change reminder shows on Today once,
not per plant, and Done logs one event; archiving the environment pauses its reminder; a
water change saved offline and synced twice creates one event.

**Built notes:** Maintenance photos belong to the environment, so they also show in its
Photos section and count toward the 500-photo cap. A plant is linked when it was in the
environment on the entry's date (moved in on or before, and out after). Logging maintenance
completes a matching environment reminder due within 2 days, like plant care (D114).
Several-environment reminders aren't included; reminders for several plants still work as
before. Queued maintenance shows under the conditions card's "Waiting to send". Dev-server
pages weren't clicked through, because the only development account has two-step sign-in; a
headless Chrome test covers a water change offline, and the environment screenshot now shows
maintenance. Help topic `environment-maintenance` needs review.

### B16 Purchased tissue culture: groups, splits, stages — discussed and built 2026-11-13

**Scope**
- **Purchases (TC01, D127):** `purchase_groups` (user, name, supplier, arrival date, arrival
  quantity, container condition, deflask date, notes, photos). "Record a TC purchase" creates
  the group and one TC-origin plant per plantlet (up to 50), each with its own P-number and a
  numbered name, the chosen starting stage, and optionally an environment and setup. The
  group page lists records with stage and status, arrival vs remaining.
- **Stages (TC02, D128):** `plants.tc_stage` (sealed, deflasked, acclimatising, established)
  with a `stage` care event per change, carrying the effective date. Any order; context
  separate.
- **Checks (TC03, D129):** a `tc_check` care kind with ticks (new leaves, new roots, damage,
  suspected contamination), humidity setup, note and photos. Losses set a record's status to
  lost.
- **Group actions (D130):** change stage or log a check for all or ticked records, one entry
  each; a group check can mark ticked plantlets lost.
- **Suggestions (TC04, D131):** a code-owned table of suggested reminders per stage and
  context, offered after a stage change as ticked rows with editable cadence;
  `care_schedules.origin = "tc_stage"`.
- **Established (TC05, D132):** keep, end or replace for each open TC reminder.
- **Splitting (PL06, D133):** split a record with quantity above 1 into new linked records
  (`plants.split_from_id`, same purchase group), with reminders to copy.
- **Offline and data (D134):** TC checks and stage changes queue offline; export sections;
  deleting an empty group; help topics for TC purchases and splitting;
  `collection.tissue_culture` marked implemented.

**Deferred:** library-based suggestions (B18); TC laboratory use (excluded, C03); seller TC
stock (seller domain).

**Acceptance:** recording 5 plantlets makes a group with arrival quantity 5 and five records
P-numbered in turn; a pre-deflasked purchase starts at acclimatising; deflasked →
established in an aquarium works without an indoor stage, and both stages stay on the
timeline; marking one plantlet lost shows 4 of 5 remaining; a TC check never changes the
stage; changing to deflasked into a terrarium offers "Check readiness for repotting" and adds
only what's ticked; marking established lists open TC reminders with keep, end or replace and
removes none silently; splitting a planting of 5 into 2 and 3 leaves totals of 5, links both
to the source, and copies only the ticked reminders.

**Built notes:** The purchase group reuses `acquisitions` (already shaped for several
plants) rather than a new table, so a TC plantlet's acquisition is its purchase. A TC check
is an `inspection` care event with tick columns, so it completes inspection reminders and
never touches the stage. Stage and split events are read-only like moves (D108). Suggested
reminders count after completion and are left out for a plant that already has the same
one. The group's stage change offers suggestions for all ticked plantlets together; once
established, each plantlet's page links to its own review. Splitting keeps at least 1 in the
source. Dev-server pages weren't clicked through, because the only development account has
two-step sign-in; tests cover the flows, and the purchase and plantlet pages were checked at
phone size. Help topics `tissue-culture` and `splitting` need review.

### B17 Guidance settings and new-plant defaults — discussed and built 2026-11-13

**Scope**
- **Defaults (ST01, ST03, D135, D137):** `guidance_revisions` (user, number, library, ai,
  created_at), append-only; the latest is the account's current defaults. Settings → Guidance
  shows the library switch (the AI switch is hidden until B37), saves through the ST03 warning
  dialog with its exact copy, and lists past revisions with the number of plants on each.
  Existing accounts get revision 1 with both off.
- **Plant snapshot (ST02, D138):** `plants.guidance_library`, `plants.guidance_ai`,
  `plants.guidance_revision_id`, and a customised marker. New plants and TC plantlets
  snapshot the current revision; splits copy the source. Existing plants backfill to revision
  1, both off.
- **Plant view and edit (ST01, D139):** a Guidance section on the plant page with the switch
  and one status (matches your defaults, from older defaults, changed for this plant); edit
  changes only that plant.
- **Apply current defaults (ST04, D140):** per plant with a before/after comparison, and for
  selected plants from the collection with one summary. Changes only switches and revision.
- **Data:** guidance revisions and plant switches in the export; a help topic for guidance
  settings; flag for the settings page marked implemented.

**Deferred:** onboarding guidance step (B18, D136); library suggestions (B18); AI switch, AI
consent and the account-wide AI stop (B37); units (after the pilot); notification
preferences (B34).

**Acceptance:** plant A on revision 1 keeps its switches after revision 2 is saved, and plant
B added afterwards gets revision 2; cancelling the defaults warning changes nothing; turning
the library off for one plant changes no other plant or the defaults; applying current
defaults to a plant changes its switches and status but leaves its reminders and history;
a split keeps its source's switches.

**Built notes:** The customised state isn't stored: a plant is "changed" when its switches
differ from the revision it copied. Saving unchanged defaults adds no revision. A new flag,
`care.guidance_settings`, gates the pages; Settings → Guidance is reached from the Account
page and the plant's Guidance section rather than a new nav item. Tests cover the PRD
acceptance cases; the settings, warning, plant comparison and phone-size bulk pages were
checked in a browser. Help topic `guidance-settings` needs review.

### B18 Library profiles: platform and personal libraries, suggestions — discussed 2026-11-13, built 2026-11-14

**Scope**
- **Profiles (GU01, D141, D143, D149):** `library_profiles` belonging to the platform, a user
  or (from B31) a seller: botanical name, synonyms, common names, family. Platform profiles
  have numbered `library_profile_versions` (draft, in review, published, retired); one
  published version at a time, published versions read-only. Personal profiles hold one
  editable copy of the same content (per-context care notes and suggested reminders,
  references) with an edited-at date.
- **Platform editor (D141, D142):** Madmin library screens for operators: create, edit drafts,
  send to review, publish, retire, all audited. Two or three sample profiles in seeds.
- **Your library (D150, D153):** a Library page with Your library (search, context filter,
  new blank profile, edit, delete when unlinked) and the Platform library (search, read,
  "Copy to my library", an independent copy).
- **Linking (PL01, D151):** `plants.library_profile_id` to the collector's own profiles only;
  a name-match offer on the plant page (link yours, or copy the platform's and link); a
  picker on the edit form; unlinking keeps reminders and history.
- **Suggestions (GU03, D145, D151):** the plant's Guidance section shows care notes and
  suggested reminders for its context when the library switch is on; edit, accept, dismiss;
  `care_schedules.origin = "library"` with the profile and its edited-at time kept;
  replacing an existing reminder of the same kind after a comparison; dismissals per profile
  edit; a Today line for suggestions to review.
- **Choosing the library (ST06, D146):** a Today card until the collector chooses; Yes saves
  defaults and offers to apply them to existing plants.
- **Edits (D147, D152):** editing your profile flags linked plants with reminders accepted
  before the edit, with a comparison.
- **Flags and data:** `library.profiles` and `care.library_guidance` implemented; personal
  profiles, links, accepted sources and dismissals in the export and account deletion; help
  topics for the library and suggestions.

**Deferred:** the ~50 launch platform profiles (founder-written before the pilot, D142);
seller libraries (B31, D154); library editor role; AI suggestions (B37); care packs (B31).

**Acceptance:** copying a platform profile makes an editable profile in your library, and a
later platform correction leaves it unchanged; a blank profile can be created and linked; a
plant links only to your own profiles, and a platform-only match offers copy-and-link; a
suggestion names its profile; a plant with no profile, or none for its context, says so;
nothing changes before acceptance; accepting over an existing reminder shows the comparison
first; turning the library off for a plant hides suggestions and keeps accepted reminders;
editing your profile changes no accepted reminder and flags affected plants; platform drafts
and retired versions are never shown to collectors; another user's profiles are never
visible; the Today choice card disappears after Yes or No.

**Built notes:** Platform and personal profiles share one table and one content format
(`LibraryProfile::Contents`); a platform profile's row mirrors its published version, so
collectors' lists and copies never touch versions. A suggestion is settled when the plant
has the same reminder at the same cadence, accepted or reviewed it since the profile's last
edit, or dismissed it since then. Accepted suggestions start today and count after
completion. The operator editor is custom Madmin pages (not a generated resource) because
the content is structured. The plant page's Guidance card now shows when either the guidance
settings or the library is on. Sample profiles are seeded in development only. Tests cover
the acceptance cases; Today's choice card, the platform library, a plant's suggestions
before and after a profile edit, the profile form and the phone-size library and Today were
checked in a browser. Help topics `library` and `library-suggestions` need review.


### B19 Stock items, locations, holds and the ledger — discussed and built 2026-11-14

**Scope**
- **Items (SE01, D155, D156):** `stock_items` (seller, kind specimen or batch, code from a
  per-seller counter or the seller's own, name, cultivar, botanical name, size or pot,
  price and cost in cents, notes, photos, optional linked plant). Sell → Stock lists items
  with search, location and availability filters.
- **Locations and ledger (SE02, D157, D158):** `stock_locations` per seller;
  `stock_movements` (item, kind, quantity, location, to-location for moves, reason, member,
  occurred at, optional hold) are append-only. Balances per item and location: saleable,
  unavailable, held, available. Receive, move, mark unavailable or available, loss.
- **Holds (D159):** `stock_holds` (item, location, quantity, for whom, expiry, member,
  state active, released, fulfilled, expired). Each change locks the item and checks
  availability in one transaction; a specimen has at most one active hold; a recurring
  job expires holds.
- **Counting (D160):** counted quantity per location records an adjustment for the
  difference, never below what's held.
- **Roles (D161):** owners and managers do everything; host/packers move, mark
  unavailable or available and record losses, and never see prices or costs.
- **Collection link (SE04, D162):** "Move to stock" from a member's plant and "Move to my
  collection" from a linked specimen; fulfilling a linked specimen writes a sale entry on
  the plant's timeline; a "moved to stock" plant status.
- **Photos and data (D163):** item photos against the seller's photo limit; seller export
  of stock, locations, movements and holds; help topics; `seller.stock` implemented.

**Deferred:** listings and sale cards (B20); buyers on holds (B21); orders and
reservations from orders (B22); CSV import (B24); live sale lots (B25); stocktake sessions.

**Acceptance:** receive 5, hold 2, mark 1 unavailable → 2 available; fulfilling the hold
removes 2 from on hand and clears it; two holds for the last specimen → one succeeds;
an expired hold releases once; a count can't go below what's held; a packer can move stock
but never sees a price or cost; moving a plant to stock creates a linked specimen and keeps
the plant's history, and fulfilling it records the sale on the plant's timeline; another
seller's stock is never visible.

**Built notes:** Balances are kept in `stock_balances` beside the ledger rather than summed
on every read, so the lock-and-check stays cheap and the database refuses negatives. Holds
count only while active and unexpired, so stock is free the moment a hold's time passes;
the job then records the expiry once. The collection link moves stock into the business the
session is acting for (owners and managers), and a plant holding several plants must be
split first. Unauthorised stock actions use the app's existing redirect. The flag release
guard test now uses `seller.listings` as its unimplemented example. Tests cover the
acceptance cases; the stock list and item page as a host/packer (no prices; a move between
locations) were checked in a browser, also at phone size. Help topics `stock` and
`stock-holds` need review.


### B20 Listings, sale cards and sharing — discussed and built 2026-11-14

**Scope**
- **Listings (SE03, D164, D165):** `listings` (seller, stock item, reference L-0001 from a
  per-seller counter, title, price, listed quantity cap, photo ids, size, collection and
  delivery details, caption, state draft, active, paused or ended). One active or paused
  listing per item (partial unique index). Available = the item's available stock, capped;
  "sold out" at 0. Fulfilling a specimen ends its listing. Sell → Listings with state and
  availability filters; "List it" from an item page.
- **Stock settings (D168):** per-seller defaults for collection and delivery details.
- **Sale cards (SE07, D166, D167):** `sale_cards` (listing, format square or status, file
  type, price, title and photo shown, created by, image attachment). Rendered with libvips:
  photo cropped to fit, a text panel with name and price that never hides the price, size
  and business name. Stale flag when the listing no longer matches or isn't sellable. A
  daily job deletes cards older than 90 days.
- **Sharing (SE08, D169):** a Stimulus controller using the Web Share API with the card
  file and caption, falling back to Download and Copy caption; a wa.me link with the
  caption.
- **Roles and data (D170):** owners and managers only; listing, cards and sharing flags
  implemented; listings in the seller's CSV export; help topics.

**Deferred:** logo, social links and contact line on cards (B29); buyer listing pages and
links (B30); paid card layouts (B43); listings in live sales (B25).

**Acceptance:** a reserved quantity-1 listing shows 0 available; pausing never changes
stock; an R450 listing's card shows R450 and the chosen photo; a very long name never hides
the price; a card shows no cost, holds or notes; changing the price flags earlier cards as
stale; sharing never holds stock or creates an order; fulfilling a listed specimen ends its
listing; a host/packer can't open listings.

**Built notes:** Card text is drawn with libvips and Pango. The price is drawn on its own,
and the name tries smaller sizes and then shortens with an ellipsis until it fits, so the
price always shows. The Docker image now installs `fonts-dejavu-core`. On macOS, CoreText
crashes inside forked processes, so forked test workers draw a stand-in block the size of
the text; CI on Linux and production render real text, and the browser check rendered
real cards. Card images are served through the seller's own route, not public links.
`herb format` had not been run on the views added in B17–B19; they're formatted now, as
CI checks. Tests cover the acceptance cases; listing an item, making a Status card, the
stale flag after a price change and the listings page at phone size were checked in a
browser. Help topics `listings` and `sale-cards` need review.


### B21 Buyers, aliases and phone verification — discussed and built 2026-11-16

**Scope**
- **Buyers (BY01, D171):** `buyers` (seller, display name, phone in E.164, unique per seller,
  optional email, contact preference WhatsApp, call, SMS or email, verified at and method,
  deleted at). Local numbers are normalised to +27. Sell → Buyers lists buyers and searches
  name, alias and phone in any format. A buyer page shows contacts, addresses, aliases,
  consents, verification and holds. All lookups are scoped to the current seller.
- **Addresses (D175):** `buyer_addresses` (label, recipient, street, suburb, city, province,
  postal code, default).
- **Aliases (BY02, D172):** `buyer_aliases` (seller, display name, optional group name,
  optional buyer). Owners and managers link and unlink them by hand; matching names never
  merge. Stock holds gain an optional buyer or alias; the free-text "for" stays for older
  holds.
- **Verification (BY03, D173):** `buyer_verifications` holds a single-use token digest and
  its expiry (proposed 7 days). "Send verification link" opens wa.me with the link. The
  public page `/v/:token` names the seller as the responsible party (PR02), shows nothing
  personal beyond a masked number, and confirms the number. The page also lets the buyer
  give or withdraw WhatsApp and marketing consent. Changing a buyer's phone clears
  verification and revokes open links.
- **Consents (PR03, PR04, D174):** consent records per buyer per seller, with purpose,
  version, given or withdrawn, source (seller recorded or buyer) and how it was given.
  Marketing is off by default.
- **Roles (D176):** `BuyerPolicy`. Owners and managers have full access. Host/packers see
  names and aliases and can create aliases, never contacts or addresses.
- **Buyer data requests (PR05, D177):** an owner exports one buyer's data as JSON, or
  deletes the buyer. Deletion wipes contacts, addresses and consents, unlinks aliases and
  keeps an anonymised tombstone for holds. Each request is logged as a data request.
  Buyers, aliases and addresses join the seller CSV export.
- **Merging (D178):** a manual merge moves aliases, holds, addresses and consents to the
  kept buyer and deletes the other, recorded in the audit log.
- **Flags:** `seller.buyers`, `buyer.phone_verification` and `privacy.buyer_dsr` become
  implemented. Help topics cover buyers, aliases and verification.

**Deferred:** inbound WhatsApp verification and template messages (B38); buyers on orders
and redacting addresses after 12 months (B22); aliases captured in Host View (B25); buyer
sign-in and collection import (BY04, B32).

**Acceptance:** two "Sam" aliases stay separate until linked. Seller A can't find seller B's
buyer by phone. Entering "082 123 4567" matches "+27821234567". A used or expired
verification link can't verify again. Changing the number clears verification. A
host/packer never sees a phone or address. Withdrawing marketing consent on the buyer page
takes effect at once. A deleted buyer's export holds nothing personal, and their holds
read "Deleted buyer". Merging moves aliases and holds.

**Built notes:** Buyer data requests are logged in the audit log (`buyer.exported`,
`buyer.deleted`) rather than `data_requests`, which belongs to account holders. Deleting a
buyer also rewrites the matching hold and stock movement text, since holds copy the
holder's name. Verification links last 7 days. "Send verification link" opens wa.me in a
new tab, and after confirming, the buyer page redirects back to itself for Turbo. Tests
cover the acceptance cases. A browser check covered the buyers list, linking an alias, the
public verification page, and the verified buyer at phone width. Help topics `buyers`,
`buyer-verification` and `buyer-data` need review.

### B22 Orders, holds and cancellations — discussed and built 2026-11-20

**Scope**
- **Orders (SE05, D179, D186):** `orders` (seller, buyer, number from a per-seller counter
  such as O-0001, source, state draft, reserved, fulfilled or cancelled, payment state
  unpaid, hold expiry, delivery method pickup or shipping, address snapshot, shipping fee,
  discount and reason, courier and tracking text, fulfilled and cancelled times and
  members). `order_lines` (stock item, optional listing, quantity, agreed unit price in
  cents, state, cancel reason, optional hold). Totals are lines + shipping − discount, never
  below zero, in ZAR. A buyer is required; aliases must be linked first.
- **Reserving (SE06, D180):** reserving takes one seller-chosen expiry (no default) and
  creates one hold per line for the buyer through `Stock::Ledger`, all or nothing in one
  transaction, naming any short line. Holds show the order number. The expiry can be
  extended. Expired holds release through the existing job; the order shows expired lines.
- **Changes (D183):** add and remove lines and change quantities on draft and reserved
  orders; reserved changes adjust holds in the same transaction. Editing an agreed price
  keeps the old price and a reason. Cancel a line or the order with a reason; holds release
  once and a repeated cancel is a no-op. Fulfilled orders can't be cancelled.
- **Delivery and fulfilment (D181, D182):** shipping copies a buyer address onto the order.
  Fulfil marks the order collected or shipped and fulfils its holds. Fulfilling an unpaid
  order needs a confirmation.
- **Roles (D185):** `OrderPolicy`, owners and managers only; every change records the member
  and goes to the audit log.
- **List and data (D187):** Sell → Orders with state filters and search by number, buyer or
  item; a buyer page lists their orders. Orders and lines join the seller export and the
  buyer data export. `seller.orders` and `seller.reservations` become implemented, with a
  help topic.
- **Retention (D188):** deleting a buyer needs their draft and reserved orders closed first,
  and leaves orders with their name and address snapshots. A recurring job redacts buyer
  addresses unused on an order and unedited for 12 months.

**Deferred:** payments, paid state, receipts, returns and refunds (B23); auction and claim
orders and grouping wins by buyer (B25, B26); packing and host/packer order access (B27);
buyer order links (B30); Bob Go shipping (B42).

**Acceptance:** a draft leaves stock available; reserving holds it; two orders for the last
specimen → one reserves; cancelling releases once and a repeated cancel adds no stock; a
price change on the item after adding a line leaves the order's price; editing a price keeps
the old one and the reason; fulfilling removes stock and clears holds; a shipping address
edit on the buyer leaves the order's snapshot; seller A never sees seller B's orders; a
host/packer can't open orders; a buyer with a reserved order can't be deleted.

**Built notes:** A line has no location until it's held: reserving holds each line at the
location with the most available stock that covers it, so a quantity split across
locations needs a stock move first. "Update hold" both moves the end of current holds and
re-holds lines whose hold ran out. On a draft, removing a plant deletes the line; on a
reserved order it's cancelled with a reason. Redacting an address deletes it. The
`seller.orders` tab shows only to owners and managers. Tests cover the acceptance cases. A
browser check covered starting an order from a buyer, adding two plants, shipping with a
fee and discount, reserving, and the order at phone width. Help topic `orders` needs
review, and `buyer-data` needs a new review after its text changed.

### B23 Manual payments, returns, receipts and VAT invoices — discussed and built 2026-11-22

**Scope**
- **Business details (D193):** `sellers` gain legal name, VAT number, address, phone and
  email, edited by owners on a Business details page in Sell.
- **Payments and refunds (PY03, D189, D194):** `order_payments` (order, kind payment or
  refund, amount in cents, method EFT, cash, card machine or other, paid on, reference,
  reason, member, voided at, voided by, void reason). Never edited; voiding needs a reason.
  Refunds can't exceed what has been paid. `orders.payment_state` becomes unpaid, part
  paid, paid or overpaid, worked out after every change; overpaid shows for review.
- **Paid holds (SE06, D190):** `ExpireStockHoldsJob` skips holds on orders with any
  payment. Orders whose hold time has passed with a payment show "Hold time passed,
  review" and sit under a Needs review filter.
- **Receipts and tax invoices (RC01, D08, D191, D192):** `order_documents` (seller, order,
  kind receipt or credit note, number from a gap-free per-seller counter, issued at, a
  frozen JSON copy of seller details, buyer, lines, amounts and payments, VAT rate and
  VAT amount when the seller had a VAT number, reason for credit notes). A receipt is
  issued automatically, once, when an order becomes fully paid; then its lines and prices
  lock. Web page and Prawn PDF from the order page. VAT sellers' receipts read "Tax
  Invoice" with a VAT-inclusive breakdown at 15%.
- **Credit notes (D195):** for a VAT seller, a refund on an order with a tax invoice also
  issues a credit note for that amount in the same sequence.
- **Returns (SE06, D196):** a return against a fulfilled line (quantity up to what's left
  to return, location, reason, outcome saleable, unavailable or lost) writes a `return`
  movement through `Stock::Ledger` into the chosen bucket, or a return then a loss.
  `order_returns` records each one with the member.
- **Changes after payment (SC02, D197):** before a receipt, changes recalculate the balance
  and the previous total and reason go to the audit log; cancelling needs net paid at
  zero. After a receipt, lines and prices are locked.
- **Roles and data (D198):** owners and managers only. `payments.manual`,
  `seller.receipts` and `seller.vat_invoices` become implemented. Payments, documents
  and returns join the orders CSV, the seller export and the buyer export. Help topics for
  payments and receipts, returns, and business details.

**Deferred:** buyer receipt link (B30); Bob Pay and Yoco checkout (B40); logo on receipts
(B29); disputes (B40).

**Acceptance:** two payments of R200 on a R400 order make it paid and issue one receipt;
a voided payment returns it to part paid but the receipt stays; a non-VAT seller's receipt
has no VAT line; a VAT seller's documents are numbered without gaps and show 15% VAT;
changing the VAT number leaves issued documents unchanged; a refund over what's paid is
refused; a VAT seller's refund after a tax invoice issues a credit note; a paid order's
hold never expires and shows for review; a part-paid order can't be cancelled until
refunded; a damaged return stays unavailable; a host/packer never sees payments.

**Built notes:** Receipts number R-0001 and tax invoices INV-0001, and credit notes CN-,
all from the one per-seller counter, so the prefix changes but the numbers never skip. A
refund recorded after a receipt counts as a correction: it lowers what's due as well as
what's paid, so the order still reads paid with the refund shown; before a receipt, a
refund only lowers what's paid. Refunds with a credit note can't be voided. Holds are
pinned rather than given a far expiry, so availability and the expiry job both read one
flag. The Business details page is under Sell → Orders. The PDF uses Prawn's built-in
fonts, which only cover Windows-1252, so characters outside it are swapped or dropped.
Tests cover the acceptance cases. A browser check covered part paying, paying in full
(the tax invoice page), refunding with a credit note, the order at phone width and
Business details. Help topics `order-payments`, `order-returns` and `business-details`
need review.

### B24 CSV stock import with preview — discussed and built 2026-11-23

**Scope**
- **Upload and template (IM01, D202, D203, D207):** owners and managers upload a UTF-8
  CSV or .xlsx (2 MB, 2,000 rows) from Sell → Stock, choosing a default location. A CSV
  template downloads with the headers SKU, name, cultivar, type, quantity, price,
  location, botanical name, size, cost and notes. Headers match ignoring case and spacing.
- **Preview (IM01, D199–D201, D204):** `stock_imports` (seller, reference I-0001 from a
  per-seller counter, state previewed, committed, reversed or expired, file checksum,
  default location, add-to-existing flag, parsed rows and per-row errors and warnings as
  JSON, report, member, committed at, reversed at). Parsing writes nothing to stock. Row
  errors: missing required columns, malformed rows, invalid quantity or amounts, a
  specimen quantity other than 1, an unknown type or location, SKUs repeated in the file,
  and an existing SKU without "Add to existing". Differences on existing SKUs are
  warnings. Errors download as CSV; a file with errors can't be committed.
- **Commit (IM02, D205):** one transaction, locking the import then the affected items;
  every row is rechecked. New rows create items (blank SKU gets the S-0001 code) and a
  `receive` movement; existing rows add a `receive` movement only. Movements carry the
  import reference. A second submit finds the import committed and changes nothing; a
  checksum matching an earlier committed import needs a confirm tick. The report records
  what each row did; `stock_import.imported` is audited.
- **Reversal (IM02, D206):** once per import, all or nothing: refused, with the blocking
  rows, if any imported quantity is no longer saleable at its location (held, sold or
  moved). Otherwise `lose` movements reverse each row and created items with no stock
  left are archived. Audited as `stock_import.reversed`.
- **Housekeeping (D207):** previews older than 24 hours expire and their files are purged.
- **Roles (D208):** owners and managers; `seller.csv_import` becomes implemented, with a
  help topic.

**Deferred:** updating item details from a file; stock counts by import; an .xlsx
template with dropdowns; photo import.

**Acceptance:** a file with one bad row writes nothing and its errors download; a
specimen with quantity 2 is an error; an existing SKU is an error unless "Add to
existing" is ticked, then only its quantity grows; an unknown location is an error;
submitting commit twice creates one set of items; reversal after a unit is held is
refused and changes nothing; reversal of an untouched import leaves stock as before;
hosts and packers can't open imports.

**Built notes:** The uploaded file is never stored: the parsed rows live on the import
and only the checksum is kept, so expiring a preview just clears its rows. The state
after commit is called "imported" (`committed` clashes with Active Record). A blank
quantity is an error, but 0 is allowed for a new batch, which creates the item with no
stock. An invalid price shows as typed in the preview. Item fields on new rows go
through the stock item's own validations, so the same length and SKU format rules apply.
Tests cover the acceptance cases. A browser check covered the upload page, a file with
problems, a preview adding to an existing SKU, the import report at phone width and a
reversal. The `stock-import` help topic needs review.

### B25 Live sale sessions, auctions, Quick Claim and backup bidder — discussed and built 2026-11-25

**Scope**
- **Sessions (LS01, D209, D210, D216):** `sale_sessions` (seller, name, channel, host
  member, planned start and close, status draft, live, paused or closed, payment deadline
  hours, backup window hours). Going live needs both durations; the form prefills the
  seller's last values. Pause blocks new lots and claims; close needs no open lot.
- **Lots (LS02, D211, D212):** `sale_lots` (session, number, stock item, location,
  quantity, state queued, open, won, passed, payment missed, transferred, returned,
  winner buyer or alias, final price, backup buyer or alias, backup bid, hold, member and
  times). Opening creates an exclusive `StockHold` labelled with the session and lot; one
  open lot per session. Closing with a winner turns the hold into the winner's
  reservation expiring at the deadline, in one transaction; passing releases it once.
  Hosts can type a new alias inline.
- **Missed payment and transfer (LS03, D213):** the hold-expiry job leaves win and claim
  holds alone and marks unpaid ones "Payment missed", keeping the hold pinned until the
  backup window ends. Offer to backup (new reservation at the backup bid with a fresh
  deadline), relist as a new lot, or return to stock; the window's end returns stock
  automatically. History keeps the original winner and price.
- **Quick Claim and waitlist (LS04, D214, D215):** claim items on a session (stock item,
  location, fixed price from the listing or item); `sale_claims` (claim item, buyer or
  alias, quantity, message reference, state, hold, member). A claim that can't be held
  joins a numbered waitlist; returned stock shows "offer to #1" and the host gives it on
  a tap. Nothing reserves automatically.
- **Host View and roles (D217):** a phone-first screen for the open lot or active claim
  item. Host/packers see and enter bids and claim prices for their session only, with
  no costs, other prices, totals, payments or contacts.
- **Records (D218):** results, claims, transfers and waitlist changes are audited and in
  the seller export; the five `sales.*` flags become implemented, with help topics.

**Deferred:** grouping wins into orders and the order sources auction and claim (B26
Closeout); DM claims and automatic reserving (B39); notifying waitlisted buyers (B34).

**Acceptance:** a session without both timings can't go live; opening a lot on a held
specimen fails; a DM-style claim can't take a held lot; closing a won lot leaves one
reservation for the winner; passing twice releases once; a missed payment keeps the hold
until the backup window ends, then returns stock; offering to the backup leaves one
active reservation and the original winner in history; a claim on sold-out stock joins
the waitlist and nothing is reserved until the seller offers it; a paused session takes
no new claims; host/packers never see costs or order totals.

**Built notes:** A win doesn't change the hold in place: it releases the session's hold and
creates the winner's in the same transaction, so the stock history shows both. That hold
already ends at the payment deadline plus the backup window, so a missed payment needs no
job to keep it held; "Payment missed" is shown from the deadline, and the expiry job marks
the lot or claim returned when the hold runs out. A claim joins the waitlist when anyone is
already waiting, so nobody jumps the line; with `sales.waitlist` off, a claim that can't be
held is refused. Names the host types become aliases in the session's group (the channel)
and are reused for the same name. A host/packer can only open Host View for sessions they
host, and settling results (backup, relist, return, removing claims) is for owners and
managers. Until Closeout (B26), payment is tracked outside VIVUM, so every unpaid win shows
as missed after its deadline. The Sell tabs now wrap at phone width. Tests cover the
acceptance cases. A browser check covered setting up and going live, opening and winning a
lot with a backup, claims and the waitlist offer at phone width, and a transfer to the
backup after a missed payment. The `sale-sessions` and `quick-claim` help topics need
review.

### B26 Sale Closeout — discussed and built 2026-11-26

**Scope**
- **Closeout page (SC01, D219, D226):** per session, the won lots and held claims grouped
  by buyer, with views Unresolved, Awaiting payment, Expiring (holds ending within 24
  hours), Backup offers, Ready to pack and Completed. Each order row shows items, price
  snapshots, subtotal, payment state, hold expiry and a copy order link.
- **Create orders (D219, D220, D222):** one tap creates a reserved order per resolved buyer
  per session, source "Live sale", one line per lot or claim at its bid or claim price.
  Lines link to their lot or claim (unique, so a repeat tap adds nothing) and take over
  the existing hold without releasing it. A payment pins the holds as for any order.
- **Unresolved aliases (D221):** link an alias to an existing buyer or create a buyer from
  it in Closeout; never automatic.
- **Exceptions (SC02, D223–D225):** Move to backup cancels the winner's line ("Payment
  missed") and transfers the lot; the backup's line joins their session order. Split
  unpaid orders and cancel lines, recording previous total, new total and reason. All
  three are refused on part-paid and paid orders, which point to refunds and returns.
- **Roles, export and records (D227, D228):** owners and managers only; CSV of the current
  view; audited; `seller.closeout` becomes implemented, with a help topic.

**Deferred:** payment attempts for a changed total (B40); packing and host/packer access
(B27); buyer order links (B30); combining orders across sessions.

**Acceptance:** three wins for one buyer become one order with no re-entry; tapping Create
orders twice adds no lines; an unlinked alias's wins never join an order until linked, and
matching names never merge; an ordered line keeps the lot's hold and deadline; moving a
missed payment to the backup cancels the winner's line and leaves one active hold for the
backup; splitting or cancelling an unpaid order records the previous total and reason; a
paid order can't be split or have lines cancelled; host/packers can't open Closeout.

**Built notes:** Closeout is a page per session (`/sell/sessions/:id/closeout`), linked from
the session page. Results join the buyer's unpaid order for that session, so a part-paid
order gets a new order for later results rather than a changed total. A result counts as
on an order while an active line holds its current hold; the existing unique index on
`order_lines.stock_hold_id` stops a second line. Lines from a lot or claim can't change
quantity, and cancelling one returns the lot or claim and its stock. A paid result no
longer shows "Payment missed", and the payment pins the hold so the expiry job leaves it.
Because order lines need an exact price each, a lot of several plants now needs a winning
and backup bid that splits evenly into cents; Host View suggests the nearest amounts. Order
actions (lines, split) now go back to the page they came from, so Closeout stays in view.
Tests cover the acceptance cases. A browser check covered linking a name by adding a buyer,
creating orders, splitting one, the backup offers view, and phone width. The `closeout`
help topic needs review.

### B27 To ship list, order slips, pickup and manual tracking — discussed 2026-11-27, re-scoped 2026-11-27, built 2026-11-28

The first discussion (D229–D238) planned parcels, per-line packed quantities, short picks and
a packer view. It was replaced the same day by a simpler scope for one- or two-person
sellers (D239–D244).

**Scope**
- **To ship list (PK01, D240):** reserved orders that are paid or overpaid, oldest payment
  first, under Sell → To ship. Only owners and managers can see it.
- **Packed (D241):** an optional tick per order with member and time, which can be unticked
  before shipping. A missing or damaged plant is handled by changing or cancelling the line
  on the order.
- **Slips (PK02, D242):** one print-ready slip per order with the business name, order,
  recipient with address or Pickup, and items with codes and quantities, but no prices.
  Print all prints every order on the list.
- **Shipping and collection (D243):** one courier and tracking reference per order. Shipped
  or Collected fulfils the holds and removes stock, as now.
- **Records (D244):** audited; `seller.packing`, `shipping.pickup` and `shipping.manual`
  become implemented, with a help topic.

**Deferred:** parcels and part quantities, the short-pick workflow, host/packer access, the
delivered state, care packs on slips (B31), buyer tracking links (B30), and Bob Go booking
and waybills (B42).

**Acceptance:**
- Unpaid and part-paid orders never appear on To ship.
- Host/packers can't open To ship or slips.
- A slip lists every active line with its code and quantity, and shows no prices.
- Print all prints one slip per listed order.
- Packed can be unticked before shipping, and each change is audited.
- Shipping removes stock once, and a repeat does nothing.
- A pickup order's slip shows "Pickup" instead of an address.

**Built notes:** `Order::Packing` adds the `to_ship` scope and audited `pack!`/`unpack!` on
`orders.packed_at` and `packed_by_id`. A fully paid order already has a receipt, which
fixes its lines, so a packed order's contents can't change and Unpack is the only undo.
Sell → To ship (`Sell::ToShipController`) has the per-order slip and Print all, both on a
bare `print` layout with a Print button, and the existing fulfilment action for shipped or
collected. The order page shows Mark packed and Slip for to-ship orders. Pickup orders
are listed only with `shipping.pickup`, and courier and tracking fields need
`shipping.manual`. The help topic `to-ship` needs review.
