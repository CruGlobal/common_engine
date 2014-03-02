class Ccc::PrReviewer < AnswerSheet


  self.table_name = "pr_reviewers"
  #belongs_to :review, class_name: "Ccc::PrReview"
  belongs_to :person, class_name: 'Ccc::Person'

end
