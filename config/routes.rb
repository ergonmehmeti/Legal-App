Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]
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
      # Specific routes MUST come before catch-all routes
      get "deleted/(:category)", action: :deleted, as: :deleted
      get "deleted/:category/:id", action: :show_deleted, as: :show_deleted_lawsuit
      patch ":category/:id/restore", action: :restore, as: :restore
      get ":category/:id/edit", action: :edit, as: :edit
      delete ":category/:id", action: :destroy, as: :destroy
      get ":category/:id", action: :show, as: :show
      # Catch-all route - MUST be last
      get "(:category)", action: :index, as: :filtered
    end
  end
  resources :comments, only: [ :create ]
  resources :provisions, only: [ :index ]
  get 'services/export_csv', to: 'provisions#export_csv', as: 'export_csv_provisions'


  # Defines the root path route ("/")
  root "home#index"
end
