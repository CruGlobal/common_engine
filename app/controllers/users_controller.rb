class UsersController < ApplicationController
  def new
    @user = User.new
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @person = Person.new
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

end
