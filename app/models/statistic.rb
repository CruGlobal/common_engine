class Statistic < ActiveRecord::Base
  unloadable
  set_table_name "ministry_statistic"
  set_primary_key "StatisticID"
  belongs_to :activity, :foreign_key => "fk_Activity"
  
  validates_numericality_of :evangelisticOneOnOne, :evangelisticGroup, :exposuresViaMedia, :holySpiritConversations, 
    :decisionsHelpedByOneOnOne, :decisionsHelpedByGroup, :decisionsHelpedByMedia, :laborersSent, 
    :multipliers, :studentLeaders, :invldStudents, :ongoingEvangReln, :only_integer => true, :allow_nil => true
    
  validates_presence_of :peopleGroup, :if => Proc.new { |stat| stat.activity.strategy == "BR" }
  
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
  
  def self.weekly_stats
    ["personal_exposures", "group_exposures", "media_exposures", "holy_spirit_presentations", "personal_decisions", "group_decisions", "media_decisions", "laborers_sent"]
  end
  
  def self.semester_stats
    ["multipliers", "student_leaders", "students_involved", "seekers"]
  end
  
  def self.people_groups
    ["(Other Internationals)", "East Asian", "Ishmael Project", "Japanese", "South Asian"]
  end
  
  def self.uses_seekers
    ["BR"]
  end
  
  def prefill_semester_stats
    prev_stat = get_previous_stat
    if prev_stat
      Statistic.semester_stats.each do |field|
        self[field] = prev_stat[field]
      end
    end
  end
  
  # Don't save if everything is nil
  # TODO: add updated_by info
  def save
    attribs = attributes.clone
    
    # Don't care about these attributes
    attribs.delete("periodBegin")
    attribs.delete("periodEnd")
    attribs.delete("fk_Activity")
    attribs.delete("peopleGroup")
    
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