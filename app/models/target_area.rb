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

  validates_presence_of :name, :region, :isSecure, :type
  validates_presence_of :city, :unless => :is_event?
  validates_presence_of :country, :unless => :is_event?
  #validates_presence_of :state, :if => :country == "USA"
  
  def is_semester?
    isSemester ? "Yes" : "No"
  end
  
  def is_event?
    type == "Event"
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
  
  def self.target_area_for_event(type, event_id, name, region, is_secure, email)
    ta = TargetArea.where("eventType = ?", type).where("eventKeyID = ?", event_id).first
    unless ta
      ta = TargetArea.new
    end
    ta.name = name
    ta.region = region
    ta.isSecure = is_secure ? 'T' : 'F'
    ta.email = email
    ta.type = "Event"
    ta.eventType = type
    ta.eventKeyID = event_id
    ta.save!
    ta
  end

end
