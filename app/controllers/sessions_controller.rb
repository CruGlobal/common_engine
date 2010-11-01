class SessionsController < ApplicationController
  def show
    redirect_to authentications_path
  end
  
  def new
    session[:return_to] = params[:return_to] if params[:return_to].present?
    if logged_in?
      return_to = session[:return_to]
      return_to ||= '/'
      redirect_to(return_to)
    end
  end
  
  def create
    unless params[:username] && params[:password]
      redirect_to '/'
      return false
    end
    self.current_user = User.authenticate(params[:username], params[:password])
    if logged_in?
      if session[:omniauth]
        unless current_user.authentications.where(:provider => session[:omniauth]['provider'], :uid => session[:omniauth]['uid']).count > 0
          current_user.authentications.create!(:provider => session[:omniauth]['provider'], :uid => session[:omniauth]['uid'])
        end
        session[:omniauth] = nil
      end
      sign_in_and_redirect(current_user)
    else
      flash.now[:error] = "Incorrect Login Details, Please try again."
      render 'authentications/index' 
    end
  end
  
  def destroy
    logout_keeping_session!
    if session[:cas_user]
      CASClient::Frameworks::Rails::Filter.logout(self)
    else
      redirect_to root_path
    end
  end
  
end
