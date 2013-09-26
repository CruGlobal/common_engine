class AuthenticationFilter
  @logger = Rails.logger

  def self.filter(controller)
    unless controller.session[:user_id]
      attributes = controller.session[:cas_extra_attributes]
      if attributes
        cas_user = controller.session[:cas_user]
        guid = attributes["ssoGuid"]
        user = User.find_by_globallyUniqueID(guid)
        if user.nil?
          @logger.info("User not found for ssoGuid: " + guid)
          #check for existing, pre-gcx users.
          user = User.find_by_username(cas_user)
          if user.nil?
            @logger.info("User not found for user_name: " + cas_user + "; creating new user")
            user = User.create(:username => cas_user, :createdOn => Time.now)
          else
            @logger.info("Trusting user and associating guid " + guid + " with user " + user.username)
            #todo: prompt for old password (or verify email?)
            #for now, trust user and associate sso account with ssm
            user.globallyUniqueID = guid;
          end
        else #found user by guid
          if user.username.upcase != cas_user.upcase
            other_user = User.find_by_username(cas_user)
            if other_user
              @logger.info("Sso username different, but new username already exists in SSM table. Marking for merge and moving on.")
              user.needs_merge = "#{guid} - #{cas_user}"
              other_user.needs_merge = "#{guid} - #{cas_user}"
              other_user.save
            else
              @logger.info("Sso username different; changing username from " + user.username + " to " + cas_user)
              user.username = cas_user
            end
          end
        end
        #stamp user login
        user.lastLogin = Time.now
        #set password if it is blank
        if user.password.blank?
          user.password = User.encrypt(Time.now.to_s)
        end
        #set the global unique ID if it's blank
        if user.globallyUniqueID.nil?
          user.globallyUniqueID = guid
        end
        user.save!
        if attributes["emplid"].present?
          controller.session[:cas_emplid] = attributes["emplid"]
        end
        person = user.person
        if person.nil?
        	person = user.create_person_and_address({
        		:user => user,
            :firstName => attributes["firstName"],
            :lastName => attributes["lastName"],
            :fk_ssmUserId => user.userID
        	})
          if attributes["emplid"].present?
            person.accountNo = attributes["emplid"]
            person.staff = Staff.find_by_accountNo(attributes["emplid"])
            person.isStaff = true
            if staff = Staff.find_by_accountNo(person.accountNo)
              staff.person = person
              staff.save!
            end
          end
          person.save!
        end
      
        controller.session[:user_id] = user.id
      end
      return true
    end
  end
end
