# VIVUM Plant Codex

A South African plant collection and seller operations platform. Collectors record their plants, growing setups and care. Sellers manage stock, run WhatsApp group auctions and DM claims, take payment through their own provider, pack, ship and hand over care packs. One account can do both.

- Product requirements: [docs/VIVUM_Plant_Codex_PRD_v1_3.md](docs/VIVUM_Plant_Codex_PRD_v1_3.md)
- Decision log: [docs/prd_decisions.md](docs/prd_decisions.md)

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

GitHub Actions runs the same checks on every push and pull request (`.github/workflows/ci.yml`).

## Deployment

Production runs at https://plants.vivumlabs.co.za. Kamal (`config/deploy.yml`) serves that host through kamal-proxy with a Let's Encrypt certificate; Rails assumes SSL from the proxy, forces HTTPS and only accepts that host (except `/up`). The server address and image registry in `config/deploy.yml` are still placeholders, and the production database is not set up yet. Production needs `RAILS_MASTER_KEY` and the credentials above.
