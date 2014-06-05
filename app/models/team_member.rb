require 'global_registry_relationship_methods'

class TeamMember < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryRelationshipMethods

  self.table_name	= "ministry_missional_team_member"
  self.primary_key = "id"
  belongs_to :team, :foreign_key => "teamID"
  belongs_to :person, :foreign_key => "personID"

  def async_push_to_global_registry
    return unless person && team

    person.async_push_to_global_registry unless person.global_registry_id.present?
    team.async_push_to_global_registry unless team.global_registry_id.present?
    super
  end

  def attributes_to_push
    if global_registry_id
      attributes_to_push = super
      attributes_to_push['role'] = is_leader? ? 'Leader' : 'Member'
      attributes_to_push
    else
      super('ministry', 'ministry', team)
    end
  end

  def create_in_global_registry(base_object = nil, relationship_name = nil)
    super(person, 'ministry')
  end

  def self.push_structure_to_global_registry
    super(Person, Team, 'person', 'ministry')
  end

  def self.columns_to_push
    super + [{name: 'role', type: 'string'}]
  end

  def self.skip_fields_for_gr
    super + %w(person_id team_id is_people_soft is_leader created_at updated_at)
  end
end
