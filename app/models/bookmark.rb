class Bookmark < ActiveRecord::Base
  unloadable
  
  set_table_name "infobase_bookmarks"
  
  belongs_to :user
  belongs_to :activity, :conditions => Bookmark.table_name + ".name = 'activity'", :foreign_key => "value"
end
