module AppStore
  module V1
    module Nsm
      # rubocop:disable Metrics/ClassLength
      class Claim < AppStore::V1::Base
        include ClaimDetails

        one :firm_office, AppStore::V1::FirmOffice
        one :solicitor, AppStore::V1::Solicitor
        many :letters_and_calls, AppStore::V1::Nsm::LetterOrCall
        many :defendants, AppStore::V1::Defendant
        many :supporting_evidence, AppStore::V1::SupportingDocument, key: :supporting_evidences
        many :further_informations, AppStore::V1::FurtherInformation, key: :further_information
        many :work_items, AppStore::V1::Nsm::WorkItem, collection_class: AppStore::V1::Nsm::WorkItemCollection
        many :disbursements, AppStore::V1::Nsm::Disbursement, collection_class: AppStore::V1::Nsm::DisbursementCollection

        ::Claim.states.each_key do |state_string|
          define_method(:"#{state_string}?") { state == state_string }
        end

        attribute :application_id, :string
        attribute :ufn, :string
        attribute :office_code, :string
        attribute :state, :string
        attribute :claim_type, :possibly_translated_string
        attribute :rep_order_date, :date
        attribute :cntp_order, :string
        attribute :cntp_date, :date
        attribute :created_at, :datetime
        attribute :updated_at, :datetime
        attribute :reasons_for_claim, :possibly_translated_array
        attribute :representation_order_withdrawn_date, :date
        attribute :reason_for_claim_other_details, :string
        attribute :main_offence, :string
        attribute :main_offence_date, :date
        attribute :assigned_counsel, :string
        attribute :unassigned_counsel, :string
        attribute :agent_instructed, :string
        attribute :remitted_to_magistrate, :string
        attribute :plea, :possibly_translated_string
        attribute :arrest_warrant_date, :date
        attribute :cracked_trial_date, :date
        attribute :first_hearing_date, :date
        attribute :number_of_hearing, :integer
        attribute :court, :string
        attribute :youth_court, :string
        attribute :hearing_outcome, :possibly_translated_string
        attribute :matter_type, :possibly_translated_string
        attribute :prosecution_evidence, :integer
        attribute :defence_statement, :integer
        attribute :number_of_witnesses, :integer
        attribute :supplemental_claim, :string
        attribute :time_spent, :integer
        attribute :other_info, :string
        attribute :conclusion, :string
        attribute :concluded, :string
        attribute :laa_reference, :string
        attribute :work_before_date, :date
        attribute :work_after_date, :date
        attribute :signatory_name, :string
        attribute :gender, :possibly_translated_string
        attribute :ethnic_group, :possibly_translated_string
        attribute :disability, :possibly_translated_string
        attribute :send_by_post, :boolean
        attribute :remitted_to_magistrate_date, :date
        attribute :preparation_time, :string
        attribute :work_before, :string
        attribute :work_after, :string
        attribute :has_disbursements, :string
        attribute :is_other_info, :string
        attribute :answer_equality, :possibly_translated_string
        attribute :plea_category, :possibly_translated_string
        attribute :submitted_total, :float
        attribute :submitted_total_inc_vat, :float
        attribute :adjusted_total, :float
        attribute :adjusted_total_inc_vat, :float
        attribute :assessment_comment, :string
        attribute :wasted_costs, :string
        attribute :work_completed_date, :date
        attribute :office_in_undesignated_area, :boolean
        attribute :court_in_undesignated_area, :boolean
        attribute :transferred_to_undesignated_area, :boolean
        attribute :submit_to_app_store_completed, :boolean
        attribute :send_notification_email_completed, :boolean
        attribute :originally_submitted_at, :datetime
        adjustable_attribute :include_youth_court_fee, :boolean
        attribute :change_solicitor_date, :date
        attribute :case_outcome_other_info, :string
        attribute :main_offence_type, :string
        attribute :letters_and_calls
        attribute :application_state, :string
        attribute :last_updated_at, :datetime
        attribute :youth_court_fee_adjustment_comment
        attribute :resubmission_deadline, :datetime
        attribute :gdpr_documents_deleted, :boolean

        alias state application_state
        alias app_store_updated_at last_updated_at
        alias id application_id
        alias to_param id
        alias allowed_youth_court_fee assessed_include_youth_court_fee

        def application
          self
        end

        def letter_details
          @letter_details ||= letters_and_calls.detect { _1.type == 'letters' }
        end

        def call_details
          @call_details ||= letters_and_calls.detect { _1.type == 'calls' }
        end

        def main_defendant
          @main_defendant ||= defendants.detect(&:main)
        end

        def additional_defendants
          @additional_defendants ||= defendants.reject(&:main)
        end

        def letters
          letter_details.count
        end

        def calls
          call_details.count
        end

        def letters_uplift
          letter_details.uplift
        end

        def calls_uplift
          call_details.uplift
        end

        def assessed_letters
          letter_details.assessed_count
        end

        def assessed_calls
          call_details.assessed_count
        end

        def assessed_letters_uplift
          letter_details.assessed_uplift
        end

        def assessed_calls_uplift
          call_details.assessed_uplift
        end

        def calls_for_calculation
          {
            type: :calls,
            claimed_items: calls,
            claimed_uplift_percentage: apply_calls_uplift ? calls_uplift : 0,
            assessed_items: assessed_calls,
            assessed_uplift_percentage: assessed_calls_uplift,
          }
        end

        def letters_for_calculation
          {
            type: :letters,
            claimed_items: letters,
            claimed_uplift_percentage: apply_letters_uplift ? letters_uplift : 0,
            assessed_items: assessed_letters,
            assessed_uplift_percentage: assessed_letters_uplift,
          }
        end

        def letters_adjustment_comment
          letter_details.adjustment_comment
        end

        def calls_adjustment_comment
          call_details.adjustment_comment
        end

        def pending_further_information
          further_informations.reject(&:previously_completed?).max_by(&:requested_at)
        end

        def local_record
          # The reason we're doing a "find_or_create_by" here rather than just "find"
          # is that in very rare cases (mostly this will be when dealing with dev branches)
          # there may not be a claim in the local DB to match the app store record.
          # This only matters if we are in an RFI loop and need a local `further_information`
          # record to hold the not-yet-resubmitted provider response to the caseworker request.
          # further_informations map polymortphically to claims, and that mechanism requires
          # a claim with the appropriate ID to exist in the local db.
          @local_record ||= ::Claim.find_or_create_by!(id:)
        end

        def gdpr_documents_deleted?
          respond_to?(:gdpr_documents_deleted) && gdpr_documents_deleted
        end

        delegate :with_lock, :provider_updated!, to: :local_record
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
