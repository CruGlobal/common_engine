class Ccc::PrReview < ActiveRecord::Base


  #belongs_to :subject, class_name: "Ccc::Person"
  #belongs_to :initiator, class_name: "Ccc::Person"
  #belongs_to :question_sheet, class_name: 'Ccc::PrQuestionSheet'
  #has_many :reviewings, class_name: "Ccc::PrReviewer", dependent: :destroy
  #has_many :reviewers, through: :reviewings, class_name: "Person", source: :person
  #has_one :personal_form, class_name: "Ccc::PrPersonalForm"

  self.table_name = "pr_reviews"


end
