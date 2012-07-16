class TeamMember < ActiveRecord::Base
  unloadable
  self.table_name	= "ministry_missional_team_member"
  self.primary_key = "id"
  belongs_to :team, :foreign_key => "teamID"
  belongs_to :person, :foreign_key => "personID"
end
