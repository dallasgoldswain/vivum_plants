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
