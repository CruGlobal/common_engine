class SpDesignationNumber < ActiveRecord::Base
  
  belongs_to :person
  belongs_to :project, :class_name => 'SpProject'
  has_many :donations, :class_name => "SpDonation", :primary_key => "designation_number", :order => 'donation_date desc'
  
end
