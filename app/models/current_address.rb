class CurrentAddress < Address

  def save(*)
    self.addressType = "current"
    super
  end

  def save!(*)
    self.addressType = "current"
    super
  end
end
