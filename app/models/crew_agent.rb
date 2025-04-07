# frozen_string_literal: true

# == Schema Information
#
# Table name: crew_agents
#
# id             :bigint(8)        not null, primary key
# name           :string           not null
# role           :string           not null
# goal           :text             not null
# backstory      :text
# chat_room_id   :bigint(8)        
# active         :boolean          default(TRUE)
# config         :jsonb            default({})
# created_at     :datetime         not null
# updated_at     :datetime         not null
#
# Indexes
#
#  index_crew_agents_on_chat_room_id          (chat_room_id)
#  index_crew_agents_on_name_and_chat_room_id (name, chat_room_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (chat_room_id => chat_rooms.id)
#

# Use Python integration to access CrewAI
require 'open3'
require 'json'

class CrewAgent < ApplicationRecord
  # The CrewAgent model represents an AI agent in the CrewAI framework
  # Each agent has a specific role, goal, and backstory
  
  belongs_to :chat_room, optional: true
  has_many :crew_tasks, dependent: :nullify
  
  validates :name, presence: true
  validates :role, presence: true
  validates :goal, presence: true
  validates :name, uniqueness: { scope: :chat_room_id }, if: -> { chat_room_id.present? }
  
  # Store configuration as JSON (model, temperature, etc.)
  # Default to reasonable values for Ollama integration
  after_initialize :set_default_config, if: :new_record?
  
  # Scopes for filtering agents
  scope :active, -> { where(active: true) }
  scope :global, -> { where(chat_room_id: nil) }
  scope :for_room, ->(room_id) { where(chat_room_id: room_id) }
  
  def mention_name
    "@#{name.downcase}"
  end
  
  def model_name
    config['model'] || ENV.fetch('OLLAMA_MODEL', 'phi3')
  end
  
  def temperature
    config['temperature'] || 0.7
  end
  
  # Creates a CrewAI-compatible Agent object by calling Python
  def to_crew_ai_agent(memory = nil)
    # Prepare agent data for Python
    agent_data = {
      role: role,
      goal: goal,
      backstory: backstory,
      verbose: Rails.env.development?,
      llm: {
        provider: :ollama,
        model: model_name,
        temperature: temperature
      },
      memory: memory
    }
    
    # Call Python helper to create the agent
    python_script = Rails.root.join('lib', 'crewai', 'create_agent.py')
    
    # Verify that the Python script exists
    unless File.exist?(python_script)
      Rails.logger.error("CrewAI Python script not found: #{python_script}")
      raise "CrewAI Python script not found: #{python_script}"
    end
    
    # Execute the Python script with the agent data
    command = "python #{python_script} '#{agent_data.to_json.gsub("'", "\\'")}'"
    stdout, stderr, status = Open3.capture3(command)
    
    unless status.success?
      Rails.logger.error "Error creating CrewAI agent: #{stderr}"
      raise "CrewAI is required but encountered an error: #{stderr}"
    end
    
    # Parse the JSON output to get the agent ID
    result = JSON.parse(stdout)
    
    # Return the agent ID from Python
    result["agent_id"]
  rescue => e
    Rails.logger.error "Error creating CrewAI agent: #{e.message}"
    raise "CrewAI is required but encountered an error: #{e.message}"
  end
  
  private
  
  def set_default_config
    self.config ||= {
      'model' => ENV.fetch('OLLAMA_MODEL', 'phi3'),
      'temperature' => 0.7,
      'max_tokens' => 2000
    }
  end
end