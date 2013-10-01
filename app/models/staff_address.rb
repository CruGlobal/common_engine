class StaffAddress < ActiveRecord::Base
  self.table_name = "ministry_address"
  self.primary_key = "AddressID"
end