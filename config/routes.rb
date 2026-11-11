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

  root "home#show"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
