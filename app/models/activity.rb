class Activity < ActiveRecord::Base
  unloadable
  set_table_name			"ministry_activity"
  set_primary_key   			"ActivityID"
  belongs_to :target_area, :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID"
  belongs_to :team, :foreign_key => "fk_teamID", :primary_key => "teamID"
  has_and_belongs_to_many :contacts, :join_table => "ministry_movement_contact", 
    :foreign_key => "ActivityID", :association_foreign_key => "personID", :class_name => "Person"
  
  def self.strategies
    {
      "FS" => "Campus Field Ministry",
      "IE" => "Epic",
      "ID" => "Destino", 
      "II" => "Impact",
      "IN" => "Nations",
      "WS" => "WSN",
      "BR" => "Bridges",
      "AA" => "Athletes In Action",
      "FC" => "Faculty Commons",
      "KC" => "Korean CCC",
      "GK" => "Greek",
      "VL" => "Valor",
      "SV" => "Student Venture",
      "EV" => "Events",
      "OT" => "Other"
    }
  end
  
  def self.statuses
    {
      "AC" => "Launched",
      "IN" => "Inactive",
      "FR" => "Pioneering",
      "PI" => "Pioneering",
      "KE" => "Key Leader",
      "LA" => "Launched",
      "TR" => "Multiplying (formerly Transformational)",
      "MU" => "Multiplying (formerly Transformational)",
      "TN" => "Transitioned"
    }
  end
  
  def self.determine_open_strategies(target_area)
    current_activities = target_area.activities
    open_strategies = strategies.keys
    current_activities.each do |activity|
      open_strategies.delete(activity.strategy)
    end
    open_strategies.delete("EV")
    open_strategies
  end
end
