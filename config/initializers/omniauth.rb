if defined?(OmniAuth::Builder)
  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :facebook, ENV['FB_APP_ID'], ENV['FB_SECRET'],
             :scope => 'user_about_me,user_birthday,email',
             :client_options => {
                 :site => 'https://graph.facebook.com/v2.0',
                 :authorize_url => "https://www.facebook.com/v2.0/dialog/oauth"
             }

    #provider :google_apps, OpenID::Store::Filesystem.new('/tmp'), :domain => 'gmail.com'
    provider :CAS, :host => 'https://signin.ccci.org/cas', :name => 'relay'
  end
  OmniAuth.config.logger = Rails.logger
end

