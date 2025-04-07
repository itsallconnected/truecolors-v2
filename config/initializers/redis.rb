# frozen_string_literal: true

Redis.sadd_returns_boolean = false

module RedisConfiguration
  class << self
    def establish_redis_connection
      redis_url = ENV.fetch('REDIS_URL') { 'redis://localhost:6379/0' }
      
      # During asset precompilation Rails.env might not be properly set up
      # or Redis may not be available, so handle errors gracefully
      begin
        redis_connection = Redis.new(
          url: redis_url,
          driver: ENV.fetch('REDIS_DRIVER', 'ruby').to_sym,
          id: ENV.fetch('REDIS_ID', nil),
          reconnect_attempts: 1,  # Try to reconnect only once during precompile
          reconnect_delay: 0.1,   # Short delay between reconnection attempts
          reconnect_delay_max: 0.3
        )
        
        # Test connection, will raise Redis::CannotConnectError if it fails
        redis_connection.ping
        
        redis_connection
      rescue Redis::BaseConnectionError => e
        Rails.logger.error("Redis connection failed: #{e.inspect}") if defined?(Rails) && Rails.logger
        # Return stub Redis client for asset precompilation
        if defined?(Rails.env) && (Rails.env.development? || Rails.env.test? || ENV['PRECOMPILING_ASSETS'])
          require 'redis/store/namespace'
          require 'redis/connection/memory'
          Redis::Store::Namespace.new('truecolors', redis: Redis.new(driver: :memory))
        else
          raise # Re-raise exception in production environments
        end
      end
    end
  end
end

# Set up Redis instance
Redis.current = RedisConfiguration.establish_redis_connection
