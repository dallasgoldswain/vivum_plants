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
      resources :care_events, only: %i[ create edit update destroy ]
      resources :care_schedules, only: %i[ new create edit update destroy ] do
        resource :pause, only: %i[ create destroy ], module: :care_schedules
      end
      resources :photos, only: %i[ create update destroy ] do
        post :cover, on: :member
      end
      resource :deletion, only: %i[ new create ]
      resources :moves, only: :create
      resources :setups, only: :create
      resource :context_offer, only: :update
      resources :stage_changes, only: :create
      resource :split, only: %i[ new create ]
      resource :tc_review, only: %i[ new create ]
      resource :guidance, only: :update
      resource :guidance_application, only: :create
      resource :library_link, only: %i[ create destroy ]
      resource :stock_transfer, only: %i[ new create ]
      resources :library_suggestions, only: :create
      resources :library_dismissals, only: :create
    end
  end

  # Purchased tissue culture groups (TC01, D127), at /purchases.
  resources :acquisitions, path: "purchases", only: %i[ new create show destroy ] do
    scope module: :acquisitions do
      resources :photos, only: %i[ create update destroy ] do
        post :cover, on: :member
      end
      resource :group_action, only: :create
    end
  end
  resources :tc_suggestions, only: %i[ new create ]
  resources :guidance_applications, only: %i[ new create ]
  resource :library_choice, only: :create

  # The library (D149–D153): the platform's published profiles, and your own at /library.
  resources :platform_profiles, path: "library/platform", only: %i[ index show ] do
    resource :copy, only: :create, module: :platform_profiles
  end
  resources :library_profiles, path: "library"

  resources :care_logs, only: %i[ new create ]
  resources :care_schedules, only: %i[ new create ]
  resources :task_completions, only: :create
  resources :care_tasks, only: :update do
    scope module: :care_tasks do
      resource :completion, only: %i[ new create ]
      resource :skip, only: :create
      resource :snooze, only: :create
    end
  end

  resources :environments, except: :destroy do
    scope module: :environments do
      resources :maintenance_events, only: %i[ create edit update destroy ]
      resources :care_schedules, only: %i[ new create edit update destroy ] do
        resource :pause, only: %i[ create destroy ], module: :care_schedules
      end
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

  # A buyer confirms their number (BY03, D173): opens without signing in.
  get "v/:token", to: "buyer_verifications#show", as: :buyer_verification
  post "v/:token", to: "buyer_verifications#update"

  namespace :sell do
    root "home#show"
    # Stock (SE01, SE02, D155–D163).
    resources :stock_items, path: "stock" do
      scope module: :stock_items do
        resources :movements, only: :create
        resources :holds, only: :create do
          member do
            post :release
            post :fulfil
          end
        end
        resources :photos, only: %i[ create destroy ] do
          post :cover, on: :member
        end
        resource :collection_return, only: :create
        resource :archive, only: :create
      end
    end
    resources :stock_locations, path: "locations", only: %i[ index create update ]
    resource :stock_export, only: :show
    # Stock import with preview (IM01, IM02, D199–D208).
    resources :stock_imports, path: "imports", only: %i[ index show create ] do
      get :template, on: :collection
      member do
        post :commit
        post :reverse
      end
    end
    resource :stock_settings, only: %i[ edit update ]
    resource :business_details, only: %i[ edit update ]
    # Listings and sale cards (SE03, SE07, SE08, D164–D170).
    resources :listings, except: :destroy do
      scope module: :listings do
        resource :state, only: :update
        resources :sale_cards, only: %i[ create show ]
      end
    end
    # Buyers and aliases (BY01–BY03, D171–D178).
    resources :buyers do
      scope module: :buyers do
        resources :addresses, only: %i[ create destroy ] do
          post :default, on: :member
        end
        resource :verification, only: :create
        resources :alias_links, only: :create
        resources :consents, only: :create
        resource :merge, only: :create
        resource :export, only: :show
      end
    end
    resources :orders, only: %i[ index show new create update ] do
      scope module: :orders do
        resources :lines, only: %i[ create update destroy ]
        resource :reservation, only: :create
        resource :cancellation, only: :create
        resource :fulfilment, only: :create
        resources :payments, only: :create do
          post :void, on: :member
        end
        resources :returns, only: :create
        resources :documents, only: :show
      end
    end
    # Live sales (LS01–LS04, D209–D218).
    resources :sale_sessions, path: "sessions", except: :destroy do
      scope module: :sale_sessions do
        resource :status, only: :update
        resource :host, only: :show
        resources :lots, only: %i[ create destroy ] do
          member do
            post :open
            post :win
            post :pass
            post :transfer
            post :relist
            post :return_stock
          end
        end
        resources :claim_items, only: %i[ create destroy ]
        resources :claims, only: :create do
          member do
            post :offer
            post :return_stock
            post :remove
          end
        end
      end
    end
    resources :buyer_aliases, path: "aliases", only: %i[ create update destroy ]
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
    resource :time_zone, only: :update
    resource :guidance, only: %i[ show update ], controller: "guidance"
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
