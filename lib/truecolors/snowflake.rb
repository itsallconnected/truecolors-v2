# frozen_string_literal: true

module Truecolors
  # Snowflake ID generator for Truecolors
  # This is a time-based ID generator that creates unique 64-bit IDs
  class Snowflake
    # Epoch is 2023-01-01 00:00:00 UTC
    EPOCH = 1_672_531_200_000

    # Number of bits for different parts of the ID
    TIMESTAMP_BITS = 42
    WORKER_ID_BITS = 10
    SEQUENCE_BITS = 12

    # Maximum values
    MAX_WORKER_ID = (1 << WORKER_ID_BITS) - 1
    MAX_SEQUENCE = (1 << SEQUENCE_BITS) - 1

    # Bit shifts
    WORKER_ID_SHIFT = SEQUENCE_BITS
    TIMESTAMP_SHIFT = WORKER_ID_BITS + SEQUENCE_BITS

    attr_reader :worker_id

    # Initialize a new Snowflake generator
    #
    # @param worker_id [Integer] The worker ID for this generator
    def initialize(worker_id = 0)
      raise ArgumentError, "Worker ID must be between 0 and #{MAX_WORKER_ID}" if worker_id < 0 || worker_id > MAX_WORKER_ID
      
      @worker_id = worker_id
      @sequence = 0
      @last_timestamp = -1
      @mutex = Mutex.new
    end

    # Generate a new Snowflake ID
    #
    # @return [Integer] A unique 64-bit ID
    def next_id
      @mutex.synchronize do
        timestamp = current_timestamp

        if timestamp < @last_timestamp
          raise "Clock moved backwards. Refusing to generate ID for #{@last_timestamp - timestamp} milliseconds"
        end

        if timestamp == @last_timestamp
          @sequence = (@sequence + 1) & MAX_SEQUENCE
          if @sequence.zero?
            timestamp = wait_next_millis(@last_timestamp)
          end
        else
          @sequence = 0
        end

        @last_timestamp = timestamp
        
        ((timestamp - EPOCH) << TIMESTAMP_SHIFT) |
          (@worker_id << WORKER_ID_SHIFT) |
          @sequence
      end
    end

    private

    # Get the current timestamp in milliseconds
    #
    # @return [Integer] Current timestamp in milliseconds
    def current_timestamp
      (Time.now.to_f * 1000).to_i
    end

    # Wait until the next millisecond
    #
    # @param last_timestamp [Integer] The last timestamp generated
    # @return [Integer] The new current timestamp
    def wait_next_millis(last_timestamp)
      timestamp = current_timestamp
      while timestamp <= last_timestamp
        timestamp = current_timestamp
      end
      timestamp
    end
  end
end
