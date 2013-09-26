class CurrentAddress < Address
  unloadable
  attr_accessible :address1, :address2, :city, :state, :zip, :homePhone, :cellPhone
  
  def save(*)
    self.addressType = "current"
    super
  end

  def save!(*)
    self.addressType = "current"
    super
  end
end
