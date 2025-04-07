# frozen_string_literal: true

Redis.sadd_returns_boolean = false

# Skip Redis initialization during asset precompilation or CI
if ENV['PRECOMPILING_ASSETS'] || ENV['CI'] || (defined?(Rake) && Rake.application.top_level_tasks.any? { |task| task.include?('assets:') })
  module Redis
    def self.current
      @null_redis ||= Object.new.tap do |o|
        def o.method_missing(*args)
          # Return sensible defaults based on common Redis methods
          case args[0].to_s
          when /ping/
            "PONG"
          when /get|hget/
            nil
          when /set|sadd|del/
            true
          when /keys/
            []
          else
            nil
          end
        end
      end
    end
  end
else
  # Normal Redis setup for non-asset-compilation environments
  module RedisConfiguration
    class << self
      def redis
        @redis ||= begin
          redis_url = ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' }
          
          Redis.new(
            url: redis_url,
            driver: ENV.fetch('REDIS_DRIVER', 'ruby').to_sym,
            id: ENV.fetch('REDIS_ID', nil)
          )
        end
      end
    end
  end

  # Set Redis.current for backward compatibility
  Redis.instance_eval do
    def self.current
      RedisConfiguration.redis
    end
  end
end
