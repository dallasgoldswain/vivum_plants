# Changelog

Technical changes to VIVUM Plants, for developers and operators. The user-facing
release notes for the in-app What's new page live in [WHATS_NEW.md](WHATS_NEW.md).

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are dated
releases (`YYYY.MM.DD`) once the app is deployed; until then everything sits under
Unreleased. Reference PRD requirement or decision IDs (e.g. SO02, D35) where they apply.

## [Unreleased]

### Added

- Rails 8.1 application on Ruby 4.0 and PostgreSQL 18, with Solid Queue, Solid Cache and
  Solid Cable each in their own database in development and production; jobs run inside
  Puma in development (D41).
- Authentication from the Rails 8 generator, extended with sign-up, email verification and
  database-stored sessions; passwords of at least 12 characters (D33).
- Two-step sign-in with TOTP (`rotp`) and 10 single-use, hashed backup codes; required for
  platform operators and seller owners. TOTP secrets use Active Record encryption (D34).
- `Seller` and `Membership` models with owner, manager and host_packer roles; sessions
  record the seller they act for and re-check membership on every request (SO01, SO02).
- Action Policy authorisation with user and membership context, `verify_authorized` on
  every controller, and `SellerPolicy` and `MembershipPolicy` (D35, D36).
- Madmin operator area at `/madmin`, restricted to operators with two-step sign-in;
  sessions and notifications read-only, TOTP secrets and backup codes hidden (D37).
- Noticed tables and `user.notifications`; no notifiers yet (D38).
- Refer referral tracking: `?ref=` cookie for 30 days, credited on sign-up, visit
  tracking off (D40).
- Admin seed from `user.admin_email` and `user.admin_password` credentials
  (`User.ensure_platform_operator!`).
- Email delivery through Resend in production; from address from `mailer_from` (D39).
- Tailwind CSS v4 with BasecoatUI 0.3.11 themed to the VIVUM Labs Design System; app shell
  (desktop sidebar, mobile bottom nav) and auth layout; brand fonts and icon (D42, D43).
- Action Text with Lexxy, and Active Storage.
- Gems installed for upcoming work: RubyLLM with `anthropic` and `openai`, caxlsx, roo,
  Redcarpet, Prawn, prawn-table, pdf-reader, docx (D44).
- Checks: ArchSpec architecture rules, Herb HTML+ERB lint and format, alongside RuboCop,
  Brakeman, bundler-audit and importmap audit, in `bin/ci` and GitHub Actions.
- Git `pre-push` hook (`.githooks/pre-push`, installed by `bin/setup`) running Brakeman,
  bundler-audit with `--update`, and importmap audit before each push.
- Docs: PRD v1.3 and the decision log (D01–D44).

### Configuration

- Production domain `plants.vivumlabs.co.za`: host allowlist (except `/up`), `assume_ssl`,
  `force_ssl`, mailer link host, and Kamal proxy with Let's Encrypt (D32).
- Development runs on port 3001; `bin/dev` starts web and the Tailwind watcher via
  `Procfile.dev`.
- Production database password from `VIVUM_PLANTS_DATABASE_PASSWORD` or `db.password` in
  credentials.
- Fixed, non-secret Active Record encryption keys for development and test only; production
  keys must be added to credentials.
- `code` added to filtered log parameters.

### Not done yet

- Kamal server address and image registry are placeholders; production database not set up.
- Operator audit log for Madmin changes (O14).
- Production Active Record encryption keys in credentials.
