require 'spec_helper'

describe SitrackTracking do 
  it { should belong_to :hr_si_application }
  it { should belong_to :team }
end
