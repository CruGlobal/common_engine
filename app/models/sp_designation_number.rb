class SpDesignationNumber < ActiveRecord::Base

  belongs_to :person
  belongs_to :project, :class_name => 'SpProject'
  has_many :donations, -> { order('donation_date desc') }, :class_name => "SpDonation", :primary_key => "designation_number"

  after_create :secure_designation_if_necessary

  def sp_application
    SpApplication.where(person_id: person_id, project_id: project_id, year: year).first
  end

  # if this person is going to a secure location, mark them as secure in siebel
  def secure_designation_if_necessary

    if sp_application && sp_application.is_secure? && APP_CONFIG['designation_base_url']
      url = "#{APP_CONFIG['designation_base_url']}/designations/#{designation_number}/secureStatus"
      parameters = {
          startDate: "03-01-#{year}",
          endDate: "09-01-#{year}",
          access_token: APP_CONFIG['designation_access_token']}
      logger.ap parameters
      RestClient::Request.execute(:method => :post, :url => url, :payload => parameters, :timeout => -1) { |res, request, result, &block|
        logger.ap res
        logger.ap request
        logger.ap result
                                            # check for error response
                                            if res.code.to_i != 200
                                              raise res.inspect
                                            end
                                            res
    }
    end
  end

end
