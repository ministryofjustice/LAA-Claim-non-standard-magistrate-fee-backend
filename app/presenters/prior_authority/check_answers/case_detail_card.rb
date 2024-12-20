# frozen_string_literal: true

module PriorAuthority
  module CheckAnswers
    class CaseDetailCard < Base
      attr_reader :application

      def initialize(application)
        @group = 'about_case'
        @section = 'case_detail'
        @application = application
        super()
      end

      def row_data
        base_rows
      end

      def base_rows
        [
          main_offence_row,
          rep_order_date_row,
          maat_row,
          client_detained_row,
          subject_to_poca_row
        ]
      end

      private

      def main_offence_row
        {
          head_key: 'main_offence',
          text: main_offence
        }
      end

      def rep_order_date_row
        {
          head_key: 'rep_order_date',
          text: application.rep_order_date.to_fs(:stamp),
        }
      end

      def maat_row
        {
          head_key: 'maat',
          text: application.defendant.maat,
        }
      end

      def client_detained_row
        {
          head_key: 'client_detained',
          text: client_detained,
        }
      end

      def subject_to_poca_row
        {
          head_key: 'subject_to_poca',
          text: I18n.t("generic.#{application.subject_to_poca}"),
        }
      end

      def client_detained
        @client_detained ||= if application.client_detained?
                               if application.prison_id == 'custom'
                                 application.custom_prison_name
                               else
                                 I18n.t("prior_authority.prisons.#{application.prison_id}")
                               end
                             else
                               I18n.t("generic.#{application.client_detained?}")
                             end
      end

      def main_offence
        if application.main_offence_id == 'custom'
          application.custom_main_offence_name
        else
          I18n.t("prior_authority.offences.#{application.main_offence_id}")
        end
      end
    end
  end
end
