class Team < ActiveRecord::Base
  unloadable
  set_table_name "ministry_locallevel"
  set_primary_key "teamID"

  has_many :team_members, :foreign_key => "teamID", :include => :person, :order => Person.table_name + ".lastName"
  has_many :people, :through => :team_members, :order => Person.table_name + ".lastName"
  has_many :activities, :foreign_key => 'fk_teamID', :primary_key => "teamID", :include => :target_area, :order => TargetArea.table_name + ".name"
  has_many :target_areas, :through => :activities, :order => "name"

  scope :active, where("isActive = 'T'")
  scope :from_region, lambda {|region| active.where("region = ? or hasMultiRegionalAccess = 'T'", region).order(:name)}

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
