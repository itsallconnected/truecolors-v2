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
      return feature.call(**args) if feature.is_a?(Proc)
      
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
      features.keys.index_with { |name| enabled?(name) }
    end

    # Determine if specified features are enabled globally
    #
    # @param features [Array<String,Symbol>] List of features to check
    # @return [Boolean] True if all specified features are enabled
    def self.enabled?(*features)
      features.all? do |feature|
        truecolors_config.key?('experimental_features') &&
          feature_enabled_in_experimental?(feature)
      end
    end

    # Determine if a specified feature is enabled in experimental features
    #
    # @param feature [String,Symbol] The feature to check
    # @return [Boolean] True if the specified feature is enabled
    def self.feature_enabled_in_experimental?(feature)
      features = ENV.fetch('EXPERIMENTAL_FEATURES', truecolors_config['experimental_features'])
      return false if features.blank?

      features.split(',').map(&:strip).include?(feature.to_s)
    end

    # Get the TrueColors configuration from Rails
    #
    # @return [Hash] TrueColors configuration from Rails
    def self.truecolors_config
      Rails.application.config_for(:truecolors).fetch(Rails.env.to_s, {})
    rescue
      # Failsafe for when the file is missing or invalid
      {
        'experimental_features' => ENV.fetch('EXPERIMENTAL_FEATURES', ''),
        'features' => {
          'xmpp' => true,
        },
      }
    end

    class << self
      private

      def features
        @features ||= {
          'chat' => true,
          'xmpp' => true
        }
      end
      
      def feature_enabled_in_database?(_name)
        # This would normally check a database table for override values
        # For now, return false (use default value)
        false
      end
    end
  end
end
