class Region < ActiveRecord::Base
  unloadable
  set_table_name "ministry_regionalteam"
  set_primary_key "teamID"
  
  default_scope order(:region)

  cattr_reader :standard_region_codes
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
end
