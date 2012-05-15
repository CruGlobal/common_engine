class CurrentAddress < Address
  unloadable
  attr_accessible :address1, :address2, :city, :state, :zip, :homePhone, :cellPhone
end
