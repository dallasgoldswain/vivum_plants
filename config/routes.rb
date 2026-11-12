Rails.application.routes.draw do
  draw :madmin
  resource :session
  resources :passwords, param: :token
  resource :registration, only: %i[ new create ]
  resource :email_verification, only: %i[ new create ]
  get "email_verification/:token", to: "email_verifications#show", as: :verify_email
  resource :two_factor_enrolment, only: %i[ new create destroy ]
  resource :two_factor_challenge, only: %i[ new create ]
  resource :two_factor_backup_codes, only: :create
  resource :current_seller, only: :update
  resource :consent_acceptance, only: %i[ new create ]
  resource :deletion_cancellation, only: %i[ new create ]

  resources :invitations, only: :show, param: :token do
    resource :acceptance, only: :create, module: :invitations
  end

  resources :plants do
    scope module: :plants do
      resources :status_changes, only: :create
      resources :care_events, only: %i[ create destroy ]
      resources :photos, only: %i[ create update destroy ] do
        post :cover, on: :member
      end
      resource :deletion, only: %i[ new create ]
      resources :moves, only: :create
      resources :setups, only: :create
      resource :context_offer, only: :update
    end
  end

  resources :environments, except: :destroy do
    scope module: :environments do
      resources :measurements, only: %i[ create destroy ]
      resources :moves, only: :create
      resources :photos, only: %i[ create update destroy ] do
        post :cover, on: :member
      end
      resource :archive, only: %i[ create destroy ]
      resource :context_offer, only: :update
      resource :deletion, only: %i[ new create ]
    end
  end

  resources :ingredients, except: :destroy do
    scope module: :ingredients do
      resource :copy, only: :create
      resource :archive, only: %i[ create destroy ]
      resource :deletion, only: %i[ new create ]
    end
  end

  resources :recipes, except: :destroy do
    scope module: :recipes do
      resource :archive, only: %i[ create destroy ]
      resource :deletion, only: %i[ new create ]
      resource :share, only: %i[ create destroy ]
    end
  end

  # A recipe's public link (D102): opens without signing in.
  get "r/:token", to: "shared_recipes#show", as: :shared_recipe

  namespace :sell do
    root "home#show"
    resources :members, only: %i[ index update destroy ], controller: "memberships"
    resources :invitations, only: %i[ create destroy ] do
      post :resend, on: :member
    end
  end

  namespace :settings do
    resource :privacy, only: :show, controller: "privacy"
    resources :consents, only: :update, param: :purpose
    resources :privacy_requests, only: :create
    resource :account, only: :show, controller: "account"
    resources :exports, only: %i[ create show ], param: :token
    resource :account_deletion, only: %i[ new create ]
  end

  scope :legal, controller: :legal, as: :legal do
    get :terms
    get :privacy
    get "seller-terms", action: :seller_terms, as: :seller_terms
  end
  get "account-deletion", to: "legal#account_deletion", as: :account_deletion_help

  get "help", to: "help#index", as: :help
  get "help/:id", to: "help#show", as: :help_topic
  get "whats-new", to: "whats_new#show", as: :whats_new

  root "home#show"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Offline reading and queued observations (OF02, D84). The manifest waits for the PWA (client.pwa).
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
