require 'spec_helper'

describe Staff do 
  it { should belong_to :person }
  it { should belong_to :primary_address }
  it { should belong_to :secondary_address }
end
