require_dependency 'global_registry_methods'
require_dependency 'async'
module GlobalRegistryRelationshipMethods
  extend ActiveSupport::Concern
  include GlobalRegistryMethods

  def async_push_to_global_registry
    super
  end

  # TODO - deleting a relationship is different.
  def delete_from_global_registry
    if global_registry_id
      Sidekiq::Client.enqueue(self.class, nil, :async_delete_from_global_registry, global_registry_id)
    end
  end

  def attributes_to_push(relationship_name = nil, related_name = nil, related_object = nil)
    if global_registry_id
      attributes_to_push = super
      attributes_to_push
    else
      {
        "#{relationship_name}:relationship" => {
          client_integration_id: id,
          related_name => related_object.global_registry_id
        }
      }
    end
  end

  def create_in_global_registry(base_object, relationship_name)
    entity = GlobalRegistry::Entity.put(
      base_object.global_registry_id,
      entity: {base_object.class.global_registry_entity_type_name => attributes_to_push}
    )

    id = entity['entity'][base_object.class.global_registry_entity_type_name]['id']

    entity = GlobalRegistry::Entity.find(id)['entity']

    update_column(
      :global_registry_id,
      entity[base_object.class.global_registry_entity_type_name]["#{relationship_name}:relationship"]['relationship_entity_id']
    )
    update_in_global_registry
  end

  module ClassMethods
    # @param [Class] base_type
    # @param [Class] related_type
    # @param [String] relationship1_name
    # @param [String] relationship2_name
    def push_structure_to_global_registry(base_type, related_type, relationship1_name, relationship2_name)
      # A summer project application is a join table between people and projects
      base_type_cache_key = "#{base_type.global_registry_entity_type_name}_entity_type"
      base_entity_type = Rails.cache.fetch(base_type_cache_key, expires_in: 1.hour) do
        GlobalRegistry::EntityType.get({'filters[name]' => base_type.global_registry_entity_type_name})['entity_types'].first
      end

      related_type_cache_key = "#{related_type.global_registry_entity_type_name}_entity_type"
      related_entity_type = Rails.cache.fetch(related_type_cache_key, expires_in: 1.hour) do
        GlobalRegistry::EntityType.get({'filters[name]' => related_type.global_registry_entity_type_name})['entity_types'].first
      end

      relationship_type_cache_key = "#{base_type}_#{related_type}_#{relationship1_name}"
      relationship_type = Rails.cache.fetch(relationship_type_cache_key, expires_in: 1.hour) do
        GlobalRegistry::RelationshipType.get(
          {'filters[between]' => "#{base_entity_type['id']},#{related_entity_type['id']}"}
        )['relationship_types'].detect { |r| r['relationship1']['relationship_name'] == relationship1_name }
      end

      unless relationship_type
        relationship_type = GlobalRegistry::RelationshipType.post(relationship_type: {
          entity_type1_id: base_entity_type['id'],
          entity_type2_id: related_entity_type['id'],
          relationship1: relationship1_name,
          relationship2: relationship2_name
        })['relationship_type']
      end

      existing_fields = relationship_type['fields'].collect {|f| f['name']}

      (columns_to_push + [{name: 'client_integration_id'}]).each do |field|
        next if existing_fields.include?(field[:name])

        GlobalRegistry::RelationshipType.put(relationship_type['id'], relationship_type: {
          fields: [field]
        })
      end
    end

    def columns_to_push
      super
    end
  end
end

