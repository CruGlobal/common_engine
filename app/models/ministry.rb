class Ministry < ActiveRecord::Base
  unloadable
  default_scope order(:name)
  
  def to_s
    name
  end
end
