require 'global_registry_methods'
class EmailAddress < ActiveRecord::Base
  include GlobalRegistryMethods
  include Sidekiq::Worker
  belongs_to :person

  def async_push_to_global_registry(parent_id = nil)
    person.async_push_to_global_registry unless person.global_registry_id.present?
    parent_id = person.global_registry_id unless parent_id

    super(parent_id)
  end

  def self.skip_fields_for_gr
    %w[id created_at updated_at global_registry_id]
  end
end