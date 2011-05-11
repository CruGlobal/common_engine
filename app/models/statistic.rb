class Statistic < ActiveRecord::Base
  unloadable
  set_table_name "ministry_statistic"
  set_primary_key "StatisticID"
  belongs_to :activity, :foreign_key => "fk_Activity"
  
  validates_numericality_of :evangelisticOneOnOne, :evangelisticGroup, :exposuresViaMedia, :holySpiritConversations, 
    :decisionsHelpedByOneOnOne, :decisionsHelpedByGroup, :decisionsHelpedByMedia, :laborersSent, 
    :multipliers, :studentLeaders, :invldStudents, :ongoingEvangReln, :only_integer => true, :allow_nil => true
    
  validates_presence_of :peopleGroup, :if => Proc.new { |stat| stat.activity.strategy == "BR" }
  
  def self.semester_stats
    ["multipliers", "studentLeaders", "invldStudents", "ongoingEvangReln"]
  end
  
  def self.people_groups
    ["(Other Internationals)", "East Asian", "Ishmael Project", "Japanese", "South Asian"]
  end
  
  def self.uses_seekers
    ["BR"]
  end
  
  def seekers
    ongoingEvangReln
  end
  
  def seekers=(seekers)
    ongoingEvangReln = seekers
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