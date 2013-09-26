class StaffsitePref < ActiveRecord::Base
  unloadable
  
  self.table_name = "staffsite_staffsitepref"
 	self.primary_key = "StaffSitePrefID"
end
