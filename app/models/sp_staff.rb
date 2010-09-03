class SpStaff < ActiveRecord::Base
  unloadable
  set_inheritance_column 'fake_column'
  set_table_name 'sp_staff'
  belongs_to :person
  belongs_to :sp_project, :class_name => "SpProject", :foreign_key => "project_id"
  
  validate :only_one_of_each_director
  after_create :create_sp_user
  after_destroy :destroy_sp_user
  
  protected 
    def only_one_of_each_director
      return true unless %w{PD APD OPD Coordinator}.include?(type)
      SpStaff.where(:type => type, :year => year, :project_id => project_id).first.nil?
    end
    
    def create_sp_user
      return true if type == 'Kid' # Kids don't need users
      ssm_id = person.try(:fk_ssmUserId)
      return true unless ssm_id.present?
      
      sp_user = SpUser.find_by_ssm_id(ssm_id)
      if sp_user
        # Don't demote someone based on adding them to a project
        return true if [SpNationalCoordinator, SpRegionalCoordinator].include?(sp_user.class)
        return true if type == 'Evaluator' && sp_user.class == SpDirector
        return true if ['Staff', 'Volunteer'].include?(type)  && sp_user.class == [SpDirector, SpEvaluator].include?(sp_user.class)
        sp_user.destroy
      end 
      base = case type
             when 'PD', 'APD', 'OPD', 'Coordinator' then SpDirector
             when 'Evaluator' then SpEvaluator
             else SpProjectStaff
             end
      base.create!(:ssm_id => ssm_id,
                   :created_at => Time.now)
    end
end