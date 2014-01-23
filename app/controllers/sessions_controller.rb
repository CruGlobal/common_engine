class SessionsController < ApplicationController
  skip_before_filter :ssm_login_required, :except => :destroy
  def show
    redirect_to authentications_path
  end
  
  def new
    session[:return_to] = params[:return_to] if params[:return_to].present?
    if logged_in?
      return_to = session[:return_to]
      return_to ||= '/'
      redirect_to(return_to)
    else
      redirect_to '/authentications'
    end
  end
  
  def create
    unless params[:username] && params[:password]
      redirect_to '/'
      return false
    end
    # Remove SSM
#    self.current_user = User.authenticate(params[:username], params[:password])
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
			session[:event_id] = nil
      CASClient::Frameworks::Rails::Filter.logout(self)
    else
      redirect_to root_path
    end
  end
  
  def send_password_email
    if params[:email].present?
      @user = User.where(:username => params[:email]).first
      if @user
        @user.generate_password_key!
        SessionMailer.password_link(@user, :protocol => 'https', :host => request.host, :port => request.port == 80 ? nil : request.port).deliver
        redirect_to login_path(:username => params[:email]), :notice => "Password reset email sent. If you don't see it within 2 minutes, please check your spam folder and add help@campuscrusadeforchrist.com to your spam filter."
      else
        flash[:alert] = "Couldn't find a record with that email."
        redirect_to :back
      end
      return
    end
  end
end
