Rails.application.routes.draw do
  get "/api"  => "application#api"

  devise_for :users, controllers: {
    omniauth_callbacks: "callbacks",
    sessions: "sessions",
    registrations: "registrations"
  }

  authenticated :user do
    root "calendars#index"
  end

  unauthenticated :user do
    root "home#show", as: :unauthenticated_root
  end

  resources :search, only: [:index]
  resources :users, only: :show
  resources :calendars do
    collection do
      get :search, to: "calendars/search#show"
    end
  end
  resources :share_calendars, only: :new
  resources :events
  resources :attendees, only: [:create, :destroy]
  resources :particular_calendars, only: [:show, :update]
  resources :organizations do
    resource :invite, only: :show
    resource :invitation, only: :show
    resources :teams
  end
  resources :user_organizations

  namespace :api do
    resources :calendars, only: [:update, :new]
    resources :users, only: :index
    resources :events, except: [:edit, :new]
    resources :request_emails, only: :new
    resources :particular_events, only: [:index, :show]
    get "search" => "searches#index"
    resources :sessions, only: [:create, :destroy]
  end
end
