class Ministry < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods
  default_scope -> { order(:name) }
  
  def to_s
    name
  end
end
