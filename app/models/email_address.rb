class EmailAddress < ActiveRecord::Base
	unloadable

	belongs_to :person
end