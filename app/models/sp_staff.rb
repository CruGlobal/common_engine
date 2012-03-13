class SpStaff < ActiveRecord::Base
  DIRECTORSHIPS = ['PD', 'APD', 'OPD', 'Coordinator']
  unloadable
  set_inheritance_column 'fake_column'
  set_table_name 'sp_staff'
  belongs_to :person
  belongs_to :sp_project, :class_name => "SpProject", :foreign_key => "project_id"
  
  validate :only_one_of_each_director
  after_create :create_sp_user
  after_destroy :destroy_sp_user

  scope :pd, where(:type => 'PD')
  scope :apd, where(:type => 'APD')
  scope :opd, where(:type => 'OPD')
  scope :year, proc {|year| where(:year => year)}
  scope :most_recent, order('year desc').limit(1)
  scope :other_involved, where('sp_staff.type' => "Non App Participant")
  scope :for_year, proc {|year| {:conditions => {:year => year}}}
  
  delegate :email, :to => :person

  protected 
    def only_one_of_each_director
      return true unless DIRECTORSHIPS.include?(type)
      SpStaff.where(:type => type, :year => year, :project_id => project_id).first.nil?
    end
    
    def create_sp_user
      SpUser.create_max_role(person.id) unless type == 'Kid' # Kids don't need users
      true
    end
    
    def destroy_sp_user
      ssm_id = person.try(:fk_ssmUserId)
      sp_user = SpUser.where(:ssm_id => ssm_id, :person_id => person.id).first if ssm_id
      sp_user.destroy if sp_user
    end
end
