class UsersController < ApplicationController
  def index
    redirect_to :action => 'new'
  end
  
  def new
    @user = User.new
    @person = Person.new
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @person.apply_omniauth(session[:omniauth]["user_info"])
      @user.valid?
      @person.valid?
      @user.errors[:omniauth] = true if @user.errors.present? || @person.errors.present?
    end
  end
  
  def create
    @user = User.new(params[:user])
    @user.username = params[:email]
    @person = Person.new(params[:person])
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @person.apply_omniauth(session[:omniauth]["user_info"])
    end
    if @user.valid? && @person.valid?
      @user.save!
      @person.user = @user
      @person.save!
      Address.create(:person => @person, :email => @user.username, :addressType => 'current')
      login_user!(@user)
      session[:omniauth] = nil 
      redirect_to(root_path)
    else
      render :new
    end
  end
  
  def update
    if params[:c]
      @user = User.find_by_password_reset_key(params[:c])
    else
      redirect_to '/' and return unless logged_in?
      @user = current_user
    end
    @user.update_attributes(params[:user])
    if @user.valid?
      if omniauth = session[:omniauth]
        @user.apply_omniauth(omniauth)
        @user.save(:false)
        flash[:notice] = "Thanks for logging in with #{omniauth['provider'].camelcase}!"
      else
        flash[:notice] = "Your user was updated successfully"
      end
      sign_in_and_redirect(@user)
    else
      flash[:alert] = @user.errors.full_messages.join('<br />')
      redirect_to :back
    end
  end
  
  def reset_password
    @user = User.find_by_password_reset_key(params[:c])
    unless @user
      redirect_to(send_password_email_session_path, :error => "That link isn't valid. It's possible it appears on two lines in your email. If you haven't already, please try copy/pasting the link instead of clicking on it.") and return
    end
  end

end
