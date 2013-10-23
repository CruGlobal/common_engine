require 'spec_helper'

describe SpMinistryFocus do 
  # it { should have_many :project_ministry_focuses } # schema.rb does not have expected foreign_key, :ministry_focus_id
  it { should have_many :projects }
end
