class Activity < ActiveRecord::Base
  self.table_name = "ministry_activity"
  self.primary_key = "ActivityID"
  belongs_to :target_area, :foreign_key => "fk_targetAreaID", :primary_key => "targetAreaID"
  belongs_to :team, :foreign_key => "fk_teamID", :primary_key => "teamID"
  has_many :activity_histories
  has_many :statistics, -> { order :periodBegin }, :foreign_key => "fk_Activity"
  has_many :last_fifteen_stats, -> { where("periodBegin > '#{(Date.today - 15.weeks).to_s(:db)}'").order(:periodBegin) },
    :class_name => "Statistic", :foreign_key => "fk_Activity"
  has_and_belongs_to_many :contacts, :join_table => "ministry_movement_contact", 
    :foreign_key => "ActivityID", :association_foreign_key => "personID", :class_name => "Person"
    
  validates_presence_of :status, :strategy, :periodBegin, :fk_targetAreaID, :fk_teamID
    
  scope :inactive, -> { where("status = 'IN'") }
  scope :active, -> { where("status NOT IN ('IN', 'TN')") }
  scope :strategy, lambda {|strategy| where("strategy = ?", strategy)}
  
  def self.strategies
    {
      "FS" => "Campus Field Ministry",
      "AA" => "Athletes In Action",
      "BR" => "Bridges",
      "SV" => "Cru High School",
      "ID" => "Destino", 
      "IC" => "Ethnic Field Ministry",
      "IE" => "Epic",
      "EV" => "Events",
      "FC" => "Faculty Commons",
      "FD" => "Fund Development",
      "WS" => "Global Missions",
      "GK" => "Greek",
      "II" => "Impact",
      "KN" => "Keynote",
      "KC" => "Korea CCC",
      "HR" => "Leadership Development",
      "ND" => "National",
      "IN" => "Nations",
      "OP" => "Operations",
      "SA" => "SALT",
      "VL" => "Valor",
      "OT" => "Other"
    }
  end
  
  def self.bridges
    "BR"
  end
  
  def self.strategies_translations
    {
      "FS" => "CFM",
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
      "SA" => "SA",
      "SV" => "SV",
      "EV" => "EV",
      "OT" => "OT",
    }
  end
  
  def self.event_strategies
    result = strategies.clone
    result.delete("IC")
    result.delete("FD")
    result.delete("HR")
    result.delete("OP")
    result.delete("ND")
    result    
  end
  
  def self.visible_strategies
    result = event_strategies.clone
    result.delete("EV")
    result
  end
  
  def self.visible_team_strategies
    result = strategies.clone
    result.delete("EV")
    result
  end
  
  def self.crs_strategies
    {
      "USCM" => "EV",
      "Bridges" => "BR",
      "CCCI" => "OT",
      "StudentVenture" => "SV",
      "Other" => "OT"
    }
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
    result = wsn_statuses.clone
    result.delete("TN")
    result
  end
  
  def self.wsn_statuses
    result = statuses.clone
    result.delete("FR")
    result.delete("AC")
    result.delete("TR")
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
    unless activity
      activity = Activity.new(:strategy => strategy)
      activity.target_area = target_area
    end
    activity
  end
  
  def self.movement_for_event(target_area, period_begin, strategy = "EV")
    activity = Activity.where("fk_targetAreaID = ?", target_area.targetAreaID).first
    unless activity
      activity = Activity.create_movement_for_event(target_area, period_begin, strategy)
    end
    activity.strategy = strategy
    activity.save
    activity
  end
  
  def self.create_movement_for_event(target_area, period_begin, strategy = "EV")
    activity = Activity.new(:strategy => strategy, :periodBegin => period_begin, :fk_teamID => 0)
    activity.status = "IN"
    activity.target_area = target_area
    activity.save!
    activity    
  end
  
  def self.interpret_strategy_from_crs(strategy)
    crs_strategies[strategy]
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
    stat
  end
  
  def get_stats_for_dates(begin_date, end_date, people_group = nil)
    stats = nil
    start_date = begin_date.traditional_beginning_of_week
    ending_date = end_date.traditional_end_of_week
    stat_rel = statistics.where("periodBegin >= ? AND periodEnd <= ?", start_date, ending_date)
    stats = stat_rel.load
    stats
  end
  
  def get_sp_stat_for(year, period_begin, period_end, people_group = nil)
    stat = nil
    stat_rel = statistics.where("sp_year = ?", year)
    stat_rel = stat_rel.where("peopleGroup = ?", people_group) if !people_group.blank?
    stat = stat_rel.first
    unless stat
      stat = Statistic.new
      stat.activity = self
    end
    stat.periodBegin = period_begin
    stat.periodEnd = period_end
    stat.sp_year = year
    stat
  end
  
  def get_crs_stat_for(period_begin, period_end, people_group = nil) # TODO: people groups
    if statistics.size > 1
      raise "Too many stats for this Conference"
    else
      stat = statistics.first
      unless stat
        stat = Statistic.new
        stat.activity = self
      end
      stat.periodBegin = period_begin
      stat.periodEnd = period_end
    end
    stat
  end
  
  def get_event_stat_for(period_begin, period_end, people_group = nil) # TODO: people groups
    stat = nil
    if target_area.eventType == TargetArea.other_conference
      stat = get_crs_stat_for(period_begin, period_end, people_group)
    else
      stat = statistics.where("periodEnd = ?", period_end).first
    end
    unless stat
      stat = Statistic.new
      stat.activity = self
    end
    stat.periodBegin = period_begin
    stat.periodEnd = period_end
    stat
  end
  
  def get_activity_history_for_date(date)
    # Find correct date
    max_date = activity_histories.where("period_begin <= ?", date).maximum(:period_begin)
    result = activity_histories.where("period_begin = ?", max_date).first
  end
  
  def add_bookmark_for(user)
    Bookmark.add_activity_bookmark_for(user, self)
  end
  
  def get_bookmark_for(user)
    Bookmark.get_activity_bookmark_for(user, self)
  end
  
  private
  
  def convert_date(hash, date_symbol_or_string)
    attribute = date_symbol_or_string.to_s
    return Date.new(hash[attribute + '(1i)'].to_i, hash[attribute + '(2i)'].to_i, hash[attribute + '(3i)'].to_i)   
  end

end
