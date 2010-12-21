class Country < ActiveRecord::Base
  unloadable
  
  def self.to_hash_US_first
    result = {}
    top = where('country = ?', 'United States').first
    result[top.country] = top.code
    countries = order(:country)
    countries.each do |country|
      result[country.country] = country.code
    end
    result
  end
end
