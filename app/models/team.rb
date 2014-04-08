require 'global_registry_methods'
class Team < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

  self.table_name  = "ministry_locallevel"
  self.primary_key = "teamID"

  has_many :team_members, :foreign_key => "teamID"
  has_many :people, -> { order(Person.table_name + ".lastName") }, :through => :team_members
  has_many :activities, :foreign_key => 'fk_teamID', :primary_key => "teamID"
  has_many :target_areas, -> { order("name") }, :through => :activities

  scope :active, -> { where("isActive = 'T'") }
  scope :from_region, lambda {|region| active.where("region = ? or hasMultiRegionalAccess = 'T'", region).order(:name)}


  validates_uniqueness_of :name
  validates_presence_of :name, :lane, :region, :country
  
  def to_s() name; end

  def team_members_ordered
    team_members.includes(:person).order(Person.table_name + ".lastName")
  end

  def activities_ordered
    activities.includes(:target_area).order(TargetArea.table_name + ".name")
  end

  def get_activities_for_strategies(strategies)
    activities.where(Activity.table_name + ".strategy IN (?)", strategies)
  end
  
  def can_deactivate?
    activities.active.empty?
  end
  
  def is_active?
    isActive && isActive == 'T'
  end
  
  def is_responsible_for_strategies?(strategies)
    result = false
    strategies.each do |strategy|
      activities.each do |activity|
        if activity.is_active? && activity.strategy == strategy
          result = true
          return result
        end
      end
    end
    result
  end
  
  def is_responsible_for_strategies_in_region?(strategies, region)
    result = false
    activities.each do |activity|
      if (activity.is_active? && strategies.include?(activity.strategy) && activity.target_area.region == region)
        result = true
        return result
      end
    end
    result
  end

  def is_leader?(person)
    result = false
    member = find_member(person)
    if member
      result = member.is_leader
    end
    result
  end
  
  def add_leader(person)
    result = false
    member = find_member(person)
    if member
      member.is_leader = true
      result = member.save
    end
    result
  end
  
  def remove_leader(person)
    result = false
    member = find_member(person)
    if member
      member.is_leader = false
      result = member.save
    end
    result
  end
  
  def find_member(person)
    TeamMember.where(TeamMember.table_name + ".personID = ?", person.personID).where(teamID: self.id).first
  end

  def async_push_to_global_registry(parent_id = nil)
    unless parent_id
      region_object = Region.find_by(abbrv: region)
      parent_id = region_object.global_registry_id
    end

    attributes_to_push['abbreviation'] = abbrv
    attributes_to_push['is_active'] = is_active?

    super(parent_id)
  end

  def self.columns_to_push
    super
    @columns_to_push += [{name: 'abbreviation', type: 'string'}]
    @columns_to_push.each do |column|
      column[:type] = 'boolean' if column[:name] == 'is_active'
    end
  end

  # @return [Array]
  def self.skip_fields_for_gr
    super + ["team_id", "note", "region", "address1", "address2", "city", "state", "zip", "country", "fax", "email", "startdate", "stopdate", "fk_org_rel", "no", "abbrv", "has_multi_regional_access", "dept_id", "created_at", "updated_at", "global_registry_id"]
  end
end
