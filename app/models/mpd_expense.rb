class MpdExpense < ActiveRecord::Base
  belongs_to :mpd_user
  belongs_to :mpd_expense_type
end
