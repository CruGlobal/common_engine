Rails::Application.routes.draw do 
  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failed'
  resources :authentications
  resource :session
  resources :users
  match '/login' => "sessions#new", :as => :login
  
end