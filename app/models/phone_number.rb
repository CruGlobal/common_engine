class PhoneNumber < ActiveRecord::Base
	unloadable

	belongs_to :person
end