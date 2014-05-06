require 'global_registry_methods'
class Region < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

  self.table_name = "ministry_regionalteam"
  self.primary_key = "teamID"
  
  default_scope -> { order(:region) }

  cattr_reader :standard_region_codes, :campus_region_codes
  @@standard_region_codes = ["GL", "GP", "MA", "MS", "NE", "NW", "RR", "SE", "SW", "UM"]
  @@campus_region_codes = @@standard_region_codes.clone << "NC"
  
  def self.standard_regions
    where(["region IN (?)", @@standard_region_codes])
  end

  def self.campus_regions
    where(["region IN (?)", @@campus_region_codes])
  end
  
  def self.standard_regions_hash
    result = {}
    standard_regions.each do |region|
      result[region.name] = region.region
    end
    result
  end
  
  def self.full_name(code)
    region = where("region = ?", code).first
    if region
      region.name
    elsif code == "nil"
      "Unspecified Region"
    else
      ""
    end
  end
  
  def sp_phone
    @sp_phone ||= spPhone.blank? ? phone : spPhone
  end
  
  def to_s
    region
  end

  def async_push_to_global_registry(parent_id = nil)
    unless parent_id
      campus_ministry = Ministry.find_by(abbreviation: 'FS')
      parent_id = campus_ministry.global_registry_id
    end

    attributes_to_push['abbreviation'] = abbrv

    super(parent_id)
  end

  def self.columns_to_push
    super
    @columns_to_push += [{name: 'abbreviation', type: 'string'}]
  end

  def self.skip_fields_for_gr
    super + ["team_id", "is_active", 'stopdate', 'startdate', 'hrd', "abbrv", "region", "address1", "address2", "city", "state", "zip", "phone", "fax", "email", "url", "no"]
  end

  def self.global_registry_entity_type_name
    'ministry'
  end
end
