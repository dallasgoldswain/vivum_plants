# VIVUM Plant Codex — Product Requirements Document

**Version 1.3** · 9 November 2026 · Implementation requirements
**Status:** Draft for product owner sign-off. Supersedes v1.2.
**Decision log:** [prd_decisions.md](prd_decisions.md) (D01–D32)

Working brand: VIVUM Plant Codex. Proposed tagline: *Every plant. Every detail.* Production domain: `plants.vivumlabs.co.za` (D32); the parent name VIVUM Labs plays on a tissue culture lab and a software lab. Trademark clearance is outside this PRD and unverified.

---

## 0 What changed from v1.2

- **One scope table.** v1.2 listed live sales, checkout, fulfilment, branding and care packs as both "additional" (§2) and "current build" (§21). v1.3 has a single scope (§2): the collector product and the full seller product launch together (D01).
- **Integrations and AI in v1.** Bob Pay, Yoco, Bob Go, WhatsApp Cloud API DM claims, AI care suggestions and AI DM extraction are all in the launch build (D02, D03). WhatsApp catalogue sync and cart import remain roadmap.
- **New sections:** seller business and staff roles (§13), buyer identity (§16), receipts and VAT (§15), seller subscription billing (§13), notifications (§10), offline (§4), storage limits (§4), AI architecture (§11), POPIA (§25).
- **Resolved open decisions:** AI provider abstraction (RubyLLM), library ownership and size, commercial model, clients, consent defaults, seller onboarding, shipping lanes, hold timings.
- **Flag registry** extended for the new capabilities; granularity unchanged (D04).
- Requirement IDs from v1.2 are kept. New IDs: SO, SB, BY, RC, NT, OF, AI, PR.

## Document status

**Confirmed** = explicitly decided (C01–C08, D01–D31). **Baseline** = detailed requirement adopted for build, subject to product owner sign-off of this version. **Open** = decision still required (§32). Numeric performance and retention targets are planning targets until confirmed.

## Reading guide

| Sections | Content |
|---|---|
| 1–5 | Intent, scope, users, platform, navigation |
| 6–12 | Collector product: plants, environments, substrates, TC, care, guidance, settings |
| 13–24 | Seller product: business, stock, orders, buyers, live sales, WhatsApp, closeout, packing, payments, shipping, care packs, buyer pages, sitter, manual |
| 25–29 | Privacy, quality, data, flags, engineering |
| 30–32 | Measurement, delivery and acceptance tests, risks and open decisions |

---

## 1 Product intent and decision record

### Problem and intended outcome

Collectors need to connect what a plant is with where it grows, what substrate it uses, what care it received and how it changed. Sellers in the South African plant community sell through WhatsApp groups, auctions and DMs, and track stock, claims, payments and parcels by hand. VIVUM is a South African plant collection and seller operations platform that serves both, with one account able to do both. User research has not yet validated frequency or market size.

### Confirmed decisions

| ID | Decision |
|---|---|
| C01 | Audience includes collectors who want detailed records. |
| C02 | Cover indoor plants, aquatic plants, terrariums and purchased tissue culture plants. |
| C03 | Track purchased TC plants, progress, repotting checks and reminders. Exclude TC laboratory use. |
| C04 | Support user-set schedules and VIVUM-suggested schedules. |
| C05 | Combine built-in library guidance and AI guidance; users can enable either, both or neither. |
| C06 | Set defaults app-wide and allow users to edit plant settings. |
| C07 | Changed defaults do not affect existing plants. Warn the user when saving changes. |
| C08 | Sellers are primary users. Support stock control and sales alongside collection management. |
| D01 | Collector and seller products launch together. |
| D02 | Bob Pay, Yoco, Bob Go and WhatsApp Cloud API DM claims are in v1. |
| D03 | AI care suggestions and AI WhatsApp DM extraction are in v1. |
| D04 | Feature flags: one flag per capability, CI covers enabled and disabled behaviour. |
| D05 | Seller is a business with members and roles. |
| D06 | Buyers are seller-scoped records keyed on verified phone number (E.164). |
| D07 | Full POPIA compliance requirements are part of this PRD. |
| D08 | Seller receipts per order; VAT breakdown and tax-invoice fields when the seller is VAT-registered. |
| D09 | AI via RubyLLM with the `anthropic` and `openai` gems; provider selectable per use case. |
| D10 | Curated library of ~50 species profiles at launch, editor-published. |
| D11 | Collectors free; sellers pay a monthly subscription; paid branding is an add-on or higher tier. |
| D12 | Web, PWA and Hotwire Native iOS and Android apps at launch. |
| D13 | Seller subscriptions billed through Paystack, separate from seller-owned checkout. |
| D14 | No platform default for hold expiry or backup-bidder windows; seller must set them. |
| D15 | Guidance sources off until chosen at onboarding; AI data use explained first; account-wide AI stop. |
| D16 | Notifications via native push, web push, email digest and WhatsApp templates. |
| D17 | Seller access is invite-only during the pilot. |
| D18 | Offline: cached reads and queued care logs/photos; sales actions online only. |
| D19 | Strict photo caps: 500 photos for free collectors; seller caps per tier. |
| D20 | No platform restriction on Bob Go services; seller is responsible for live-plant suitability. |
| D21 | Two seller tiers (Starter R199, Pro R449 per month); pilot sellers free; operators can mark any seller as a no-charge comp/test account. |
| D22 | WhatsApp access route (Cloud API direct vs BSP) decided during the pilot; adapter-neutral build. |
| D23 | Claude Haiku for DM/request extraction, Claude Sonnet for care suggestions, OpenAI as fallback. |
| D24 | Per-account AI caps: collectors 30 care suggestions/month; seller extraction by tier; platform spend alert. |
| D25 | Pilot cohort of 5–10 invited sellers with a mix of selling styles. |
| D26 | Founder is POPIA Information Officer; external SA privacy attorney reviews before production. |
| D27 | Organisation developer accounts; subscriptions sold on web only, no purchase UI in native apps. |
| D28 | Email and push providers chosen at build behind adapters. |
| D29 | Founder edits the library; species list from pilot sellers' most-traded stock; AI may draft, founder publishes. |
| D30 | Help topics and screenshots written in the same change as each feature; founder reviews before flag goes live. |
| D31 | Widening a pilot flag is a founder judgement, recorded with evidence in the flag audit trail. |
| D32 | Production domain is plants.vivumlabs.co.za under the VIVUM Labs name. |

### Product principles

- Keep each physical plant record separate from its species reference profile.
- Make routine logging fast; keep optional detail available but never required.
- Show the source of every care suggestion and preserve user control over schedules.
- Keep history accurate when plants move, substrates change, guidance changes or stock is sold.
- VIVUM never receives, holds or distributes buyer funds.

### Success means

- A collector can add a plant, record its setup, choose a care approach, act on reminders and inspect a reliable timeline — for a potted aroid, an aquatic planting, a terrarium plant and a newly purchased TC plant.
- A seller can receive stock, run a WhatsApp group auction, capture wins and DM claims, close out by buyer, take payment through their own provider, pack, ship and hand over a care pack, with stock correct across every channel.

---

## 2 Scope

### Launch scope

| Area | In v1 |
|---|---|
| Collection | Plant records, photos, acquisition, tags, search, archive, purchase groups and splits |
| Environments | Rooms, cabinets, tanks, terrariums, acclimatisation containers; manual measurements; shared maintenance |
| Substrates | Ingredient library, versioned recipes, scaling, plant assignments, recipe sharing |
| Care | Care logs, recurring and one-off reminders, Today inbox, notifications on four channels |
| Guidance | ~50 built-in profiles; AI suggestions; independent switches |
| Purchased TC | Receipt, stages, progress, stage reminders |
| Seller business | Business profile, members and roles, invite onboarding, Paystack subscription, paid branding |
| Stock and sales | Specimens and lots, stock ledger, listings, sale cards, CSV import, reservations, orders, receipts/VAT |
| Live sales | Sale sessions, WhatsApp group auctions (manual capture), Quick Claim, backup bidder, waitlist |
| WhatsApp | Share/download; Cloud API connection; DM claims with AI extraction; request capture; outbound templates |
| Requests | Request form, manual entry, matching, offers, Wanted List |
| Fulfilment | Closeout, packing checklist, parcel slips, pickup, manual tracking, Bob Go |
| Payments | Manual payment records, Bob Pay, Yoco (seller-owned) |
| Buyer handover | Request, offer, order, checkout, tracking and care links; care packs, PDF, QR labels; collection import |
| Collaboration | Plant Sitter scoped access |
| Help | Searchable web manual with contextual links |
| Data control | POPIA controls, export, deletion, backup recovery |
| Clients | Web portal, PWA, Hotwire Native iOS and Android |

### Explicit exclusions

- TC laboratory workflows: media preparation, sterilisation, vessel inventory, subculture, lab batches, lab QC.
- Livestock management for fish, shrimp or terrarium animals.
- Automated dosing, irrigation, lighting or equipment control; sensor integrations.
- Public marketplace, multi-seller carts, discovery, storefront builders, custom domains, footer removal.
- VIVUM holding, splitting or distributing buyer funds; escrow; platform balances.
- Guaranteed identification, diagnosis or care outcomes.
- AI image analysis and AI web browsing.

### Roadmap (flags registered as unavailable)

Marketplace discovery, cross-seller Wanted Board, native storefront, Shopify and WooCommerce connectors, WhatsApp catalogue sync, WhatsApp cart import, custom domains, footer removal, self-serve seller sign-up, sensor connections, bulk editing, third-party collection import.

### Release boundary

A TC purchase may include several plantlets; the app records quantity and can split them into individual records. This is collection tracking, not lab inventory. Substrate recipes cover growing mixes; culture-media formulation is excluded.

### Core pilot scenario

A buyer wins three unique plants in a WhatsApp group auction. The seller captures results in Host View, combines the wins in Closeout, shares one Bob Pay checkout, packs the three correct specimens, books one Bob Go shipment and shares one care pack. The buyer opens the care pack in a browser and saves the plants to a private collection.

---

## 3 Users, roles and journeys

### Actors

| Actor | Description |
|---|---|
| Collector | Account holder managing a private collection. Free. |
| Seller member | Account holder who belongs to a seller business with a role (§13). The same account may also be a collector. |
| Buyer | No account required. Seller-scoped record keyed on phone number (§16). Uses task-specific links. May sign in to import plants to a collection. |
| Sitter | Temporary, link-scoped access to selected plants and tasks (§24). |
| Library editor | Internal role that publishes versioned reference profiles and ingredients. Cannot change any user records. |
| Platform operator | Internal role: invites sellers, manages flags, handles support and POPIA requests. Audited. |

### Key journeys

| Journey | Required path |
|---|---|
| Add a purchase | Choose plant type → name → optional source and photo → review settings → save |
| Care for today | Today → inspect plant or environment → complete, skip or snooze |
| Repot a plant | Plant → log repot → select recipe version and pot → date and observations |
| Manage an aquarium | Create tank → add plants → record conditions → log shared maintenance |
| Acclimatise a TC purchase | Record receipt → deflask → record setup → monitor stages and reminders |
| Use care guidance | Enable source → review suggestion → edit or accept → schedule created |
| Change defaults | Edit settings → read warning → save → existing plants unchanged |
| Run an auction | Create session with hold and backup windows → go live → open lot → capture winner → close |
| Close out | Closeout → group wins by buyer → create order → share checkout → pack → ship → care pack |
| Fulfil a DM claim | Inbound DM → AI extraction → claim (review or auto-reserve) → order |

### Experience requirements

- UK English, plain care terms; common and botanical names without forcing verified identification.
- A useful plant record needs only a display name and growing context.
- Empty states show a direct next action; no unlabelled demo data in real collections.
- Seller times display in Africa/Johannesburg; money in ZAR.

---

## 4 Platform, clients, offline and storage

### OF01 Clients (D12)

Ship a server-rendered Rails web portal (Turbo, Stimulus), an installable PWA, and Hotwire Native apps for iOS and Android in the App Store and Play Store. Native apps wrap shared Rails flows; native screens only where the platform requires (push permission, camera, share sheet, file picker).

*Acceptance:* Every journey in §3 completes in web, iOS and Android. A flow fixed in Rails is fixed in all three without an app release, except native bridge components.

App store requirements to satisfy: privacy nutrition labels / data safety forms consistent with §25; account deletion from inside the app; no in-app purchase of digital goods (seller subscriptions are sold and managed on the web, per store rules for business services — confirm in review).

### OF02 Offline behaviour (D18)

- Cache the collection list, plant detail, Today and help pages for read access offline.
- Queue care events, observations and photos offline with a client-generated idempotency key; sync when online. Show queued state per item.
- Sales, stock, reservation, order, payment, shipment and flag-gated actions require server confirmation and are disabled offline with a clear message.
- Never cache payment or order tokens, buyer pages or seller admin pages in the service worker.

*Acceptance:* A care log saved offline and synced twice creates one event. A seller cannot reserve stock offline. A queued photo that fails upload keeps its note.

### OF03 Photo storage and limits (D19)

- Free collectors: 500 photos per account. Sellers: Starter 2,000, Pro 10,000 (SB01).
- Resize originals server-side (proposed max 2560 px long edge) and generate thumbnails; strip location EXIF before storage.
- At 80% and 100% of cap, warn; at cap, block new uploads without affecting existing photos or other writes.
- Photos linked to sold stock, care packs or seller listings count against the seller, not the collector.

*Acceptance:* An upload at the cap is rejected with an explanation; the typed note is retained. Deleting photos frees quota.

---

## 5 Information structure

| Area | Primary content and actions |
|---|---|
| Today | Due and overdue tasks, upcoming checks, quick log, guidance awaiting review |
| Collection | Grid/list, search, filters, add plant, archive |
| Plant detail | Overview, setup, timeline, photos, care plan, reminders, guidance settings |
| Environments | Rooms, tanks, terrariums, cabinets, occupants, conditions, maintenance |
| Substrates | Ingredients, recipes, versions, plants using a recipe |
| Codex | Built-in reference profiles and collector notes, clearly separated |
| Sell | Inventory, listings, sale cards, sessions/Host View, claims, requests, Closeout, orders, packing, buyers |
| Seller settings | Business profile, members, connections (WhatsApp, Bob Pay, Yoco, Bob Go), subscription, branding, keyword presets |
| Settings | New-plant defaults, notifications, units, privacy, AI, export, account |
| Help | Searchable manual |

UX01 **Find a record** — search common/botanical name, cultivar, nickname, record ID, tags; filter by context, location, status, TC origin, care due. *Acceptance:* two Monstera records of the same cultivar are found separately; each opens its own history.

UX02 **Quick care entry** — short route from Today and plant detail to watering, feeding, repotting, observation, treatment, photo or custom event. *Acceptance:* a basic event saves without the edit form; optional details never block saving.

UX03 **Linked records** — plant detail shows current environment and substrate; opening them and returning keeps an unsaved care entry. *Acceptance:* a recipe shows ingredients and version; a tank shows current plants.

**Context rules:** a plant has one current primary environment with history retained. TC origin is separate from growing context; a TC-origin plant can be aquatic.

---

## 6 Collection and plant requirements

PL01 **Create and edit plant records** — stable ID, display name, botanical name, cultivar, common name, optional profile link, growing context, origin, quantity, status, notes. Unknown identity and duplicate names allowed. *Acceptance:* an unknown plant saves without species; renaming preserves ID, photos, reminders, history.

PL02 **Record acquisition** — date, source, cost, currency, order reference, arrival notes. Cost optional; no inferred market value. *Acceptance:* a gift saves without price; prices keep original currency.

PL03 **Status** — active, quarantined, lost, sold, gifted, archived, with effective date and reason. Offer to stop reminders for inactive plants. *Acceptance:* archiving hides from active collection but keeps timeline; restoring asks about reminders and creates no past notifications.

PL04 **Photos and observations** — dated photos and notes on plant or event; captions; cover image; event date separate from entry date. *Acceptance:* yesterday's observation sorts correctly; failed upload keeps the note.

PL05 **Setup and movement history** — pot/container, size and units, watering method, environment, recipe version, setup date; prior assignments retained. *Acceptance:* repotting changes current setup; earlier events still show the earlier setup.

PL06 **Quantity and splits** — purchase groups for TC plantlets or aquatic plantings; splitting creates linked records with own IDs. *Acceptance:* splitting five into two and three keeps the source purchase and never counts eight; each gets an independent care plan after review.

**Record integrity:** warn before permanent deletion and show linked effects; archive is the routine alternative. Profile edits never overwrite collector identity notes, photos, acquisition or history.

---

## 7 Environments and shared care

EN01 **Create environments** — rooms/shelves, grow cabinets, aquariums, terrariums, acclimatisation containers; name, type, notes, dimensions/volume, units, photos. *Acceptance:* a tank works with only name and type.

EN02 **Record conditions** — dated manual measurements. Indoor/terrarium: temperature, humidity, light duration, optional measured light. Aquatic: water temperature, pH, hardness, light duration, CO2 notes. *Acceptance:* every value has unit, date and source; missing stays unknown, never zero.

EN03 **Occupants** — many plants per environment, dated moves, history kept, unassign allowed. *Acceptance:* a moved plant appears only in the new environment's current occupants; both appear in its history.

EN04 **Shared maintenance** — environment tasks (water change, misting check, equipment check) distinct from plant care. *Acceptance:* one water change creates one environment event linked to plants present at that time; no per-plant notifications.

EN05 **Conditions in guidance** — when AI is enabled, latest measurements and their dates may be used; show which informed a suggestion. *Acceptance:* stale or missing inputs are identified; moving a plant never silently rewrites its accepted schedule.

---

## 8 Substrate and ingredient library

SU01 **Ingredients** — built-in and personal; name, category, particle size, water retention, aeration, intended use, preparation, source. Qualitative properties labelled as guidance. *Acceptance:* a branded ingredient keeps manufacturer details and is distinct from generic.

SU02 **Recipes** — named recipes, quantities, mixing basis (parts or % by volume), notes, contexts, source. *Acceptance:* 2 bark : 1 perlite : 1 coir shows 50/25/25%; a % recipe must total 100% before ready.

SU03 **Scale a mix** — compute volumes from a target total with practical rounding. *Acceptance:* 2:1:1 to 4 L gives 2 L / 1 L / 1 L; weight is not converted to volume without an explicit model.

SU04 **Version and assign** — assign an exact version; editing an in-use recipe creates a new version; never rewrite past repots. *Acceptance:* a plant on v1 stays on v1 after v2 is saved.

SU05 **Search and reuse** — search by name, category, context; current vs past use; copy built-in to personal. *Acceptance:* deleting a used personal recipe never breaks history (archive or snapshot).

Single-material substrates are one-ingredient recipes. Ingredient stock control and cost estimates are excluded.

---

## 9 Purchased tissue culture plants

Confirmed boundary C03: tracks arrival, acclimatisation, care and establishment of purchased TC plants only.

TC01 **Record a purchase** — TC origin flag, supplier, arrival date, plantlet quantity, container condition, photos, optional deflask date. *Acceptance:* a pre-deflasked plant can start at acclimatising; unknowns optional.

TC02 **Stages** — sealed on arrival, deflasked, acclimatising, established; user-set with effective date; direct route into aquatic. *Acceptance:* deflasked → established in an aquarium without an indoor stage; prior stages stay in the timeline.

TC03 **Monitor progress** — new leaves, roots, damage, suspected contamination, losses, substrate, humidity setup, photos; no confirmed diagnosis claims. *Acceptance:* recording one lost plantlet updates remaining count and keeps the arrival quantity.

TC04 **Stage reminders** — custom reminders and source-based suggestions for inspection, ventilation, humidity review, repot readiness, follow-up, tailored to destination context. *Acceptance:* prompts "Check readiness for repotting" rather than recording a repot; inspections never advance a stage automatically.

TC05 **Continue normal care** — an established TC plant stays the same record with TC origin and history. *Acceptance:* marking established offers keep, cancel or replace for outstanding TC tasks; none are silently deleted.

---

## 10 Care logs, reminders and notifications

CA01 **Care events** — watering, feeding, repotting, pruning, treatment, inspection, movement, stage change, custom; actual time, notes, amount and units, linked task. *Acceptance:* completing a watering task creates one event; a retry after failure creates no second event.

CA02 **Schedules** — one-off and recurring by days, weeks or calendar months; fixed-calendar or after-completion; preview upcoming dates. *Acceptance:* 7-day after-completion done 10 Nov → next 17 Nov; fixed weekly keeps its weekday when completed late.

CA03 **Task states** — upcoming, due, overdue, completed, skipped, cancelled; snooze moves the next alert only; original due date and history kept. *Acceptance:* skipping logs no care; an overdue recurring task shows one unresolved occurrence, not a stack.

CA04 **In-app inbox** — Today is authoritative regardless of notification delivery. Permission denial never blocks task use. *Acceptance:* with push denied, tasks still appear in Today.

CA05 **Protect plans** — manual plans change only on acceptance; check for equivalent active tasks before creating a suggested one; offer merge, replace or keep. *Acceptance:* a second watering suggestion shows the existing task first; an edited due date is never changed by a background suggestion.

**Date rules:** store timezone and recurrence semantics; month schedules clamp to last valid day; timezone change prompts to keep local times or absolute times.

### Notifications (D16)

NT01 **Channels** — native push (APNs via iOS app, FCM via Android app), web push (PWA; iOS only when installed to home screen), daily email digest, WhatsApp template messages. Users choose channels per notification type, preferred time, quiet hours and timezone.

NT02 **Delivery rules** — one notification per occurrence per channel; retries deduplicated by occurrence and channel; a notification deep-links to the correct record in web or native app.

NT03 **WhatsApp reminders** — opt-in only, with explicit consent recorded (§25); approved Meta templates; per-message cost. Sent from a VIVUM platform number for collector reminders, and from the seller's connected number for buyer messages (§18). Opt-out keywords honoured immediately. Collector WhatsApp reminders are sent as one daily summary to control cost (proposed cap: 31 per account per month).

NT04 **Email digest** — daily summary of due and overdue tasks at the chosen time; unsubscribe link; no private notes in email.

*Acceptance:* with all four channels on, one occurrence produces at most one message per channel. Turning WhatsApp off stops queued template sends before delivery. An opt-out reply stops further WhatsApp messages.

---

## 11 Library and AI guidance

| Library | AI | Behaviour |
|---|---|---|
| On | Off | Suggestions from versioned built-in profiles |
| Off | On | AI suggestions from permitted plant and environment context; no injected library content |
| On | On | Library baseline with AI adjustments and reasons shown |
| Off | Off | Manual records and schedules only |

GU01 **Reference profiles** — name, taxonomy, contexts, care guidance, references, review status, version, review date. *Acceptance:* suggestions cite profile and version; no match gives an explicit unavailable state.

GU02 **AI suggestions** — use selected plant data, stage, setup, environment and care history; show inputs, assumptions, missing information and reason. *Acceptance:* unknown conditions are never shown as measurements; the AI may ask for more information or decline.

GU03 **Review and acceptance** — label as library, AI or library + AI; edit, accept, dismiss, regenerate; accepted content snapshotted with source. *Acceptance:* reminders change only on acceptance; acceptance after a manual edit requires a refreshed comparison.

GU04 **Control and failures** — AI off for a plant blocks new requests and suppresses pending suggestions; accepted plans preserved; timeouts and rate limits never block manual care. *Acceptance:* a failed request changes nothing; turning AI off keeps accepted reminders and history.

### Launch library (D10)

- ~50 curated species profiles plus the core ingredient set. The species list is taken from the most-traded plants in pilot sellers' stock (D29).
- The founder is the library editor. AI may draft a profile; the founder reviews, adds references and publishes. AI-drafted content is never published unreviewed.
- Published through a controlled process (version-controlled seed data or an internal admin screen with draft → review → publish → retire).
- Each published profile has references, contexts, version and review date. Unreviewed content is never labelled verified.
- Corrections never rewrite accepted plans or history; users with affected active plans are offered a review.
- Care packs (§22) use these profiles as templates; species without a profile start from a blank seller-authored template.

### AI architecture (D09)

AI01 **Provider abstraction** — use RubyLLM with the `anthropic` and `openai` gems. Each AI use case (care suggestion, DM extraction, request extraction) is configured with its own provider and model, switchable without code change. Defaults (D23): Claude Haiku for DM and request extraction; Claude Sonnet for care suggestions; OpenAI configured as fallback when the primary provider errors or is unavailable. Fallbacks are logged with the model actually used.

AI02 **Structured output** — extraction returns a validated schema (intent, listing code, quantity, confidence, buyer wording). Invalid or low-confidence output routes to seller review. Rails, not the model, checks flags, permissions and stock before any action.

AI03 **Traceability and limits** — record provider, model, prompt version, inputs used, generation time, token usage and cost per request. Monthly caps (D24): collectors 30 care suggestions; sellers 1,000 (Starter) or 5,000 (Pro) DM/request extractions; pilot and comp sellers use their assigned tier's cap. Usage visible to the account; at the cap, AI pauses with a message and manual flows continue. A platform-wide spend alert notifies operators when monthly AI cost passes a configured threshold. Prompts and model outputs are excluded from general analytics.

AI04 **Data minimisation** — exclude supplier contact details, prices, order references, buyer addresses and photo metadata unless required. No photo transmission in v1. Use provider zero-retention / no-training terms where available; record the transfer basis (§25).

*Acceptance:* switching the extraction provider from Anthropic to OpenAI in config changes no behaviour outside AI calls. A malformed model response creates no claim. An account at its AI budget gets a clear message and manual flows still work.

---

## 12 Settings, inheritance and onboarding

ST01 **Independent switches** — library and AI switches at app and plant level; all four combinations; effective settings shown on each plant. *Acceptance:* library off/AI on for one plant changes nothing else.

ST02 **Snapshot defaults** — copy defaults into each new plant; store default revision used. *Acceptance:* plant A on revision 1 keeps its switches after revision 2; plant B gets revision 2.

ST03 **Warn when changing defaults** — warning before save; cancel changes nothing. Required copy: *"These settings will apply to plants you add from now on. Existing plants will keep their current settings. You can edit each plant's settings at any time."* Actions: **Cancel**, **Save defaults**.

ST04 **Apply current app defaults** — explicit per-plant action with comparison; updates only guidance switches. *Acceptance:* custom reminders and history unchanged.

ST05 **Separate scopes** — guidance defaults follow the snapshot rule; timezone, units, notification preferences and the account-wide AI stop have their own scopes. *Acceptance:* changing units changes display only; the AI stop blocks all AI requests without rewriting plant switches.

ST06 **Onboarding consent (D15)** — new accounts start with library and AI off. Onboarding asks the user to choose guidance sources; choosing AI shows what data is sent, to which provider category, and why, and records consent (§25). The account-wide AI stop is available in Settings at all times.

*Acceptance:* no AI request is made for an account that has not consented. Withdrawing consent activates the AI stop.

---

## 13 Seller business, members, onboarding and billing

SO01 **Seller business** — a seller is a business entity with name, legal name, VAT number (optional), contact details, logo and settings. All seller records carry `seller_id`. A member account can also keep a private collection; transfers between collection and stock are explicit (SE04).

SO02 **Members and roles (D05)** — roles: **Owner** (everything, billing, connections, members), **Manager** (stock, sales, orders, payments review, packing, requests; no billing or connections), **Host/Packer** (Host View, Quick Claim, packing, pickup confirmation; no prices, costs or refunds). Every stock movement, claim, order change and payment review records the acting member. Owners can invite and remove members; removal revokes access immediately.

*Acceptance:* a Packer cannot see private cost or change a price. A removed member's open sessions stop working. Audit shows who reserved each unit.

SO03 **Invite-only onboarding (D17)** — platform operators issue seller invites. An invite creates the seller business and owner membership after sign-in and acceptance of seller terms (§25). Without an accepted invite, `seller.workspace` is denied. Self-serve sign-up is roadmap.

*Acceptance:* an uninvited account cannot open Sell. An expired invite cannot be accepted.

SB01 **Subscription billing (D11, D13, D21)** — sellers pay a monthly ZAR subscription through Paystack. VIVUM's subscription billing is entirely separate from seller-owned buyer checkout (PY03). Subscriptions are bought and managed on the web only; native apps show plan status but no purchase UI (D27).

| Plan | Price / month | Members | Photos | Branding | AI extractions / month |
|---|---|---|---|---|---|
| Starter | R199 | 2 | 2,000 | Standard identity | 1,000 |
| Pro | R449 | 5 | 10,000 | Paid branding included | 5,000 |

Prices and limits are stored as plan data so they can change without a release; existing subscribers keep their price until notified per the seller terms.

SB03 **Pilot and comp accounts** — a platform operator can set any seller's billing mode to **Paid**, **Pilot (free)** or **Comp/test (free)** and assign the tier whose entitlements apply. Free modes create no Paystack subscription and are never charged. Each change records operator, reason, and optional end date; at the end date the seller is prompted to choose a paid plan, with the SB02 grace rules applying. All pilot sellers (D25) start in Pilot mode on Pro entitlements.

*Acceptance:* a comp seller on Pro can use paid branding without a Paystack record. Changing a seller from Pilot to Paid requires a successful Paystack subscription before the free mode ends. Only operators can change billing mode, and every change is in the audit trail.

SB02 **Entitlements** — entitlements derive from verified Paystack subscription state (webhooks verified and deduplicated). Grace period on failed renewal (proposed 7 days), then seller tools become read-only for new sales; existing orders, payment reconciliation, fulfilment, care access and exports stay available. Enabling a flag never grants an entitlement.

*Acceptance:* a lapsed seller can still fulfil and reconcile paid orders but cannot open a new sale session. A repeated Paystack webhook changes state once. Collectors are never charged.

---

## 14 Seller inventory and listings

SE01 **Sale stock** — unique specimens (quantity 1) and repeatable SKUs; name, cultivar, size/pot, location, photo, price, currency, optional private cost; optional plant link. *Acceptance:* two same-cultivar plants have distinct photos, prices, SKUs; ten identical pots can be one batch.

SE02 **Stock movements** — receipt, reserve, release, fulfil, return, loss, adjustment with time, quantity, reason, member. On hand, reserved and available by SKU and location; quarantined or damaged excluded. *Acceptance:* receive 5, reserve 2, mark 1 unavailable → 2 available; fulfilment removes the 2 from on hand and clears the reservation.

SE03 **Listings** — draft from available stock; name, price, photos, size, SKU, quantity, collection/delivery details; draft, active, paused, sold out. *Acceptance:* a reserved quantity-1 listing shows 0 available; pausing never changes stock.

SE04 **Collection link** — explicit transfers; care history preserved; sale status separate from health. *Acceptance:* selling a linked specimen closes its listing and records the sale on its timeline.

**Availability rule:** available = saleable on hand − active holds (lot holds + reservations). Every stock change is one transaction that locks affected rows in a stable order and validates availability. A quantity-1 specimen has at most one active hold.

---

## 15 Orders, receipts and sale cards

SE05 **Orders** — chat, in-person, auction, claim, request or other; SKU, quantity, agreed price snapshot, buyer (§16), pickup or shipping. Order state (draft, reserved, fulfilled, cancelled) separate from payment state. *Acceptance:* draft leaves stock available; reserving holds it; payment keeps the reservation until fulfilment; cancellation releases once.

SE06 **Holds and returns** — every hold has an expiry set by the seller (D14: no platform default; a session or listing cannot go live without one). Expired unpaid holds release automatically; paid orders whose hold would expire go to review. Returns are saleable only after inspection. *Acceptance:* two buyers for the last plant → one reservation; duplicate cancellation or webhook adds no stock; a damaged return stays unavailable.

SE07 **Sale cards** — selected photo; rendered name and price with currency; optional brand, SKU, pot size, contact. Square and vertical (Status) previews; PNG/JPEG export and caption. *Acceptance:* an R450 plant shows R450 and the selected image; long names never hide the price; no private data on the card.

SE08 **Share through WhatsApp** — Share and Download; device share sheet where supported (native share in iOS/Android apps); copyable caption; wa.me link with listing reference. *Acceptance:* sharing never reserves stock or creates an order.

**Price changes:** cards record price at export; stale cards are flagged with an offer to regenerate.

RC01 **Receipts and VAT (D08)** — every paid order can produce a receipt (web page and PDF) with seller details, order number, date, lines, quantities, prices, shipping, total and payment method. If the seller has a VAT number, show VAT-inclusive breakdown (15% SA VAT, rate stored per order) and tax-invoice fields: "Tax Invoice" label, seller VAT number, buyer name and address where supplied, sequential invoice number per seller. Receipt numbers are immutable once issued; corrections use a credit note.

*Acceptance:* a non-VAT seller's receipt shows no VAT line. A VAT seller's invoice numbers are sequential with no gaps per seller. Changing the seller's VAT number does not alter issued invoices.

---

## 16 Buyers and identity (D06)

BY01 **Buyer record** — seller-scoped buyer with phone number in E.164 (unique per seller), display name, optional email, delivery addresses, contact preference and marketing/WhatsApp consent. Sellers cannot see each other's buyers, even with the same phone number.

BY02 **Aliases and confirmation** — group auction wins and claims may be recorded against an alias (group display name). An alias links to a buyer only when the seller confirms, or when an inbound DM from a verified number claims it and the seller approves. Never merge automatically on matching names.

BY03 **Phone verification** — a phone number is verified by an inbound WhatsApp message from that number (Cloud API) or by a one-time code on a buyer link. Unverified buyers can still receive orders but are marked unverified.

BY04 **Buyer sign-in for collection import** — buyers who want to save plants (CP03) sign in to a VIVUM account; the seller never sees that account or collection.

*Acceptance:* two "Sam" aliases stay separate until linked. Seller A cannot find seller B's buyer by phone. A buyer's data export/deletion request (§25) is handled per seller.

---

## 17 Live sales and auction results

LS01 **Sale session** — seller, name, start/close, status (draft, live, paused, closed), channel, host member, lots, **hold expiry and backup-bidder window (required, D14)**. Bidding stays in the WhatsApp group; results captured in Host View and Quick Claim. *Acceptance:* a session without hold and backup windows cannot go live; pausing blocks new automatic claims; existing holds stay visible.

LS02 **Allocate and resolve lots** — opening a lot creates an exclusive hold; capture winner, final price, optional backup bidder and bid; record group alias when contact unknown; pass or open next. *Acceptance:* a DM claim cannot reserve a held lot; closing with a winner converts the hold to a reservation in one transaction; passing releases once.

LS03 **Transfer a failed win** — after the payment deadline, offer to backup bidder (within the session's backup window), relist or return to stock; record new price and member. Paid or disputed lines need explicit review. *Acceptance:* one active reservation; original winner and price kept in history; item removed from the original winner's unpaid order.

LS04 **Group claims** — Quick Claim records active plant, alias or buyer, quantity, optional message reference; waitlist when out of stock. *Acceptance:* identical claim rules for group and DM claims.

---

## 18 WhatsApp connection, DM claims and requests

### WhatsApp stages

| Capability | v1 |
|---|---|
| Manual share/download | Yes, always available |
| Cloud API connection (Embedded Signup, coexistence with Business app) | Yes, flagged pilot |
| DM claims with AI extraction | Yes, flagged pilot |
| Request capture from DMs | Yes, flagged pilot |
| Outbound templates (buyer messages, reminders) | Yes, opt-in |
| Catalogue sync, cart import | Roadmap |

WA01 **Connect and scope** — connect the seller's number via Meta Embedded Signup. The access route (VIVUM as Meta Tech Provider on Cloud API direct, or a BSP) is chosen during the pilot (D22) by testing both with a +27 number; the WhatsApp adapter must not assume either. Support coexistence with the WhatsApp Business app where eligible. Route inbound messages by seller and number. *Acceptance:* a disconnected seller can still run auctions and orders; a message for seller A can never create a claim for seller B.

WA02 **Configurable claims** — keyword presets (SOLD, MINE, ME, VAT HOM) normalised for case/spacing; modes Off, Review, Auto-reserve per session or listing. AI extraction (AI02) proposes intent, listing code and quantity; auto-reserve requires an unambiguous code or verified reply reference, positive quantity and high confidence. Questions, uncertain references and conflicts go to review. *Acceptance:* "MINE A17 x2" holds two when allowed; "Is A17 sold?" holds nothing; duplicates hold nothing extra.

WA03 **Inbound events** — verify signature, persist before acknowledging, deduplicate by provider, account and message ID; treat text as untrusted data.

WA04 **Outbound messages** — within the 24-hour service window, free-form replies; outside it, approved templates only. Respect buyer opt-in/opt-out and contact preference. Record cost category per message. Offer manual follow-up when a template is unavailable.

RQ01 **Private requests** — seller web form, manual entry, AI extraction from DMs; cultivar, form/stage, quantity, budget (ZAR), town/province, contact preference, source. Extracted requests need buyer confirmation or seller review. *Acceptance:* buyers submit without an app; ambiguous DMs go to review; requests never reserve stock.

RQ02 **Match and offer** — match on cultivar, stage, quantity, price, location; seller sets price and expiry; acceptance attempts a standard reservation. *Acceptance:* expired offers or stock sold elsewhere cannot reserve.

Eligibility, pricing and South African +27 coexistence are validated in the pilot before onboarding sellers widely.

---

## 19 Sale Closeout and Wanted List

SC01 **Close out by buyer** — confirmed lots and claims grouped by buyer: items, price snapshots, subtotal, payment status, hold expiry, packing, dispatch. Views: unresolved identities, awaiting payment, expiring holds, backup offers, ready to pack, completed. *Acceptance:* three wins for one buyer become one order with no re-entry; unresolved aliases never auto-merge.

SC02 **Exceptions and export** — split unpaid orders, cancel lines, move to backup, copy order link, export filtered report. A changed unpaid total needs a new payment attempt; previous total and reason recorded. *Acceptance:* repeated actions create no duplicate lines or payment attempts; paid orders need refund/adjustment review.

WL01 **Wanted List** — the seller's own open requests grouped by cultivar, form, budget, location with counts; drill to detail; select recipients for offers. *Acceptance:* rooted and unrooted requests group separately; closed excluded; other sellers see nothing.

**Order grouping:** one order = one seller + one confirmed buyer. Parcels can split; payment and fulfilment records stay with their original order and parcel.

---

## 20 CSV import and packing

IM01 **Preview imports** — UTF-8 template: SKU, name, cultivar, quantity, ZAR price, location, specimen/batch type. Parsed preview with errors (missing columns, malformed rows, invalid amounts, repeated SKUs, conflicts). Create-only default. *Acceptance:* an invalid file writes nothing; row errors downloadable; specimens must be quantity 1.

IM02 **Commit once** — commit validated rows only; recheck at commit; quantity changes as stock movements; import ID + checksum prevent duplicates; audit report; reversal via compensating adjustments. *Acceptance:* double submission → one result; imports cannot drop stock below commitments.

PK01 **Pack against the order** — checklist from paid or approved pickup lines; photos, SKUs, quantities, parcel allocation; packed quantity, member, time. *Acceptance:* same-cultivar plants for different buyers are distinguishable; short picks block completion.

PK02 **Parcel documents** — packing slip per parcel, printable with care pack; waybills separate. *Acceptance:* one parcel of three → one slip; a split → two correct slips.

**Fulfilment states:** paid, packed, booked, dispatched, delivered, collected — distinct, so an integration outage never blocks manual progress.

---

## 21 Seller payments and shipping

PY01 **Seller-owned payment connections** — Bob Pay and Yoco scoped to the seller business; test and live credentials separate, encrypted, never logged or sent to the browser. Provider-approved onboarding. Bob Pay piloted first; Yoco live only after third-party integration and domain approval. *Acceptance:* seller A's order can't be charged through seller B; no connection → manual payment recording.

PY02 **Verified checkout** — payment attempt for the exact total (including shipping) and currency; verify provider events and reconcile merchant, order, amount and currency; deduplicate callbacks; review late, duplicate, unmatched or partial payments. *Acceptance:* a success redirect alone never marks paid; a repeated webhook never duplicates payment or shipment; payment after stock release goes to review.

PY03 **Funds stay with the seller** — the seller's provider account receives funds; no platform balance, escrow or splits. Refund and dispute state recorded for seller review. *Acceptance:* disabling new checkouts still reconciles existing attempts.

SH01 **Quote, book, track** — seller-authorised Bob Go connection; quote, parcel dimensions/weight, origin, destination, booking reference, tracking; pending until confirmed; verified, deduplicated callbacks; reconcile ambiguous bookings before retry. *Acceptance:* a quote never books; a retry after timeout never books twice.

SH02 **Service choice (D20)** — sellers may use any Bob Go service. VIVUM shows a notice that live-plant suitability, packaging and courier acceptance are the seller's responsibility, recorded once per seller. If Bob Go rejects or fails a booking, offer pickup or manual tracking.

---

## 22 Care packs and QR labels

CP01 **Care content** — reusable sheets from library profiles (or blank templates), adapted per plant: approved photo, stage, setup, initial care, light and watering, repot checks, optional recipe. Published versions are immutable. *Acceptance:* established and TC-acclimatising plants get different instructions; template edits never change sent packs.

CP02 **Packs and recipes** — one pack per order, one sheet per applicable line; browser view and printable PDF; recipes shareable alone or attached, scalable. *Acceptance:* opens without sign-in; excludes costs, notes and customer details; a recipe can be viewed without the order.

QR01 **Care QR labels** — printable label/insert with logo, plant name, stock code, QR; resolves to a revocable care-only link; short URL fallback. *Acceptance:* scan opens the correct sheet; labels survive template edits; revocation blocks reads and imports.

CP03 **Copy to collection** — "Add to my collection" after sign-in and confirmation copies photo, identity, sheet version, seller credit and recipe; suggests reminders under the buyer's settings. *Acceptance:* seller cannot see the buyer's collection; repeat import creates no duplicate unless explicit.

---

## 23 Seller identity and buyer web pages

BR01 **Standard identity** — business name, logo, optional YouTube, Instagram and Facebook links, each toggleable; used on cards, forms, order, care pages and PDFs. *Acceptance:* available without a paid plan; hidden links never render.

BR02 **Paid branding** — approved palettes and layouts; entitlement from subscription (SB02) independent of flags; contrast fallback; seller and provider identity always shown on checkout. *Acceptance:* a flag alone never grants branding; on expiry new output reverts, existing orders and files still work.

WB01 **Task-specific buyer links** — request, offer, order review, checkout, tracking, care, receipt. Distinct high-entropy scoped tokens; expiry and revocation for sensitive actions; minimal personal data; nothing personal in link previews. *Acceptance:* a care link can't open payment, address or order; a revoked order link can't start checkout.

---

## 24 Plant Sitter and product manual

PS01 **Share temporary care access** — choose plants/environments, date range, tasks; expiring scoped invite link; revocable. *Acceptance:* sitter sees only selected plants and tasks; no private notes, prices, other plants or seller records.

PS02 **Sitter actions** — complete permitted tasks or add notes, attributed in the owner's timeline; same idempotency as owner logging. *Acceptance:* repeated taps → one event; expired or revoked links can't read or write.

HM01 **Web manual** — searchable, mobile-friendly, from Help with contextual links; collectors, sellers, dual-role users. *Acceptance:* search finds MINE, backup bidder, release reservation, closeout, CSV import, care QR, sitter access, receipts, members.

HM02 **Help with releases** — every user-facing capability has a help topic ID. The implementing agent writes or updates the topic and screenshots in the same change (D30); the founder reviews it before the capability's flag goes live. Topics mark integrations, rollout and subscription prerequisites. *Acceptance:* release check finds a topic for every enabled capability.

---

## 25 Privacy and POPIA (D07)

VIVUM processes personal information of collectors, seller members, buyers and sitters in South Africa and is subject to the Protection of Personal Information Act (POPIA). Legal review of this section is required before launch (§32).

PR01 **Roles and accountability** — VIVUM is the responsible party for account, collector, subscription and platform data. For buyer data held in a seller workspace, the **seller is the responsible party** and VIVUM acts as operator; seller terms include an operator agreement (POPIA s21). The founder registers as Information Officer with the Information Regulator (D26) and publishes a PAIA manual. An external South African privacy attorney reviews this section, the privacy notices, seller terms and operator agreement before production launch.

PR02 **Lawful basis and notices** — privacy notice for collectors and sellers at sign-up; short buyer notice on every buyer page and request form identifying the seller as responsible party. Record the basis for each processing purpose (contract, consent, legitimate interest).

PR03 **Consent records** — store timestamped, versioned consent for: AI processing (ST06), WhatsApp messages (per buyer per seller, and per collector for reminders), email marketing, buyer collection import. Withdrawal is as easy as giving consent and takes effect for queued jobs.

PR04 **Direct marketing (s69)** — no unsolicited electronic marketing to buyers except to existing customers for similar products with opt-out on every message; opt-out honoured across channels for that seller.

PR05 **Data subject requests** — access, correction, deletion and objection requests for account holders via Settings; for buyers via the seller (seller tools to find, export and delete a buyer's data) with platform-operator escalation. Respond within a defined period (proposed 30 days). Log requests and outcomes.

PR06 **Cross-border transfer (s72)** — AI providers (Anthropic, OpenAI), email, push and hosting providers outside SA require a transfer basis (adequate protection / binding agreement or consent). List sub-processors publicly; use no-training / zero-retention terms where available.

PR07 **Minimisation and retention** — collect only what each task needs; strip photo location metadata; buyer addresses retained only as long as needed for fulfilment and seller records (proposed: order data 5 years for tax, addresses redacted after 12 months unless reused). Account deletion removes active data within 30 days; backups expire within 90 days. Raw provider payloads retained with restricted access and a limit (proposed 90 days).

PR08 **Security safeguards (s19)** — encryption in transit and at rest; credential encryption for provider keys; least-privilege roles; audited operator access; private media via signed URLs only.

PR09 **Breach notification (s22)** — incident runbook to notify the Information Regulator and affected parties as soon as reasonably possible; sellers notified when their buyers' data is affected.

PR10 **Training** — private collection or buyer data is never used for model training without explicit consent.

*Acceptance:* a buyer opting out of a seller's WhatsApp stops queued templates. A seller can export and delete one buyer's data. An AI request is impossible without a recorded consent. Deleting an account removes its private photos from active storage within the target.

---

## 26 Quality, security and accessibility

| ID | Requirement | Verification |
|---|---|---|
| N01 | Collections, sellers and buyers isolated by tenant | Cross-account and cross-seller reads, edits, media, exports, links all fail |
| N02 | Protect data in transit and at rest | Config review; no public URLs for private media |
| N03 | Preserve saved work | Autosave/unsaved warnings; retried uploads; tested restore from backup |
| N04 | Responsive routine use | 1,000 plants / 10,000 events: p95 < 2 s for cached list and search on agreed device |
| N05 | AI latency separate from manual work | Navigation and logging during generation; pending state < 1 s; cancellable |
| N06 | Accessibility | WCAG 2.2 AA on web and native wrappers: keyboard, screen readers, focus, contrast, text scaling |
| N07 | Dates and units | Southern Hemisphere seasons, SAST, DST zones, metric defaults, unit round trips |
| N08 | Reliable task processing | Retries, clock changes, restarts, permission denial; one notification per occurrence per channel |
| N09 | Concurrency | Concurrent holds, claims, auctions, imports and payments preserve stock invariants |
| N10 | Provider resilience | Each integration down → manual path works; no lost VIVUM records |

**Export:** machine-readable export of plants, events, setups, recipes, settings, reminders, plus attachment manifest and photos; seller export of stock, movements, orders, receipts, buyers.

---

## 27 Logical data requirements

Business records, not a database design. Stable IDs, ownership, created/modified timestamps, explicit relationships, event date separate from entry time, UTC storage, ZAR as integer cents.

| Entity | Responsibility | Key links |
|---|---|---|
| Account | Identity, preferences, timezone, units, defaults revision, consents | Collection, memberships |
| Seller | Business profile, VAT number, settings, subscription | Members, all seller records |
| Membership | Account + seller + role | Audit of actions |
| Subscription | Paystack plan, state, entitlements | Seller |
| Plant | Identity, context, origin, quantity, status | Profile, acquisition, setup, stock item |
| Acquisition | Supplier, date, cost, currency, quantity | Plants |
| Reference profile | Versioned care knowledge, sources | Plants, suggestions, care sheets |
| Environment | Type, name, dimensions | Occupancy, measurements |
| Setup assignment | Dated pot, recipe version, environment | Plant |
| Ingredient, recipe version | Components, ratios, basis | Setup assignments |
| Care event | Action, dates, observations, photos | Plant or environment, task |
| Care plan, task occurrence | Recurrence, timezone, origin, state | Target, suggestion |
| Guidance settings | Two switches, revision | Plant or defaults |
| Suggestion, AI request | Content, inputs, provider, model, cost, status | Profile version, acceptance |
| Notification delivery | Occurrence, channel, state | Task, account |
| Media attachment | Photo, caption, date, upload state | Plant, environment, event, stock, listing |
| Stock item / lot | SKU, specimen/lot, location, quantity, condition, cost | Seller, plant |
| Stock movement | Type, quantity, member, reason | Item, order, hold |
| Listing, sale card | Price, photos, state, exported revision | Stock items |
| Sale session, lot | State, host, hold expiry, backup window | Stock, winners, backup |
| Claim, waitlist | Source, alias/buyer, quantity, mode | Listing/lot, message |
| Buyer, alias | Phone (E.164), names, addresses, consents | Seller |
| Request, offer | Wording, structured fields, expiry | Buyer, stock |
| Order, line, hold | Price snapshots, states, expiry | Buyer, stock, parcel |
| Receipt / tax invoice, credit note | Sequential number, VAT breakdown | Order |
| Payment attempt, payment | Provider, amount, state, reconciliation | Order, connection |
| Parcel, shipment | Dimensions, booking, tracking | Order lines |
| Care sheet / pack version | Published content | Order lines, QR shares |
| Share link | Purpose, token hash, expiry, revocation | Exact record |
| Channel connection | Provider, credentials ref, sync state | Seller |
| Inbound / outbound event | Provider, external ID, payload ref, status | Connection |
| Consent record, DSR request | Purpose, version, time, outcome | Account or buyer |
| Feature flag override, audit | Key, scope, value, actor, reason | Registry |

**Integrity:** linked IDs belong to the same account/seller or an authorised public reference; non-negative quantities; snapshots of accepted guidance, recipe composition, prices and care content; parent–child links on splits; idempotent completion and provider events.

---

## 28 Feature flags

### Policy (FF01–FF04, unchanged from v1.2)

- Every capability has a registered, code-owned flag before implementation; keys are never created from user input.
- One Rails capability service evaluates for web, PWA, native, API, webhooks and jobs, in order: registered and implemented → emergency stop → environment → cohort/account grant → dependencies → entitlement → authorisation → user preference. Unknown keys and unmet dependencies deny.
- CI uses deterministic fixtures and covers enabled and disabled behaviour for every implemented key. Dev/test can enable all implemented features with sandbox credentials. Production: core features on an allowlist; external writes and automation off until provider checks pass.
- Each flag declares dependencies, roles, surfaces, jobs/callbacks, help topic, owner, default and off behaviour. Flags are checked before enqueue and again before side effects. Off stops new actions; reads, reconciliation and recovery continue.
- Changes restricted to platform operators, fully audited, cached with bounded lifetime and explicit invalidation.
- Widening a pilot flag beyond the pilot cohort is a founder decision (D31). The audit entry records the reason and evidence considered (time in pilot, incidents, acceptance tests, help topic).
- Bootstrap paths (sign-in, security checks, flag console, recovery) are never flagged off. Authorisation and privacy always apply.

### Registry

| Domain | Keys | Initial state |
|---|---|---|
| Billing | billing.subscriptions, billing.comp_accounts | Comp Core; Paystack Pilot |
| Account and access | account.profile, account.preferences, account.export, account.deletion, account.onboarding, help.manual, help.contextual | Core |
| Privacy | privacy.consents, privacy.dsr, privacy.buyer_dsr | Core |
| Clients | client.pwa, client.offline_queue, client.ios, client.android | Core |
| Collector | collection.plants, collection.search, collection.media, collection.acquisition, collection.environments, collection.measurements, collection.tissue_culture | Core |
| Care and library | care.logs, care.shared_maintenance, care.reminders, care.library_guidance, care.ai_guidance, library.profiles, substrate.ingredients, substrate.recipes, substrate.scaling | Core; AI Pilot |
| Notifications | notifications.native_push, notifications.web_push, notifications.email_digest, notifications.whatsapp | Push and email Core; WhatsApp Pilot |
| AI | ai.care_suggestions, ai.dm_extraction, ai.request_extraction, ai.account_stop | Pilot (stop always available) |
| Seller business | seller.workspace, seller.members, seller.invites, seller.profile, seller.logo, seller.social_links, seller.paid_branding | Core; paid branding Pilot |
| Seller foundation | seller.stock, seller.listings, seller.sale_cards, seller.csv_import, seller.orders, seller.reservations, seller.receipts, seller.vat_invoices, seller.buyers, seller.closeout, seller.packing | Core |
| Live sales | sales.sessions, sales.auctions, sales.backup_bidder, sales.quick_claim, sales.waitlist | Core |
| WhatsApp | whatsapp.share, whatsapp.connection, whatsapp.dm_claims, whatsapp.auto_reserve, whatsapp.request_capture, whatsapp.outbound | Share Core; connected Pilot |
| Plant requests | requests.form, requests.manual, requests.matching, requests.offers, requests.wanted_list | Core |
| Payments and shipping | payments.manual, payments.bob_pay, payments.yoco, shipping.pickup, shipping.manual, shipping.bob_go, shipping.tracking | Manual and pickup Core; providers Pilot |
| Buyer pages | buyer.order_link, buyer.tracking_link, buyer.receipt_link, buyer.phone_verification | Core |
| Care handover | care.sheets, care.packs, care.pdf, substrate.share, care.qr_labels, buyer.collection_import, care.sitter | Core |
| Roadmap | marketplace.discovery, marketplace.wanted_board, storefront.native, storefront.shopify, storefront.woocommerce, whatsapp.catalogue_sync, whatsapp.cart_import, branding.custom_domains, branding.remove_footer, seller.self_signup, collection.sensors | Roadmap (unavailable) |

**Dependency examples:** sales.auctions → seller.stock, seller.reservations. whatsapp.auto_reserve → whatsapp.dm_claims, ai.dm_extraction, seller.reservations. ai.* → privacy.consents. payments.yoco → seller.orders, buyer.order_link. seller.vat_invoices → seller.receipts. care.qr_labels → care.sheets. buyer.collection_import → collection.plants. notifications.whatsapp → privacy.consents, whatsapp.outbound. seller.paid_branding → billing.subscriptions (entitlement).

---

## 29 Engineering context

| Component | Contract |
|---|---|
| Rails and Hotwire | Latest stable Rails at build start (baseline 8.1.4.1, Ruby 4.0). Turbo and Stimulus for web and PWA; Hotwire Native for iOS and Android with bridge components for push, camera, share. |
| PostgreSQL | Version 18 baseline in dev, CI, production. Transactions, row locks, FKs, check constraints, unique indexes for invariants. |
| Jobs and deploy | Solid Queue for reminders, notifications, provider events, AI calls, retries. Kamal deploy of web and worker roles; managed or persistent PostgreSQL; off-host backups; tested restore. |
| AI | RubyLLM with `anthropic` and `openai` gems; per-use-case provider/model config; structured output schemas; cost logging. |
| Notifications | APNs and FCM (native), Web Push (VAPID), transactional email, WhatsApp templates. Push and email providers chosen at build (D28) behind adapters. |
| Integrations | Tenant-scoped adapters: WhatsApp, Bob Pay, Yoco, Bob Go, Paystack. Separate sandbox and production credentials (Rails encrypted credentials / Active Record encryption). Provider errors never lose the VIVUM record. |
| Storage | Active Storage on private object storage; signed URLs; server-side resize; EXIF location stripped; per-account quota. |

**Records and ownership:** `seller_id` on all seller records; plants belong to accounts; guest links bound to exact purpose and record; buyers seller-scoped; UTC storage, Africa/Johannesburg display; ZAR integer cents.

**Commands and events:** stock changes only through reserve, release, transfer and fulfil commands. Inventory, auction, order, payment and shipment states are separate. Persist verified inbound events before acknowledging; deduplicate by provider, account and event ID; durable dispatch records for outbound work; reconcile uncertain outcomes before retrying anything that charges or books.

**Agent delivery rules:** each change names requirement IDs, flag keys, surfaces, migrations and acceptance tests; covers enable, disable, authorisation, tenant isolation and retries; updates the help topic; treats provider payloads and AI output as untrusted; uses sandbox fixtures in CI.

---

## 30 Measurement

| Measure | Definition |
|---|---|
| Activation (collector) | New accounts with 3 plants and 1 care event within 7 days ÷ eligible accounts |
| Activation (seller) | Invited sellers completing one paid order end to end within 14 days ÷ invited sellers |
| Weekly care use | Accounts logging care or completing a task in a week |
| Reminder follow-through | Occurrences completed within 48 h of due ÷ due (skips and snoozes separate) |
| Suggestion acceptance / correction | By source (library, AI, both) |
| Closeout time | Last lot closed → all buyer orders ready for payment or pickup |
| Oversells prevented | Rejected holds due to unavailability |
| Claim extraction accuracy | AI-proposed claims approved unchanged ÷ reviewed |
| AI cost | Cost per seller per month; per collector suggestion |
| Messaging cost | WhatsApp template cost per seller and per collector |
| Duplicate task rate | Unintended equivalent tasks ÷ active recurring tasks |

**Analytics boundaries:** pseudonymous IDs, coarse properties; no notes, images, supplier details, buyer data or AI prompts in analytics.

---

## 31 Delivery sequence and acceptance tests

| Order | Deliverable |
|---|---|
| 1 Foundation | Accounts, sellers, memberships, invites, feature registry, audit, consents, PostgreSQL, jobs, deploy, test accounts |
| 2 Shared domain | Plants, substrates, care and reminders, inventory ledger, holds, orders, buyers, receipts; concurrency tests |
| 3 Seller and collector flows | Host View, Closeout, requests and offers, CSV, packing, care packs, QR, sitter, branding, buyer links, library content, help |
| 4 Clients and notifications | PWA offline queue, Hotwire Native iOS/Android, push, email digest |
| 5 Connected flows | WhatsApp connection, DM claims and AI extraction, AI care suggestions, Bob Pay, Yoco, Bob Go, Paystack, WhatsApp templates — each behind its provider gate |
| 6 Pilot and release | 5–10 invited sellers (D25) including auction-heavy, DM/listing, VAT-registered and TC sellers, all in Pilot billing mode; end-to-end scenarios; WhatsApp route decision (D22); staged exposure by flag (D31); app store review on organisation accounts (D27); POPIA attorney sign-off (D26) |

### Acceptance tests

| Test | Required outcome |
|---|---|
| AT01 | Plants in all four contexts; TC origin coexists with aquatic/terrarium; no lab fields |
| AT02 | Four source-switch combinations; only enabled sources suggest |
| AT03 | Plant A, change defaults, plant B: A unchanged, B new defaults, warning shown |
| AT04 | Cancel the defaults warning: nothing changes |
| AT05 | Apply current defaults to one plant: others and schedules unchanged |
| AT06 | Manual and suggested watering: equivalent task detected |
| AT07 | Complete, skip, snooze, late completion in both modes: dates match preview, no duplicate logs |
| AT08 | TC repot-readiness check: no repot or stage change until recorded |
| AT09 | Version a recipe: old setups keep old composition; 2:1:1 to 4 L = 2/1/1 L |
| AT10 | Tank maintenance after moving a plant out links only current occupants |
| AT11 | Disable plant AI during a pending request: no actionable suggestion; accepted plans remain |
| AT12 | Retry task completion and photo upload: one event, notes kept |
| AT13 | Export a mixed collection: IDs, quantities, dates, versions, settings, attachments match |
| AT14 | Second account cannot access private records or attachments; keyboard and screen-reader access to core tasks |
| AT15 | Specimen and multi-unit SKU listed; no private data on cards |
| AT16 | Concurrent requests for last plant: one reservation; cancel restores once |
| AT17 | Fulfilment changes on-hand and reserved in one transaction; ledger reconciles |
| AT18 | Square and vertical cards correct; download when sharing unavailable |
| AT19 | Manual WhatsApp order works with disconnected or ineligible Business Platform account |
| AT21 | Price change after export: new card shows new price; existing order keeps agreed price |
| AT22 | Three wins → one order, one checkout; care pack and slip show the same three |
| AT23 | Concurrent lot open and DM claim: one hold; pass/replace releases or transfers once |
| AT24 | Claim automation off: inbound and queued jobs cannot reserve; Quick Claim still works |
| AT25 | Requests never reserve; competing acceptances → one hold |
| AT26 | Seller A cannot use B's checkout or see B's requests, stock, orders, buyers; duplicate and late callbacks reconcile |
| AT27 | CSV preview writes nothing; repeat commit writes once; open holds block conflicting updates |
| AT28 | QR scan opens care and saves plant; care link can't read order; revocation blocks reads and imports |
| AT29 | Sitter completes allowed task once; revocation blocks; help covers all added features |
| AT30 | Flags gate every capability server-side; paid orders and shipments reconcile after new writes disabled |
| AT31 | Packer role cannot see costs or change prices; removed member loses access immediately |
| AT32 | Uninvited account cannot open Sell; expired invite cannot be accepted |
| AT33 | Lapsed subscription: no new sessions; existing orders fulfil and reconcile; repeated Paystack webhook applies once |
| AT34 | Session without hold expiry and backup window cannot go live |
| AT35 | VAT seller invoice sequential and correct at 15%; non-VAT receipt has no VAT; credit note for correction |
| AT36 | Two "Sam" aliases stay separate; seller A can't find seller B's buyer by phone |
| AT37 | DM "MINE A17 x2" with auto-reserve holds two; malformed AI output creates no claim; provider switch via config works |
| AT38 | No AI request without consent; withdrawing consent stops queued AI jobs |
| AT39 | One occurrence → at most one message per channel; WhatsApp opt-out stops queued templates |
| AT40 | Offline care log synced twice → one event; sales actions disabled offline |
| AT41 | Upload at photo cap rejected with note retained; EXIF location stripped |
| AT42 | Seller exports and deletes one buyer's data; account deletion removes private photos from active storage |
| AT43 | Journeys complete on web, iOS and Android apps; push deep-links open the right record |
| AT44 | Comp/pilot seller gets tier entitlements with no Paystack charge; only operators change billing mode; changes audited |
| AT45 | AI cap reached: AI pauses with message, manual flows work; primary-provider failure falls back to OpenAI and logs the model used |
| AT46 | Native apps show subscription status but no purchase UI |

(AT20 — catalogue sync/cart replay — moves to roadmap with whatsapp.cart_import.)

---

## 32 Risks and open decisions

### Risks

| Risk | Response |
|---|---|
| Launch scope is very large (both products, five providers, AI, native apps) | Strict dependency order (§31); every provider behind a pilot flag with manual fallback; pilot with invited sellers only |
| Provider approvals (Yoco, Meta, app stores) outside our control | Manual paths always work; approvals tracked as release gates, not dates |
| Live plants shipped on unsuitable services (D20) | Seller responsibility notice; fallback to pickup; monitor failed/damaged deliveries in pilot |
| No default hold timings (D14) slows session setup | Remember each seller's last values as a pre-fill (not a platform default) |
| AI extraction errors reserve the wrong plant | Auto-reserve only on unambiguous code + high confidence; Review mode default per seller; audit trail |
| AI and WhatsApp costs | Per-account budgets, usage visibility, cost logging per request and message |
| POPIA non-compliance | Legal review before launch; consent records; seller operator agreement |
| Strict photo caps frustrate collectors | Clear quota UI; resize to reduce size; revisit with pricing |
| Too much data entry | Minimal fields, context forms, quick logging |
| Historical records change silently | Versioning and snapshots throughout |

### Open decisions

O1, O3, O4, O5 (ownership), O7, O9, O10 and O11 were resolved by D21–D31. Remaining:

| # | Decision | Needed before | How it gets decided |
|---|---|---|---|
| O2 | WhatsApp access route (Cloud API direct vs BSP) and platform reminder number | WhatsApp live flags | Pilot test with a +27 number (D22) |
| O5 | Final retention periods and sub-processor list | Production launch | Attorney review (D26) |
| O6 | Yoco third-party and shared-domain approval | payments.yoco live | Provider approval |
| O8 | Email and push providers | Notifications build | Engineering choice at build (D28) |
| O12 | Exact Pilot/Comp end dates and conversion offer for pilot sellers | End of pilot | Founder |
| O13 | Proposed values still to confirm: subscription grace period (7 days), DSR response time (30 days), address redaction (12 months), raw payload retention (90 days), photo max size (2560 px) | Production launch | Founder + attorney |

### Ready for development when

The product owner signs off this version; design covers the core journeys, warning states and seller roles; engineering confirms platform, notifications, identity, storage and AI handling; QA can run the acceptance tests with representative collector, seller (multiple roles) and buyer-link records.
