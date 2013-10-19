class SitrackTracking < ActiveRecord::Base
  self.table_name = "sitrack_tracking"
  belongs_to :hr_si_application, :foreign_key => 'application_id'
  belongs_to :team, foreign_key: 'asgTeam'

  def is_stint?
    return true if ['ICS','STINT'].include?(internType)
    return false
  end
end
