Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Two verbs, one path. A name search is a GET so its pages can be
  # linked; a urn search stays a POST so the identifier never reaches
  # the url.
  #
  # Declared first: patients#show answers GET /patients/:id, which would
  # otherwise swallow /patients/search as a patient with that id.
  namespace :patients do
    resource :search, only: %i[ create show ]
  end

  resources :patients, only: %i[ index create show ]

  # Defines the root path route ("/")
  root "static_pages#home"
end
