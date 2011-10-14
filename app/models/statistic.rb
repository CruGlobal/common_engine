class Statistic < ActiveRecord::Base
  unloadable
  set_table_name "ministry_statistic"
  set_primary_key "StatisticID"
  belongs_to :activity, :foreign_key => "fk_Activity"
  
  validates_numericality_of :evangelisticOneOnOne, :evangelisticGroup, :exposuresViaMedia, :holySpiritConversations, 
    :decisionsHelpedByOneOnOne, :decisionsHelpedByGroup, :decisionsHelpedByMedia, :laborersSent, 
    :multipliers, :studentLeaders, :invldStudents, :ongoingEvangReln, :dollars_raised, :only_integer => true, :allow_nil => true
    
  validates_presence_of :peopleGroup, :if => Proc.new { |stat| stat.activity.strategy == "BR" if stat.activity }
  
  alias_attribute :personal_exposures, :evangelisticOneOnOne
  alias_attribute :group_exposures, :evangelisticGroup
  alias_attribute :media_exposures, :exposuresViaMedia
  alias_attribute :holy_spirit_presentations, :holySpiritConversations
  alias_attribute :personal_decisions, :decisionsHelpedByOneOnOne
  alias_attribute :group_decisions, :decisionsHelpedByGroup
  alias_attribute :media_decisions, :decisionsHelpedByMedia
  alias_attribute :laborers_sent, :laborersSent
  alias_attribute :student_leaders, :studentLeaders
  alias_attribute :students_involved, :invldStudents
  alias_attribute :seekers, :ongoingEvangReln
  
  #Scopes
  def self.before_date(date)
    where(Statistic.table_name + ".periodEnd <= ?", date)
  end
  
  def self.after_date(date)
    where(Statistic.table_name + ".periodBegin >= ?", date)
  end
  
  def self.between_dates(from_date, to_date)
    after_date(from_date).before_date(to_date)
  end
  
  #Constants
  def self.weekly_stats # Order matters! Reports rely on correct order,
    ["evangelisticOneOnOne", "decisionsHelpedByOneOnOne", "evangelisticGroup", "decisionsHelpedByGroup", "exposuresViaMedia", "decisionsHelpedByMedia", "holySpiritConversations", "laborersSent"]
  end
  
  def self.semester_stats # Order matters! Reports rely on correct order,
    ["invldStudents", "multipliers", "studentLeaders", "ongoingEvangReln"]
  end
  
  def self.all_stats
    Statistic.weekly_stats + Statistic.semester_stats + ["dollars_raised"]
  end
  
  def self.event_stats
    Statistic.weekly_stats + ["invldStudents", "dollars_raised"]
  end
  
  def self.people_groups
    ["(Other Internationals)", "East Asian", "Ishmael Project", "Japanese", "South Asian"]
  end
  
  def self.uses_seekers
    ["BR"]
  end
  
  #Instance Methods
  def prefill_semester_stats
    prev_stat = get_previous_stat
    if prev_stat
      Statistic.semester_stats.each do |field|
        self[field] = prev_stat[field]
      end
    end
  end
  
  def add_stats(new_stat)
    Statistic.event_stats.each do |stat|
      old_stat = self[stat] || 0
      self[stat] = old_stat + new_stat[stat].to_i
      if self[stat] == 0
        self[stat] = nil
      end
    end
  end
  
  # Don't save if everything is nil
  def save
    attribs = attributes.clone
    
    # Don't care about these attributes
    attribs.delete("periodBegin")
    attribs.delete("periodEnd")
    attribs.delete("fk_Activity")
    attribs.delete("peopleGroup")
    attribs.delete("updated_by")
    
    # Need to compare the semester/quarter stats to previous stat record
    prev_stat = get_previous_stat
    changed = false
    if prev_stat
      Statistic.semester_stats.each do |field|
        changed = changed || self[field] != prev_stat[field]
        attribs.delete(field)
      end
    end
    
    values = attribs.values.compact
    if !values.empty? || changed
      super
    end
  end
  
  # Will return nil if there isn't a previous stat
  def get_previous_stat
    result = nil
    stats = activity.statistics
    if activity.strategy == "BR"
      stats = stats.where(:peopleGroup => peopleGroup)
    end
    index = stats.index(self)
    if index == nil
      result = stats.last
    elsif index > 0
      result = stats[index - 1]
    end
  end
end