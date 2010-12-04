class MinistryLocalLevel < ActiveRecord::Base
  unloadable
  set_table_name "ministry_locallevel"
  set_primary_key "teamID"

  has_many :ministry_missional_team_members, :foreign_key => "teamID"
  has_many :people, :through => :ministry_missional_team_members
  has_many :ministry_activities, :class_name => 'MinistryActivity', :foreign_key => 'fk_teamID'
  has_many :target_areas, :through => :ministry_activities

  def to_s() name; end
end
