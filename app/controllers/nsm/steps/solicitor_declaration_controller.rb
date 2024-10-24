module Nsm
  module Steps
    class SolicitorDeclarationController < Nsm::Steps::BaseController
      before_action :check_complete?

      def edit
        @form_object = SolicitorDeclarationForm.build(
          record,
          application: current_application
        )
      end

      def update
        update_and_advance(SolicitorDeclarationForm, as: :solicitor_declaration, record: record)
      end

      private

      def decision_tree_class
        Decisions::DecisionTree
      end

      def record
        current_application.sent_back? ? current_application.pending_further_information : current_application
      end

      def step_valid?
        current_application.draft? || current_application.sent_back?
      end

      def check_complete?
        # In prior authority all we have to do is check that the check answers task is startable.
        # For Nsm you can technically end up with states where check answers is startable
        # but other tasks are incomplete. So we iterate through each task to check it's valid
        task_names = Nsm::StartPage::TaskList::SECTIONS.pluck(1).flatten
        # ViewClaim only "knows" it's complete by checking if there is something after it
        # in the navigation_stack. There are known issues with this
        # (https://mojdt.slack.com/archives/C05212WRK5J/p1729766304910019?thread_ts=1729765990.496229&cid=C05212WRK5J)
        # and ViewClaim is a readonly screen anyway, so we discount it here.
        known_incomplete_tasks = ['nsm/solicitor_declaration', 'nsm/view_claim']
        incomplete = (task_names - known_incomplete_tasks).reject do |task_name|
          task_class = task_name.gsub('nsm', 'nsm/tasks').camelize.constantize
          task_class.new(application: current_application).completed?
        end

        redirect_to nsm_steps_start_page_path(current_application) if incomplete.any?
      end

      def skip_stack
        true
      end
    end
  end
end
