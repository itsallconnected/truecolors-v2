# frozen_string_literal: true

module Truecolors
  # Implements the Twitter snowflake ID generation algorithm
  # IDs are 64-bit positive integers composed of:
  # - 41 bits of millisecond timestamp
  # - 10 bits of machine ID
  # - 12 bits of sequence number
  class Snowflake
    # The epoch for Truecolors IDs (January 1, 2016 UTC)
    DEFAULT_EPOCH = 1451606400_000

    # Maximum worker ID (10 bits)
    MAX_WORKER_ID = 1023

    # Maximum sequence number (12 bits)
    MAX_SEQUENCE = 4095

    attr_reader :worker_id, :epoch

    # Initialize a new snowflake generator
    # @param worker_id [Integer] Machine ID (0-1023)
    # @param epoch [Integer] Custom epoch in milliseconds
    def initialize(worker_id = 0, epoch = DEFAULT_EPOCH)
      raise ArgumentError, "Worker ID must be between 0 and #{MAX_WORKER_ID}" if worker_id.negative? || worker_id > MAX_WORKER_ID
      @worker_id = worker_id
      @epoch = epoch
      @mutex = Mutex.new
      @sequence = 0
      @last_timestamp = 0
    end

    # Generate a new snowflake ID
    # @return [Integer] Unique 64-bit ID
    def next_id
      @mutex.synchronize do
        timestamp = current_time

        if timestamp < @last_timestamp
          raise StandardError, "Clock moved backwards! #{@last_timestamp - timestamp}ms"
        end

        if timestamp == @last_timestamp
          @sequence = (@sequence + 1) & MAX_SEQUENCE
          if @sequence.zero?
            timestamp = next_timestamp(@last_timestamp)
          end
        else
          @sequence = 0
        end

        @last_timestamp = timestamp
        generate_id(timestamp)
      end
    end

    private

    # Generate the ID from the timestamp, worker ID, and sequence
    # @param timestamp [Integer] Current timestamp in milliseconds
    # @return [Integer] Generated ID
    def generate_id(timestamp)
      ((timestamp - @epoch) << 22) | (@worker_id << 12) | @sequence
    end

    # Get current time in milliseconds
    # @return [Integer] Current time in milliseconds
    def current_time
      (Time.now.to_f * 1000).to_i
    end

    # Wait until next millisecond if needed
    # @param last_timestamp [Integer] Last timestamp used
    # @return [Integer] Next timestamp to use
    def next_timestamp(last_timestamp)
      timestamp = current_time
      while timestamp <= last_timestamp
        timestamp = current_time
      end
      timestamp
    end
  end
end
