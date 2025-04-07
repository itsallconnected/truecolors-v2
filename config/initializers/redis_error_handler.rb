# frozen_string_literal: true

# Set up error handler for Redis ActionCable adapter
# This is defined here instead of in cable.yml to avoid YAML parsing issues

Rails.application.config.after_initialize do
  if Rails.env.production? && defined?(ActionCable)
    config = ActionCable.server.config
    if config.cable[:adapter] == 'redis'
      config.cable[:error_handler] = ->(error) { Rails.logger.error("Redis error: #{error}") }
    end
  end
end 