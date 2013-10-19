require 'spec_helper'

describe SpStaff do 
  it { should belong_to :person }
  it { should belong_to :sp_project }
end
