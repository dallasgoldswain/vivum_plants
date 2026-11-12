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
