class Staff < ActiveRecord::Base
  unloadable
  set_table_name "ministry_staff"
  set_primary_key "accountNo"
  belongs_to  :person
  
  def self.get_staff(ssm_id)
    if ssm_id.nil? then raise "nil ssm_id!" end
    ssm_user = User.find(:first, :conditions => ["userID = ?", ssm_id])
    if ssm_user.nil? then raise "ssm_id doesn't exist: #{ssm_id}" end
    username = ssm_user.username
    profile = StaffsiteProfile.find(:first, :conditions => ["userName = ?", username])
    account_no = profile.accountNo
    staff = Staff.find(:first, :conditions => ["accountNo = ?", account_no])
  end
  
  def self.field_roles
    ['Director (Direct Ministry)','Team Leader (Direct Ministry)','Team Member - Mom','Field Staff In Training','Raising Support Full Time','Seminary Staff','Field Staff','Local Leader']
  end
  
  def self.strategy_order
    ['National Director','Operations','HR','LD','Fund Dev','CFM','FLD','EFM','DES','EPI','ESS','NTN','BRD','WSN','R&D','SR','SV','SSS','JPO','LHS','']
  end
  
  scope :specialty_roles, where(:jobStatus => "Full Time Staff").where(:ministry => "Campus Ministry").
      where(:removedFromPeopleSoft => "N").where("jobTitle NOT IN (?)", field_roles).order(:jobTitle).order(:lastName)

  def self.get_roles(region)
    result = {}
    Staff.strategy_order.each do |strategy|
      result[strategy] = specialty_roles.where(:strategy => strategy).where(:region => region)
    end
    result
  end
  
  # "first_name last_name"
  def full_name
    firstName.to_s  + " " + lastName.to_s
  end

  def informal_full_name
    nickname.to_s  + " " + lastName.to_s
  end
  
  def nickname
    (!preferredName.to_s.strip.empty?) ? preferredName : firstName
  end
end
