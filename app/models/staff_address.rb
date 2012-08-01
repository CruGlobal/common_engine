class StaffAddress < ActiveRecord::Base
  unloadable
  self.table_name = "ministry_address"
  self.primary_key = "AddressID"
end