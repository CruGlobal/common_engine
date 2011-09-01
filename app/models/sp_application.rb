require 'digest/md5'
class SpApplication < AnswerSheet
  set_table_name 'sp_applications'
  COST_BEFORE_DEADLINE = 25
  COST_AFTER_DEADLINE = 25
  
  unloadable
  acts_as_state_machine :initial => :started, :column => :status

  # State machine stuff
  state :started
  state :submitted, :enter => Proc.new {|app|
                                # SpApplicationMailer.deliver_submitted(app)
                                Notifier.notification(app.email, # RECIPIENTS
                                  Questionnaire.from_email, # FROM
                                  "Application Submitted").deliver # LIQUID TEMPLATE NAME
                                app.submitted_at = Time.now
                                app.previous_status = app.status
                              }

  state :ready, :enter => Proc.new {|app|
                                logger.info("application #{app.id} ready")
                                app.completed_at = Time.now
                                Notifier.notification(app.email, # RECIPIENTS
                                  Questionnaire.from_email, # FROM
                                  "Application Completed").deliver # LIQUID TEMPLATE NAME
                                app.previous_status = app.status
                              }

  state :unsubmitted, :enter => Proc.new {|app|
                                Notifier.notification(app.email, # RECIPIENTS
                                  Questionnaire.from_email, # FROM
                                  "Application Unsubmitted").deliver # LIQUID TEMPLATE NAME
                                app.previous_status = app.status
                              }

  state :withdrawn, :enter => Proc.new {|app|
                                logger.info("application #{app.id} withdrawn")
                                Notifier.notification(app.email, # RECIPIENTS
                                  Questionnaire.from_email, # FROM
                                  "Application Withdrawn").deliver if app.email
                                app.withdrawn_at = Time.now
                                app.previous_status = app.status
                              }

  state :accepted_as_student_staff, :enter => Proc.new {|app|
                                logger.info("application #{app.id} accepted as student staff")
                                app.accepted_at = Time.now
                                app.previous_status = app.status
                             }

  state :accepted_as_participant, :enter => Proc.new {|app|
                                logger.info("application #{app.id} accepted as participant")
                                app.accepted_at = Time.now
                                app.previous_status = app.status
                             }

  state :declined, :enter => Proc.new {|app|
                                logger.info("application #{app.id} declined")
                                app.previous_status = app.status
                             }

  event :submit do
    transitions :to => :submitted, :from => :started
    transitions :to => :submitted, :from => :unsubmitted
    transitions :to => :submitted, :from => :withdrawn
    transitions :to => :submitted, :from => :ready
  end

  event :withdraw do
    transitions :to => :withdrawn, :from => :started
    transitions :to => :withdrawn, :from => :submitted
    transitions :to => :withdrawn, :from => :ready
    transitions :to => :withdrawn, :from => :unsubmitted
    transitions :to => :withdrawn, :from => :declined
    transitions :to => :withdrawn, :from => :accepted_as_student_staff
    transitions :to => :withdrawn, :from => :accepted_as_participant
  end

  event :unsubmit do
    transitions :to => :unsubmitted, :from => :submitted
    transitions :to => :unsubmitted, :from => :withdrawn
    transitions :to => :unsubmitted, :from => :ready
  end

  event :complete do
    transitions :to => :ready, :from => :submitted
    transitions :to => :ready, :from => :unsubmitted
    transitions :to => :ready, :from => :started
    transitions :to => :ready, :from => :withdrawn
    transitions :to => :ready, :from => :declined
    transitions :to => :ready, :from => :accepted_as_student_staff
    transitions :to => :ready, :from => :accepted_as_participant
  end

  event :accept_as_student_staff do
    transitions :to => :accepted_as_student_staff, :from => :ready
    transitions :to => :accepted_as_student_staff, :from => :started
    transitions :to => :accepted_as_student_staff, :from => :withdrawn
    transitions :to => :accepted_as_student_staff, :from => :declined
    transitions :to => :accepted_as_student_staff, :from => :submitted
    transitions :to => :accepted_as_student_staff, :from => :accepted_as_participant
  end

  event :accept_as_participant do
    transitions :to => :accepted_as_participant, :from => :ready
    transitions :to => :accepted_as_participant, :from => :started
    transitions :to => :accepted_as_participant, :from => :withdrawn
    transitions :to => :accepted_as_participant, :from => :declined
    transitions :to => :accepted_as_participant, :from => :submitted
    transitions :to => :accepted_as_participant, :from => :accepted_as_student_staff
  end

  event :decline do
    transitions :to => :declined, :from => :started
    transitions :to => :declined, :from => :submitted
    transitions :to => :declined, :from => :ready
    transitions :to => :declined, :from => :accepted_as_student_staff
    transitions :to => :declined, :from => :accepted_as_participant
  end

  belongs_to :person
  belongs_to :project, :class_name => 'SpProject', :foreign_key => :project_id
  has_many :sp_references, :class_name => 'ReferenceSheet', :foreign_key => :applicant_answer_sheet_id, :dependent => :destroy
  # has_one :sp_peer_reference, :class_name => 'SpPeerReference', :foreign_key => :application_id
  # has_one :sp_spiritual_reference1, :class_name => 'SpSpiritualReference1', :foreign_key => :application_id
  # has_one :sp_spiritual_reference2, :class_name => 'SpSpiritualReference2', :foreign_key => :application_id
  # has_one :sp_parent_reference, :class_name => 'SpParentReference', :foreign_key => :application_id
  has_many :payments, :class_name => "SpPayment", :foreign_key => "application_id"
  has_many :answers, :class_name => 'Answer', :foreign_key => 'answer_sheet_id', :dependent => :destroy
  has_many :donations, :class_name => "SpDonation", :foreign_key => "designation_number", :primary_key => "designation_number", :order => 'donation_date desc'
  belongs_to :preference1, :class_name => 'SpProject', :foreign_key => :preference1_id
  belongs_to :preference2, :class_name => 'SpProject', :foreign_key => :preference2_id
  belongs_to :preference3, :class_name => 'SpProject', :foreign_key => :preference3_id
  belongs_to :preference4, :class_name => 'SpProject', :foreign_key => :preference4_id
  belongs_to :preference5, :class_name => 'SpProject', :foreign_key => :preference5_id
  belongs_to :current_project_queue, :class_name => 'SpProject', :foreign_key => :current_project_queue_id
  # has_many :answers, :foreign_key => :instance_id  do
  #   def by_question_id(q_id)
  #     self.detect {|a| a.question_id == q_id}
  #   end
  # end
  has_one :evaluation, :class_name => 'SpEvaluation', :foreign_key => :application_id
  
  scope :for_year, proc {|year| {:conditions => {:year => year}}}
  scope :preferrenced_project, proc {|project_id| {:conditions => ["project_id = ? OR preference1_id = ? OR preference2_id = ? OR preference3_id = ?", project_id, project_id, project_id, project_id]}}

  scope :preferred_project, proc {|project_id| {:conditions => ["project_id = ?", project_id], 
                                                      :include => :person }}
  before_create :set_su_code
  after_save :unsubmit_on_project_change, :complete, :send_acceptance_email, :update_project_counts

  def validates
    if ((status == 'accepted_as_student_staff' || status == 'accepted_as_participant') && project_id.nil?)
      errors.add_to_base("You must specify which project you are accepting this applicant to.")
    end
  end

  YEAR = 2012
  
  DEADLINE1 = Time.parse((SpApplication::YEAR - 1).to_s + "/12/10");
  DEADLINE2 = Time.parse(SpApplication::YEAR.to_s + "/01/24");
  DEADLINE3 = Time.parse(SpApplication::YEAR.to_s + "/02/24");

  def name
    person.try(:informal_full_name)
  end
  
  def phone
    person.try(:current_address).try(:homePhone)
  end
  
  def deadline_met
    if completed_at
      if completed_at < DEADLINE1 + 1.day
        return 1
      end
      if completed_at < DEADLINE2 + 1.day
        return 2
      end
      if completed_at < DEADLINE3 + 1.day
        return 3
      end
    end
    return 0
  end
  
  def project_cost
    project.student_cost if project
  end

  # The statuses that mean an application has NOT been submitted
  def self.unsubmitted_statuses
    %w(started unsubmitted)
  end

  # The statuses that mean an applicant is NOT ready to evaluate
  def self.not_ready_statuses
    %w(submitted)
  end

  # The statuses that mean an applicant is NOT going
  def self.not_going_statuses
    %w(withdrawn declined)
  end

  # The statuses that mean an applicant IS ready to evaluate
  def self.ready_statuses
    %w(ready)
  end
  
  def self.accepted_statuses
    %w(accepted_as_student_staff accepted_as_participant)
  end

  def self.applied_statuses
    SpApplication.ready_statuses | SpApplication.accepted_statuses
  end
  
  # The statuses that mean an applicant's application is not ready, but still in progress
  def self.uncompleted_statuses
    %w(started submitted unsubmitted)
  end

  def self.statuses
    SpApplication.unsubmitted_statuses | SpApplication.not_ready_statuses | SpApplication.ready_statuses | SpApplication.accepted_statuses | SpApplication.not_going_statuses
  end
  
  scope :accepted, where('sp_applications.status' => SpApplication.accepted_statuses)
  scope :accepted_participants, where('sp_applications.status' => 'accepted_as_participant')
  scope :accepted_student_staff, where('sp_applications.status' => 'accepted_as_student_staff')
  scope :ready_to_evaluate, where('sp_applications.status' => SpApplication.ready_statuses)
  scope :submitted, where('sp_applications.status' => SpApplication.not_ready_statuses)
  scope :not_submitted, where('sp_applications.status' => SpApplication.unsubmitted_statuses)
  scope :not_going, where('sp_applications.status' => SpApplication.not_going_statuses)
  scope :applicant, where('sp_applications.status' => SpApplication.applied_statuses)
  
  scope :male, where('ministry_person.gender = 1').includes(:person)
  scope :female, where('ministry_person.gender <> 1').includes(:person)
  
  delegate :campus, :to => :person

  def self.cost
    if Time.now < payment_deadline
      return COST_BEFORE_DEADLINE
    else
      return COST_AFTER_DEADLINE
    end
  end
  
  
  def self.payment_deadline
    Time.parse("#{SpApplication::YEAR.to_s}-02-25 03:00")
  end

  def has_paid?
    return true if self.payments.detect(&:approved?)
    return true unless question_sheets.collect(&:questions).flatten.detect {|q| q.is_a?(PaymentQuestion) && q.required?}
    return false
  end

  def accepted?
    SpApplication.accepted_statuses.include?(status)
  end

  def paid_at
    self.payments.each do |payment|
      return payment.updated_at if payment.approved?
    end
    return nil
  end
  
  def waive_fee!
    self.payments.create!(:status => "Approved", :payment_type => 'Waived')
    self.complete #Check to see if application is complete
  end

  def self.questionnaire()
    @@questionnaire ||= Questionnaire.find_by_id(1, :include => :pages, :order => 'sp_questionnaire_pages.position')
  end

  def complete(ref = nil)
    return false unless self.submitted?
    # Make sure all required references are copmleted
    sp_references.each do |reference|
      if reference.required?
        return false  unless reference.completed? || reference == ref
      end
    end
    return false unless self.has_paid?
    return self.complete!
  end

  def set_su_code
    self.su_code = Digest::MD5.hexdigest((object_id + Time.now.to_i).to_s)
  end

  # The :frozen? method lets the QuestionnaireEngine know to not allow
  # the user to change the answer to a question.
  def frozen?
    !%w(started unsubmitted).include?(self.status)
  end

  def can_change_references?
    %w(started unsubmitted submitted).include?(self.status)
  end

  def available_date
    @available_date ||= get_answer(53)
  end

  def available_date=(val)
    save_answer(53, val)
  end

  def return_date
    @return_date ||= get_answer(54)
  end

  def return_date=(val)
    save_answer(54, val)
  end

  def check_email_frequency
    @check_email_frequency ||= get_answer(33)
  end

  def communication_preference
    @communication_preference ||= get_answer(34)
  end

  def health_insurance
    @health_insurance ||= get_answer(248)
  end

  def insurance_provider
    @insurance_provider ||= get_answer(249)
  end

  def insurance_policy_number
    @insurance_policy_number ||= get_answer(250)
  end

  def continuing_school?
    @continuing_school ||= is_true(get_answer(57)) ? "Yes" : "No"
  end
  
  def has_passport?
    @has_passport ||= is_true(get_answer(409)) ? "Yes" : "No"
  end

  def activities_on_campus
    @activities_on_campus ||= Element.find(65)
  end

  def ministries_on_campus
    @ministries_on_campus ||= Element.find(68)
  end
  
  def applying_for_internship
    @applying_for_internship ||= Element.find(98)
  end

  def willing_for_other_projects
    @willing_for_other_projects ||= Element.find(88)
  end

  def willing_for_other_projects_answer
    is_true(get_answer(88))
  end

  def willing_for_other_projects_answer=(val)
    save_answer(88, val)
  end

  def is_true(val)
    [1,'1',true,'true'].include?(val)
  end

  def get_answer(q_id)
    answer = get_answer_object(q_id)
    answer ? answer.answer.to_s : ''
  end

  def save_answer(q_id, val)
    answer = get_answer_object(q_id)
    if answer
      answer.answer = val
      answer.save!
    end
  end

  def get_answer_object(q_id)
    answers.detect {|a| a.question_id == q_id}
  end


  # When an applicant status changes, we need to update the project counts
  def update_project_counts
    if changed.include?('status')
      if person.gender.present?
        count = SpApplication.connection.select_value("SELECT count(*) from sp_applications a inner join ministry_person p on a.person_id = p.personID where year = #{project.year} AND status IN('#{SpApplication.ready_statuses.join("','")}') AND p.gender = #{person.gender} AND a.project_id = #{project.id}")
        if person.is_male?
          project.current_applicants_men = count
        else
          project.current_applicants_women = count
        end
        count = SpApplication.connection.select_value("SELECT count(*) from sp_applications a inner join ministry_person p on a.person_id = p.personID where year = #{project.year} AND status IN('#{SpApplication.accepted_statuses.join("','")}') AND p.gender = #{person.gender} AND a.project_id = #{project.id}")
        if person.is_male?
          project.current_students_men = count
        else
          project.current_students_women = count
        end
      end
      project.save(:validate => false)
      count
    end
  end

  # This method removes the applicant from their project queue and
  # project assignment (decrementing counts appropriately).
  def remove_from_project_assignment
    if project
      project.current_students_men -= 1 if person.is_male?
      project.current_students_women -= 1 unless person.is_male?
      project.save(false)
    end
    return project
  end

  def email_address
    person.current_address.email if person && person.current_address
  end
  alias_method :email, :email_address

  def account_balance
    SpDonation.get_balance(designation_number, year)
  end


  def self.send_status_emails
    logger.info("Sending application reminder emails")
    uncompleted_apps = SpApplication.find(:all,
    :select => "app.*",
    :joins => "as app inner join sp_projects as proj on (proj.id = app.preference1_id)",
    :conditions => ["app.status in (?) and app.year = ? and proj.start_date > ?", SpApplication.uncompleted_statuses, SpApplication::YEAR, Time.now])
    uncompleted_apps.each do |app|
      if (app.person.informal_full_name && app.email_address && app.email_address != "")
        SpApplicationMailer.deliver_status(app)
      end
    end
  end
  
  def send_acceptance_email
      if changed.include?('applicant_notified') and applicant_notified? && status.starts_with?("accept")
        Notifier.notification(email_address, # RECIPIENTS
                                  Questionnaire.from_email, # FROM
                                  "Application Accepted", # LIQUID TEMPLATE NAME
                                  {'project_name' => project.try(:name)}).deliver
      end
  end
  
  def unsubmit_on_project_change
    if changed.include?('project_id')
      # If the new project uses a different template or has additional questions, we need to unsubmit
      if changes['project_id'].length == 2 && changes.all?(&:present?)
        old_project, new_project = SpProject.find_by_id(changes['project_id'][0]), SpProject.find_by_id(changes['project_id'][1])
        if old_project && new_project
          if old_project.basic_info_question_sheet != new_project.basic_info_question_sheet ||
                 old_project.template_question_sheet != new_project.template_question_sheet ||
                 (new_project.project_specific_question_sheet && new_project.project_specific_question_sheet.questions.present?)
            if submitted? || ready? || withdrawn?
              unsubmit!
            end
            clean_up_unneeded_references
          end
        end
      end
    end
  end
  
  def clean_up_unneeded_references
    # Do any necessary cleanup of references to match new project's requirements
    if project
      logger.debug('has project')
      reference_questions = project.template_question_sheet.questions.select {|q| q.is_a?(ReferenceQuestion)}
      if sp_references.length > reference_questions.length
        sp_references.each do |reference|
          # See if this reference's question_id matches any of the questions for the new project
          if question = reference_questions.detect {|rq| rq.id == reference.question_id}
            logger.debug('matched question: ' + question.id.to_s)
            next 
          end
          # If the question_id doesn't match, but the reference question is based on the same reference template (question sheet)
          # AND we don't already have a reference for that question
          # update the reference with the new question_id
          if (reference_question = reference_questions.detect {|rq| rq.related_question_sheet_id == reference.question.related_question_sheet_id}) &&
              !sp_references.detect {|r| r.question_id == reference_question.id}
            reference.update_attribute(:question_id, reference_question.id) 
            logger.debug("matched question sheet")
            next
          end
          # If we get here, the reference isn't needed anymore on this application, so we should delete it.
          logger.debug "destroy: #{reference.id}"
          reference.destroy unless reference.completed? # no point in deleting a completed reference
        end
      end
    end
  end
end
