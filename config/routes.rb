Rails.application.routes.draw do
  match '/auth/:provider/callback' => 'authentications#create'
  match '/auth/failure' => 'authentications#failed'
  resources :authentications
  resource :session do
    get :send_password_email
    post :send_password_email
  end
  resources :users do
    collection do
      get :reset_password
    end
  end
  match '/login' => "sessions#new", :as => :login
  match '/logout' => "sessions#destroy", :as => :logout
end
