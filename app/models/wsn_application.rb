class WsnApplication < ActiveRecord::Base
  self.table_name = "wsn_sp_WsnApplication"
	self.primary_key = "WsnApplicationID"
	
	belongs_to :summer_project, :foreign_key => "fk_isMember"
	belongs_to :person, :foreign_key => "fk_PersonID"
end