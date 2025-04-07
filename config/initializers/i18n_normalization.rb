# frozen_string_literal: true

# Automatically normalize i18n files when running in development
if defined?(Rails::Server) && Rails.env.development? && system('which i18n-tasks > /dev/null 2>&1')
  Rails.application.config.after_initialize do
    Rails.logger.info 'Normalizing i18n YAML files...'
    system('bundle exec i18n-tasks normalize')
  end
end 