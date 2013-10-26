require 'digest/md5'
require 'base64'
require_dependency 'global_registry_methods'

class User < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

  self.table_name = "simplesecuritymanager_user"
	self.primary_key = "userID"

	# Relationships
	has_one :person, :foreign_key => 'fk_ssmUserId'
	has_many :authentications
	has_many :activity_bookmarks, -> { where(Bookmark.table_name + ".name = 'activity'") }, :class_name => 'Bookmark'
	has_many :activities, -> { order(TargetArea.table_name + ".name").includes(:target_area) }, :through => :activity_bookmarks
  has_one :balance_bookmark, -> { where(Bookmark.table_name + ".name = 'balance'") }, :class_name => 'Bookmark'

  # Virtual attribute for the unencrypted password
  attr_accessor :plain_password, :plain_password_confirmation

  validates_format_of       :username, :message => "must be an email address", :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  #validates_presence_of     :plain_password,                   :if => :password_required?
  #validates_presence_of     :plain_password_confirmation,      :if => :password_required?
  #validates_length_of       :plain_password, :within => 6..80, :if => :password_required?
  # validates_format_of       :plain_password, :message => "isn't secure enough (you must include upper and lower case letters)", :with => /[a-z]+.*[A-Z]+|[A-Z]+.*[a-z]+/, :if => :password_required?
  #validates_confirmation_of :plain_password,                   :if => :password_required?
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
#  def self.authenticate(username, plain_password)
#    u = find_by_username(username) # need to get the salt
#    ret_val = u && u.authenticated?(plain_password) ? u : nil
#    u.stamp_last_login if ret_val
#    return ret_val
#  end

  def self.find_or_create_from_cas(atts)
    # Look for a user with this guid
    guid = att_from_receipt(atts, 'ssoGuid')
    first_name = att_from_receipt(atts, 'firstName')
    last_name = att_from_receipt(atts, 'lastName')
    email = atts['username']
    find_or_create_from_guid_or_email(guid, email, first_name, last_name)
  end

  def self.find_or_create_from_guid_or_email(guid, email, first_name, last_name, secure = true)
    if guid
      u = ::User.where(:globallyUniqueID => guid).first
    end

    # if we have a user by this method, great! update the email address if it doesn't match
    # We also need to make sure there isn't already another user with this email
    if u
      u.username = email if u.username != email && !User.find_by_username(email)
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
      address = ::CurrentAddress.joins(:person => :user)
                                .where(:email => email)
                                .order("lastLogin DESC")
                                .first
      person = address.try(:person)

      # Attach the found person to the user, or create a new person
      u.person = person || ::Person.create!(:firstName => first_name,
                                          :lastName => last_name)
      u.person.fk_ssmUserId = u.id

      # Create a current address record if we don't already have one.
      u.person.current_address ||= ::CurrentAddress.create!(:fk_PersonID => u.person.id, :email => email)
      u.person.save(:validate => false)
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
    save(:validate => false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate => false)
  end

  def apply_omniauth(omniauth)
    self.username = omniauth['info']['email'] if username.blank?
    unless Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
      authentication = authentications.build(:provider => omniauth['provider'], :uid => omniauth['uid'])
      authentication.token = omniauth['credentials']['token'] if omniauth['credentials']
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

  def create_person_and_address(person_attributes = {})
    unless person
      new_hash = {:dateCreated => Time.now, :dateChanged => Time.now,
                  :createdBy => ApplicationController.application_name,
                  :changedBy => ApplicationController.application_name}
  	  person = Person.new(person_attributes.merge(new_hash))
  	  person.user = self
      person.save!
      address = Address.new(new_hash.merge({:email => self.username,
                                             :addressType => 'current'}))
      address.person = person
      address.save!
    end
    person
	end

	def create_person_from_omniauth(omniauth)
    unless person
      new_hash = {:dateCreated => Time.now, :dateChanged => Time.now,
                  :createdBy => ApplicationController.application_name,
                  :changedBy => ApplicationController.application_name}
  	  person = Person.new(new_hash.merge({:firstName => omniauth['first_name'], :lastName => omniauth['last_name']}))
  	  person.user = self
      person.save!
      address = Address.new(new_hash.merge({:email => self.username,
                                             :addressType => 'current'}))
      address.person = person
      address.save!
    end
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
    u.save(:validate => false)
    # make sure we have a person
    unless u.person
      u.create_person_and_address(firstName: first_name, lastName: last_name)
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
  	  begin
    	  self.createdOn = Time.now
    	rescue; end
  	end

    # not sure why but cas sometimes sends the extra attributes as underscored
    def self.att_from_receipt(atts, key)
      atts[key] || atts[key.underscore]
    end

    def self.skip_fields_for_gr
      %w[user_id password password_question password_answer last_failure last_failure_cnt last_login created_on email_verified remember_token remember_token_expires_at developer facebook_hash facebook_username fb_user_id password_reset_key email encrypted_password remember_created_at sign_in_count current_sign_in_at current_sign_in_ip last_sign_in_ip last_sign_in_at locale checked_guid settings needs_merge password_plain global_registry_id]
    end

    def self.global_registry_entity_type_name
      'user'
    end

end
