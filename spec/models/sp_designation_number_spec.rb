require 'spec_helper' 

describe SpDesignationNumber do 
  it { should belong_to :person }
  it { should belong_to :project }
  # it { should have_many :donations } Expected SpDesignationNumber to have a has_many association called donations (SpDonation does not have a sp_designation_number_id foreign key.)
end

