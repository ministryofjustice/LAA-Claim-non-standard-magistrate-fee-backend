Rails.application.configure do
  config.lograge.enabled = Rails.env.production?
  config.lograge.base_controller_class = 'ActionController::Base'
  config.lograge.logger = ActiveSupport::Logger.new($stdout)
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  # Reduce noise in the logs by ignoring the healthcheck actions
  config.lograge.ignore_actions = %w[
    HealthcheckController#ping
    HealthcheckController#ready
  ]

  # Important: the `controller` might not be a full-featured
  # `ApplicationController` but instead a `BareApplicationController`
  config.lograge.custom_payload do |controller|
    {
      provider_id: controller.current_provider.to_param
    }
  end
end
