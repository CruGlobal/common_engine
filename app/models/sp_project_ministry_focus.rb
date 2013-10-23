require_dependency 'global_registry_methods'

class SpProjectMinistryFocus < ActiveRecord::Base
  self.table_name = "sp_project_ministry_focuses"
  include Sidekiq::Worker
  include GlobalRegistryMethods

  belongs_to :ministry_focus, :class_name => "SpMinistryFocus", :foreign_key => "ministry_focus_id"
  belongs_to :project, :class_name => "SpProject", :foreign_key => "project_id"

  def async_push_to_global_registry
    attributes_to_push['project_id'] = project.global_registry_id if project && project.global_registry_id
    attributes_to_push['ministry_focus_id'] = ministry_focus.global_registry_id if ministry_focus && ministry_focus.global_registry_id

    super
  end

  def self.skip_fields_for_gr
    %w[id created_at updated_at global_registry_id]
  end

  def self.global_registry_entity_type_name
    'summer_project_project_ministry_focus'
  end
end
