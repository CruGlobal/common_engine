class TargetArea < ActiveRecord::Base
  self.table_name = "ministry_targetarea"
  self.primary_key = "targetAreaID"
  
  #override the inheritance column
  self.inheritance_column = "nothing"
  
  has_many :activities, -> { where("status != 'IN'") }, :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID"
  has_many :all_activities, :class_name => "Activity", :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID"
  has_many :teams, :through => :activities
  
  belongs_to :sp_project, :primary_key => :eventKeyID

  validates_uniqueness_of :name
  validates_presence_of :name, :isSecure, :type
  validates_presence_of :city, :unless => :is_event?
  validates_presence_of :country, :unless => :is_event?
  validates_presence_of :region, :unless => :is_event?
  #validates_presence_of :state, :if => :country == "USA"
  
  scope :open_school, -> { where("isClosed is null or isClosed <> 'T'").where("eventType is null or eventType <=> ''") }
  scope :special_events, -> { where("type = 'Event' AND ongoing_special_event = 1") }
  
  before_save :stamp_changed
  before_update :set_coordinates

  #Event Types
  @@summer_project = "SP"
  @@crs_conference = "C2"
  @@other_conference = "CS"
  @@website = "DI"
  @@other = "OT"
  cattr_reader :summer_project, :crs_conference, :other_conference, :website, :other
  
  def is_semester?
    isSemester ? "Yes" : "No"
  end
  
  def is_event?
    type == "Event"
  end
  
  def is_special_event?
    is_event? && (eventType == "DI" || eventType == "CS" || eventType == "OT") 
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
  
  def get_event_activity(date, strategy)
    if eventType == @@other_conference
      activity = all_activities.first
    else
      activity = all_activities.where("strategy = ?", strategy).first
    end
    unless activity
      activity = Activity.create_movement_for_event(self, date, strategy)
    end
    activity
  end
  
  def stamp_changed
    self.modified = Time.now
  end

  def set_coordinates
    if changed.include?('address1') || latitude.blank? || longitude.blank?
      self.latitude, self.longitude = Geocoder.coordinates([address1, city, state, country].select(&:present?).join(','))
    end
  end

  def self.inactive_statuses
    ['IN']
  end
  
  def self.target_area_for_event(type, event_id, name, region, is_secure, email, ta_id = nil)
    ta = nil
    if !ta_id.blank?
      ta = TargetArea.find(ta_id)
    else
      if !event_id.blank?
        ta = TargetArea.where("eventType = ?", type).where("eventKeyID = ?", event_id).first
      else
        ta = TargetArea.where("eventType = ?", type).where("name = ?", name).first
      end
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
    end
    ta
  end
  
  def self.special_events_hash
    result = {}
    special_events.each do |event|
      result[event.name] = event.id
    end
    result
  end

end
