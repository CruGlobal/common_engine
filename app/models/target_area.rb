class TargetArea < ActiveRecord::Base
  unloadable
  
  set_table_name				"ministry_targetarea"
  set_primary_key   			"targetAreaID"
  
  #override the inheritance column
  self.inheritance_column = "nothing"
  
  has_many :activities, :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID", :conditions => "status != 'IN'"
  has_many :all_activities, :class_name => "Activity", :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID"
  has_many :teams, :through => :activities
  
  belongs_to :sp_project, :primary_key => :eventKeyID

  validates_presence_of :name, :region, :city, :country, :isSecure, :type
  #validates_presence_of :state, :if => :country == "USA"
  
  def is_semester?
    isSemester ? "Yes" : "No"
  end
  
  def active
    @active = false
    activities.each do |activity|
      if !TargetArea.inactive_statuses.include?(activity.status)
        @active = true
        break;
      end
    end
    @active
  end
  
  def get_activities_for_strategies(strategies)
    all_activities.where(Activity.table_name + ".strategy IN (?)", strategies)
  end
  
  def self.inactive_statuses
    ['IN']
  end
  
  def self.target_area_for_sp(sp_project_id, project_name, region, is_secure, project_email)
    ta = TargetArea.where("eventType = 'SP'").where("eventKeyID = ?", sp_project_id).first
    unless ta
      ta = TargetArea.new
    end
    ta.name = project_name
    ta.region = region
    ta.isSecure = is_secure
    ta.email = project_email
    ta.type = "Event"
    ta.eventType = "SP"
    ta.eventKeyID = sp_project_id
    ta.save
    ta
  end

end
