class MinistryLocalLevel < ActiveRecord::Base
  unloadable
  set_table_name "ministry_locallevel"
  set_primary_key "teamID"

  has_many :ministry_missional_team_members, :foreign_key => "teamID"
  has_many :people, :through => :ministry_missional_team_members
end
