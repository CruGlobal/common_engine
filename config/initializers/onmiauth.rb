if File.exist?(Rails.root.join("config/facebook.yml")) && !defined?(FACEBOOK)
  raw_config = File.read(Rails.root.join("config/facebook.yml"))
  FACEBOOK = YAML.load(raw_config)[Rails.env].symbolize_keys
end
if defined?(OmniAuth::Builder)
  require 'openid/store/filesystem'
  Rails.application.config.middleware.use OmniAuth::Builder do
    if defined?(FACEBOOK)
      provider :facebook, FACEBOOK[:api_key], FACEBOOK[:secret_key], {:scope => 'user_about_me,user_birthday,email,offline_access'}
    end
    #provider :google_apps, OpenID::Store::Filesystem.new('/tmp'), :domain => 'gmail.com'
    provider :CAS, :host => 'https://signin.ccci.org/cas', :name => 'relay'

    # provider :open_id, OpenID::Store::Filesystem.new('/tmp'), :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'
  end
end