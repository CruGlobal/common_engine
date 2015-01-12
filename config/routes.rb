Rails.application.routes.draw do
  match '/auth/:provider/callback' => 'authentications#create', via: :get
  match '/auth/failure' => 'authentications#failed', via: :get
  resources :authentications
  resource :session do
    get :send_password_email
    post :send_password_email
  end
  match '/login' => "sessions#new", :as => :login, via: :get
  match '/logout' => "sessions#destroy", :as => :logout, via: [:get, :post, :delete]
end
