if defined?(OmniAuth::Builder)
  require 'openid/store/filesystem'
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :twitter, 'XWNYOYAEpytG5H8MJJ94vQ', 'ruuPqjdWYoyObmaygIGlTkIYBcGqD2cmDVReVwek'
    provider :facebook, "397d1b7b879f3c3812285f75a4eda340", "4a9da4c1c3b8e7a9787d71b4f14ed2a2"  
    provider :open_id, OpenID::Store::Filesystem.new('/tmp')
    provider :google_apps, OpenID::Store::Filesystem.new('/tmp'), :domain => 'gmail.com'
    provider :CAS, :cas_server => 'https://signin.ccci.org/cas', :name => 'relay'

    # provider :open_id, OpenID::Store::Filesystem.new('/tmp'), :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'
  end
end