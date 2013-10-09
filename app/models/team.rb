class Team < ActiveRecord::Base
  self.table_name  = "ministry_locallevel"
  self.primary_key = "teamID"

  has_many :team_members, -> { joins(:person).order(Person.table_name + ".lastName") }, :foreign_key => "teamID"
  has_many :people, -> { order(Person.table_name + ".lastName") }, :through => :team_members
  has_many :activities, -> { joins(:target_area).order(TargetArea.table_name + ".name") }, :foreign_key => 'fk_teamID', :primary_key => "teamID"
  has_many :target_areas, -> { order("name") }, :through => :activities

  scope :active, -> { where("isActive = 'T'") }
  scope :from_region, lambda {|region| active.where("region = ? or hasMultiRegionalAccess = 'T'", region).order(:name)}

  validates_uniqueness_of :name
  validates_presence_of :name, :lane, :region, :country
  
  def to_s() name; end
  
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
    team_members.where(TeamMember.table_name + ".personID = ?", person.personID).first
  end
end
