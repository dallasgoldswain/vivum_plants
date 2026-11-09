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

  root "home#show"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
