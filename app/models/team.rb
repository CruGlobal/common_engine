class Team < ActiveRecord::Base
  unloadable
  set_table_name "ministry_locallevel"
  set_primary_key "teamID"

  has_many :team_members, :foreign_key => "teamID"
  has_many :people, :through => :team_members
  has_many :activities, :foreign_key => 'fk_teamID', :primary_key => "teamID"
  has_many :target_areas, :through => :activities

  def to_s() name; end
end
