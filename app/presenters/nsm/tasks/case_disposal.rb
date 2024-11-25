module Nsm
  module Tasks
    class CaseDisposal < Base
      PREVIOUS_TASKS = HearingDetails
      FORM = Nsm::Steps::CaseDisposalForm

      def path
        if application.nsm? && application.can_claim_youth_court?
          edit_nsm_steps_case_category_path(application)
        else
          edit_nsm_steps_case_disposal_path(application)
        end
      end

      def form
        if application.nsm? && application.can_claim_youth_court?
          Steps::CaseCategoryForm
        else
          Steps::CaseDisposalForm
        end
      end
    end
  end
end
