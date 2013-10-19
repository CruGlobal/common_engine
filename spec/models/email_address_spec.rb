require 'spec_helper'

describe EmailAddress do 
  it { should belong_to :person }
end
