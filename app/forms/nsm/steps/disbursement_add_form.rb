module Nsm
  module Steps
    class DisbursementAddForm < ::Steps::BaseFormObject
      attribute :has_disbursements, :value_object, source: YesNoAnswer
      validates :has_disbursements, presence: true

      private

      def persist!
        record.update!(attributes)
      end
    end
  end
end
