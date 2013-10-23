require_dependency 'global_registry_methods'

class SpMinistryFocus < ActiveRecord::Base
  self.table_name = "sp_ministry_focuses"
  
  include Sidekiq::Worker
  include GlobalRegistryMethods

  has_many :project_ministry_focuses, :class_name => 'SpProjectMinistryFocus', foreign_key: 'ministry_focus_id'
  has_many :projects, -> { order(:name) }, through: :project_ministry_focuses

  default_scope -> { order(:name) }

  def to_s
    name
  end

  def self.skip_fields_for_gr
    %w[id global_registry_id]
  end

  def self.global_registry_entity_type_name
    'summer_project_ministry_focus'
  end
end
