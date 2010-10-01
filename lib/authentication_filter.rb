class AuthenticationFilter
  @logger = Rails.logger

  def self.filter(controller)
    unless controller.session[:user_id]
      last_response = controller.session[:cas_last_valid_ticket].try(:response)
      if last_response
        cas_user = controller.session[:cas_user]
        attributes = last_response.extra_attributes
        guid = attributes["ssoGuid"]
        user = User.find_by_globallyUniqueID(guid)
        if user.nil?
          @logger.info("User not found for ssoGuid: " + guid)
          #check for existing, pre-gcx users.
          user = User.find_by_username(cas_user)
          if user.nil?
            @logger.info("User not found for user_name: " + cas_user + "; creating new user")
            user = User.create(:username => cas_user,
              :globallyUniqueID => guid,
              :createdOn => Time.now,
              :password => User.encrypt(Time.now.to_s))
          else
            @logger.info("Trusting user and associating guid " + guid + " with user " + user.username)
            #todo: prompt for old password (or verify email?)
            #for now, trust user and associate sso account with ssm
            user.globallyUniqueID = guid;
          end
        else #found user by guid
          if user.username != cas_user
            @logger.info("Sso username different; changing username from " + user.username + " to " + cas_user)
            user.username = cas_user
          end
        end
        #stamp user login
        user.lastLogin = Time.now
        #set password if it is blank
        if user.password.blank?
          user.password = User.encrypt(Time.now.to_s)
        end
        user.save!
        person = user.person
        if person.nil?
          person = Person.create(:user => user,
            :firstName => attributes["firstName"],
            :lastName => attributes["lastName"],
            :dateCreated => Time.now,
            :dateChanged => Time.now,
            :createdBy => controller.application_name,
            :changedBy => controller.application_name)
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
