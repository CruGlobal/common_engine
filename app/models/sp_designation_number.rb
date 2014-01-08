require 'async'
class SpDesignationNumber < ActiveRecord::Base
  include Async
  include Sidekiq::Worker

  belongs_to :person
  belongs_to :project, :class_name => 'SpProject'
  has_many :donations, -> { order('donation_date desc') }, :class_name => "SpDonation", :primary_key => "designation_number"

  after_save :async_secure_designation_if_necessary

  def sp_application
    SpApplication.where(person_id: person_id, project_id: project_id, year: year).first
  end

  def async_secure_designation_if_necessary
    if changed.include?('designation_number')
      async(:secure_designation) if mark_secure_necessary?
    end
  end

  private
  # if this person is going to a secure location, mark them as secure in siebel
  def secure_designation
    parameters = {
      startDate: Date.today.to_s(:db),
      endDate: 1.year.from_now.to_date.to_s(:db),
      access_token: get_required_config('designation_access_token')
    }

    RestClient::Request.execute(:method => :post, :url => url, :payload => parameters, :timeout => -1) { |res, request, result, &block|
      if res.code.to_i >= 400
        raise res.inspect
      end
      res
    }
  end

  def mark_secure_necessary?
    sp_application && sp_application.is_secure? && designation_number.present?
  end

  def url
    base_url = get_required_config('designation_base_url')
    "#{base_url}/designations/#{designation_number}/secureStatus"
  end

  def get_required_config(key)
    value = APP_CONFIG[key]
    unless value
      raise "'#{key}' not specified in APP_CONFIG!"
    end
    value
  end

end
