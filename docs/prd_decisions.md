# VIVUM PRD — Decision Log

Decisions captured interactively on 2026-11-09 while revising PRD v1.2 → v1.3.

## Round 1 — Product focus and v1 scope

| ID | Question | Decision |
|----|----------|----------|
| D01 | Launch focus | Both collector and seller products launch together (full combined v1.2 scope). |
| D02 | Integrations in v1 | All integrations in v1: Bob Pay, Yoco, Bob Go, WhatsApp Cloud API DM claims. |
| D03 | AI in v1 | Both AI uses in v1: collector care suggestions and WhatsApp DM claim/request extraction. |
| D04 | Feature flags | Keep the v1.2 registry: every capability its own flag, CI covers on and off. |

## Round 2 — Sellers, buyers, compliance

| ID | Question | Decision |
|----|----------|----------|
| D05 | Seller model | Seller business with members and roles (owner, manager, host/packer). Stock movements record the acting member. One account can belong to a seller and keep a private collection. |
| D06 | Buyer identity | Seller-scoped buyer record keyed on verified phone number (E.164). Group aliases link to a buyer only after seller confirmation. |
| D07 | POPIA | Add a full POPIA section: consent, information officer, data subject requests, retention, cross-border AI transfer, seller-as-responsible-party terms. |
| D08 | VAT / receipts | Seller receipt per order. If the seller has a VAT number, show VAT-inclusive breakdown and tax invoice fields. |

## Round 3 — AI, library, commercial, clients

| ID | Question | Decision |
|----|----------|----------|
| D09 | AI provider | Use RubyLLM as the AI abstraction, with the `anthropic` and `openai` gems added. Provider selectable per use case. |
| D10 | Plant library | Curated ~50 species profiles (commonly traded aroids, aquatics, TC species), written by a founder/editor through a controlled publish process. |
| D11 | Commercial model | Collectors free; sellers pay a monthly subscription. Paid branding is an add-on or higher tier. |
| D12 | Clients at launch | Web, PWA and Hotwire Native iOS and Android apps in the app stores at launch. |

## Round 4 — Billing, timings, consent, notifications

| ID | Question | Decision |
|----|----------|----------|
| D13 | Seller subscription billing | Paystack recurring subscriptions in ZAR, fully separate from seller-owned Bob Pay/Yoco checkout. |
| D14 | Hold / backup timings | No platform default. Seller must set payment hold expiry and backup-bidder window per sale session (or listing). |
| D15 | AI consent defaults | Ask at onboarding: library and AI off until the user picks sources; AI data use explained before first request; account-wide AI stop included. |
| D16 | Notification channels | Native push (APNs/FCM), web push (PWA), daily email digest, and WhatsApp template messages (opt-in, per-message cost). |

## Round 5 — Onboarding, offline, storage, shipping

| ID | Question | Decision |
|----|----------|----------|
| D17 | Seller onboarding | Invite-only pilot: platform operators invite sellers. Self-serve is a later release. |
| D18 | Offline | Cache collection and Today; queue care logs and photos offline with idempotent sync. Sales, payment and stock actions always require the server. |
| D19 | Photo storage | Strict caps: free collectors 500 photos; seller caps set per subscription tier (values set with pricing). Originals resized server-side. |
| D20 | Shipping lanes | No platform restriction. Any Bob Go service the seller chooses; suitability for live plants is the seller's responsibility. Provider rejection falls back to pickup/manual. |

## Round 6 — Open decisions: pricing, WhatsApp, AI (resolves O1–O3)

| ID | Question | Decision |
|----|----------|----------|
| D21 | Seller tiers | Two tiers: Starter R199/month (2 members, 2,000 photos, standard identity) and Pro R449/month (5 members, 10,000 photos, paid branding included, higher AI budget). Pilot sellers free. Operators can also mark any seller as a no-charge comp/test account with a chosen tier. |
| D22 | WhatsApp route | Decide in pilot: adapter-neutral; evaluate Cloud API direct (Tech Provider) and a BSP with a +27 number. |
| D23 | AI models | Claude Haiku for DM/request extraction; Claude Sonnet for care suggestions; OpenAI configured as fallback. |
| D24 | AI budgets | Per-account caps: collectors 30 care suggestions/month; sellers' extraction budget by tier (Starter 1,000 DMs, Pro 5,000 DMs/month); platform-wide spend alert. |

## Round 7 — Open decisions: pilot, POPIA, stores, delivery (resolves O4, O5, O7; O8 deferred)

| ID | Question | Decision |
|----|----------|----------|
| D25 | Pilot cohort | 5–10 invited sellers: mix of auction-heavy and DM/listing sellers, at least one VAT-registered and at least one TC seller. |
| D26 | POPIA ownership | Founder registers as Information Officer; external SA privacy attorney reviews §25, terms and operator agreement before production launch. |
| D27 | App stores | Apple and Google organisation developer accounts (company + D-U-N-S). Subscriptions bought on web only; native apps show no purchase UI. |
| D28 | Email/push infrastructure | Decide at build; adapters for push (APNs/FCM/Web Push) and email keep the choice open. |

## Round 8 — Open decisions: library, help, rollout (resolves O9–O11)

| ID | Question | Decision |
|----|----------|----------|
| D29 | Library authoring | Founder is library editor. Species list = most-traded plants in pilot sellers' stock. AI may draft profiles; founder reviews and publishes. |
| D30 | Help ownership | Implementing agent writes/updates the help topic and screenshots in the same change (HM02); founder reviews before the flag goes live. |
| D31 | Rollout widening | Founder judgement per flag; no fixed numeric thresholds. Decision and evidence recorded in the flag audit trail. |

## Still open after round 8

- O2 WhatsApp route — decided during pilot (D22).
- O6 Yoco third-party and shared-domain approval — provider-controlled gate.
- O8 Email and push providers — decided at build (D28).

## Round 9 — Domain

| ID | Question | Decision |
|----|----------|----------|
| D32 | Production domain | The app runs at `plants.vivumlabs.co.za`. The parent brand `vivumlabs.co.za` is a play on words: a tissue culture lab and a software lab. |

## Round 10 — Build stack (2026-11-09 to 2026-11-10)

Decisions made while setting up the codebase. They implement the PRD; none changes product scope.

| ID | Question | Decision |
|----|----------|----------|
| D33 | Authentication | Rails 8 authentication generator, extended with sign-up, email verification and database-stored sessions. ReviseAuth and Devise rejected (no stored sessions / heavier); Rodauth kept as the alternative if passkeys are needed. |
| D34 | Two-step sign-in | TOTP (`rotp`) with 10 single-use backup codes; required for platform operators and seller owners, optional for others. Secrets encrypted with Active Record encryption. QR codes via `rqrcode`. |
| D35 | Authorisation | Action Policy with `user` and current `membership` context; `verify_authorized` on every controller. Seller members: owner, manager, host_packer (SO02). |
| D36 | Multi-tenancy | Shared database with `seller_id` scoping and policy relation scopes. `activerecord-tenanted` rejected: SQLite-only and database-per-tenant, while VIVUM data crosses tenants (CP03, SE04, D05). PostgreSQL row-level security is a later option. |
| D37 | Operator area | Madmin at `/madmin`, operators with two-step sign-in only (404 for others); TOTP secrets and backup codes never shown. An operator audit log (PR08) is still to be built. |
| D38 | Notifications framework | Noticed for in-app notifications and delivery; web push and WhatsApp need custom delivery methods. |
| D39 | Email delivery | Resend in production (resolves the email half of O8; push provider still open). |
| D40 | Referrals | Refer installed: `?ref=` cookie (30 days), sign-up credits the referrer. Visit tracking off to minimise personal data under POPIA. Codes, sharing UI and rewards not built. |
| D41 | Jobs, cache, cable | Solid Queue, Solid Cache and Solid Cable in development and production, each in its own database; jobs run inside Puma in development. |
| D42 | Styling | Tailwind v4 (`tailwindcss-rails`) with BasecoatUI 0.3.11, themed to the VIVUM Labs Design System (sister product). Moss and cork are not used as text on linen (contrast). |
| D43 | Product name in the UI | "VIVUM Plants", following the "VIVUM Labs" wordmark pattern; VIVUM Plant Codex stays the working name in the PRD. |
| D44 | PDF generation | Prawn and prawn-table for receipts, slips and labels. ferrum_pdf (headless Chrome) deferred; reconsider for care packs and sale cards if Prawn makes them slow to build. |

## Still open after round 10

- O2 WhatsApp route — decided during pilot (D22).
- O6 Yoco third-party and shared-domain approval — provider-controlled gate.
- O8 Push provider (APNs/FCM/Web Push service) — decided at build (D28); email is Resend (D39).

## Round 11 — Build order and feature flags (2026-11-10)

| ID | Question | Decision |
|----|----------|----------|
| D45 | Build order | Foundation first (flags B03, audit log B04, consents B05, seller invites B06), then the seller domain, then the collector domain. Plan: `docs/build_plan.md`. |
| D46 | Flag implementation | Flipper (Active Record adapter) wrapped by a code-owned registry and one capability service implementing FF01's evaluation order. |
| D47 | Flag console | flipper-ui at `/madmin/flags`, operators with two-step sign-in only; changes audited (B04). |
| D48 | Flag registry and targeting | All PRD §28 keys registered now with state and `implemented: false` until built. Targeting by global, seller business and user account; no percentage rollouts. |

## Round 12 — Audit log (2026-11-10)

| ID | Question | Decision |
|----|----------|----------|
| D49 | Audit scope | Record operator changes and record views in Madmin, flag changes, and account security events (sign-in, failures, password resets, two-step changes, backup codes). |
| D50 | Audit implementation | Custom append-only `audit_events` table and `Audit.record` API; PostgreSQL blocks updates and early deletes. paper_trail and audited not used. |
| D51 | Flag change reasons | Optional for now; required once VIVUM has its own flag screens. |
| D52 | Audit retention | 2 years, then purged by a daily job; confirm with the attorney (O13). |

## Round 13 — Personal data in the audit log (2026-11-10)

| ID | Question | Decision |
|----|----------|----------|
| D53 | Personal data in audit events | Minimise (POPIA s10): actor stored as a user id only; attempted emails stored as a keyed HMAC fingerprint, never the address; Madmin changes record field names, with before/after values only for allowlisted non-personal fields; deletes record type and id; searches record that a search happened, not its text. IP address and user agent are kept for security investigation and must be named in the privacy notice. Account deletion (B08) should soft-delete or anonymise users so audit ids stay meaningful; confirm with the attorney. |

## Round 14 — Consents (2026-11-10)

| ID | Question | Decision |
|----|----------|----------|
| D54 | Consent purposes now | Terms of use, privacy notice, email marketing, AI processing, WhatsApp reminders. Buyer consents come with buyers (B21). |
| D55 | Legal text before attorney review | Draft v0 terms and privacy notice, clearly marked as drafts; versioned so users re-accept when the reviewed versions ship. |
| D56 | When consent is asked | Terms, privacy and marketing on sign-up; AI and WhatsApp in context when those features ship; everything on Settings → Privacy. |
| D57 | Existing accounts | Asked to accept current terms and privacy at their next request before using the app. |

## Round 15 — Seller and staff invites (2026-11-10)

| ID | Question | Decision |
|----|----------|----------|
| D58 | Who can accept an invite | Only an account with the invited email address (new sellers sign up with it). Links can be shared anywhere because they are useless to anyone else. |
| D59 | Invite expiry and delivery | 14 days. Sent by email and copyable for WhatsApp; resending issues a new link and voids the old one; invites can be revoked. |
| D60 | Seller terms before attorney review | Draft v0 seller terms with the POPIA operator agreement for buyer data (PR01), versioned like D55 and accepted when a seller invite is accepted. |
| D61 | Staff invites in B06 | Included: owners invite members by email and role, change roles and remove members. Owners may invite or promote other owners; the last owner can't be removed or demoted. |
| D62 | Seller invite details | Operator enters the email and business name; the owner confirms or edits the name on acceptance. Legal name, VAT and contacts come with the business profile (BR01). |
| D63 | Sell area before stock | A Sell nav item for members only, with a Sell home page and a Members page. |

## Round 16 — Seller billing modes (2026-11-11)

| ID | Question | Decision |
|----|----------|----------|
| D64 | Billing scope in B07 | Free modes only: Pilot and Comp/test, each on a chosen plan. Paid mode exists but can't be selected until Paystack subscriptions are built (later item); no charges, webhooks or grace periods yet. |
| D65 | Where plans live | A `plans` table seeded with Starter (R199, 2 members, 2,000 photos, standard identity, 1,000 AI extractions) and Pro (R449, 5 members, 10,000 photos, paid branding, 5,000 AI extractions); operators edit them in Madmin, so prices change without a release (SB01). |
| D66 | Limits enforced now | Member limit (members plus pending staff invites) and the paid branding entitlement through `Capabilities.entitled?`. Photo and AI limits are stored and enforced when those features ship. |
| D67 | End of a free period | Owners see a prompt to choose a paid plan and operators see the seller flagged; access is not reduced until Paystack and the SB02 grace rules exist. |

## Round 17 — Account export and deletion (2026-11-11)

| ID | Question | Decision |
|----|----------|----------|
| D68 | How exports are delivered | A background job builds a JSON zip (photos added as later domains add them); the user gets an email with a signed link that expires after 7 days. One export in progress at a time. Each domain contributes its own section as it ships. |
| D69 | What deletion does | After re-entering the password (and two-step code if on), the account is deactivated and signed out everywhere at once. Signing in within 30 days offers to cancel; after 30 days a daily job purges it (PR07). |
| D70 | What a purged account leaves | An anonymised tombstone: the user row keeps only its id and deletion time; email, name, password, two-step secrets, sessions, notifications and referral details are wiped. Audit events show "Deleted user #id". Consent records are kept as proof for the audit retention period (2 years, D52), then purged. Confirm with the attorney (O13). |
| D71 | Last owner of a seller | Deletion is refused until another member is made owner, or VIVUM closes the business. Seller data belongs to the seller and is never deleted as a side effect of a person's deletion. |
| D72 | Other data subject requests | Settings → Privacy has a "Make a privacy request" form (access, correction, objection, other). All requests, including exports and deletions, are logged in one table with a 30-day due date (O13) and an outcome; operators work the queue in Madmin. Buyer requests come with buyers (B21). |
| D73 | App-store deletion rule | The web flow (Settings → Account → Delete account) is the one path; native shells open the same page. A public `/account-deletion` page explains the steps (Google Play). Emails go out on request, on cancel and on purge. |

## Round 18 — Help manual (2026-11-11)

| ID | Question | Decision |
|----|----------|----------|
| D74 | Where help topics live | Markdown files in the repo (`app/help`), one per topic, with front matter: id, title, audience (collector, seller, everyone), capability keys, prerequisites (integration, subscription, rollout) and search keywords. Rendered with Redcarpet; written in the same change as the feature (D30). |
| D75 | Who can read the manual | `/help` is public. A topic is listed only when its capabilities are live for the viewer (enabled globally, or for the signed-in user or their business); topics with no capability (account basics) always show. Search runs over title, keywords and text in memory, so it finds "MINE" and similar terms by keyword. |
| D76 | Release check (HM02) | A test fails when an implemented, user-facing capability has no topic. Enabling a capability globally or by percentage in production is refused until its topic is reviewed; enabling it for one user or business (founder testing, pilot sellers) and turning anything off are never blocked. Development and test skip the block. |
| D77 | Marking a topic reviewed | Front matter `reviewed` (date) and `reviewed_digest` (hash of the topic text), written by `bin/rails "help:review[topic-id]"` at the founder's request. A later text change no longer matches the digest, so the topic counts as unreviewed until reviewed again. |
| D78 | Contextual help and screenshots | A Help link beside page headings opens the topic (or a section of it). Screenshots ship with topics from B09 on: headless Chrome system tests sign in with fixture data and save phone and desktop PNGs, run with `bin/rails help:screenshots` rather than on every CI run. |
| D79 | What's new page | `/whats-new` renders WHATS_NEW.md with the same renderer, linked from Help and the sidebar, with a dot until the user has seen the latest entry. |

## Round 19 — Plant records (2026-11-11)

| ID | Question | Decision |
|----|----------|----------|
| D80 | Growing contexts | Five fixed contexts: indoor, terrarium, paludarium, aquatic, outdoor. TC origin is a separate field (stages with B16), so a TC-origin plant can be aquatic (AT01). |
| D81 | Record ID | A short number per collection (P-0001, P-0002, …) shown on the plant, searchable and later printed on labels. Never reused, never changed by renaming; the database ID stays internal. |
| D82 | Observations and the timeline | The plant timeline is a `care_events` table from B10; observations are its first kind (note, photos, event date separate from entry time). B13 adds watering, feeding, repotting and other kinds to the same table. |
| D83 | Photo storage | Active Storage on the app server's disk (a Kamal volume) for the pilot, included in server backups; move to an S3-compatible bucket later. Originals resized to 2560 px long edge with location data stripped, plus thumbnails; caps from OF03 (500 photos for collectors). |
| D84 | Offline (OF02) | Built in B10: a service worker caches the collection list and plant pages for reading offline, and observations with photos queue offline with a client-generated idempotency key, showing their queued state and syncing once (AT12). |
| D85 | Tags | Free-text tags per plant, suggested from the collector's own earlier tags; searchable and filterable. |
| D86 | Permanent deletion | Archive is the routine path. Permanent delete is allowed after a warning that lists what goes (photos, observations, and later reminders and links) and a confirmation. |
| D87 | Ownership | Plants belong to a user's personal collection only. Seller stock (B19) has its own records and links to a plant where needed; a seller's team never edits a member's personal plants. |


## Round 20 — Environments, occupants and measurements (2026-11-11)

| ID | Question | Decision |
|----|----------|----------|
| D88 | Environment types | A fixed list, one level deep (no environments inside environments): room or shelf, grow cabinet, terrarium, paludarium, aquarium, acclimatisation container, outdoor bed. Only the name and type are required; notes, dimensions (cm), volume (litres) and photos are optional (EN01). A shelf in a room is its own environment. |
| D89 | Plant setup in B11 | Dated environment assignments and dated setups (container, size with unit, watering method), one current of each with history kept (PL05). Recipe version joins the setup with substrates (B12). |
| D90 | Measurements | Fixed metrics per environment type in metric units (air or water temperature °C, humidity %, light hours per day, optional light as lux or PPFD, pH, GH and KH in °dH, CO2 note), plus collector-defined custom metrics with their own name and unit (e.g. TDS in ppm). Every value has a unit, a measured-at date and a source (manual, or the meter's name); a blank stays unknown, never zero (EN02). Imperial display waits for unit settings (B17). |
| D91 | Environment type and growing context | Moving a plant into an environment whose type implies a different growing context offers to update the context; the collector confirms or keeps it. Context stays the plant's own field (D80). |
| D92 | Moves and setup on the timeline | A move or setup change writes a dated `movement` or `setup` care event as well as the assignment, so the timeline shows it and older events still show the setup at the time (PL05). |
| D93 | Moving plants | From the plant page (one plant) or the environment page (several plants, one date). A plant has one current environment or none; unassigning is allowed, and the move history keeps both environments (EN03). |
| D94 | Photos, offline and filters | Environment photos count toward the same 500-photo collector cap (D83). Environment pages are readable offline and measurements queue offline with an idempotency key and sync once, like observations (D84). The collection gets an environment filter. |
| D95 | Deleting environments | Archive is the routine path and keeps history. Permanent delete is offered only for an environment that has never had a plant in it, after a warning listing its measurements and photos. |

## Round 21 — Substrates, recipes and scaling (2026-11-12)

| ID | Question | Decision |
|----|----------|----------|
| D96 | Built-in ingredients | About 40 generic ingredients ship as a founder-maintained YAML seed (orchid bark, perlite, pumice, coir, sphagnum, leca, horticultural charcoal, worm castings, aquasoil and the like). Built-ins can't be edited; a collector copies one to personal to change it. Personal ingredients can be generic or branded, with manufacturer details (SU01). No built-in recipes yet. |
| D97 | Ingredient properties | Category from a fixed list; water retention and aeration as low, medium or high; particle size as an optional mm range; intended use, preparation and source as text. Qualitative properties are labelled as guidance, not measurements (SU01). |
| D98 | Mixing basis and scaling | Recipes are by volume only, in parts or %. A % recipe must total 100% before it's ready, and parts show their % equivalents. Scaling takes a target volume in L or mL and rounds each part to the nearest 50 mL (25 mL under 1 L), keeping the rounded total visible. Weight recipes and cups or scoops aren't supported (SU02, SU03). |
| D99 | Versions | A recipe starts as a draft and can't be assigned until it's ready. A ready version that no setup uses is edited in place; saving a change to a version a setup uses creates the next version. Setups keep the exact version they were given (SU04, AT09). |
| D100 | Assigning to plants | The plant setup form (D89) gets an optional recipe picker that offers the latest ready version of each active recipe. The recipe page lists plants on each version, current and past. Bulk assignment isn't included (PL05). |
| D101 | Archiving and deleting | Same rule as environments (D95): a recipe or personal ingredient that has been used (in a setup, or in any recipe version) can only be archived, which hides it from pickers and keeps history; an unused one can be deleted after a warning (SU05). |
| D102 | Sharing, offline and search | A recipe can have a public share link (unguessable token, revocable) that opens without sign-in and shows the current ready version with scaling, without private notes. Recipe and ingredient pages are readable offline, and scaling runs in the browser. The recipe list is searchable by name and ingredient and filterable by growing context and current or past use (SU05, substrate.share). |

## Round 22 — Care events and quick care entry (2026-11-12)

| ID | Question | Decision |
|----|----------|----------|
| D103 | Quick care entry | The plant page has a row of care buttons (Water, Feed, Repot, Prune, Treat, Inspect, More). Water saves "Watered now" at once, with Undo and an "Add details" link; the other kinds open a short sheet where every field is optional and the date defaults to now. Details never block saving (UX02). The Today route joins in B14. |
| D104 | Care kinds and details | Kinds: watering, feeding, repotting, pruning, treatment, inspection and custom, alongside the existing observation, movement and setup events (D82, D92). All details are optional. Watering: amount (mL or L) and method (top, bottom, soak, mist). Feeding: product, dose (mL/L, g/L, mL, g, drops) and strength (full, half, quarter). Treatment: product, target (pest or problem, free text) and dose. Pruning and inspection: note and photos. Every kind takes a note and photos (CA01). |
| D105 | Products and custom labels | Fertiliser and treatment products are free text, suggested from the collector's own earlier entries (like tags, D85); there are no product records. A custom event asks for a free label (e.g. "Flushed with RO water"), also suggested from earlier labels; there's no settings page for kinds. |
| D106 | Repotting | A repot asks for the new container, size and substrate recipe version (all optional, prefilled from the current setup). Saving logs one repotting event and a new dated setup (D89, D100), so the timeline shows a single "Repotted into Clay pot · Aroid mix v2" entry. |
| D107 | Logging for several plants | From an environment page (plants there, with checkboxes) and from the collection list (selected plants), one care entry with the same date and details creates one event per plant. A retry creates no duplicates. |
| D108 | Editing and deleting | The collector can edit (date, details, note) or delete, after a confirmation, any care event or observation. Moves and setup changes stay as they are, because they mirror the environment and setup history. |
| D109 | Last care | The plant page shows a summary of the latest event of each main kind ("Watered 3 days ago · Fed 2 weeks ago · Repotted Mar 2026"). The collection list shows days since the last watering and can filter by "not watered in N+ days". A plant's timeline can be filtered by kind. Scheduled "care due" filters come with B14. |
| D110 | Offline, tasks and stages | Every care kind queues offline with a client-generated idempotency key and syncs once, like observations (D84, OF02). The link from an event to the task it completes comes with reminders (B14); stage-change events come with tissue culture (B16). |

## Round 23 — Reminders, schedules and Today (2026-11-12)

| ID | Question | Decision |
|----|----------|----------|
| D111 | Where Today lives | The signed-in home page becomes Today, and "Home" in the navigation is renamed "Today". It shows overdue and due tasks first, then the next 7 days collapsed, with the invites and seller cards below (CA04). Today is authoritative whatever notifications do (B34). |
| D112 | Setting up reminders | A Reminders card on the plant page sets up a schedule: what (a care kind, or a custom label), once or every N days, weeks or calendar months, after-completion or fixed-calendar, and a start date, with a preview of the next dates (CA02). After logging care, the saved notice offers "Repeat this every…". Several plants can get a schedule at once from an environment or the collection, which makes one schedule per plant. |
| D113 | Completing | Done logs the matching care event now, linked to the task (CA01); "Done with details…" opens the same optional form as quick care entry. A custom reminder logs a custom event with its label. Skip logs no care (CA03). Completing a task twice, or retrying, logs one event. |
| D114 | Logging care completes reminders | Logging care of the same kind for a plant (from the plant page, several-plant logging or Today) completes that plant's open task of that kind when the task is overdue, due today or due within the next 2 days, and links them. The saved notice says so, and Undo reverses both. For after-completion schedules the next date counts from the care that completed it. |
| D115 | Today layout | Tasks are grouped by kind ("Water · 5 plants"), overdue first, then due today, then the next 7 days collapsed. Done on a group completes every plant in it, or the collector ticks some. Each task shows its plant, original due date and how overdue it is. |
| D116 | Snooze | Snooze offers tomorrow, in 3 days, or a chosen date. It hides the task from Today until then and keeps the original due date and history; it doesn't move the schedule, and after-completion schedules still count from when it's done (CA03). |
| D117 | Dates and timezone | Tasks are due on a date, not a time, in the collector's timezone, which is detected from the browser at first and can be changed in settings. Fixed-calendar weekly schedules keep their weekday, and monthly ones clamp to the last valid day (e.g. 31 Jan → 28 Feb). Times of day and notification times come with notifications (B34). |
| D118 | Task states and occurrences | A schedule has one open task at a time. The next task is created only when the open one is completed or skipped, so an overdue recurring schedule shows one task, never a stack (CA03). States are upcoming, due, overdue (derived from the date), completed, skipped and cancelled. Editing a schedule recalculates its open task's date unless the collector changed that date by hand (CA05). |
| D119 | Inactive plants | Changing a plant to an inactive status (lost, sold, gifted, archived) pauses its schedules automatically and cancels their open tasks. Restoring it to active or quarantined resumes them from today and creates no past tasks (PL03). |
| D120 | Duplicates, offline and history | Adding a schedule of the same kind for a plant that already has an active one shows the existing one first, with keep both or replace (CA05). Today is readable offline, and Done, Skip and Snooze queue offline with an idempotency key like care entries (OF02). Ending a schedule cancels its open task and keeps completed and skipped history. |

## Round 24 — Shared environment maintenance (2026-11-13)

| ID | Question | Decision |
|----|----------|----------|
| D121 | Maintenance kinds | A fixed list: water change, top-up, filter clean, dosing, substrate vacuum, glass clean, misting check, ventilation check, equipment check and light check, plus the collector's own label (suggested from earlier ones). Each environment type lists the kinds that fit it first (tanks: water change, top-up, filter clean, dosing; terrariums and paludariums: misting, ventilation, glass clean); the rest stay under More (EN04). |
| D122 | Logging maintenance | A Log maintenance card on the environment page, in the same pattern as plant care (D103): buttons that open a short form where every field is optional. Water change: % or litres; top-up: litres; dosing: product and dose; every kind: note, photos and when. After a water change, the saved notice offers "Add a reading". Events can be edited and deleted (D108). |
| D123 | One event, linked to the plants present | Each entry is one environment event, linked to the plants in the environment at the time it happened (EN04). It's never copied per plant and never sends per-plant notifications. |
| D124 | Plant timelines | A plant's timeline shows the maintenance of environments it was in at the time, as "Water change in 60 cm tank", read from the environment event. Editing or deleting the event changes every timeline. Maintenance never completes plant reminders (D114). |
| D125 | Environment reminders | Environments get the same reminders as plants (D112, D116–D118): once or repeating, after-completion or fixed, change date, pause, snooze, skip and end, set on the environment page. Today shows them in an Environments group above plant care, one task per environment. Archiving an environment pauses its reminders and restoring resumes them from today (D119). |
| D126 | Offline and history | Maintenance and its Today actions queue offline with an idempotency key (OF02, D110, D120). The environment page lists maintenance history, filterable by kind. Export includes maintenance and environment reminders, and permanently deleting an environment deletes them, after the warning lists them (D95). |

## Round 25 — Purchased tissue culture (2026-11-13)

| ID | Question | Decision |
|----|----------|----------|
| D127 | TC purchases | A TC purchase is its own purchase group: supplier, arrival date, arrival quantity, container condition, optional deflask date, notes and photos (TC01). Recording it creates one plant record per plantlet (quantity 1, TC origin, its own P-number, up to 50 per purchase), named after the purchase with a number ("Monstera TC 1", "Monstera TC 2", …). The group keeps the arrival quantity; its page lists the records with their stage and status and shows how many remain. Unknowns are optional. |
| D128 | Stages | TC-origin plants have a stage: sealed on arrival, deflasked, acclimatising or established, chosen at arrival (a pre-deflasked plant can start at acclimatising). Changing it takes an effective date and writes a stage entry on the timeline. Stages can follow in any order, and the growing context stays separate, so deflasked → established in an aquarium needs no indoor stage (TC02, D80). |
| D129 | Checks and losses | A TC check care entry with optional ticks (new leaves, new roots, damage, suspected contamination), humidity setup, note and photos (TC03). Its wording never claims a diagnosis. A lost plantlet is a record set to lost (D86 statuses), so the group's arrival quantity stays and its remaining count drops. |
| D130 | Group actions | Stages, checks and reminders belong to each record. The group page can change the stage of, or log a check for, all or ticked records at once, which makes one entry per record. A group check can mark ticked plantlets as lost. |
| D131 | Stage reminder suggestions | Changing stage offers a short suggested set of reminders from a code-owned list per stage and destination context (e.g. deflasked into a terrarium: inspect every 2 days, ventilation review weekly, "Check readiness for repotting" in 4 weeks). Each can be ticked, edited or skipped; nothing is added without the collector. They're marked as TC reminders. Inspections never advance a stage (TC04). |
| D132 | Established | Marking a plant established lists its open TC reminders, each with keep, end, or replace (which opens the reminder form for normal care). Nothing is removed without a choice, and ending keeps history (TC05). The record, TC origin and history stay. |
| D133 | Splitting | A record with a quantity above 1, such as an aquatic planting, can be split into new records with their own P-numbers (PL06). They copy identity, stage, environment, setup, TC origin and purchase group, link to the source, and the source's quantity drops so the total never grows (5 → 2 and 3 never counts 8). The split lists the source's reminders with ticks to copy to each new record. |
| D134 | Offline and data | TC checks and stage changes queue offline like care entries (D110). Recording a purchase, group actions and splits need a connection. Purchase groups, stages and checks are in the export; deleting a group's last record leaves the group, which can be deleted on its own. |

## Round 26 — Guidance settings and new-plant defaults (2026-11-13)

| ID | Question | Decision |
|----|----------|----------|
| D135 | What B17 shows | Both switches (library, AI) are stored at app-default and plant level now, with revisions and snapshots (ST01, ST02). Only the library switch is shown, with a note that library suggestions arrive soon; the AI switch stays hidden until the AI pilot flag and AI consent arrive (B37). Units are deferred: metric only for the pilot, so ST05's units scope waits. Notification preferences wait for B34 and the AI stop for B37. |
| D136 | Onboarding | The guidance-sources onboarding step (ST06) arrives with the library (B18), when the choice does something. Until then every account and plant starts with both switches off (D15). |
| D137 | Defaults and revisions | Saving app defaults shows the ST03 warning (exact copy, Cancel and Save defaults) and adds a revision with the switch values and date. Revisions are kept; Settings → Guidance lists past revisions and how many plants use each. Every new plant snapshots the current defaults and records the revision; existing accounts and plants start at revision 1 with both off. |
| D138 | New records | A plant added, or created by a TC purchase, takes the current defaults. A split copies its source's switches and revision, like identity and stage (D133). |
| D139 | Plant view and edits | The plant page has a Guidance section showing each switch and one plain status: "Matches your defaults", "From older defaults" (with Apply current defaults), or "Changed for this plant". No revision numbers are shown. Editing a plant's switches changes only that plant (ST01). |
| D140 | Applying defaults | Apply current defaults is an explicit action on a plant with a before/after comparison, and on several selected plants from the collection with one summary. It changes only the guidance switches and revision; reminders and history are untouched (ST04). |

## Round 27 — Built-in library profiles and suggestions (2026-11-13)

| ID | Question | Decision |
|----|----------|----------|
| D141 | Authoring and publishing | Profiles live in the database and are edited by platform operators on library screens in Madmin. Operators already need two-step sign-in, and every change goes to the audit log. Each profile has numbered versions that move draft → in review → published → retired. Only one version is published at a time, and a published version is never edited: a correction is a new version (D10, D29). There's no separate library editor role for the pilot. Unreviewed content is never shown to collectors. |
| D142 | Launch content | B18 ships the structure, editor, review flow and suggestions with two or three sample profiles. The founder writes the ~50 launch profiles from the pilot sellers' most-traded stock (D29) before the pilot; AI may draft them outside the app, and the founder reviews and publishes them. |
| D143 | Profile content | Each profile has a botanical name, synonyms, common names, family, and the growing contexts it covers (GU01). Each context has short care notes (light, watering, humidity, temperature, substrate, feeding) and suggested reminders (kind, optional label, interval). Each version has references (title and link), a review date and who published it. TC stage reminders stay code-owned (D131). |
| D144 | *(Revised by D151.)* Linking plants | PL01's optional profile link. When a plant's botanical name matches a published profile or one of its synonyms, the plant page offers "Link to the Monstera deliciosa profile?". The edit form has a searchable picker too. Nothing links without the collector, and unlinking keeps accepted reminders and history. A linked profile never overwrites the plant's own names or notes. |
| D145 | *(Revised by D151.)* Suggestions | For a linked plant with the library switch on (D139), the Guidance section shows the profile's care notes and suggested reminders for the plant's growing context, labelled "Library" with the profile name and version (GU03). Each reminder can be edited, accepted or dismissed. Accepting creates a reminder that keeps the profile version it came from (origin library). Where the plant already has a reminder of that kind, the suggestion shows a comparison first, and accepting replaces it (the old one ends, keeping history). Dismissals are remembered per profile version. With no linked profile or no notes for its context, the section says so plainly. Today shows a "Suggestions to review" line. Turning the switch off hides suggestions and keeps accepted reminders. |
| D146 | Choosing the library | Until a collector chooses, Today shows a card: "Use library care suggestions?" Yes saves new defaults with the library on (D137) and offers to apply them to existing plants (D140). No hides the card and changes nothing. This is the onboarding step deferred in D136; Settings can change the choice at any time. |
| D147 | *(Revised by D152.)* Corrections | Publishing a corrected version never changes accepted reminders or history. A plant with reminders accepted from an older version gets a notice in its Guidance section ("The Monstera deliciosa profile was updated") with a comparison of its reminders against the new suggestions. Each can be accepted or dismissed, and dismissing all clears the notice. |
| D148 | *(Revised by D153.)* Browsing the library | A Library page lists published profiles, searchable by name (including synonyms and common names) and filterable by context. A profile page shows its care notes per context, references, version and review date, and the collector's plants linked to it, with "Link a plant". Personal notes on profiles come later. |

## Round 28 — Personal libraries (2026-11-13)

| ID | Question | Decision |
|----|----------|----------|
| D149 | Own libraries | Each collector has their own library of profiles, and each seller business will have one too. The platform library (D141) is the published source they copy from. A user's profiles are private to them, like recipes. |
| D150 | Copying and writing | A collector can copy a published platform profile into their library, or start a blank one (e.g. for a rare species the platform lacks), and edit either freely. A copy is independent: it keeps no link to its source, so platform corrections never reach it. Personal profiles are labelled "Your profile", never verified. |
| D151 | Linking and suggestions | Plants link only to profiles in the collector's own library. When a plant's botanical name matches one of their profiles or synonyms, the plant page offers to link it. When it matches only a platform profile, it offers "Copy the Monstera deliciosa profile to your library and link it". Suggestions (D145) come from the linked profile and keep the edit, accept and dismiss flow, labelled with the profile name and the date it was last edited. This replaces D144 and D145 where they mention platform profiles. |
| D152 | Editing your profile | Editing a profile never changes accepted reminders or history. Plants linked to it with reminders accepted before the edit get the review notice and comparison from D147. Platform corrections affect only the platform library and future copies. |
| D153 | Library page | The Library page has two parts: Your library (search, context filter, new profile) and the Platform library (search, read, "Copy to my library"). A profile page shows its care notes, references, and the plants linked to it. |
| D154 | Seller libraries | A seller's library belongs to the business; owners and managers edit it. It's built with care packs (B31), which use it. B18 shapes profiles so they belong to the platform, a user or a seller. |


## Round 29 — Stock items, locations and the ledger (2026-11-14)

| ID | Question | Decision |
|----|----------|----------|
| D155 | Stock items | A seller's stock item is a specimen (one unique plant, quantity at most 1) or a batch SKU (identical plants, any quantity) (SE01). Each has a name, optional cultivar and botanical name, size or pot, price per plant in ZAR cents (optional until listed), an optional private cost, notes and photos. Two same-cultivar specimens stay separate items. |
| D156 | Codes | Each item gets a seller-unique code such as S-0042 from a per-seller counter. Owners and managers can replace it with their own (unique within the seller), and codes are never reused. |
| D157 | Locations and the ledger | Sellers keep a list of locations (e.g. Greenhouse, Shop shelf). Every stock change is a ledger movement: receipt, move between locations, mark unavailable or available again, loss, adjustment, and (with holds) reserve, release and fulfil. Each has a quantity, location, reason, time and acting member (SE02, D05). On hand, unavailable, held and available show per item and per location. Movements are never edited; mistakes are corrected with another movement. |
| D158 | Unavailable stock | Quarantined or damaged units are moved from saleable to unavailable with a reason (quarantine, damaged, other), and back when they recover. They stay on hand but never count as available. |
| D159 | Holds | B19 builds holds and the availability rule: available = saleable on hand − active holds. A manual hold has a quantity, who it's for (free text until buyers exist, B21), a required expiry (D14, no default) and the member. Expired holds release automatically; a hold can be released early or fulfilled, which removes the units from on hand. A specimen has at most one active hold. Each change locks the item and checks availability in one transaction. Orders (B22) and live sales (B25) reuse holds. |
| D160 | Counting | On an item, entering the counted quantity at a location records an adjustment for the difference with a reason. A count can't take saleable stock below what's held there. |
| D161 | Roles | Owners and managers add and edit items, prices and costs, and record any movement or hold. Host/packers see items, locations and availability, and can record moves between locations, mark units unavailable or available, and record losses, but never see prices or costs (SO02). Every movement records the acting member. |
| D162 | Collection link | From a plant in a member's own collection, "Move to stock" creates a specimen for one of their sellers, linked to the plant and copying its names, quantity 1, received at a chosen location, and copies the cover photo; the plant's status becomes "moved to stock" with history kept. From a linked specimen with nothing held, "Move to my collection" reverses it for the member who moved it. When a linked specimen is fulfilled, the sale is recorded on the plant's timeline (SE04). The seller team never edits a member's personal plant (D87). |
| D163 | Photos, offline and data | Item photos are processed like plant photos and count against the seller's plan photo limit. Stock pages and actions need a connection (D18). The seller's stock, locations, movements and holds are in a seller export; Sell → Stock is gated by `seller.stock`. |

## Round 30 — Listings, sale cards and sharing (2026-11-14)

| ID | Question | Decision |
|----|----------|----------|
| D164 | Listings | A listing is for one stock item: its own title, price (starting from the item's price, then independent), chosen photos from the item, size, code, collection and delivery details, and a reference such as L-0012 from a per-seller counter (SE03). An item has at most one active or paused listing; ended listings stay as history. States: draft, active, paused, ended. |
| D165 | Availability | A listing never holds stock. It shows the item's available stock, optionally capped by a listed quantity (list 5 of 20), and reads as sold out at 0, coming back by itself when stock returns. Pausing or ending never changes stock. A specimen's listing ends when the specimen is fulfilled (SE04), since it won't return. |
| D166 | Sale cards | Cards are rendered on the server with libvips in a fixed layout: the chosen photo, the name and the price in rands, with the size and the business name. Square (1080×1080) and vertical Status (1080×1920) sizes, JPEG or PNG. The price can never be hidden by a long name, which wraps or shortens first. Nothing private appears: no cost, holds, notes or buyer details (SE07). |
| D167 | Stale cards | Each exported card is stored with the price, title and photo it shows. If the listing's price, title or photo changes, or it's sold out, paused or ended, earlier cards are flagged ("Shows R450; the price is now R500") with "Make a new card". |
| D168 | Captions and details | Each listing has a caption that starts from a template (name, price, size, collection and delivery, reference) and can be edited. Collection and delivery details default from the business's Stock settings and can be changed per listing. |
| D169 | Sharing | Share opens the device share sheet with the card image and caption where the browser or app supports it. Otherwise Download the image and Copy the caption. "Send on WhatsApp" opens a wa.me link with the caption, which includes the reference. Sharing never holds stock or creates an order (SE08). |
| D170 | Roles and gating | Listings and cards are for owners and managers; host/packers get their own tools with live sales (B25). Gated by `seller.listings`, `seller.sale_cards` and `whatsapp.share`. Listing and card images count as stock photos for the seller's plan; cards are kept for 90 days. |

## Round 31 — Buyers, aliases and phone verification (2026-11-16)

| ID | Question | Decision |
|----|----------|----------|
| D171 | Buyer records | A buyer belongs to one seller and needs a phone number, stored in E.164 and unique within that seller; local numbers such as 082… are normalised to +27 (BY01). Each has a display name, an optional email and a contact preference. Sellers never see each other's buyers, even with the same number. Contacts whose number isn't known yet stay as aliases. |
| D172 | Aliases | An alias is a seller-scoped display name (such as "Sam 🌿") with an optional group name. Owners and managers link an alias to a buyer by hand and can unlink it; a buyer can have many aliases, and an alias links to at most one buyer. Matching names never merge (BY02). Stock holds are for a buyer or an alias; older free-text holds keep their text. |
| D173 | Phone verification | "Send verification link" opens a wa.me chat to the buyer's number with a single-use, expiring link. The buyer opens it and confirms the number is theirs, which marks the buyer verified with the method and time (BY03). Changing the number clears verification. Unverified buyers can still be used but show as unverified. Verification by an inbound WhatsApp message arrives with B38. No SMS. |
| D174 | Consents | WhatsApp messages and marketing consents are versioned records per buyer per seller (PR03). The seller can record "the buyer agreed", with how it was given and the date. The buyer can give or withdraw either one on the verification page. Marketing is off by default, and a withdrawal takes effect at once (PR04). |
| D175 | Addresses | A buyer can have several South African delivery addresses. Each has a label, recipient, street, suburb, city, province and postal code, and one is the default. Redacting unused addresses after 12 months (PR07) comes with orders (B22). |
| D176 | Roles | Owners and managers manage buyers, contacts, addresses, consents, verification and merges. Host/packers see buyer names and aliases and can add aliases. They never see phone numbers, emails or addresses (PR07). |
| D177 | Buyer data requests | From a buyer page, owners can download that buyer's data as JSON and delete the buyer (PR05, `privacy.buyer_dsr`). Deletion removes contact details, addresses and consents, and unlinks aliases. Holds keep an anonymised "Deleted buyer". Each request is logged. Buyers, aliases and addresses are in the seller export. |
| D178 | Duplicates and merging | A clashing number shows "This number belongs to Sam Dlamini". Owners and managers can merge two buyers. Aliases, holds, addresses and consents move to the kept record. Merging is never automatic. |

## Round 32 — Orders, holds and cancellations (2026-11-20)

| ID | Question | Decision |
|----|----------|----------|
| D179 | Order lines and buyer | An order belongs to one seller and one buyer; an alias must be linked to a buyer first (§17 order grouping). Each line is a stock item, optionally from its listing, with a quantity and the agreed price snapshotted at the time it's added. A later price change on the item or listing never changes the order (AT21). Orders have a source: chat, in person, request or other (auction and claim arrive with B25). |
| D180 | States and reserving | Order state (draft, reserved, fulfilled, cancelled) is separate from payment state (SE05). A draft leaves stock available. Reserving creates one stock hold per line for the buyer, all with one expiry the seller chooses (no default, D14), and labelled with the order number. If any line can't be held, nothing is reserved and the short lines are named. The seller can extend the expiry. Expired holds release as they do today (D159), and the order shows the expired lines. |
| D181 | Payment | Orders carry a payment state, unpaid until B23 adds recording payments, the paid state, receipts and review of paid orders whose holds would expire (SE06). B22 lets an owner or manager fulfil an unpaid order on purpose (such as cash on pickup) after a confirmation. |
| D182 | Pickup and shipping | Each order is for pickup or shipping. Shipping copies one of the buyer's addresses onto the order, so later edits to the buyer never change it, and has a manual shipping fee. Fulfilling marks the order collected or shipped (with optional courier and tracking text) and fulfils its holds, removing the stock. Packing (B27) and Bob Go (B42) come later. |
| D183 | Changes and cancellation | A draft or reserved order can add and remove lines and change quantities; on a reserved order each change adjusts the holds in one transaction. Prices stay as agreed unless an owner or manager edits one, which keeps the old price and a reason. A line or the whole order can be cancelled with a reason; holds release once, and a repeated cancel changes nothing. A fulfilled order can't be cancelled. |
| D184 | Returns | Returns (SE06: saleable only after inspection) move to B23 with refunds and credit notes. |
| D185 | Roles | Owners and managers create and manage orders. Host/packers get order access with packing (B27), without prices or contacts. Every order change records the acting member (SO02). |
| D186 | Numbers, discount and totals | Each order gets a number such as O-0001 from a per-seller counter, never reused. An order can have one discount, a rand amount with a reason, set by owners and managers. Total = lines + shipping − discount, never below zero, in ZAR. |
| D187 | Order list and data | Sell → Orders lists orders with state filters and search by number, buyer or item. A buyer page lists their orders. Orders and lines join the seller export and the buyer's data export. Gated by `seller.orders` and `seller.reservations`. |
| D188 | Retention and deleting buyers | Orders, with their buyer name and address snapshots, are kept as seller records for 5 years (PR07). Deleting a buyer (D177) needs their draft and reserved orders cancelled or fulfilled first; it wipes the buyer record and leaves their orders unchanged. A recurring job redacts buyer addresses not used on an order or edited for 12 months (PR07, D175). |

## Round 33 — Manual payments, returns, receipts and VAT invoices (2026-11-22)

| ID | Question | Decision |
|----|----------|----------|
| D189 | Manual payments | Owners and managers record one or more payments on an order: amount, method (EFT, cash, card machine, other), date, optional reference and the member. Payments are never edited; a mistake is voided with a reason. Payment state comes from what's been paid against the total: unpaid, part paid, paid or overpaid. Overpaid orders show for review (PY03 manual). |
| D190 | Paid holds | Holds on an order with any payment never expire on their own. Once the order's hold time passes it shows "Hold time passed, review" and appears under a Needs review filter, until the seller updates the hold, fulfils or cancels (SE06). Unpaid holds expire as before. |
| D191 | Receipts | A receipt is issued automatically when an order becomes fully paid. It's a frozen copy of the seller's details, buyer, lines, shipping, discount, total and payments, numbered from one gap-free sequence per seller, and never changes (RC01). It opens as a web page and a PDF from the order. After a receipt is issued the order's lines and prices are locked. |
| D192 | Tax invoices | When the seller has a VAT number at issue time, the receipt is a "Tax Invoice" with the seller's VAT number, buyer name and address where supplied, and a VAT-inclusive breakdown at 15%, with the rate stored on it (D08). A non-VAT receipt shows no VAT line. Changing the seller's VAT number never changes issued documents (AT35). |
| D193 | Business details | Owners set the legal name, VAT number, address, phone and email on a Business details page in Sell. Receipts copy them when issued. Logo and social links stay with B29. |
| D194 | Refunds | Owners and managers record a refund against an order: amount, method, date, reference and reason. Refunds can't exceed what has been paid and are never edited. They're shown with the payments and reduce what's been paid. |
| D195 | Credit notes | For a VAT seller, refunding against an issued tax invoice also issues a credit note for that amount, with the reason and VAT breakdown, numbered in the same sequence as receipts (RC01, AT35). Non-VAT sellers record refunds without credit notes. |
| D196 | Returns | Owners and managers record a return against a fulfilled line: quantity (up to what was fulfilled and not yet returned), location, reason, and where the units go: saleable (checked and fine), unavailable (damaged) or lost (SE06). Choosing saleable is the inspection. A return never refunds by itself. |
| D197 | Changes after payment | Before a receipt, line and price changes recalculate the balance due; the previous total and the reason are kept in the order's history (SC02). A part-paid order can be cancelled only after its payments are refunded. After a receipt, corrections are refunds (and credit notes for VAT sellers). |
| D198 | Roles and gating | Payments, refunds, credit notes and returns are for owners and managers; host/packers never see prices, payments or refunds (SO02). Gated by `payments.manual`, `seller.receipts` and `seller.vat_invoices`. Payments, receipts, refunds and returns join the seller export and the buyer's data export. A buyer receipt link comes with B30. |

## Round 34 — CSV stock import with preview (2026-11-23)

| ID | Question | Decision |
|----|----------|----------|
| D199 | Existing SKUs | New SKUs create stock items. A row for an existing SKU is a conflict error unless the seller ticks "Add to existing", when its quantity is received as new stock (IM01, IM02). Imports never set counts or lower stock. |
| D200 | What an existing row changes | With "Add to existing", only the quantity is added. A name, cultivar, price or type on the row that differs from the item shows as a warning in the preview and is ignored. |
| D201 | Locations | A location must match one of the seller's active locations by name, ignoring case; an unknown name is a row error, so typos never create locations. A blank location uses the one chosen on the upload form, which defaults to the seller's first location. |
| D202 | Formats | UTF-8 CSV and Excel .xlsx, read with roo. The template downloads as CSV. Headers match ignoring case and spacing. |
| D203 | Columns | Required: name, quantity and type (specimen or batch). Optional: SKU, cultivar, price (ZAR), location, botanical name, size, cost and notes. A blank SKU gets the next automatic S-0001 code at commit. A specimen's quantity must be 1. Blank prices are allowed. |
| D204 | Preview | Uploading writes nothing to stock: it parses the file and shows a preview with row errors (missing columns, malformed rows, invalid amounts, repeated SKUs in the file, conflicts with existing SKUs, unknown locations) and warnings. Errors download as CSV. A file with any error can't be committed. |
| D205 | Commit once | Commit rechecks every row inside one transaction, creates items and writes `receive` movements through Stock::Ledger, all or nothing. Each import gets a reference (I-0001) and the file's SHA-256 checksum; a double submit commits once, and committing a file with the same checksum as an earlier committed import needs confirmation. The import keeps a report of what each row did and is audited. |
| D206 | Reversal | Owners and managers can reverse a whole committed import once. It writes `lose` movements with the reason "Import I-0001 reversed" for each imported quantity and archives created items left with no stock. If any imported unit is held, sold or moved, nothing is reversed and the rows that block it are listed. |
| D207 | Limits and lifetime | Files up to 2 MB and 2,000 rows. A preview not committed within 24 hours expires and its file is deleted by the housekeeping job. |
| D208 | Roles and gating | Owners and managers import and reverse; hosts and packers can't. Gated by `seller.csv_import`. A help topic covers the template, preview, commit and reversal. |

## Round 35 — Live sale sessions, auctions, Quick Claim and backup bidder (2026-11-25)

| ID | Question | Decision |
|----|----------|----------|
| D209 | Sessions | A sale session belongs to one seller: name, channel (such as the WhatsApp group's name), host member, planned start and close, and status draft, live, paused or closed (LS01). Bidding stays in the group; results are captured in Host View. Sell → Sessions lists sessions by status. |
| D210 | Hold and backup timings | Each session has a payment deadline and a backup window, both durations in hours: the deadline counts from when a lot closes or a claim is taken, the backup window from a missed deadline. A session can't go live without both (D14). The form prefills the seller's last values, never a platform default. |
| D211 | Lots | A lot is one stock item and a quantity: a specimen is always 1, a batch lot can be several units sold together. Lots are numbered within the session, can be lined up in order while the session is a draft, and can be added on the fly while it's live. Opening a lot creates an exclusive hold labelled with the session and lot number, and fails if the units aren't available. One lot is open at a time. |
| D212 | Resolving a lot | Closing a lot records the winner (an existing buyer or alias, or a new alias typed by the host), the final price and an optional backup bidder and bid. In one transaction the hold becomes the winner's reservation, expiring at the payment deadline (LS02). Passing releases the hold once. A win is a result on the session with its hold; Closeout (B26) turns a buyer's wins into one order. A DM claim can never reserve a held lot. |
| D213 | Missed payment | When the deadline passes on an unpaid win it shows "Payment missed" and its hold stays through the backup window while the seller chooses: offer to the backup bidder (a new reservation at the backup bid with a fresh deadline), relist as a new lot, or return to stock (LS03). If nothing is chosen by the window's end, the stock returns automatically. The original winner and price stay in the history; there's only ever one active reservation. Once wins are on orders (B26), a transfer removes the line from the original winner's unpaid order, and paid or disputed lines need review. |
| D214 | Quick Claim | The seller adds plants to a live session as claim items at a fixed price, starting from the listing or item price. The host taps the active claim item and records the alias or buyer, quantity and an optional message reference (LS04). Each claim holds the units for the claimer until the payment deadline and follows the same missed-payment rules as a win. Group and DM claims use the same rules. |
| D215 | Waitlist | A claim for more than is available joins a numbered waitlist for that item. When stock comes back (released, expired or returned), the item shows "Stock back: offer to #1", and the host or seller taps to give it to the next person. Nothing is reserved automatically (AT24). Waitlist entries can be removed, and end when the session closes. |
| D216 | Pause and close | A paused session takes no new lots or claims; an open lot can still be resolved and existing holds stay visible (LS01). A session closes only when no lot is open; unopened lots stay unsold with no hold. Wins and claims carry on to Closeout after the session closes. |
| D217 | Roles and prices | Owners and managers create, edit and run sessions. Host/packers run Host View and Quick Claim for sessions: they enter and see winning bids, backup bids and claim prices for those sessions only, and never see costs, stock or listing prices elsewhere, order totals, payments or buyer contact details (SO02, D176). Every lot action, claim and transfer records the acting member. |
| D218 | Gating and records | Gated by `sales.sessions`, `sales.auctions`, `sales.backup_bidder`, `sales.quick_claim` and `sales.waitlist`. Lot results, claims, transfers and waitlist changes are audited and join the seller export. Help covers sessions, Host View, Quick Claim, the backup bidder and the waitlist. |
