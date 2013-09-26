class ActivityHistory < ActiveRecord::Base
  unloadable
  self.table_name = "ministry_activity_history"
  belongs_to :activity
  
  def self.max_records_for_date(date)
    where(ActivityHistory.table_name + ".period_begin <= ?", date).
    group(ActivityHistory.table_name + ".activity_id").having("max(" + ActivityHistory.table_name + ".period_begin)")
  end
  
  def self.max_date_for_date_activity(date, activity_id)
    where(ActivityHistory.table_name + ".activity_id = ?", activity_id).
    where(ActivityHistory.table_name + ".period_begin <= ?", date).
    group(ActivityHistory.table_name + ".activity_id").maximum(ActivityHistory.table_name + ".period_begin")
  end 
end