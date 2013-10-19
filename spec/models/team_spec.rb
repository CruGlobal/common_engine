require 'spec_helper'

describe Team do 
  it { should have_many :team_members }
  it { should have_many :people }
  it { should have_many :activities }
  it { should have_many :target_areas }
end
