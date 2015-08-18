if File.exist?(Rails.root.join("config/facebook.yml")) && !defined?(FACEBOOK)
  raw_config = File.read(Rails.root.join("config/facebook.yml"))
  FACEBOOK = YAML.load(raw_config)[Rails.env].symbolize_keys
end
if defined?(OmniAuth::Builder)
  Rails.application.config.middleware.use OmniAuth::Builder do
    if defined?(FACEBOOK)
      provider :facebook, FACEBOOK[:api_key], FACEBOOK[:secret_key],
               :scope => 'user_about_me,user_birthday,email',
               :client_options => {
                   :site => 'https://graph.facebook.com/v2.0',
                   :authorize_url => "https://www.facebook.com/v2.0/dialog/oauth"
               }
    end
    #provider :google_apps, OpenID::Store::Filesystem.new('/tmp'), :domain => 'gmail.com'
    provider :CAS, :host => 'https://signin.ccci.org/cas', :name => 'relay'
  end
  OmniAuth.config.logger = Rails.logger
end

