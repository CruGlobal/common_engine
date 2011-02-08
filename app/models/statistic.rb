class Statistic < ActiveRecord::Base
  unloadable
  set_table_name "ministry_statistic"
  set_primary_key "StatisticID"
  belongs_to :activity, :foreign_key => "fk_Activity"
end