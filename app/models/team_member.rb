class TeamMember < ActiveRecord::Base
  unloadable
  set_table_name			"ministry_missional_team_member"
  set_primary_key   			"id"
  belongs_to :team, :foreign_key => "teamID"
  belongs_to :person, :foreign_key => "personID"
end
