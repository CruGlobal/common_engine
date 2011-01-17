class Team < ActiveRecord::Base
  unloadable
  set_table_name "ministry_locallevel"
  set_primary_key "teamID"

  has_many :team_members, :foreign_key => "teamID"
  has_many :people, :through => :team_members
  has_many :activities, :foreign_key => 'fk_teamID', :primary_key => "teamID", :include => :target_area, :order => TargetArea.table_name + ".name"
  has_many :target_areas, :through => :activities, :order => "name"

  scope :active, where("isActive = 'T'")
  scope :from_region, lambda {|region| active.where("region = ? or hasMultiRegionalAccess = 'T'", region).order(:name)}

  validates_presence_of :name, :lane, :region, :country
  
  def to_s() name; end
  
  def can_deactivate?
    activities.active.empty?
  end
end
