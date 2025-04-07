# frozen_string_literal: true

# Initialize CrewAI configuration for Truecolors

# Only proceed when XMPP features are enabled and we're not in a test environment
if defined?(Truecolors::Feature) && Truecolors::Feature.enabled?(:xmpp) && ENV['CREWAI_ENABLED'] != 'false'
  require 'open3'
  require 'json'
  
  # Verify Python and CrewAI are available
  python_check_cmd = "python -c \"import crewai; import langchain_ollama; print('CrewAI available')\""
  stdout, stderr, status = Open3.capture3(python_check_cmd)
  
  unless status.success?
    error_message = "CrewAI Python module not available: #{stderr.strip}"
    Rails.logger.error(error_message)
    raise error_message
  end
  
  # Initialize CrewAI through Python
  python_init_script = Rails.root.join('lib', 'crewai', 'initialize.py')
  
  unless File.exist?(python_init_script)
    # Create the initialize.py script if it doesn't exist
    FileUtils.mkdir_p(File.dirname(python_init_script))
    File.write(python_init_script, <<~PYTHON)
      #!/usr/bin/env python
      
      import os
      import sys
      import json
      
      try:
          from crewai import Agent, Task, Crew, CrewAI
          from langchain_ollama import ChatOllama
          import psycopg2
          
          # Configure CrewAI with settings from environment
          config = {
              "ollama_host": os.environ.get("OLLAMA_HOST", "http://localhost:11434"),
              "ollama_model": os.environ.get("OLLAMA_MODEL", "phi3"),
              "temperature": float(os.environ.get("OLLAMA_TEMPERATURE", "0.7")),
              "verbose": os.environ.get("RAILS_ENV") == "development",
              "rpg_mode": os.environ.get("CREWAI_RPG_MODE", "false") == "true"
          }
          
          # Set up Ollama LLM provider
          if os.environ.get("OLLAMA_HOST"):
              os.environ["LANGCHAIN_OLLAMA_BASE_URL"] = os.environ.get("OLLAMA_HOST")
          
          # Initialize CrewAI
          CrewAI.configure(
              memory="postgres",
              agent_defaults={
                  "verbose": config["verbose"],
                  "memory": True
              },
              rpg_mode=config["rpg_mode"]
          )
          
          # Print success message and config
          print(json.dumps({
              "status": "success",
              "message": "CrewAI initialized successfully",
              "config": config
          }))
      except ImportError as e:
          print(json.dumps({
              "status": "error",
              "message": f"Error importing required Python modules: {str(e)}"
          }), file=sys.stderr)
          sys.exit(1)
      except Exception as e:
          print(json.dumps({
              "status": "error",
              "message": f"Error initializing CrewAI: {str(e)}"
          }), file=sys.stderr)
          sys.exit(1)
    PYTHON
  end
  
  # Execute the Python initialization script
  stdout, stderr, status = Open3.capture3("python #{python_init_script}")
  
  unless status.success?
    error_message = "CrewAI initialization failed: #{stderr.strip}"
    Rails.logger.error(error_message)
    raise error_message
  end
  
  # Extract config from the Python script output
  begin
    result = JSON.parse(stdout.strip)
    Rails.logger.info("CrewAI initialized: #{result['message']}")
    
    # Set up additional agent configuration from YAML if exists
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
        error_message = "Failed to load CrewAI agents: #{e.message}"
        Rails.logger.error(error_message)
        raise error_message
      end
    end
  rescue JSON::ParserError => e
    error_message = "Error parsing CrewAI initialization output: #{e.message}"
    Rails.logger.error(error_message)
    raise error_message
  end
else
  # CrewAI is disabled by configuration
  Rails.logger.info "CrewAI disabled: either XMPP feature is disabled or CREWAI_ENABLED is set to 'false'"
end