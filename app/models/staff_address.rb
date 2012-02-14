class StaffAddress < ActiveRecord::Base
  unloadable
  set_table_name "ministry_address"
  set_primary_key "AddressID"
end