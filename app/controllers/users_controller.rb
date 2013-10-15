class UsersController < ApplicationController
  skip_before_filter :ssm_login_required, :only => [:new, :create, :reset_password, :update]
  def index
    redirect_to :action => 'new'
  end

  def new
    @user = User.new
    @person = Person.new
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @person.apply_omniauth(session[:omniauth]["info"])
      @user.valid?
      @person.valid?
      @user.errors[:omniauth] = true if @user.errors.present? || @person.errors.present?
    end
  end

  def create
    @user = User.new(user_params)
    @user.username = params[:email]
    @person = Person.new(person_params)
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @person.apply_omniauth(session[:omniauth]["info"])
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
      unless user_params[:plain_password].to_s.strip.present?
        flash[:alert] = "You didn't provide a new password"
        redirect_to :back and return
      end
      unless user_params[:plain_password] && user_params[:plain_password] == user_params[:plain_password_confirmation]
        flash[:alert] = "Your confirmation didn't match the password you provided"
        redirect_to :back and return
      end
      if @user.update_attributes(user_params)
        redirect_to '/', :notice => "Your password has been updated."
      else
        flash[:alert] = @user.errors.full_messages.join('<br>')
        redirect_to :back
      end
    else
      redirect_to '/' and return unless logged_in?
      @user = current_user
      @user.update_attributes(user_params)
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
  end

  def reset_password
    @user = User.find_by_password_reset_key(params[:c])
    unless @user
      redirect_to(send_password_email_session_path, :error => "That link isn't valid. It's possible it appears on two lines in your email. If you haven't already, please try copy/pasting the link instead of clicking on it.") and return
    end
  end

  def person_params
    params.fetch(:person, {}).permit(:firstName, :lastName)
  end

  def user_params
    params.fetch(:user, {}).permit(:username, :password, :passwordQuestion, :passwordAnswer, :email, :locale, :settings, :password_plain,
                                   :plain_password, :plain_password_confirmation)
  end

end
