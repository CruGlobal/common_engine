class Bookmark < ActiveRecord::Base
  unloadable
  
  set_table_name "infobase_bookmarks"
  
  belongs_to :user
  belongs_to :activity, :conditions => Bookmark.table_name + ".name = 'activity'", :foreign_key => "value"
  
  scope :activity_bookmark, where("name = 'activity'")
  
  def self.add_activity_bookmark_for(user, activity)
    unless Bookmark.get_activity_bookmark_for(user, activity)
      Bookmark.create({:user_id => user.id, :name => "activity", :value => activity.id})
    end
  end
  
  def self.get_activity_bookmark_for(user, activity)
    activity_bookmark.where("user_id = ?", user.id).where("value = ?", activity.id).first
  end
end
