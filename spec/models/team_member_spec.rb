require 'spec_helper'

describe TeamMember do 
  it { should belong_to :team }
  it { should belong_to :person }
end
