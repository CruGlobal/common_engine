require_dependency 'global_registry_methods'

class TeamMember < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

  self.table_name	= "ministry_missional_team_member"
  self.primary_key = "id"
  belongs_to :team, :foreign_key => "teamID"
  belongs_to :person, :foreign_key => "personID"

  delegate :global_registry_id, to: :person

  def async_push_to_global_registry
    self.class.push_structure_to_global_registry

    if team && person
      team.async_push_to_global_registry unless team.global_registry_id.present?
      person.async_push_to_global_registry unless person.global_registry_id.present?
      team_relationships = []
      person.teams.each do |team|
        team_relationships << {
            ministry: team.global_registry_id,
            role: is_leader? ? 'Leader' : 'Member'
        }
      end
      @attributes_to_push = {
        'ministry:relationship' => team_relationships,
      }

      update_in_global_registry
    end
  end

  def self.push_structure_to_global_registry
    Team.push_structure_to_global_registry
    Person.push_structure_to_global_registry

    # Make sure relationships are defined
    team_entity_type = Rails.cache.fetch(:team_entity_type, expires_in: 1.hour) do
      GlobalRegistry::EntityType.get({'filters[name]' => 'ministry'})['entity_types'].first
    end
    person_entity_type = Rails.cache.fetch(:activity_entity_type, expires_in: 1.hour) do
      GlobalRegistry::EntityType.get({'filters[name]' => 'person'})['entity_types'].first
    end
    role_enum_entity_type = Rails.cache.fetch(:role_enum_entity_type, expires_in: 1.hour) do
      GlobalRegistry::EntityType.get({'filters[name]' => 'role'})['entity_types'].first
    end

    person_team_relationship_type = Rails.cache.fetch(:person_team_relationship_type, expires_in: 1.hour) do
      GlobalRegistry::RelationshipType.get({'filters[between]' => "#{team_entity_type['id']},#{person_entity_type['id']}"})['relationship_types'].first
    end

    unless person_team_relationship_type
      GlobalRegistry::RelationshipType.post(relationship_type: {
          entity_type1_id: person_entity_type['id'],
          entity_type2_id: team_entity_type['id'],
          relationship1: 'person',
          relationship2: 'ministry',
          enum_entity_type_id: role_enum_entity_type['id']
      })
    end
  end

  def global_registry_entity_type_name
    'person'
  end
end
