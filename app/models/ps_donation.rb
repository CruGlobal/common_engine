class PsDonation < ActiveRecord::Base
  establish_connection :donor
end
