require 'spec_helper'

describe Statistic do 
  it { should belong_to :activity }
  it { should validate_numericality_of :spiritual_conversations }
end
