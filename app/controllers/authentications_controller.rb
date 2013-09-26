class AuthenticationsController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => :create
  skip_before_filter :ssm_login_required, :check_authorization, :except => :destroy
  def index
    if params[:ticket].present? 
      login_from_cas_ticket
      if logged_in?
        redirect_to root_path and return
      end
    end
    @authentications = current_user.authentications if logged_in?
  end
  
  def create
    omniauth = request.env["omniauth.auth"]
    unless omniauth['info']
      redirect_to '/' and return
    end
    omniauth['info']['email'] ||= omniauth['extra']['raw_info']['email'] if omniauth['extra'] && omniauth['extra']['raw_info']
    if omniauth
      authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid']) 
      Authentication.transaction do
        if authentication
          authentication.update_attribute(:token, omniauth['credentials']['token']) if omniauth['credentials']
          flash[:notice] = "Signed in successfully."
          authentication.user.create_person_from_omniauth(omniauth['info'])
          sign_in_and_redirect(authentication.user, root_path)
        elsif logged_in?
          current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
          flash[:notice] = "Authentication successful."
          redirect_to authentications_url and return
        else
          user = User.new
          user.apply_omniauth(omniauth)
          # If we have an email address, we should see if there's an existing account with that email.
          if user.username.present? && old_user = User.find_by_username(user.username)
            user = old_user
            user.apply_omniauth(omniauth)
          end
          if user.save && (user.person || omniauth['info']['first_name'])
            user.create_person_from_omniauth(omniauth['info'])
            flash[:notice] = "Signed in successfully."
            sign_in_and_redirect(user)
          else
            session[:omniauth] = omniauth.except('extra')
            redirect_to new_user_url and return
          end
        end
      end
    else
      flash[:alert] = "There was a problem logging you in with that method. Please try again"
      redirect_to :action => 'index'
    end
  end
  
  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url and return
  end
  
  def failed
    flash[:alert] = "There was a problem logging you in with that method. Please try again"
    redirect_to authentications_path and return
  end
  
  protected
  def login_from_cas_ticket
    CASClient::Frameworks::Rails::Filter.filter(self)
    login_from_cas
  end
end
