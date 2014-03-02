class Ccc::MinistryTargetarea < ActiveRecord::Base


  self.primary_key = 'targetAreaID'
  self.table_name = 'ministry_targetarea'
  self.inheritance_column = 'not_in_use'
  
end
