require 'spec_helper'

describe MpdUser do 
  # it { should belong_to :mpd_letter } # uninitialized constant
  it { should belong_to :user }
  # it { should have_many_and_belong_to :mpd_roles } # uninitialized constant
  # it { should have_many :mpd_contacts } # uninitialized constant
  it { should have_many :mpd_expenses }
  # it { should have_one :prefs } # uninitialized constant
end
