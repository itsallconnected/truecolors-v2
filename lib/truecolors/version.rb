# frozen_string_literal: true

module Truecolors
  # Returns the version of the currently loaded Truecolors
  # as a <tt>Gem::Version</tt>
  def self.version
    Gem::Version.new VERSION::STRING
  end

  module VERSION
    # Major version number
    MAJOR = 1
    
    # Minor version number
    MINOR = 0
    
    # Patch version number
    PATCH = 0
    
    # Pre-release designation, if any (e.g., 'alpha.1', 'beta.2', etc.)
    PRE = nil

    STRING = [MAJOR, MINOR, PATCH, PRE].compact.join('.')

    # Compile the version string
    # @return [String] version string
    def self.to_s
      [MAJOR, MINOR, PATCH].join('.') + (PRE ? "-#{PRE}" : '')
    end
  end

  # Version information for Truecolors
  module Version
    module_function

    def major
      4
    end

    def minor
      4
    end

    def patch
      0
    end

    def default_prerelease
      'alpha.4'
    end

    def prerelease
      version_configuration[:prerelease].presence || default_prerelease
    end

    def build_metadata
      version_configuration[:metadata]
    end

    def to_a
      [major, minor, patch].compact
    end

    def to_s
      components = [to_a.join('.')]
      components << "-#{prerelease}" if prerelease.present?
      components << "+#{build_metadata}" if build_metadata.present?
      components.join
    end

    def gem_version
      @gem_version ||= Gem::Version.new(to_s.split('+')[0])
    end

    def api_versions
      {
        truecolors: 5,
      }
    end

    def repository
      source_configuration[:repository]
    end

    def source_base_url
      source_configuration[:base_url] || "https://github.com/#{repository}"
    end

    # specify git tag or commit hash here
    def source_tag
      source_configuration[:tag]
    end

    def source_url
      if source_tag
        "#{source_base_url}/tree/#{source_tag}"
      else
        source_base_url
      end
    end

    def source_commit
      ENV.fetch('SOURCE_COMMIT', nil)
    end

    def user_agent
      @user_agent ||= "Truecolors/#{Version} (#{HTTP::Request::USER_AGENT}; +http#{Rails.configuration.x.use_https ? 's' : ''}://#{Rails.configuration.x.web_domain}/)"
    end

    def version_configuration
      truecolors_configuration.version
    end

    def source_configuration
      truecolors_configuration.source
    end

    def truecolors_configuration
      Rails.configuration.x.truecolors
    end
  end
end
