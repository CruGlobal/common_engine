require 'spec_helper'

describe HrSiApplication do 
  it { should belong_to :apply }
  it { should belong_to :person } 
  it { should have_one :sitrack_tracking }
  # it { should have_one :sitrack_mpd } # uninitialized constant
  # it { should have_many :sitrack_salary_forms } # uninitialized constant
  it { should belong_to :location_a }
  it { should belong_to :location_b }
  it { should belong_to :location_c }
end
