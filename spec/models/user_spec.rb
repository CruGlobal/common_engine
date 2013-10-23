require 'spec_helper'

describe User do 
  it { should have_one :person }
  it { should have_many :authentications }
  it { should have_many :activity_bookmarks }
  it { should have_many :activities }
  it { should have_one :balance_bookmark }
end
