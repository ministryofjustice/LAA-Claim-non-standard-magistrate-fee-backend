module PriorAuthority
  module Steps
    class OfficeCodeForm < ::Steps::BaseFormObject
      attribute :office_code, :string

      validates :office_code, inclusion: { in: :options, allow_blank: false }

      def options
        ActiveOfficeCodeService.call(application.provider.office_codes)
      end

      private

      def persist!
        application.update!(office_code: office_code.presence)
      end
    end
  end
end
