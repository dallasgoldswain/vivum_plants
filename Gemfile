source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.4", ">= 8.1.4.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Tailwind CSS v4 via the standalone CLI (no Node) [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails", "~> 4.7"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Authorisation policies [https://actionpolicy.evilmartians.io]
gem "action_policy"

# TOTP one-time codes for two-step sign-in
gem "rotp"

# QR codes (authenticator enrolment, care labels)
gem "rqrcode"

# Transactional email delivery [https://resend.com/docs/send-with-rails]
gem "resend"

# In-app notifications and delivery (email, push) [https://github.com/excid3/noticed]
gem "noticed"

# Platform operator management area at /madmin [https://github.com/excid3/madmin]
gem "madmin"

# Referral codes and links [https://github.com/excid3/refer]
gem "refer"

# Import and export (not built yet): caxlsx writes Excel templates (with dropdowns) and exports,
# roo reads uploaded workbooks and CSVs (e.g. stock import, PRD IM01/IM02)
gem "caxlsx"
gem "roo"

# Rich text editor on Action Text for care sheets and notes [https://github.com/basecamp/lexxy]
gem "lexxy"

# AI via one client for Anthropic and OpenAI (PRD D09/D23); the provider gems are for
# provider-specific features RubyLLM doesn't cover
gem "ruby_llm", "~> 2.1.1"
gem "anthropic"
gem "openai"

# Markdown rendering for AI-generated care content before it's saved as rich text
gem "redcarpet"

# Text extraction from uploaded PDF and Word documents
gem "pdf-reader"
gem "docx"

# PDF generation in pure Ruby: care packs, receipts/tax invoices, packing slips, QR labels
gem "prawn"
gem "prawn-table"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Static architecture boundary checks [https://archspecrb.dev]
  gem "archspec", require: false

  # HTML+ERB parser, linter and formatter [https://herb-tools.dev]
  gem "herb", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
