require_dependency 'global_registry_methods'

class TargetArea < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

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
  before_save :ensure_urls_http
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

  def async_push_to_global_registry
    attributes_to_push['is_secure'] = isSecure == 'T'
    case eventType
    when 'SP'
      project = SpProject.find(eventKeyID)
      if  project
        project.async_push_to_global_registry unless project.global_registry_id
        attributes_to_push['event_id'] = project.global_registry_id
      end
    end

    super
  end

  def ensure_urls_http
    [ :url, :urlToLogo, :ciaUrl, :infoUrl ].each do |c|
      val = public_send(c)
      if val.present? && !val.starts_with?("http://") && !val.starts_with?("https://")
        public_send("#{c}=", "http://#{val}")
      end
    end
  end

  def self.columns_to_push
    super
    @columns_to_push.each do |column|
      column[:type] = 'boolean' if ['is_secure'].include?(column[:name])
    end
    @columns_to_push << { name: 'event_id', type: 'uuid' }
  end

  def self.skip_fields_for_gr
    super + ["target_area_id", "is_closed", "mpta", "url_to_logo", "enrollment", "month_school_starts", "month_school_stops", "is_semester", "is_approved", "aoa_priority", "aoa", "cia_url", "info_url", "calendar", "program1", "program2", "program3", "program4", "program5", "emphasis", "sex", "institution_type", "highest_offering", "affiliation", "carnegie_classification", "irs_status", "established_date", "tuition", "modified", "event_key_id", "county", "created_at", "updated_at"]
  end
end
