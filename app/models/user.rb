require 'digest/md5'
require 'base64'
class User < ActiveRecord::Base
  unloadable
  set_table_name 			"simplesecuritymanager_user"
	set_primary_key 		"userID"

	# Relationships
	has_one :person, :foreign_key => 'fk_ssmUserID'	
	has_many :authentications
	
  # Virtual attribute for the unencrypted password
  attr_accessor :plain_password

  validates_format_of       :username, :message => "must be an email address", :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
  validates_presence_of     :plain_password,                   :if => :password_required?
  validates_presence_of     :plain_password_confirmation,      :if => :password_required?
  validates_length_of       :plain_password, :within => 8..80, :if => :password_required?
  # validates_format_of       :plain_password, :message => "isn't secure enough (you must include upper and lower case letters)", :with => /[a-z]+.*[A-Z]+|[A-Z]+.*[a-z]+/, :if => :password_required?
  validates_confirmation_of :plain_password,                   :if => :password_required?
  # validates_presence_of     :secret_question,                  :if => :password_required?
  # validates_presence_of     :secret_answer,                    :if => :password_required?
  validates_uniqueness_of   :username, :case_sensitive => false, :message => "is already registered in our system.  This may have occurred when you registered for a Campus Crusade related conference; therefore, you do not need to create a new account. If you need help with your password, please click on the appropriate link at the login screen.  If you still need assistance, please send an email to help@campuscrusadeforchrist.com describing your problem."
  
  before_save :encrypt_password
  before_create :stamp_created_on

  def secret_question() self[:passwordQuestion]; end
  def secret_question=(val) self[:passwordQuestion] = val; end
  def secret_answer() self[:passwordAnswer]; end
  def secret_answer=(val) self[:passwordAnswer] = val; end
  
  def self.find_by_id(id) self.find_by_userID(id); end

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(username, plain_password)
    u = find_by_username(username) # need to get the salt
    ret_val = u && u.authenticated?(plain_password) ? u : nil
    u.stamp_last_login if ret_val
    return ret_val
  end
  
  def self.find_or_create_from_cas(ticket)
    # Look for a user with this guid
    receipt = ticket.response
    atts = receipt.extra_attributes
    guid = att_from_receipt(atts, 'ssoGuid')
    first_name = att_from_receipt(atts, 'firstName')
    last_name = att_from_receipt(atts, 'lastName')
    email = receipt.user
    find_or_create_from_guid_or_email(guid, email, first_name, last_name)
  end
  
  def self.find_or_create_from_guid_or_email(guid, email, first_name, last_name, secure = true)
    if guid
      u = ::User.where(:globallyUniqueID => guid).first
    else
      u = nil
    end

    # if we have a user by this method, great! update the email address if it doesn't match
    if u
      u.username = email
    else
      # If we didn't find a user with the guid, do it by email address and stamp the guid
      u = ::User.where(:username => email).first
      if u
        u.globallyUniqueID = guid
      else
        # If we still don't have a user in SSM, we need to create one.
        u = ::User.create!(:username => email, :globallyUniqueID => guid)
      end
    end
    # Update the password to match their gcx password too. This will save a round-trip later
    # u.plain_password = params[:plain_password]
    u.save(:validate => false) if secure
    # make sure we have a person
    unless u.person
      # Try to find a person with the same email address.  If multiple people are found, use
      # the one who's logged in most recently
      address = ::CurrentAddress.find(:first, 
                                      :joins => { :person => :user },
                                      :conditions => {:email => email},
                                      :order => "lastLogin DESC"
                                     )
      person = address.try(:person)

      # Attach the found person to the user, or create a new person
      u.person = person || ::Person.create!(:fk_ssmUserId => u.id, :firstName => first_name,
                                          :lastName => last_name)

      # Create a current address record if we don't already have one.
      u.person.current_address ||= ::CurrentAddress.create!(:fk_PersonID => u.person.id, :email => email)
      u.person.save(false)
    end
    u
  end
  
  def generate_password_key!
    self.update_attribute(:password_reset_key, Digest::MD5.hexdigest(username + 'yo mama' + Time.now.to_s) + '_' + username)
  end


  # Encrypts some data with the salt.
  def self.encrypt(plain_password)
    md5_password = Digest::MD5.digest(plain_password)
  	base64_password = Base64.encode64(md5_password).chomp
  	base64_password
  end

  # Encrypts the password with the user salt
  def encrypt(plain_password)
    self.class.encrypt(plain_password)
  end

  def authenticated?(plain_password)
    password == encrypt(plain_password)
  end

  def remember_token?
    remember_token_expires_at && Time.now < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now
    self.remember_token            = encrypt("#{username}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  def apply_omniauth(omniauth)
    self.username = omniauth['user_info']['email'] if username.blank?
    unless Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
      authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
    end
  end
  	
	def stamp_last_login
	  self.lastLogin = Time.now
	  save!
	end

	# A generic method for stamping a user has logged into a tool
	def stamp_column(column)
		if(person = self.person)
			person[column] = Time.new.to_s
			person.save!
		end
	end
	
  def create_person_and_address(attributes = {})
    new_hash = {:dateCreated => Time.now, :dateChanged => Time.now,
                :createdBy => ApplicationController.application_name,
                :changedBy => ApplicationController.application_name}
	  person = Person.new(attributes.merge(new_hash.merge({:firstName => "Please Enter Your First Name"})))
	  person.user = self
    person.save!
    address = Address.new(new_hash.merge({:email => self.username, 
                                           :addressType => 'current'}))
    address.person = person
    address.save!
    person
	end
	
	def self.create_new_user_from_cas(username, cas_extra_attributes)
    # Look for a user with this guid
    guid = cas_extra_attributes['ssoGuid']
    first_name = cas_extra_attributes['firstName']
    last_name = cas_extra_attributes['lastName']
    u = User.find(:first, :conditions => ["globallyUniqueID = ?", guid])
    # if we have a user by this method, great! update the email address if it doesn't match
    if u
      u.username = username
    else
      # If we didn't find a user with the guid, do it by email address and stamp the guid
      u = User.find(:first, :conditions => ["username = ?", username])
      if u
        u.globallyUniqueID = guid
      else
        # If we still don't have a user in SSM, we need to create one.
        u = User.new(:username => username.downcase, :globallyUniqueID => guid)
      end
    end            
    # Update the password to match their gcx password too. This will save a round-trip later
    # u.plain_password = params[:plain_password]
    u.save(false)
    # make sure we have a person
    unless u.person
      u.create_person_and_address
    end
    u
  end
  	
  def password_required?
    (authentications.empty? && password.blank? && globallyUniqueID.blank?) || !plain_password.blank?
  end
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end
  
  def refresh_token
    remember_me_until 1.year.from_now
  end

  # Useful place to put the login methods
  def remember_me_until(time)
    self.lastLogin = ::Time.now
    self.remember_token_expires_at = time
    self.remember_token = encrypt("#{username}--#{remember_token_expires_at}")
    save(:validate => false)
  end
	
  protected
    # before filter 
    def encrypt_password
      return if plain_password.blank?
  		self.password = encrypt(plain_password)
  	end	
  	
  	def stamp_created_on
  	  self.createdOn = Time.now
  	end
  	
    # not sure why but cas sometimes sends the extra attributes as underscored
    def self.att_from_receipt(atts, key)
      atts[key] || atts[key.underscore]
    end
end
