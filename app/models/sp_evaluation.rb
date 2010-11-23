class SpEvaluation < ActiveRecord::Base
  belongs_to :sp_application, :foreign_key => 'application_id', :class_name => 'SpApplication'
  
  # Each of the qualifying facotrs has a weight contributing to a final score.
  # This score is supposed to help in objectively evaluating an applicant.
  SPIRITUAL_MATURITY = 10
  TEACHABILITY       = 10
  LEADERSHIP         = 8
  STABILITY          = 7
  GOOD_EVANGELISM    = 7
  REASON             = 6
  SOCIAL_MATURITY    = 6
  CCC_INVOLVEMENT    = 6
  
  def spiritual_maturity_score
    SPIRITUAL_MATURITY * spiritual_maturity
  end
  
  def teachability_score
    TEACHABILITY * teachability
  end
  
  def leadership_score
    LEADERSHIP * leadership
  end
  
  def stability_score
    STABILITY * stability
  end
  
  def good_evangelism_score
    GOOD_EVANGELISM * good_evangelism
  end
  
  def reason_score
    REASON * reason
  end
  
  def social_maturity_score
    SOCIAL_MATURITY * social_maturity
  end
  
  def ccc_involvement_score
    CCC_INVOLVEMENT * ccc_involvement
  end
  
  def total_score
    spiritual_maturity_score + teachability_score + leadership_score + stability_score +  
    good_evangelism_score + reason_score + social_maturity_score + ccc_involvement_score
  end
end