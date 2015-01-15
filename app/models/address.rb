require 'global_registry_methods'
class Address < ActiveRecord::Base
  include GlobalRegistryMethods
  include Sidekiq::Worker

  self.table_name = "ministry_newaddress"

	validates_presence_of :address_type

	belongs_to :person

	before_save :stamp

  #set dateChanged and changedBy
  def stamp
    self.changed_by = ApplicationController.application_name
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
    phone = (self.home_phone && !self.home_phone.empty?) ? self.home_phone : self.cell_phone
    phone = (phone && !phone.empty?) ? phone : self.work_phone
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

  def async_push_to_global_registry(parent_id = nil, parent_type = 'person')
    return unless person

    person.async_push_to_global_registry unless person.global_registry_id.present?
    parent_id = person.global_registry_id unless parent_id

    attributes_to_push['line1'] = address1
    attributes_to_push['line2'] = address2
    attributes_to_push['line3'] = address3
    attributes_to_push['line4'] = address4
    attributes_to_push['postal_code'] = zip
    super(parent_id, parent_type)
  end

  def self.push_structure_to_global_registry
    parent_id = GlobalRegistry::EntityType.get(
        {'filters[name]' => 'person'}
    )['entity_types'].first['id']
    super(parent_id)
  end

  def self.columns_to_push
    super
    @columns_to_push + [{ name: 'line1', type: 'string' },
                        { name: 'line2', type: 'string' },
                        { name: 'line3', type: 'string' },
                        { name: 'line4', type: 'string' },
                        { name: 'postal_code', type: 'string' }]
  end

  def self.skip_fields_for_gr
    super + %w(address_id address1 address2 address3 address4 home_phone work_phone cell_phone fax skype email url date_created date_changed created_by changed_by fk_person_id email2 start_date end_date facebook_link myspace_link title preferred_phone phone1_type phone2_type phone3_type)
  end

  def self.global_registry_entity_type_name
    'address'
  end
end
