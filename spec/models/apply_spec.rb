require 'spec_helper'

describe Apply do
  it { should belong_to :applicant }
  # it { should have_many :references } # uninitialized constant
  # it { should have_many :payments } # uninitialized constant
  it { should have_one :hr_si_application }
  # it { should have_one :answer_sheet_question_sheet } # uninitialized constant
end
