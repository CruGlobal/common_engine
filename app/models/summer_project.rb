class SummerProject < ActiveRecord::Base
  unloadable
  
	self.table_name = "wsn_sp_WsnProject"
	self.primary_key = "WsnProjectID"
	has_many :applicants, :foreign_key => 'fk_isMember'
end
