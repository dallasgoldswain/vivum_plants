# Platform operator management area. Access: Madmin::ApplicationController.
namespace :madmin do
  resources :sellers
  resources :memberships
  resources :users
  resources :sessions
  namespace :noticed do
    resources :events
    resources :notifications
  end
  # Feature flag console (PRD §28): operators with two-step sign-in only.
  mount Flipper::UI.app(Flipper), at: "flags", constraints: OperatorConstraint
  root to: "dashboard#show"
end
