require 'spec_helper'

describe MpdExpense do 
  it { should belong_to :mpd_user }
  it { should belong_to :mpd_expense_type }
end

