module PriorAuthority
  module Steps
    class PrimaryQuoteForm < ::Steps::BaseFormObject
      attribute :service_required, :string

      validates :service_required, presence: true

      private

      def persist!
        application.update!(attributes)
      end
    end
  end
end
