begin
  require 'retryable'
rescue LoadError
  # do nothing
end
class SpDonation < ActiveRecord::Base

  scope :for_year, lambda {|year| where(["donation_date > ?", Time.new(year - 1,10,1)])}
  MEDIUMS = {
    'AE'  => 'American Express',
    'CCK' => 'Cashiers Check',
    'CSH' => 'Cash',
    'EFT' => 'Electronic Funds Transfer',
    'MC'  => 'MasterCard',
    'MO'  => 'Money Order',
    'PCK' => 'Personal Check',
    'Check' => 'Personal Check',
    'VI'  => 'VISA',
    'WT'  => 'Wire Transfer',
    'CC'  => 'Credit Card',
    'Credit Card' => 'Credit Card',
    'DC'  => 'Diner\'s Club',
    'DS'  => 'Discover',
    'NCG' => 'Non-Cash Gift',
    'IGT' => 'Internal Gift Transfer'
  }
  # This may be backed by Peoplesoft/Oracle in the future.
  # For now, it is backed by a table that is synchronized with Oracle
  def self.get_balance(designation_number, year = nil)
    return 0 unless designation_number
    if year
      (SpDonation.sum(:amount,
                      :conditions => ["designation_number = ? AND donation_date > ?",
                                      designation_number,
                                      Time.new(year - 1,10,1)]) || 0)
    else
      (SpDonation.sum(:amount,
                      :conditions => ["designation_number = ?",
                                      designation_number]) || 0)
    end
  end

  def self.get_balances(designation_numbers)
    return [] unless !designation_numbers.empty?
    sums = SpDonation.sum(:amount,
      :conditions => ["designation_number in (?)", designation_numbers],
      :group => :designation_number)
    balances = Hash.new
    sums.each do |designation_number, amount|
      balances[designation_number] = amount
    end
    return balances
  end

  def self.update_from_siebel
    total_donations = 0
    start_date = 2.years.ago.strftime("%Y-%m-%d")
    end_date = Time.now.strftime("%Y-%m-%d")

    # last_date = SpDonation.maximum(:donation_date) || 2.years.ago
    SpDesignationNumber.where(year: SpApplication.year).find_each do |dn|
      if dn.designation_number.present?
        donation_ids = []

        # Get all donations for current designations
        Rails.logger.debug(Time.now)
        begin
          donations = SiebelDonations::Donation.find(designations: dn.designation_number, start_date: start_date, end_date: end_date)
        rescue RestClient::ExceptionWithResponse
          # If there was something bad about this request, skip it and move on
          next
        end

        donors = Hash[SiebelDonations::Donor.find(having_given_to_designations: dn.designation_number).collect {|sd| [sd.id, sd] }]

        donations.each do |donation|
          attributes = {
                         designation_number: donation.designation,
                         amount: donation.amount,
                         medium_type: donation.payment_method,
                         donation_id: donation.id
                       }

          Retryable.retryable :on => [ActiveRecord::RecordNotUnique], :times => 3 do
            if old_donation = SpDonation.find_by_donation_id(donation.id)
              old_donation.update_attributes(attributes)
            else
              # Find the donor for this donation
              unless donors[donation.donor_id]
                donors[donation.donor_id] = SiebelDonations::Donor.find(ids: donation.donor_id).first

                # Make sure we got a donor
                if donors[donation.donor_id].nil?
                  Rails.logger.debug "Couldn't find a donor with ID: #{donation.donor_id} -- #{donation.inspect}"
                  next
                end
              end
              donor = donors[donation.donor_id]
              address = donor.primary_address || SiebelDonations::Address.new
              contact = donor.primary_contact || SiebelDonations::Contact.new
              email_address = contact.primary_email_address || SiebelDonations::EmailAddress.new
              phone_number = contact.primary_phone_number || SiebelDonations::PhoneNumber.new

              attributes.merge!({
                people_id: donor.id,
                donor_name: donor.account_name,
                donation_date: donation.donation_date,
                address1: address.address1,
                address2: address.address2,
                address3: address.address3,
                city: address.city,
                state: address.state,
                zip: address.zip,
                phone: phone_number.phone,
                email_address: email_address.email,
              })

              SpDonation.create(attributes)
            end
          end
          donation_ids << donation.id
        end

        # Remove any donations not found in the update
        SpDonation.where(designation_number: dn.designation_number)
                  .where("donation_date > ? AND donation_id NOT IN(?)", 2.years.ago, donation_ids)
                  .delete_all if donation_ids.present?

        total_donations += donations.length
      end

      # If there is a give site for this designation number, update it
      if dn.person.sp_gcx_site.present?
        site = GcxApi::Site.new(name: dn.person.sp_gcx_site)

        site.set_option_values(
            'cru_spkick[spkick_current_amount]' => get_balance(da.designation_number, SpApplication.year)
        )
      end
    end

    total_donations
  end


	def	medium
		MEDIUMS[medium_type]
	end

  def address
    street = [address1, address2, address3]
    street.reject!(&:blank?)
    "#{street.join('<br/>')}<br/>#{city}, #{state} #{zip}"
  end

end
