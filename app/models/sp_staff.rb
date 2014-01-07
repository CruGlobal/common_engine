require_dependency 'global_registry_methods'

class SpStaff < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

  DIRECTORSHIPS = ['PD', 'APD', 'OPD', 'Coordinator']
  self.inheritance_column = 'fake_column'
  self.table_name = 'sp_staff'
  belongs_to :person
  belongs_to :sp_project, :class_name => "SpProject", :foreign_key => "project_id"

  validate :only_one_of_each_director
  after_create :create_or_reset_sp_user
  after_destroy :delete_or_reset_sp_user

  scope :pd, -> { where(:type => 'PD') }
  scope :apd, -> { where(:type => 'APD') }
  scope :opd, -> { where(:type => 'OPD') }
  scope :year, proc {|year| where(:year => year)}
  scope :most_recent, -> { order('year desc').limit(1) }

  scope :other_involved, -> { where("sp_staff.type NOT IN ('Kid','Evaluator','Coordinator','Staff')") }

  delegate :email, :to => :person

  def designation_number=(val)
    if designation = SpDesignationNumber.where(:person_id => self.person_id, :project_id => self.project_id).first
      designation.designation_number = val
    else
      designation = SpDesignationNumber.new(
                      :person_id => self.person_id,
                      :project_id => self.project_id,
                      :designation_number => val)
    end
    designation.save!
  end

  def designation_number
    if designation = SpDesignationNumber.where(:person_id => self.person_id, :project_id => self.project_id).first
      designation.designation_number.to_s
    else
      nil
    end
  end

  def async_push_to_global_registry
    attributes_to_push['person_id'] = person.global_registry_id
    attributes_to_push.delete('project_id')

    super(sp_project.global_registry_id)
  end

  def self.skip_fields_for_gr
    %w[id project_id global_registry_id]
  end

  def self.global_registry_entity_type_name
    'summer_project_staff'
  end

  protected
    def only_one_of_each_director
      return true unless DIRECTORSHIPS.include?(type)
      SpStaff.where(:type => type, :year => year, :project_id => project_id).first.nil?
    end

    def create_or_reset_sp_user
      ssm_id = person.try(:fk_ssmUserId)
      return false unless ssm_id.present?

      new_role = SpUser.get_max_role(person.id)
      sp_user = SpUser.where(:ssm_id => ssm_id, :person_id => person.id).first
      if sp_user
        if new_role && sp_user.type != 'SpNationalCoordinator' && sp_user.type != 'SpRegionalCoordinator'
          sp_user.update_attribute(:type, new_role.to_s)
        end
      else
        SpUser.create_max_role(person.id) unless type == 'Kid' # Kids don't need users
      end
      return true
    end

    def delete_or_reset_sp_user
      ssm_id = person.try(:fk_ssmUserId)
      return false unless ssm_id.present?

      new_role = SpUser.get_max_role(person.id)
      sp_user = SpUser.where(:ssm_id => ssm_id, :person_id => person.id).first
      if sp_user && sp_user.type != 'SpNationalCoordinator' && sp_user.type != 'SpRegionalCoordinator'
        if new_role
          sp_user.update_attribute(:type, new_role.to_s)
        else
          sp_user.destroy
        end
      end
      return true
    end
end
