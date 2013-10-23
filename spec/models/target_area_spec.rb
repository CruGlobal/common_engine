require 'spec_helper'

describe TargetArea do 
  it { should have_many :activities }
  it { should have_many :all_activities }
  it { should have_many :teams }
  # it { should belong_to :sp_project } # Expected TargetArea to have a belongs_to association called sp_project (TargetArea does not have a sp_project_id foreign key.)
end
