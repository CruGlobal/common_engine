class SpDesignationNumber < ActiveRecord::Base

  belongs_to :person
  belongs_to :project, :class_name => 'SpProject'
  has_many :donations, :class_name => "SpDonation", :primary_key => "designation_number", :order => 'donation_date desc'

  after_create :secure_siebel

  def sp_application
    SpApplication.where(person_id: person_id, project_id: project_id, year: year).first
  end

  # if this person is going to a secure location, mark them as secure in siebel
  def secure_siebel
    if sp_application && sp_application.is_secure? && APP_CONFIG['siebel_url']
      parameters = {designation: designation_number, startDate: "03-01-#{year}", endDate: "09-01-#{year}", key: APP_CONFIG['siebel_key'], dateFormatString: 'MM-dd-yyyy'}
      logger.ap parameters
      RestClient::Request.execute(:method => :post, :url => APP_CONFIG['siebel_url'], :payload => parameters, :timeout => -1) { |res, request, result, &block|
        logger.ap res
        logger.ap request
        logger.ap result
                                            # check for error response
                                            if res.code.to_i == 400
                                              raise res.inspect
                                            end
                                            res
    }
    end
  end

end
