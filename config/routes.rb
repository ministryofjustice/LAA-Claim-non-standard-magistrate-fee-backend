Rails.application.routes.draw do
  root "main#index"

  get 'main/index'

  resources :claims do
    member do
      get :delete
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
end
