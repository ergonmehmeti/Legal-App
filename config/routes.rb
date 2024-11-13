Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  resources :lawsuits, only: [ :index, :new, :create, :edit, :update, :destroy ] do
    collection do
      get "new", action: :new, as: :new
      get ":category/:id/edit", action: :edit, as: :edit
      get "(:category)", action: :index, as: :filtered
      get ":category/:id", action: :show, as: :show
      delete ":category/:id", action: :destroy, as: :destroy
    end
  end
  resources :comments, only: [ :create ]


  # Defines the root path route ("/")
  root "home#index"
end
