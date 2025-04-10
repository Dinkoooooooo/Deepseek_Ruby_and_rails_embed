Rails.application.routes.draw do
  get "pages/blank"
    root  "sessions#new"
    
    get 'login', to: 'sessions#new'
    post 'login', to: 'sessions#create'
    delete 'logout', to: 'sessions#destroy'
    get 'blank', to: 'pages#blank'

    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

    # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
    # Can be used by load balancers and uptime monitors to verify that the app is live.
    get "up" => "rails/health#show", as: :rails_health_check

    # Render dynamic PWA files from app/views/pwa/*
    get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
    get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

    # Defines the root path route ("/")



    # root "posts#index"

    resources :users do
      member do
        get :heidi_widget
      end
    end

    namespace :api do
      post 'ollama_models/query', to: 'ollama_models#query'
      get 'ollama_models/job_status', to: 'ollama_models#job_status'
    end
    


end
