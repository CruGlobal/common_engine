class Ccc::Person < ActiveRecord::Base

  self.table_name = 'ministry_person'
  self.primary_key = 'personID'




  belongs_to :user, class_name: 'Ccc::SimplesecuritymanagerUser', foreign_key: 'fk_ssmUserId'
  has_many :crs_registrations, class_name: 'Ccc::CrsRegistration', foreign_key: :fk_PersonID, dependent: :destroy

  has_one :crs2_profile, class_name: 'Ccc::Crs2Profile', foreign_key: :ministry_person_id, dependent: :destroy
  has_many :crs2_registrants, through: :crs2_profile
  has_many :crs2_registrant_types, through: :crs2_registrants
  has_many :conferences, -> { where "crs2_registrant.status = 'Complete'" }, :through => :crs2_registrant_types, source: :crs2_conference

  has_many :pr_reviewers, class_name: 'Ccc::PrReviewer', dependent: :destroy
  has_many :pr_reviews, class_name: 'Ccc::PrReview', foreign_key: :subject_id # dependant? subject_id, initiator_id
  has_many :pr_review_initiators, class_name: 'Ccc::PrReview', foreign_key: :initiator_id
  has_many :pr_admins, class_name: 'Ccc::PrAdmin', dependent: :destroy
  has_many :pr_summary_forms, class_name: 'Ccc::PrSummaryForm', dependent: :destroy
  has_many :pr_reminders, class_name: 'Ccc::PrReminder', dependent: :destroy
  has_many :pr_personal_forms, class_name: 'Ccc::PrPersonalForm', dependent: :destroy

  has_many :sp_applications, class_name: 'Ccc::SpApplication'
  has_many :summer_projects, -> { where "sp_applications.status IN('accepted_as_participant', 'accepted_as_student_staff')" }, :class_name => "Ccc::SpProject", through: :sp_applications, source: :sp_project
  has_many :sp_projects, class_name: 'Ccc::SpProject', foreign_key: :pd_id
  has_many :sp_project_apds, class_name: 'Ccc::SpProject', foreign_key: :apd_id
  has_many :sp_project_opds, class_name: 'Ccc::SpProject', foreign_key: :opd_id
  has_many :sp_project_coordinators, class_name: 'Ccc::SpProject', foreign_key: :coordinator_id
  has_one  :sp_user, class_name: 'Ccc::SpUser'  #created by and ssm/person?
  has_many :sp_staff, class_name: 'Ccc::SpStaff', dependent: :destroy
  has_many :sp_application_moves, class_name: 'Ccc::SpApplicationMove', foreign_key: 'moved_by_person_id'
  has_many :si_applies, class_name: 'Ccc::SiApply', foreign_key: 'applicant_id'
  has_many :ministry_staff, class_name: 'Ccc::MinistryStaff', dependent: :destroy
  has_many :hr_si_applications, class_name: 'Ccc::HrSiApplication', foreign_key: 'fk_personID'
  has_many :sitrack_mpd, class_name: 'Ccc::SitrackMpd', dependent: :destroy
  has_many :sitrack_tracking, class_name: 'Ccc::SitrackTracking', dependent: :destroy
  has_many :rideshare_rides, class_name: 'Ccc::RideshareRide', foreign_key: :person_id, dependent: :destroy
  has_many :profile_pictures, class_name: 'Ccc::ProfilePicture', dependent: :destroy
  has_many :ministry_missional_team_members, class_name: 'Ccc::MinistryMissionalTeamMember', dependent: :destroy, foreign_key: 'personID'
  has_many :sp_designation_numbers, class_name: 'Ccc::SpDesignationNumber', dependent: :destroy
  has_many :phone_numbers, autosave: true, dependent: :destroy
  has_many :email_addresses, autosave: true, dependent: :destroy
  has_one :primary_phone_number, -> { where primary: true }, class_name: "PhoneNumber", foreign_key: "person_id"
  has_many :ministry_newaddresses, class_name: 'Ccc::MinistryNewaddress', foreign_key: :fk_PersonID, dependent: :destroy

  def self.search_by_name(name, organization_ids = nil, scope = nil)
    return Person.where('1 = 0') unless name.present?
    scope ||= Person
    query = name.strip.split(' ')
    first, last = query[0].to_s + '%', query[1].to_s + '%'
    if last == '%'
      conditions = ["preferredName like ? OR firstName like ? OR lastName like ?", first, first, first]
    else
      conditions = ["(preferredName like ? OR firstName like ?) AND lastName like ?", first, first, last]
    end
    scope = scope.where(conditions)
    scope = scope.where('organizational_roles.organization_id IN(?)', organization_ids).includes(:organizational_roles) if organization_ids
    scope
  end

  def smart_merge(other)
    if user && other.user
      user.merge(other.user)
      return self
    elsif other.user
      other.merge(self)
      return other
    else
      merge(other)
      return self
    end

  end

  def merge(other)
    reload
    Ccc::Person.transaction do
      attributes.each do |k, v|
        next if k == ::Person.primary_key
        next if v == other.attributes[k]
        self[k] = case
                  when other.attributes[k].blank? then v
                  when v.blank? then other.attributes[k]
                  else
                    other_date = other.dateChanged || other.dateCreated
                    this_date = dateChanged || dateCreated
                    if other_date && this_date
                      other_date > this_date ? other.attributes[k] : v
                    else
                      v
                    end
                  end
      end

      # Phone Numbers
      phone_numbers.each do |pn|
        opn = other.phone_numbers.detect {|oa| oa.number == pn.number && oa.extension == pn.extension}
        pn.merge(opn) if opn
      end
      other.phone_numbers.each {|pn| pn.update_attribute(:person_id, id) unless pn.frozen?}

      # Email Addresses
      email_addresses.each do |pn|
        opn = other.email_addresses.detect {|oa| oa.email == pn.email}
        pn.merge(opn) if opn
      end
      emails = email_addresses.collect(&:email)
      other.email_addresses.each do |pn|
        if emails.include?(pn.email)
          pn.destroy
        else
          begin
            pn.update_attribute(:person_id, id) unless pn.frozen?
          rescue ActiveRecord::RecordNotUnique
            pn.destroy
          end
        end
      end

      # Addresses
      ministry_newaddresses.each do |address|
        other_address = other.ministry_newaddresses.detect {|oa| oa.addressType == address.addressType}
        address.merge(other_address) if other_address
      end
      other.ministry_newaddresses do |address|
        other_address = ministry_newaddresses.detect {|oa| oa.addressType == address.addressType}
        address.update_attribute(:fk_PersonID, personID) unless address.frozen? || other_address
      end

      # CRS
      other.crs_registrations.each { |ua| ua.update_attribute(:fk_PersonID, personID) }

      if other.crs2_profile && crs2_profile
        crs2_profile.merge(other.crs2_profile)
      elsif other.crs2_profile
        other.crs2_profile.update_column(:ministry_person_id, personID)
      end


      # Panorama
      other.pr_reviewers.update_all(person_id: personID)

      Ccc::PrReview.where(["subject_id = ? or initiator_id = ?", other.id, other.id]).each do |ua|
        ua.update_column(:subject_id, personID) if ua.subject_id == other.id
        ua.update_column(:initiator_id, personID) if ua.initiator_id == other.id
      end

      other.pr_admins.update_all(person_id: personID)
      other.pr_summary_forms.update_all(person_id: personID)
      other.pr_reminders.update_all(person_id: personID)
      other.pr_personal_forms.update_all(person_id: personID)

      # end Panorama

      # Summer Project Tool
      other.sp_applications.each { |ua| ua.update_attribute(:person_id, personID) }

      Ccc::SpProject.where(["pd_id = ? or apd_id = ? or opd_id = ? or coordinator_id = ?", other.id, other.id, other.id, other.id]).each do |ua|
        ua.update_attribute(:pd_id, personID) if ua.pd_id == other.id
        ua.update_attribute(:apd_id, personID) if ua.apd_id == other.id
        ua.update_attribute(:opd_id, personID) if ua.opd_id == other.id
        ua.update_attribute(:coordinator_id, personID) if ua.coordinator_id == other.id
      end

      if other.sp_user and sp_user
        sp_user.merge(other.sp_user)
      elsif other.sp_user
        Ccc::SpUser.where(["person_id = ? or ssm_id = ? or created_by_id = ?", other.id, other.fk_ssmUserId, other.fk_ssmUserId]).each do |ua|
          ua.update_attribute(:person_id, personID) if ua.person_id == other.id
          ua.update_attribute(:ssm_id, fk_ssmUserId) if ua.ssm_id == other.fk_ssmUserId
          ua.update_attribute(:created_by_id, fk_ssmUserId) if ua.created_by_id == other.fk_ssmUserId
        end
      end

      other.sp_staff.each { |ua| ua.update_attribute(:person_id, personID) }
      other.sp_application_moves.each { |ua| ua.update_attribute(:moved_by_person_id, personID) }
      # end Summer Project Tool

      other.si_applies.each { |ua| ua.update_attribute(:applicant_id, personID) }

      other.ministry_staff.each { |ua| ua.update_attribute(:person_id, personID) }

      other.hr_si_applications.each do |ua|
        ua.update_attribute(:fk_personID, personID)
        ua.update_attribute(:fk_ssmUserID, fk_ssmUserId)
      end

      other.si_applies.each { |ua| ua.update_attribute(:applicant_id, personID) }
      other.sitrack_mpd.each { |ua| ua.update_attribute(:person_id, personID) }
      other.sitrack_tracking.each { |ua| ua.update_attribute(:person_id, personID) }

      other.profile_pictures.each { |ua| ua.update_attribute(:person_id, personID) }
      other.ministry_missional_team_members.each { |ua| ua.update_attribute(:personID, personID) }
      other.rideshare_rides.each {|ua| ua.update_attribute(:person_id, personID) }
      other.sp_designation_numbers.each do |d|
        begin
          d.update_attribute(:person_id, personID)
        rescue ActiveRecord::RecordNotUnique
        end
      end

      Ccc::MergeAudit.create!(mergeable: self, merge_looser: other)
      other.reload
      other.destroy
      begin
        save(validate: false)
      rescue ActiveRecord::ReadOnlyRecord

      end
      self
    end
  end
end
