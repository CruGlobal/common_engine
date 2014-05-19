require 'global_registry_methods'
class Address < ActiveRecord::Base
  include GlobalRegistryMethods
  include Sidekiq::Worker

  self.table_name = "ministry_newaddress"
	self.primary_key = "addressID"

	validates_presence_of :addressType

	belongs_to :person, :foreign_key => "fk_PersonID"

	before_save :stamp

  def updated_at() dateChanged end
  def created_at() dateCreated end

	def home_phone; homePhone; end
	def cell_phone; cellPhone; end
	def work_phone; workPhone; end

  #set dateChanged and changedBy
  def stamp
    self.dateChanged = Time.now
    self.changedBy = ApplicationController.application_name
  end

	def display_html
	  ret_val = address1 || ''
		ret_val += '<br/>'+address2 unless address2.nil? || address2.empty?
		ret_val += '<br/>' unless ret_val.empty?
		ret_val += city+', ' unless city.nil? || city.empty?
		ret_val += state + ' ' unless state.nil?
		ret_val += zip unless zip.nil?
		ret_val += '<br/>'+country+',' unless country.nil? || country.empty? || country == 'USA'
		return ret_val
	end
	alias_method :to_s, :display_html

	def phone_number
    phone = (self.homePhone && !self.homePhone.empty?) ? self.homePhone : self.cellPhone
    phone = (phone && !phone.empty?) ? phone : self.workPhone
    phone
	end

	def phone_numbers
	  unless @phone_numbers
	    @phone_numbers = []
	    @phone_numbers << home_phone + ' (home)' unless home_phone.blank?
	    @phone_numbers << cell_phone + ' (cell)' unless cell_phone.blank?
	    @phone_numbers << work_phone + ' (work)' unless work_phone.blank?
    end
  	@phone_numbers
  end

  def async_push_to_global_registry(parent_id = nil)
    person.async_push_to_global_registry unless person.global_registry_id.present?
    parent_id = person.global_registry_id unless parent_id

    super(parent_id)
  end

  def self.columns_to_push
    super
    @columns_to_push << [{ name: 'line1' },
                        { name: 'line2' },
                        { name: 'line3' },
                        { name: 'line4' }]
  end

  def self.skip_fields_for_gr
    super + %w(address_id address1 address2 address3 address4 home_phone work_phone cell_phone fax skype email url date_created date_changed created_by changed_by fk_person_id email2 start_date end_date facebook_link myspace_link title preferred_phone phone1_type phone2_type phone3_type)
  end
end
