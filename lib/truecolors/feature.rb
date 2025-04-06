# frozen_string_literal: true

module Truecolors
  # Feature toggle functionality for Truecolors
  # This allows enabling/disabling features based on configuration
  class Feature
    # Returns true if the specified feature is enabled
    # 
    # @param name [String] The feature name to check
    # @param args [Hash] Additional options for the feature check
    # @return [Boolean] True if the feature is enabled
    def self.enabled?(name, **args)
      feature = features[name.to_s]
      return false if feature.nil?

      # Check for enabled override in database
      return true if feature_enabled_in_database?(name.to_s)
      
      # Check for environment variable override
      return true if ENV["TRUECOLORS_FEATURE_#{name.to_s.upcase}"] == 'true'
      
      # If defined with a proc, call it with args
      if feature.is_a?(Proc)
        return feature.call(**args)
      end
      
      # Otherwise use the static boolean value
      feature == true
    end
    
    # Same as enabled? but with the boolean value flipped
    # 
    # @param name [String] The feature name to check
    # @param args [Hash] Additional options for the feature check
    # @return [Boolean] True if the feature is disabled
    def self.disabled?(name, **args)
      !enabled?(name, **args)
    end
    
    # Get a list of all features and their status
    # 
    # @return [Hash] A hash of feature names and their enabled status
    def self.all
      features.keys.map { |name| [name, enabled?(name)] }.to_h
    end

    private

    def self.features
      @features ||= {
        'chat' => true,
        'xmpp' => true
      }
    end
    
    def self.feature_enabled_in_database?(name)
      # This would normally check a database table for override values
      # For now, return nil (use default value)
      nil
    end
  end
end
