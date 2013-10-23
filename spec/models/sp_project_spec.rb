require 'spec_helper'

describe SpProject do 
  it { should have_db_column :picture_file_name }
  it { should have_db_column :picture_content_type }
  it { should have_db_column :picture_file_size }
  it { should have_db_column :picture_updated_at }
  
  # it { should have_many :sp_designation_numbers } Expected SpProject to have a has_many association called sp_designation_numbers (SpDesignationNumber does not have a sp_project_id foreign key.)
  it { should belong_to :created_by }
  it { should belong_to :updated_by }
  it { should belong_to :basic_info_question_sheet }
  it { should belong_to :template_question_sheet }
  it { should belong_to :project_specific_question_sheet }
  # it { should have_many :stats } # uninitialized constant SpProject::SpStat
  it { should have_many :ministry_focuses }
  it { should have_many :sp_staff }
  # it { should have_many :project_gospel_in_actions } # uninitialized constant SpProject::SpProjectGospelInAction
  # it { should have_many :student_quotes } # uninitialized constant
  # it { should have_many :sp_applications } # No such file to load -- answer_sheet_concern
  it { should have_one :target_area }
  # it { should have_many :statistics } # Expected SpProject to have a has_many association called statistics (Statistic does not have a sp_project_id foreign key.)
end

