require_dependency 'async'
module GlobalRegistryMethods
  include Async

  extend ActiveSupport::Concern

  included do
    after_commit :push_to_global_registry
    after_destroy :delete_from_global_registry
  end

  def delete_from_global_registry
    if global_registry_id
      Sidekiq::Client.enqueue(self.class, nil, :async_delete_from_global_registry, global_registry_id)
    end
  end

  # Define default push method
  def push_to_global_registry
    async(:async_push_to_global_registry)
  end

  def async_push_to_global_registry(parent_id = nil)
    self.class.push_structure_to_global_registry

    if global_registry_id
      GlobalRegistry::Entity.put(global_registry_id, {entity: attributes_to_push})
    else
      entity = GlobalRegistry::Entity.post(entity: {self.class.global_registry_entity_type_name => attributes_to_push.merge({client_integration_id: id}), parent_id: parent_id})
      connection.update("update #{self.class.table_name} set global_registry_id = #{entity[self.class.global_registry_entity_type_name]['id']} where id = #{id}")
    end
  end

  def attributes_to_push
    @attributes_to_push ||= attributes.select {|k, v| !self.class.skip_fields_for_gr.include?(k)}
  end


  module ClassMethods
    def push_structure_to_global_registry
      # Make sure all columns exist
      entity_type = GlobalRegistry::EntityType.get({'filters[name]' => global_registry_entity_type_name})['entity_types'].first
      if entity_type
        existing_fields = entity_type['fields'].collect {|f| f['name']}
      else
        entity_type = GlobalRegistry::EntityType.post(entity_type: {name: global_registry_entity_type_name, field_type: 'entity'})['entity_type']
        GlobalRegistry::EntityType.post(entity_type: {name: 'client_integration_id', parent_id: entity_type['id'], field_type: 'integer'})
        existing_fields = []
      end

      columns.each do |column|
        next if skip_fields_for_gr.include?(column.name)

        unless existing_fields.include?(column.name)
          GlobalRegistry::EntityType.post(entity_type: {name: column.name, parent_id: entity_type['id'], field_type: column.type})
        end
      end
    end

    def async_delete_from_global_registry(registry_id)
      GlobalRegistry::Entity.delete(registry_id)
    end

  end
end

