class SpStaff < ActiveRecord::Base
  unloadable
  set_inheritance_column 'fake_column'
  set_table_name 'sp_staff'
  belongs_to :person
  belongs_to :sp_project, :class_name => "SpProject", :foreign_key => "project_id"
  
  validate :only_one_of_each_director
  
  protected 
    def only_one_of_each_director
      return true unless %w{PD APD OPD Coordinator}.include?(type)
      SpStaff.where(:type => type, :year => year, :project_id => project_id).first.nil?
    end
end