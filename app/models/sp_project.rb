begin
  require 'google_geocode'
rescue LoadError
end
require_dependency 'global_registry_methods'
require 'auto_strip_attributes'

class SpProject < ActiveRecord::Base
  include Sidekiq::Worker
  include GlobalRegistryMethods

  auto_strip_attributes :name, :city, :state, :country, :operating_business_unit, :operating_operating_unit, :operating_department,
                        :operating_project, :operating_designation, :scholarship_business_unit, :scholarship_operating_unit, :scholarship_department,
                        :scholarship_project, :scholarship_designation, :departure_city, :destination_city, :medical_clinic, :medical_clinic_location,
                        :project_contact_name, :project_contact_role, :project_contact_phone, :project_contact_email, :url, :url_title, :ds_project_code,
                        :facebook_url, :blog_url, :blog_title, :project_contact2_name, :project_contact2_role, :project_contact2_phone, :project_contact2_email

  has_attached_file :picture, :styles => { :medium => "500x300>", :thumb => "100x100>" },
    :storage => :s3,
    :s3_credentials => Rails.root.join("config/amazon_s3.yml"),
    :path => "sp/project/:attachment/:id/:filename"

  has_attached_file :logo, :styles => { :medium => "300x300>", :thumb => "100x100>" },
    :storage => :s3,
    :s3_protocol => 'https',
    :s3_credentials => Rails.root.join("config/amazon_s3.yml"),
    :path => "sp/project/:attachment/:id/:filename"

  validates_attachment_size :picture, :less_than => 1.megabyte, :message => "can't be more than 1MB"
  validates_attachment_size :logo, :less_than => 1.megabyte, :message => "can't be more than 1MB"
  #  image_accessor :picture
  #  image_accessor :logo

  # SP-298
  has_many :sp_designation_numbers

  belongs_to :created_by, :class_name => "::Person", :foreign_key => "created_by_id"
  belongs_to :updated_by, :class_name => "::Person", :foreign_key => "updated_by_id"

  belongs_to :basic_info_question_sheet, :class_name => "QuestionSheet", :foreign_key => "basic_info_question_sheet_id"
  belongs_to :template_question_sheet, :class_name => "QuestionSheet", :foreign_key => "template_question_sheet_id"
  belongs_to :project_specific_question_sheet, :class_name => "QuestionSheet", :foreign_key => "project_specific_question_sheet_id"

  has_many   :stats, :class_name => "SpStat", :foreign_key => "project_id"
  belongs_to :primary_ministry_focus, :class_name => 'SpMinistryFocus', :foreign_key => :primary_ministry_focus_id
  has_many :project_ministry_focuses, :class_name => 'SpProjectMinistryFocus', foreign_key: 'project_id'

  has_many :ministry_focuses, through: :project_ministry_focuses
  has_many :sp_staff, :class_name => "SpStaff", :foreign_key => "project_id"

  has_many :project_gospel_in_actions, :class_name => "SpProjectGospelInAction", :foreign_key => "project_id", :dependent => :destroy
  has_many :gospel_in_actions, :through => :project_gospel_in_actions

  has_many :student_quotes, :class_name => "SpStudentQuote", :foreign_key => "project_id", :dependent => :destroy
  accepts_nested_attributes_for :student_quotes, :reject_if => lambda { |a| a[:quote].blank? }, :allow_destroy => true

  has_many :sp_applications, :dependent => :nullify, :foreign_key => :project_id

  has_one :target_area, -> { where(:eventType => "SP") }, :foreign_key => :eventKeyID

  has_many :statistics, :finder_sql => proc { "select ministry_statistic.* from sp_projects " +
                                              'left join ministry_targetarea on sp_projects.id = ministry_targetarea.eventKeyID and eventType = "SP" ' +
                                              'left join ministry_activity on ministry_activity.fk_targetAreaID = ministry_targetarea.`targetAreaID` ' +
                                              'left join ministry_statistic on ministry_statistic.`fk_Activity` = ministry_activity.`ActivityID` ' +
                                              "where sp_projects.id = #{id} and ministry_statistic.sp_year is not null " +
  'order by periodBegin desc' }

  validates_presence_of :name, :display_location, :start_date, :end_date, :student_cost, :max_accepted_men, :max_accepted_women,
    :project_contact_name,
    :city, :country,
    :primary_partner, :report_stats_to

  # :project_contact_role, :project_contact_phone, :project_contact_email,
  #                         :project_contact2_name, :project_contact2_role, :project_contact2_phone, :project_contact2_email,
  #                         :staff_start_date, :staff_end_date,
  #
  validates_inclusion_of :use_provided_application, :partner_region_only, :in => [true, false], :message => "can't be blank"

  #
  validates_presence_of  :apply_by_date, :if => :use_provided_application
  validates_presence_of  :state, :if => Proc.new { |project| !project.is_wsn? } #:is_wsn?

  validates_inclusion_of :max_student_men_applicants, :in=>1..100, :message => "can't be 0 or greater than 100"
  validates_inclusion_of :max_student_women_applicants, :in=>0..100, :message => "can't be less than 0 or greater than 100"
  # validates_inclusion_of :ideal_staff_men, :in=>1..100, :message => "can't be 0 or greater than 100"
  # validates_inclusion_of :ideal_staff_women, :in=>0..100, :message => "can't be less than 0 or greater than 100"

  validates_uniqueness_of :name
  validate :validate_partnership

  scope :with_partner, proc {|partner| where(["primary_partner IN(?) OR secondary_partner IN(?) OR tertiary_partner IN(?)", partner, partner, partner])}
  scope :show_on_website, -> { where(:show_on_website => true, :project_status => 'open') }
  scope :uses_application, -> { where(:use_provided_application => true) }
  scope :current, -> { where("project_status = 'open' AND open_application_date <= ? AND start_date >= ?", Date.today, Date.today) }
  scope :open, -> { where("project_status = 'open'") }
  scope :ascend_by_name, -> { order(:name) }
  scope :descend_by_name, -> { order("name desc") }
  scope :ascend_by_pd, -> { order(Person.table_name + '.lastName, ' + Person.table_name + '.firstName').where('sp_staff.type' => 'PD').joins({:sp_staff => :person}) }
  scope :descend_by_pd, -> { order(Person.table_name + '.lastName desc, ' + Person.table_name + '.firstName desc').where('sp_staff.type' => 'PD').joins({:sp_staff => :person}) }
  scope :ascend_by_apd, -> { order(Person.table_name + '.lastName, ' + Person.table_name + '.firstName').where('sp_staff.type' => 'APD').joins({:sp_staff => :person}) }
  scope :descend_by_apd, -> { order(Person.table_name + '.lastName desc, ' + Person.table_name + '.firstName desc').where('sp_staff.type' => 'APD').joins({:sp_staff => :person}) }
  scope :ascend_by_opd, -> { order(Person.table_name + '.lastName, ' + Person.table_name + '.firstName').where('sp_staff.type' => 'OPD').joins({:sp_staff => :person}) }
  scope :descend_by_opd, -> { order(Person.table_name + '.lastName desc, ' + Person.table_name + '.firstName desc').where('sp_staff.type' => 'OPD').joins({:sp_staff => :person}) }
  scope :not_full_men, -> { where("current_students_men < max_accepted_men AND max_student_men_applicants > current_applicants_men") }
  scope :not_full_women, -> { where("current_students_women < max_accepted_women AND max_student_women_applicants > current_applicants_women") }
  scope :has_chart_field, -> { where("operating_business_unit is not null AND operating_business_unit <> '' AND operating_operating_unit is not null AND operating_operating_unit <> '' AND operating_department is not null AND operating_department <> ''") }
  scope :missing_chart_field, -> { where("operating_business_unit is null OR operating_business_unit = '' OR operating_operating_unit is null OR operating_operating_unit = '' OR operating_department is null OR operating_department = ''") }

  scope :pd_like, lambda {|name| where(Person.table_name + '.lastName LIKE ? OR ' + Person.table_name + '.firstName LIKE ?', "%#{name}%","%#{name}%").where('sp_staff.type' => 'PD').joins({:sp_staff => :person})}
  scope :apd_like, lambda {|name| where(Person.table_name + '.lastName LIKE ? OR ' + Person.table_name + '.firstName LIKE ?', "%#{name}%","%#{name}%").where('sp_staff.type' => 'APD').joins({:sp_staff => :person})}
  scope :opd_like, lambda {|name| where(Person.table_name + '.lastName LIKE ? OR ' + Person.table_name + '.firstName LIKE ?', "%#{name}%","%#{name}%").where('sp_staff.type' => 'OPD').joins(:sp_staff)}


  before_create :set_to_open
  before_save :get_coordinates, :calculate_weeks, :set_year

  begin
    date_setters :apply_by_date, :start_date, :end_date, :date_of_departure, :date_of_return, :staff_start_date, :staff_end_date, :pd_start_date, :pd_end_date,
      :pd_close_start_date, :pd_close_end_date, :student_staff_start_date, :student_staff_end_date, :open_application_date, :archive_project_date
  rescue NoMethodError
  end


  @@regions = {}

  def current?
    !!SpProject.current.find_by_id(id)
  end

  def gospel_in_aciton_ids=(ids)
    self.gospel_in_actions = SpGospelInAction.find(ids)
  end

  # Leadership
  def pd(yr = nil)
    yr ||= year
    @pd ||= {}
    @pd[yr] ||= sp_staff.where('sp_staff.year' => yr).detect {|s| s.type == 'PD'}.try(:person)
  end
  def apd(yr = nil)
    yr ||= year
    @apd ||= {}
    @apd[yr] ||= sp_staff.where('sp_staff.year' => yr).detect {|s| s.type == 'APD'}.try(:person)
  end
  def opd(yr = nil)
    yr ||= year
    @opd ||= {}
    @opd[yr] ||= sp_staff.where('sp_staff.year' => yr).detect {|s| s.type == 'OPD'}.try(:person)
  end
  def coordinator(yr = nil)
    yr ||= year
    @coordinator ||= {}
    @coordinator[yr] ||= sp_staff.where('sp_staff.year' => yr).detect {|s| s.type == 'Coordinator'}.try(:person)
  end
  def staff(yr = nil)
    yr ||= year
    @staff ||= {}
    @staff[yr] ||= Person.where(:personid => sp_staff.where('sp_staff.year' => yr).find_all {|s| s.type == 'Staff'}.collect(&:person_id)).
      includes(:current_address).
      order('lastName, firstName')
  end
  def volunteers(yr = nil)
    yr ||= year
    @volunteers ||= {}
    @volunteers[yr] ||= Person.where(:personid => sp_staff.where('sp_staff.year' => yr).find_all {|s| s.type == 'Volunteer'}.collect(&:person_id)).
      includes(:current_address).
      order('lastName, firstName')
  end
  def staff_and_volunteers(yr = nil)
    yr ||= year
    @volunteers ||= {}
    @volunteers[yr] ||= Person.where(:personid => sp_staff.where('sp_staff.year' => yr).find_all {|s| ['Volunteer', 'Staff'].include?(s.type)}.collect(&:person_id))
    .includes(:current_address)
    .order('lastName, firstName')
  end
  def kids(yr = nil)
    yr ||= year
    @kids ||= {}
    @kids[yr] ||= Person.where(:personid => sp_staff.where('sp_staff.year' => yr).find_all {|s| s.type == 'Kid'}.collect(&:person_id)).
      includes(:current_address).
      order('lastName, firstName')
  end

  def evaluators(yr = nil)
    yr ||= year
    @evaluators ||= {}
    @evaluators[yr] ||= Person.where(:personid => sp_staff.where('sp_staff.year' => yr).find_all {|s| s.type == 'Evaluator'}.collect(&:person_id)).
      includes(:current_address).
      order('lastName, firstName')
  end

  def non_app_participants(yr = nil)
    yr ||= year
    @non_app_participants ||= {}
    @non_app_participants[yr] ||= Person.where(:personid => sp_staff.where('sp_staff.year' => yr).find_all {|s| s.type == 'Non App Participant'}.collect(&:person_id)).
      includes(:current_address).
      order('lastName, firstName')
  end

  def pd=(person_id, yr = nil)
    yr ||= year
    sp_staff.where('sp_staff.year' => yr, 'sp_staff.type' => 'PD').first.try(:destroy)
    sp_staff.create(:year => yr, :type => 'PD', :person_id => person_id) if person_id
  end

  def apd=(person_id, yr = nil)
    yr ||= year
    sp_staff.where('sp_staff.year' => yr, 'sp_staff.type' => 'APD').first.try(:destroy)
    sp_staff.create(:year => yr, :type => 'APD', :person_id => person_id) if person_id
  end

  def opd=(person_id, yr = nil)
    yr ||= year
    sp_staff.where('sp_staff.year' => yr, 'sp_staff.type' => 'OPD').first.try(:destroy)
    sp_staff.create(:year => yr, :type => 'OPD', :person_id => person_id) if person_id
  end

  def coordinator=(person_id, yr = nil)
    yr ||= year
    sp_staff.where('sp_staff.year' => yr, 'sp_staff.type' => 'Coordinator').first.try(:destroy)
    sp_staff.create(:year => yr, :type => 'Coordinator', :person_id => person_id) if person_id
  end

  def validate_partnership
    if partner_region_only && (primary_partner.length != 2 && secondary_partner.length != 2)
      errors.add_to_base("You must choose a regional partnership if you want to accept from Partner Region only.")
    end
  end

  def close!
    update_attribute('project_status', 'closed')
  end
  def open!
    update_attribute('project_status', 'open')
    update_attribute('year', SpApplication.year)
  end

  def closed?
    project_status == 'closed'
  end

  def open?
    !closed?
  end

  def url=(val)
    super
    # We allow the user to enter a free-form url. I want to make sure it gets saved
    # with an http:// on it.
    if val && !val.strip.empty? && !(/^http/ =~ val)
      self[:url] = "http://" + val
    end
  end

  def set_to_open
    self[:project_status] = 'open'
  end

  def calculate_weeks
    if start_date && end_date
      self[:weeks] = ((end_date.to_time - start_date.to_time) / 1.week).round
    end
    true
  end

  def set_year
    if start_date
      self.year = start_date.month >= 9 ? start_date.year + 1 : start_date.year
    end
  end

  def is_wsn?
    return country != 'United States'
  end

  # helper methods for xml feed
  def percent_full
    capacity.to_f > 0 ? (accepted_count.to_f / capacity.to_f) * 100 : 0
  end

  def percent_full_women
    max_accepted_women.to_i > 0 ? current_students_women / max_accepted_women.to_f * 100 : 0
  end

  def percent_full_men
    max_accepted_men.to_i > 0 ? current_students_men / max_accepted_men.to_f * 100 : 0
  end

  def contact
    pd || apd || opd || coordinator
  end

  def color
    case true
    when percent_full < 50
      'green'
    when percent_full < 100
      'yellow'
    else
      'red'
    end
  end

  def international
    country.present? && country != 'United States' ? 'Yes' : 'No'
  end
  alias_method :international?, :international

  def pd_name_non_secure
    pd.informal_full_name if pd
  end

  def pd_name
    pd_name_non_secure if (country_status == 'open' && pd && !pd.is_secure?)
  end

  def apd_name_non_secure
    apd.informal_full_name if apd
  end

  def apd_name
    apd_name_non_secure if (country_status == 'open' && apd && !apd.is_secure?)
  end

  def pd_email_non_secure
    pd.current_address.email if pd && pd.current_address
  end

  def pd_email
    pd_email_non_secure if (country_status == 'open' && pd && !pd.is_secure?)
  end

  def apd_email_non_secure
    apd.current_address.email if apd && apd.current_address
  end

  def apd_email
    apd_email_non_secure if (country_status == 'open' && apd && !apd.is_secure?)
  end

  def primary_focus_name
    primary_ministry_focus.name if primary_ministry_focus
  end

  def regional_info
    if primary_partner && region = SpProject.get_region(primary_partner)
      info =  region.name + ' Regional Office: Phone - ' + region.sp_phone
      info += ', Email - ' + region.email if region.email && !region.email.empty?
      info
    end
  end

  def self.get_region(region)
    @@regions[region] ||= Region.find_by_region(region)
  end

  def country_status
    @country_status ||=
      begin
        country = Country.find_by_country(self.country)
        country && country.closed? ? 'closed' : 'open'
      end
  end

  def update_counts(person)
    if person.gender.present?
      count = SpApplication.connection.select_value("SELECT count(*) from sp_applications a inner join ministry_person p on a.person_id = p.personID where year = #{year} AND status IN('#{SpApplication.ready_statuses.join("','")}') AND p.gender = #{person.gender} AND a.project_id = #{id}")
      if person.is_male?
        self.current_applicants_men = count
      else
        self.current_applicants_women = count
      end
      count = SpApplication.connection.select_value("SELECT count(*) from sp_applications a inner join ministry_person p on a.person_id = p.personID where year = #{year} AND status IN('#{SpApplication.accepted_statuses.join("','")}') AND p.gender = #{person.gender} AND a.project_id = #{id}")
      if person.is_male?
        self.current_students_men = count
      else
        self.current_students_women = count
      end
    end
    save(:validate => false)
    count
  end

  def self.send_leader_reminder_emails
    projects = SpProject.find(:all,
                              :select => "project.*",
                              :conditions => ["app.status IN(?) and app.year = ? and project.start_date > ?", SpApplication.ready_statuses, SpApplication.year, Time.now],
                              :joins => "as project inner join sp_applications app on (app.current_project_queue_id = project.id)",
                              :group => "project.id")
    projects.each do |project|
      if (project.pd || project.apd)
        SpProjectMailer.deliver_leader_reminder(project)
      end
    end
  end

  def self.send_stats_reminder_emails
    campus_ministry_types = ['Campus Ministry - US summer project', 'Campus Ministry - Global Missions summer project']
    projects = SpProject.find(:all,
                              :select => "project.*, stat.id as stat_id",
                              :conditions => ["project.report_stats_to in (?) and project.project_status = ?", campus_ministry_types, 'open'],
                              :joins => "as project left join sp_stats stat on (stat.project_id = project.id and stat.year = project.year)")
    #at some point, may also need to search SpProjectVersions

    projects.each do |project|
      date_to_start = Time.parse('8/15/' + project.year.to_s)
      if (Time.now > date_to_start && project.stat_id.nil?)
        if (project.pd && project.pd.email_address)
          SpProjectMailer.deliver_stats_reminder(project)
        end
      end
    end
  end

  def to_s
    name
  end

  # This method uses google geocodes to get longitude/latitude coordinates for
  # a project.
  # http://maps.google.com/maps/geo?q=orlando,FL&output=xml&key=ABQIAAAA3_Rt6DOXqoqzxOdrpwwtvhSTzVfmYDnwpEGk65AEA3VA32K1ZBTjPtznyT3qg_teDdJYQqkNfMwI7w
  def get_coordinates
    if self.country_status == 'closed'
      self.latitude = nil
      self.longitude = nil
    else
      key = 'ABQIAAAA3_Rt6DOXqoqzxOdrpwwtvhSTzVfmYDnwpEGk65AEA3VA32K1ZBTjPtznyT3qg_teDdJYQqkNfMwI7w'
      q = self.city || ''
      q += ','+self.state if self.state
      q += ','+self.country
      q.gsub!(' ','+')
      gg = GoogleGeocode.new key
      begin
        location = gg.locate q
        self.latitude = location.coordinates[0]
        self.longitude = location.coordinates[1]
        # We need to make sure that that no 2 projects have exactly the same
        # coordinates. If they do, they will overlap on the flash map and
        # you won't be able to click on one of them.
        while SpProject.find(:first, :conditions => ['latitude = ? and longitude = ?', self.latitude, self.longitude])
          delta_longitude, delta_latitude = 0,0
          delta_longitude = rand(6) - 3 while delta_longitude.abs < 2
          delta_latitude = rand(6) - 3 while delta_latitude.abs < 2
          # move it over a little.
          self.longitude += delta_longitude.to_f/10
          self.latitude += delta_latitude.to_f/10
        end
      rescue GoogleGeocode::AddressError
      rescue
      end
    end
    true
  end

  def get_previous_year_records(version)
    versions = SpProjectVersion.find(:all, :conditions => ['sp_project_id = ? AND id IN (' + SpProject.build_search_project_id_string + ')', self.id], :order => :year)
    versions.reverse
  end

  def self.build_search_project_id_string
    string = ""
    query = "select max(id) as id from sp_project_versions group by sp_project_id, year order by max(id)"
    conn = SpProjectVersion.connection
    results = conn.select_all(query)
    results.each do |result|
      string += result["id"] + ", "
    end
    string.chomp(", ")
  end

  def capacity
    max_accepted_men.to_i + max_accepted_women.to_i
  end

  def accepted_count
    current_students_men.to_i + current_students_women.to_i
  end

  def male_applicants_count(yr = nil)
    yr ||= year
    yr == year ? current_applicants_men : sp_applications.applicant.male.for_year(yr).count
  end

  def female_applicants_count(yr = nil)
    yr ||= year
    yr == year ? current_applicants_women : sp_applications.applicant.female.for_year(yr).count
  end

  def male_accepted_count(yr = nil)
    yr ||= year
    yr == year ? current_students_men : sp_applications.accepted.male.for_year(yr).count
  end

  def female_accepted_count(yr = nil)
    yr ||= year
    yr == year ? current_students_women : sp_applications.accepted.female.for_year(yr).count
  end

  def initialize_project_specific_question_sheet
    unless project_specific_question_sheet
      update_attribute(:project_specific_question_sheet_id, QuestionSheet.where(label: 'Project - ' + self.to_s).first_or_create.id)
    end
    if project_specific_question_sheet.pages.length == 0
      project_specific_question_sheet.pages.create!(:label => 'Project Specific Questions', :number => 1)
    end
    project_specific_question_sheet
  end

  def self.skip_fields_for_gr
    %w[id global_registry_id]
  end

  def self.global_registry_entity_type_name
    'summer_project'
  end

end
