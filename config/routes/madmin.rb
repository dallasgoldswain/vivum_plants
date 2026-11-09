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
  root to: "dashboard#show"
end
