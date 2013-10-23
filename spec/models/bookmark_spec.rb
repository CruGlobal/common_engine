require 'spec_helper'

describe Bookmark do 
  it { should belong_to :user }
  it { should belong_to :activity }
end
