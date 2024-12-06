module Tasks
  class BaseTask
    include Routing

    attr_accessor :application, :task_statuses

    def initialize(application:, task_statuses: TaskList::TaskStatus.new)
      @application = application
      @task_statuses = task_statuses
    end

    def self.build(name, **)
      parts = name.to_s.split('/')
      namespace = parts.first.camelize if parts.count == 2
      class_name = "#{namespace}::Tasks::#{parts.last.split('.').first.camelize}"
      if const_defined?(class_name)
        class_name.constantize.new(**)
      else
        new(**)
      end
    end

    def fulfilled?(task_class)
      task_statuses.status(task_class:, application:).completed?
    end

    # Used by the `Routing` module to build the urls
    def default_url_options
      { id: application }
    end

    def status
      task_statuses.self_status(task: self)
    end

    def current_status
      return TaskStatus::NOT_APPLICABLE if not_applicable?
      return TaskStatus::UNREACHABLE unless in_progress? || can_start?
      return TaskStatus::NOT_STARTED unless in_progress?
      return TaskStatus::COMPLETED if completed?

      TaskStatus::IN_PROGRESS
    end

    def path
      ''
    end

    def not_applicable?
      true
    end

    # :nocov:
    def can_start?
      raise 'implement in task subclasses'
    end

    def in_progress?
      application.viewed_steps.include?(step_name)
    end

    def completed?
      raise 'implement in task subclasses'
    end
    # :nocov:
  end
end
