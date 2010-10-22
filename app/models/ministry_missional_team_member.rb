class MinistryMissionalTeamMember < ActiveRecord::Base
  unloadable
  set_table_name			"ministry_missional_team_member"
  set_primary_key   			"id"
  belongs_to :ministry_local_level, :foreign_key => "teamID"
  belongs_to :person, :foreign_key => "personID"
end
