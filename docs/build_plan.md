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
| B06 | Seller and staff invites, onboarding (invite-only), Sell home and Members | SO02, SO03, D17, D58–D63 | B02, B04 | Next (discussed) |
| B07 | Seller billing modes: Pilot, Comp, Paid (Paystack later) | SB01–SB03, D21 | B06 | Planned |
| B08 | Account export and deletion | §26 export, PR05, PR07, OF01 store rules | B01 | Planned |
| B09 | Help manual skeleton and contextual links | HM01, HM02 | B03 | Planned |

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
| B10 | Plant records, acquisition, status, photos, search | PL01–PL04, UX01, OF03 | B03 | Planned |
| B11 | Environments, occupants, measurements | EN01–EN03, PL05 | B10 | Planned |
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

### B06 Seller and staff invites — discussed 2026-11-10

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
