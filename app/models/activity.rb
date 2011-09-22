class Activity < ActiveRecord::Base
  unloadable
  set_table_name			"ministry_activity"
  set_primary_key   			"ActivityID"
  belongs_to :target_area, :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID"
  belongs_to :team, :foreign_key => "fk_teamID", :primary_key => "teamID"
  has_many :activity_histories
  has_many :statistics, :foreign_key => "fk_Activity", :order => "periodBegin"
  has_many :last_fifteen_stats, :class_name => "Statistic", :foreign_key => "fk_Activity",
    :conditions => proc {"periodBegin > '#{(Date.today - 15.weeks).to_s(:db)}'"}, :order => "periodBegin"
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
      "KC" => "Korea CCC",
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
  
  def self.bridges
    "BR"
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
  
  def self.active_statuses
    ["LA", "AC", "TR", "MU"]
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
  
  def is_active?
    !['IN', 'TN'].include?(status)
  end
  
  def is_bridges?
    ['BR'].include?(strategy)
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
  
  def get_stat_for(date, people_group = nil)
    stat = nil
    if strategy == "BR" && people_group.blank?
      stat = get_bridges_stats_for(date)
    else
      sunday = date.traditional_beginning_of_week
      stat_rel = statistics.where("periodBegin = ?", sunday)
      stat_rel = stat_rel.where("peopleGroup = ?", people_group) if !people_group.blank?
      stat = stat_rel.first
      unless stat
        stat = Statistic.new
        stat.activity = self
        stat.periodBegin = sunday
        stat.periodEnd = sunday.traditional_end_of_week
        stat.prefill_semester_stats
      end
    end
    stat
  end
  
  def add_bookmark_for(user)
    Bookmark.add_activity_bookmark_for(user, self)
  end
  
  def get_bookmark_for(user)
    Bookmark.get_activity_bookmark_for(user, self)
  end
  
  private
  
  def get_bridges_stats_for(date)
    sunday = date.traditional_beginning_of_week
    stats = statistics.where("periodBegin = ?", sunday)
    stats_array = []
    Statistic.people_groups.each do |group|
      stat = stats.where(:peopleGroup => group).first
      unless stat
        stat = Statistic.new
        stat.activity = self
        stat.periodBegin = sunday
        stat.periodEnd = sunday.traditional_end_of_week
        stat.peopleGroup = group
        stat.prefill_semester_stats
      end
      stats_array << stat
    end
    stats_array
  end
  
  def convert_date(hash, date_symbol_or_string)
    attribute = date_symbol_or_string.to_s
    return Date.new(hash[attribute + '(1i)'].to_i, hash[attribute + '(2i)'].to_i, hash[attribute + '(3i)'].to_i)   
  end

end
