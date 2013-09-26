require_dependency 'global_registry_methods'

class SpMinistryFocus < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

  unloadable
  has_many :project_ministry_focuses, :class_name => 'SpProjectMinistryFocus', foreign_key: 'ministry_focus_id'
  has_many :projects, through: :project_ministry_focuses, :order => :name

  default_scope order(:name)

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
