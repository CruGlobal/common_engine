class Activity < ActiveRecord::Base
  unloadable
  set_table_name			"ministry_activity"
  set_primary_key   			"ActivityID"
  belongs_to :target_area, :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID"
  belongs_to :team, :foreign_key => "fk_teamID", :primary_key => "teamID"
  has_many :activity_histories
  has_many :statistics, :foreign_key => "fk_Activity"
  has_and_belongs_to_many :contacts, :join_table => "ministry_movement_contact", 
    :foreign_key => "ActivityID", :association_foreign_key => "personID", :class_name => "Person"
    
  validates_presence_of :status, :strategy, :periodBegin, :fk_targetAreaID, :fk_teamID
    
  scope :inactive, where("status = 'IN'")
  scope :active, where("status NOT IN ('IN', 'TN')")
  scope :strategy, lambda {|strategy| where("strategy = ?", strategy)}
  
  def self.strategies
    {
      "FS" => "Campus Field Ministry",
      "IC" => "Ethnic Field Ministry",
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
      "FD" => "Fund Development",
      "HR" => "Leadership Development",
      "OP" => "Operations",
      "ND" => "National",
      "OT" => "Other"
    }
  end
  
  def self.strategies_translations
    {
      "FS" => "FLD",
      "IE" => "EPI",
      "ID" => "DES", 
      "II" => "IMP",
      "IN" => "NTN",
      "WS" => "WSN",
      "BR" => "BRD",
      "AA" => "AIA",
      "FC" => "FC",
      "KC" => "KN",
      "GK" => "GK",
      "VL" => "VL",
      "SV" => "SV",
      "EV" => "EV",
      "OT" => "OT",
    }
  end
  
  def self.visible_strategies
    result = strategies.clone
    result.delete("EV")
    result.delete("IC")
    result.delete("FD")
    result.delete("HR")
    result.delete("OP")
    result.delete("ND")
    result
  end
  
  def self.visible_team_strategies
    result = strategies.clone
    result.delete("EV")
    result
  end

  def self.statuses
    {
      "IN" => "Inactive",
      "FR" => "Pioneering",
      "PI" => "Pioneering",
      "KE" => "Key Leader",
      "LA" => "Launched",
      "AC" => "Launched",
      "TR" => "Multiplying (formerly Transformational)",
      "MU" => "Multiplying (formerly Transformational)",
      "TN" => "Transitioned"
    }
  end
  
  def self.visible_statuses
    result = statuses.clone
    result.delete("FR")
    result.delete("AC")
    result.delete("TR")
    result.delete("TN")
    result
  end
  
  def self.determine_open_strategies(target_area)
    current_activities = target_area.activities
    open_strategies = visible_strategies.keys
    current_activities.each do |activity|
      open_strategies.delete(activity.strategy)
    end
    open_strategies
  end
  
  def self.translate_strategies_to_PS(strategies)
    result = []
    strategies.each do |strategy|
      result << strategies_translations[strategy]
    end
    result
  end
  
  def self.new_movement_for_strategy(target_area, strategy)
    activity = strategy(strategy).where("fk_targetAreaID = ?", target_area.targetAreaID).first
    if activity == nil
      activity = Activity.new(:strategy => strategy)
      activity.target_area = target_area
    end
    activity
  end
  
  # If status changes, create an ActivityHistory record
  def update_attributes_add_history(attributes, user)
    new_status = attributes[:status]
    if new_status && new_status != status
      ActivityHistory.create(:activity => self, :status => new_status, :period_begin => convert_date(attributes, :periodBegin), :trans_username => user.userID)
    end
    attributes[:transUsername] = user.userID
    update_attributes(attributes)
  end
  
  def save_create_history(user)
    ActivityHistory.create(:activity => self, :status => status, :period_begin => periodBegin, :trans_username => user.userID)
    transUsername = user.userID
    save(attributes)
  end
  
  private
  
  def convert_date(hash, date_symbol_or_string)
    attribute = date_symbol_or_string.to_s
    return Date.new(hash[attribute + '(1i)'].to_i, hash[attribute + '(2i)'].to_i, hash[attribute + '(3i)'].to_i)   
  end

end
