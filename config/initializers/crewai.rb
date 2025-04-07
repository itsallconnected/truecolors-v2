# frozen_string_literal: true

# Initialize CrewAI configuration for Truecolors

begin
  # Only load when XMPP features are enabled and we're not in a test environment
  if defined?(Truecolors::Feature) && Truecolors::Feature.enabled?(:xmpp) && ENV['CREWAI_ENABLED'] == 'true'
    begin
      require 'crewai'
      require 'ollama'
      
      # Set Ollama API endpoint from environment
      Ollama.host = ENV.fetch('OLLAMA_HOST', 'http://localhost:11434')

      # Configure CrewAI with Ollama as the LLM provider
      CrewAI.configure do |config|
        # Use memory with PostgreSQL to maintain history
        config.memory = :postgres
        
        # Configure LLM settings
        config.llm = {
          provider: :ollama,
          model: ENV.fetch('OLLAMA_MODEL', 'phi3'),
          temperature: ENV.fetch('OLLAMA_TEMPERATURE', '0.7').to_f,
          response_format: { type: 'json_object' }
        }
        
        # Configure agent defaults
        config.agent_defaults = {
          verbose: Rails.env.development?,
          memory: true
        }
        
        # Configure RPG mode
        config.rpg_mode = ENV.fetch('CREWAI_RPG_MODE', 'false') == 'true'
      end
      
      # Load agent definitions from YAML if exists
      agents_file = Rails.root.join('config', 'crewai', 'agents.yml')
      if File.exist?(agents_file)
        begin
          YAML.load_file(agents_file).each do |agent_config|
            # Skip if already exists in the database
            next if defined?(CrewAgent) && CrewAgent.exists?(name: agent_config['name'])
            
            CrewAgent.create!(
              name: agent_config['name'],
              role: agent_config['role'],
              goal: agent_config['goal'],
              backstory: agent_config['backstory'],
              active: true
            )
          end
        rescue => e
          Rails.logger.error("Error loading CrewAI agents: #{e.message}")
        end
      end
      
      Rails.logger.info "CrewAI initialized with Ollama provider (model: #{ENV.fetch('OLLAMA_MODEL', 'phi3')})"
    rescue LoadError => e
      # CrewAI is not available, disable it
      ENV['CREWAI_ENABLED'] = 'false'
      Rails.logger.warn "CrewAI disabled: #{e.message}. Python module not available or not properly installed."
    end
  else
    # CrewAI is disabled by configuration
    Rails.logger.info "CrewAI disabled: either XMPP feature is disabled or CREWAI_ENABLED is not 'true'"
  end
rescue => e
  # Something else went wrong, log it but don't crash
  Rails.logger.error "CrewAI initialization error: #{e.message}. CrewAI will be disabled."
  ENV['CREWAI_ENABLED'] = 'false'
end