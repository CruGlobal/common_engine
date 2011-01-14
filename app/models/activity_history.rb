class ActivityHistory < ActiveRecord::Base
  unloadable
  set_table_name "ministry_activity_history"
  belongs_to :activity
end