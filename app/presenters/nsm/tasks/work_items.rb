module Nsm
  module Tasks
    class WorkItems < Base
      PREVIOUS_TASKS = ClaimDetails
      PREVIOUS_STEP_NAME = :claim_details
      FORM = Nsm::Steps::WorkItemForm

      def in_progress?
        [
          edit_nsm_steps_work_items_path(application),
          edit_nsm_steps_work_item_path(id: application.id, work_item_id: '')
        ].any? do |path|
          application.navigation_stack.any? { |stack| stack.start_with?(path) }
        end
      end

      def completed?
        application.work_items.any? && application.work_items.all?(&:complete?)
      end
    end
  end
end
