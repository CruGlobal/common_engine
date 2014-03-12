require 'async'
class SpDesignationNumber < ActiveRecord::Base
  include Async
  include Sidekiq::Worker
  sidekiq_options unique: true

  belongs_to :person
  belongs_to :project, :class_name => 'SpProject'
  has_many :donations, -> { order('donation_date desc') }, :class_name => "SpDonation", :primary_key => "designation_number"

  before_save :ensure_correct_number_length
  after_save :async_secure_designation, if: :mark_secure_necessary?
  after_save :async_set_up_give_site, if: :designation_number_changed?

  def sp_application
    @sp_application ||= SpApplication.where(person_id: person_id, project_id: project_id, year: year).first
  end

  def async_secure_designation
    async(:secure_designation)
  end

  def async_set_up_give_site
    sp_application.async(:set_up_give_site) if sp_application
  end

  private
  # if this person is going to a secure location, mark them as secure in siebel
  def secure_designation
    parameters = {
      startDate: Date.today.to_s(:db),
      endDate: 1.year.from_now.to_date.to_s(:db)
    }

    SpDesignationNumber.update_designation_security(designation_number, parameters)
  end


  def self.wsapi_url(designation_number)
    base_url = APP_CONFIG['designation_base_url']
    "#{base_url}/designations/#{designation_number}/secureStatus"
  end

  def self.update_designation_security(designation_number, parameters)
    RestClient::Request.execute(:method => :post, :url => wsapi_url(designation_number), :payload => parameters, headers: {'Authorization' => "Bearer #{APP_CONFIG['designation_access_token']}"}, :timeout => -1) { |res, request, result, &block|
      if res.code.to_i >= 400
        puts res.inspect
        puts request.inspect
        puts result.inspect
        raise res.inspect
      end
      res
    }
  end

  def mark_secure_necessary?
    sp_application && sp_application.is_secure? && designation_number.present?
  end

  def ensure_correct_number_length
    if designation_number.present?
      while designation_number.length < 7
        self.designation_number = '0' + designation_number
      end
    end
  end

end
