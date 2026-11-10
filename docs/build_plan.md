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
| B03 | Feature flag registry and capability service | §28 FF01–FF04 | B01 | Next (discussed) |
| B04 | Operator audit log (Madmin and flag changes) | PR08, FF04, O14 | B03 | Planned |
| B05 | Consent records and onboarding consent | PR03, ST06, D15 | B01 | Planned |
| B06 | Seller invites and onboarding (invite-only) | SO03, D17 | B02, B04 | Planned |
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

