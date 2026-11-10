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

## Consents

Consents live in `consent_records`, one row per grant or withdrawal; the latest row per purpose is the current choice (PR03, D54–D57).

- **Purposes and versions:** `ConsentRecord::PURPOSES` (terms and privacy for everyone, seller_terms for owners, then marketing_email, ai_processing and whatsapp_reminders). Bump a purpose's version when its wording changes: older grants stop counting. Bumping terms or privacy sends everyone to the acceptance page on their next request.
- **API:** `user.consented_to?(:ai_processing)`, `user.record_consent!(:marketing_email, granted: false, source: "settings")`. Check `consented_to?` before any AI request or WhatsApp send.
- **Gate:** `Authentication#require_current_consents` runs after email verification and two-step enrolment; skip it with `allow_without_current_consents` only for pages a user needs before accepting.
- **Pages:** `/legal/terms` and `/legal/privacy` (draft v0, pending legal review; text in `app/views/legal`), and Settings → Privacy at `/settings/privacy`. These are privacy controls and are never behind a feature flag.
- Records are deleted with the account; they are not in the audit log.

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

## Tests and checks

Run the full local CI (setup, style, security, architecture, tests):

```sh
bin/ci
```

Or individually:

| Check | Command |
|---|---|
| Tests | `bin/rails test` |
| Ruby style | `bin/rubocop` |
| HTML+ERB lint | `bundle exec herb lint` |
| HTML+ERB format | `bundle exec herb format --check` (fix with `bundle exec herb format`) |
| Architecture boundaries | `bundle exec archspec check` (rules in `Archspec.rb`) |
| Security | `bin/brakeman`, `bin/bundler-audit`, `bin/importmap audit` |

GitHub Actions runs the same checks on every push to `main` and every pull request (`.github/workflows/ci.yml`).

A git `pre-push` hook (`.githooks/pre-push`) runs Brakeman, bundler-audit (with a fresh advisory database) and importmap audit before every push, and blocks the push if any fails. `bin/setup` installs it with `git config core.hooksPath .githooks`. Skip it once with `git push --no-verify`.

## Deployment

Production runs at https://plants.vivumlabs.co.za. Kamal (`config/deploy.yml`) serves that host through kamal-proxy with a Let's Encrypt certificate; Rails assumes SSL from the proxy, forces HTTPS and only accepts that host (except `/up`). The server address and image registry in `config/deploy.yml` are still placeholders, and the production database is not set up yet. Production needs `RAILS_MASTER_KEY` and the credentials above.
