require_dependency 'global_registry_relationship_methods'

class SpProjectMinistryFocus < ActiveRecord::Base
  self.table_name = "sp_project_ministry_focuses"
  include Sidekiq::Worker
  include GlobalRegistryRelationshipMethods

  belongs_to :ministry_focus, :class_name => "SpMinistryFocus", :foreign_key => "ministry_focus_id"
  belongs_to :project, :class_name => "SpProject", :foreign_key => "project_id"

  def async_push_to_global_registry
    return unless ministry_focus && project

    ministry_focus.async_push_to_global_registry unless ministry_focus.global_registry_id.present?
    project.async_push_to_global_registry unless project.global_registry_id.present?
    super
  end

  def attributes_to_push
    if global_registry_id
      super
    else
      super('ministry_focus', 'summer_project_ministry_focus', ministry_focus)
    end
  end

  def create_in_global_registry(base_object = nil, relationship_name = nil)
    super(project, 'ministry_focus')
  end

  def self.push_structure_to_global_registry
    super(SpProject, SpMinistryFocus, 'summer_project', 'ministry_focus')
  end

  def self.skip_fields_for_gr
    super + %w[id created_at updated_at global_registry_id project_id ministry_focus_id]
  end

  def self.global_registry_entity_type_name
    'summer_project_project_ministry_focus'
  end
end
