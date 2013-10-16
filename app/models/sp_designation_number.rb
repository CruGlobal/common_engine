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
    if mark_necessary?
      logger.ap parameters
      RestClient::Request.execute(:method => :post, :url => url, :payload => parameters, :timeout => -1) { |res, request, result, &block|
        logger.ap res
        logger.ap request
        logger.ap result

        if res.code.to_i >= 400
          raise res.inspect
        end
        res
    }
    end
  end

  def mark_necessary?
    #TODO: remove APP_CONFIG['designation_base_url'] check
    sp_application && sp_application.is_secure? && APP_CONFIG['designation_base_url']
  end

  def url
    base_url = get_required_config('designation_base_url')
    "#{base_url}/designations/#{designation_number}/secureStatus"
  end

  def parameters
    {
      startDate: "#{year}-03-01",
      endDate: "#{year}-09-01",
      access_token: get_required_config('designation_access_token')
    }
  end

  def get_required_config(key)
    value = APP_CONFIG[key]
    unless value
      raise "'#{key}' not specified in APP_CONFIG!"
    end
    value
  end

end
