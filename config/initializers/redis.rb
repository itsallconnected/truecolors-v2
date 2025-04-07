# frozen_string_literal: true

Redis.sadd_returns_boolean = false

# Skip Redis initialization during asset precompilation or CI
if ENV['PRECOMPILING_ASSETS'] || ENV['CI'] || (defined?(Rake) && Rake.application.top_level_tasks.any? { |task| task.include?('assets:') })
  # Create a null Redis object without redefining the Redis class itself
  null_redis = Object.new.tap do |o|
    def o.method_missing(method_name, *)
      # Return sensible defaults based on common Redis methods
      case method_name.to_s
      when /ping/
        "PONG"
      when /get|hget/
        nil
      when /set|sadd|del|hmset|expire|hset/
        true
      when /keys/
        []
      when /exists/
        false
      else
        nil
      end
    end
    
    def o.respond_to_missing?(_, _ = false)
      true # Pretend to respond to all Redis methods
    end
  end
  
  # Add current method to Redis class using singleton method instead of redefining
  Redis.define_singleton_method(:current) do
    null_redis
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

  # Set Redis.current for backward compatibility without redefining
  Redis.define_singleton_method(:current) do
    RedisConfiguration.redis
  end
end
