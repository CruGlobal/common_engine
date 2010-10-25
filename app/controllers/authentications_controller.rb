class AuthenticationsController < ApplicationController
  def index
    @authentications = current_user.authentications if logged_in?
  end
  
  def create
    omniauth = request.env["omniauth.auth"]
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      flash[:notice] = "Signed in successfully."
      sign_in_and_redirect(authentication.user, root_path)
    elsif logged_in?
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      flash[:notice] = "Authentication successful."
      redirect_to authentications_url
    else
      user = User.new
      user.apply_omniauth(omniauth)
      # If we have an email address, we should see if there's an existing account with that email.
      if user.username.present? && old_user = User.find_by_username(user.username)
        user = old_user
        user.apply_omniauth(omniauth)
      end
      if user.save
        flash[:notice] = "Signed in successfully."
        sign_in_and_redirect(user)
      else
        session[:omniauth] = omniauth.except('extra')
        redirect_to new_user_url
      end
    end
  end
  
  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url
  end
  
  def failed
    flash[:alert] = "There was a problem logging you in with that method. Please try again"
    redirect_to authentications_path
  end
end
