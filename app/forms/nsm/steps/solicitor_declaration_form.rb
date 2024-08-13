module Nsm
  module Steps
    class SolicitorDeclarationForm < ::Steps::BaseFormObject
      attribute :signatory_name, :string
      validates :signatory_name, presence: true, format: { with: /\A[a-z,.'\-]+( +[a-z,.'\-]+)+\z/i }

      private

      def persist!
        Claim.transaction do
          application.status = :submitted
          application.update_disbursement_positions!
          application.update!(attributes)
        end
        SubmitToAppStore.perform_later(submission: application)
        true
      end
    end
  end
end
