class EmailAddress < ActiveRecord::Base
	belongs_to :person

  def async_push_to_global_registry(parent_id = nil)
    parent_id = person.global_registry_id unless parent_id

    super(parent_id)
  end

  def self.skip_fields_for_gr
    %w[id created_at updated_at global_registry_id]
  end
end