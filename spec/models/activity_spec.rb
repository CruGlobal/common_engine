require 'spec_helper'

describe Activity do 
  it { should belong_to :target_area }  
  it { should belong_to :team }
  it { should have_many :activity_histories }
  it { should have_many :statistics }
  it { should have_many :last_fifteen_stats }
  it { should have_and_belong_to_many :contacts }
end
