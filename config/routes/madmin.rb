# Platform operator management area. Access: Madmin::ApplicationController.
namespace :madmin do
  resources :sellers
  resources :plans
  resources :memberships
  resources :invitations, except: %i[ edit update destroy ] do
    member do
      post :resend
      post :revoke
    end
  end
  resources :users, except: :destroy # accounts are deleted by their holder, never hard-deleted (D70)
  resources :data_requests, except: :destroy
  resources :sessions
  resources :audit_events, only: %i[ index show ]
  namespace :noticed do
    resources :events
    resources :notifications
  end
  # Feature flag console (PRD §28): operators with two-step sign-in only.
  mount Flipper::UI.app(Flipper) { |builder| builder.use FlagConsoleContext }, at: "flags", constraints: OperatorConstraint
  root to: "dashboard#show"
end
