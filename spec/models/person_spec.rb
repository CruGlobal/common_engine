require 'spec_helper'

describe Person do 
  it { should belong_to :user }
  it { should have_one :staff }
  it { should have_many :team_members }
  it { should have_many :teams }
  it { should have_and_belong_to_many :activities }
  it { should have_many :email_addresses }
  it { should have_many :phone_numbers }
  it { should have_one :current_address }
  it { should have_one :permanent_address }
  it { should have_one :emergency_address1 }
  it { should have_many :addresses }
  # it { should have_many :personal_links } # no uninitialized constant
  # it { should have_many :group_messages } # uninitialized constant
  # it { should have_many :personal_messages } # uninitialized constant
  # it { should have_many :orders } # uninitialized constant
  it { should have_one :spouse }
  # it { should have_many :hr_si_applications }
  it { should have_many :sitrack_trackings }
  it { should have_many :applies }
  # it { should have_many :apply_sheets }
  # it { should have_many :sp_applications }
  # it { should have_one :current_application }
  it { should have_many :directed_projects }  
  it { should have_many :staffed_projects }
  it { should have_many :current_staffed_projects }
end
