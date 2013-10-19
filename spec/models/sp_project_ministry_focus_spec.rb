require 'spec_helper'

describe SpProjectMinistryFocus do 
  it { should belong_to :ministry_focus }
  it { should belong_to :project }
end
