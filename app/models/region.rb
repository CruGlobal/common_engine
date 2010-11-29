class Region < ActiveRecord::Base
  unloadable
  set_table_name "ministry_regionalteam"
  set_primary_key "teamID"
  
  default_scope order(:region)

  attr_reader :standard_region_codes
  @@standard_region_codes = ["NE", "MA", "MS", "SE", "GL", "UM", "GP", "RR", "NW", "SW"]
  
  def self.standard_regions
    where(["region IN (?)", @@standard_region_codes])
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
