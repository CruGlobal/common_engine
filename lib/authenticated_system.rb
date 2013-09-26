module AuthenticatedSystem
  protected
    # Returns true or false if the user is logged in.
    # Preloads @current_user with the user model if they're logged in.
    def logged_in?
      current_user && current_user != :false
    end
    
    def login_from_session
      self.current_user = User.find_by_id(session[:user_id]) if session[:user_id]
    end
    
    def login_from_cas
      cas_user = session[:cas_user]
      u = false
      if cas_user
        u = User.find_or_create_from_cas(session[:cas_extra_attributes])
        self.current_user = u
      end
    end
    
    # Accesses the current user from the session.
    def current_user
      @current_user ||= (login_from_session || login_from_cookie || login_from_cas || :false)
    end
    
    # Store the given user in the session.
    def current_user=(new_user)
      session[:user_id] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
      @current_user = new_user
    end
    
    def login_user!(user)
      self.current_user = user
    end
    
    # Check if the user is authorized.
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorize?
    #    current_user.login != "bob"
    #  end
    def authorized?
      true
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :ssm_login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :ssm_login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :ssm_login_required
    #
    def ssm_login_required
      username, passwd = get_auth_data
      self.current_user ||= :false if username && passwd
      logged_in? && authorized? ? true : access_denied
    end
    
    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |accepts|
        accepts.html do
          store_location
          flash[:alert] = "Please log in"
          redirect_to authentications_path
        end
        accepts.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Could't authenticate you", :status => '401 Unauthorized'
        end
      end
      false
    end  
    
    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.fullpath
    end
    
    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end
    
    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?
    end

    # When called with before_filter :login_from_cookie will check for an :auth_token
    # cookie and log the user back in if apropriate
    def login_from_cookie
      return unless cookies[:auth_token] && !logged_in?
      user = User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        user.remember_me
        self.current_user = user
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        flash[:notice] = "Logged in successfully"
      end
      user
    end
    def sign_in_and_redirect(user, return_to = nil)
      self.current_user = user
      self.current_user.remember_me_for(1.year)
      handle_remember_cookie! true
      session[:return_to] = return_to if return_to
      session[:return_to] = params[:return_to] if params[:return_to].present?
      flash[:notice] = "Logged in successfully"
      redirect_back_or_default(root_path)
    end
    
    #
    # Remember_me Tokens
    #
    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    # Cookies shouldn't be allowed to persist past their freshness date,
    # and they should be changed at each login

    def valid_remember_cookie?
      return nil unless @current_user
      (@current_user.remember_token?) && 
        (cookies[:auth_token] == @current_user.remember_token)
    end
    
    # Refresh the cookie auth token if it exists, create it otherwise
    def handle_remember_cookie! new_cookie_flag
      return unless @current_user
      case
      when valid_remember_cookie? then @current_user.refresh_token # keeping same expiry date
      when new_cookie_flag        then @current_user.remember_me 
      else                             @current_user.forget_me
      end
      send_remember_cookie!
    end
  
    def kill_remember_cookie!
      cookies.delete :auth_token
    end
    
    def send_remember_cookie!
      cookies[:auth_token] = {
        :value   => @current_user.remember_token,
        :expires => @current_user.remember_token_expires_at }
    end
    
    def logout_keeping_session!
      # Kill server-side auth cookie
      @current_user.forget_me if @current_user.is_a? User
      @current_user = :false     # not logged in, and don't do it for me
      kill_remember_cookie!     # Kill client-side auth cookie
      session[:user_id] = nil   # keeps the session but kill our variable
      # explicitly kill any other session variables you set
    end

    
  private
    # gets BASIC auth info
    def get_auth_data
      user, pass = nil, nil
      # extract authorisation credentials 
      if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
        # try to get it where mod_rewrite might have put it 
        authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
      elsif request.env.has_key? 'HTTP_AUTHORIZATION' 
        # this is the regular location 
        authdata = request.env['HTTP_AUTHORIZATION'].to_s.split  
      end 
       
      # at the moment we only support basic authentication 
      if authdata && authdata[0] == 'Basic' 
        user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
      end 
      return [user, pass] 
    end
end
