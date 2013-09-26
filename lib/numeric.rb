class Numeric
  def dollars
    val = self > 0 ? sprintf("$%.0f",self) : 0
  end
  
  def cents
    (self*100).round % 100
  end
  
  def dollars_and_cents
    dollars + '.' + cents.to_s
  end
end