# frozen_string_literal: true

module Nsm
  module CheckAnswers
    class CaseDetailsCard < Base
      attr_reader :claim

      def initialize(claim)
        @claim = claim
        @group = 'about_case'
        @section = 'case_details'
      end

      # TO DO: update remittal to include date of remittal when CRM457-172 is done
      # rubocop:disable Metrics/AbcSize
      def row_data
        row = [
          {
            head_key: 'main_offence',
            text: check_missing(claim.main_offence)
          },
          {
            head_key: 'main_offence_type',
            text: check_missing(claim.main_offence_type.present?) do
              I18n.t("nsm.steps.check_answers.show.sections.case_details.#{claim.main_offence_type}")
            end
          },
          {
            head_key: 'main_offence_date',
            text: check_missing(claim.main_offence_date) do
                    claim.main_offence_date.to_fs(:stamp)
                  end
          },
          {
            head_key: 'assigned_counsel',
            text: check_missing(claim.assigned_counsel.present?) do
                    claim.assigned_counsel.capitalize
                  end
          },
          {
            head_key: 'unassigned_counsel',
            text: check_missing(claim.unassigned_counsel.present?) do
                    claim.unassigned_counsel.capitalize
                  end
          },
          {
            head_key: 'agent_instructed',
            text: check_missing(claim.agent_instructed.present?) do
                    claim.agent_instructed.capitalize
                  end
          },
          process_boolean_value(boolean_field: claim.remitted_to_magistrate,
                                value_field: claim.remitted_to_magistrate_date,
                                boolean_key: 'remitted_to_magistrate',
                                value_key: 'remitted_to_magistrate_date') do
            claim.remitted_to_magistrate_date.to_fs(:stamp)
          end
        ]

        remove_main_offence_type(row) unless claim.main_offence_type

        row.flatten
      end
      # rubocop:enable Metrics/AbcSize

      private

      def remove_main_offence_type(row)
        row.delete_if { |r| r.is_a?(Hash) && r[:head_key] == 'main_offence_type' }
      end
    end
  end
end
