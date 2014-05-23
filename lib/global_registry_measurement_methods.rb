require_dependency 'async'
module GlobalRegistryMeasurementMethods
  include Async

  extend ActiveSupport::Concern

  included do
    after_commit :push_to_global_registry
    after_destroy :delete_from_global_registry
  end

  def delete_from_global_registry
    async(:async_push_to_global_registry)
  end

  def async_delete_from_global_registry(registry_id)
    begin
      GlobalRegistry::Entity.delete(registry_id)
    rescue RestClient::ResourceNotFound
      # If the record doesn't exist, we don't care
    end
  end

  # Define default push method
  def push_to_global_registry
    async(:async_push_to_global_registry)
  end

  def async_push_to_global_registry
    return unless activity

    activity.async_push_to_global_registry unless activity.global_registry_id.present?

    detailed_mappings = self.class.gr_measurement_types

    measurements = []
    detailed_mappings.each do |column_name, measurement_type|
      total = activity.statistics.where("periodBegin >= ? AND periodBegin <= ?", periodBegin.beginning_of_month, periodBegin.end_of_month)
                                 .sum(column_name)
      if total > 0
        month = periodBegin.beginning_of_month.strftime("%Y-%m")
        measurements << {
            measurement_type_id: measurement_type['id'],
            related_entity_id: activity.global_registry_id,
            period: month,
            value: total
        }
      end
    end

    GlobalRegistry::Measurement.post(measurements: measurements) if measurements.present?
  end

  def update_in_global_registry
    GlobalRegistry::Entity.put(global_registry_id, {entity: attributes_to_push})
  end

  def create_in_global_registry(parent_id = nil)
    entity = GlobalRegistry::Entity.post(entity: {self.class.global_registry_entity_type_name => attributes_to_push.merge({client_integration_id: id}), parent_id: parent_id})
    entity = entity['entity']
    update_column(:global_registry_id, entity[self.class.global_registry_entity_type_name]['id'])
  end

  module ClassMethods
    def gr_measurement_types(measurement_type_mappings = gr_measurement_type_mappings, related_entity_type_id = gr_related_entity_type_id, category = gr_category, unit = gr_unit, description = '', frequency = 'monthly')
      Rails.cache.fetch(:detailed_mappings, expires_in: 1.hour) do
        mappings = {}
        measurement_type_mappings.each do |column_name, type_name|
          gr_type = GlobalRegistry::MeasurementType.get({'filters[name]' => type_name})['measurement_types'].first

          unless gr_type
            gr_type = GlobalRegistry::MeasurementType.post(measurement_type: {
              name: type_name,
              related_entity_type_id: related_entity_type_id,
              category: category,
              unit: unit,
              description: description,
              frequency: frequency
             })
          end

          mappings[column_name] = gr_type
        end
        mappings
      end
    end
  end
end

