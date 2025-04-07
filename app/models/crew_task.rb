# frozen_string_literal: true

# == Schema Information
#
# Table name: crew_tasks
#
# id             :bigint(8)        not null, primary key
# name           :string           not null
# description    :text             not null
# crew_agent_id  :bigint(8)        
# chat_room_id   :bigint(8)        not null
# active         :boolean          default(TRUE)
# config         :jsonb            default({})
# created_at     :datetime         not null
# updated_at     :datetime         not null
#
# Indexes
#
#  index_crew_tasks_on_chat_room_id   (chat_room_id)
#  index_crew_tasks_on_crew_agent_id  (crew_agent_id)
#  index_crew_tasks_on_name           (name)
#
# Foreign Keys
#
#  fk_rails_...  (chat_room_id => chat_rooms.id)
#  fk_rails_...  (crew_agent_id => crew_agents.id)
#

# Use Python integration to access CrewAI
require 'open3'
require 'json'

class CrewTask < ApplicationRecord
  # The CrewTask model represents tasks that can be assigned to AI agents
  # Tasks are associated with a specific chat room and optionally with a specific agent
  
  belongs_to :crew_agent, optional: true
  belongs_to :chat_room
  
  validates :name, presence: true
  validates :description, presence: true
  
  # Scopes for filtering tasks
  scope :active, -> { where(active: true) }
  scope :unassigned, -> { where(crew_agent_id: nil) }
  scope :for_agent, ->(agent_id) { where(crew_agent_id: agent_id) }
  scope :for_room, ->(room_id) { where(chat_room_id: room_id) }
  
  # Method to check if this task is assigned to an agent
  def assigned?
    crew_agent_id.present?
  end
  
  # Method to get tool names enabled for this task
  def tools
    config['tools'] || []
  end
  
  # Method to assign this task to an agent
  def assign_to(agent)
    update(crew_agent_id: agent.id)
  end
  
  # Method to get expected outputs format
  def expected_output
    config['expected_output'] || 'text'
  end
  
  # Creates a CrewAI-compatible Task object through Python
  def to_crew_ai_task(agent_obj = nil, inputs = {})
    agent = agent_obj || (crew_agent.present? ? crew_agent.to_crew_ai_agent : nil)
    raise "No agent available for task" if agent.nil?
    
    # Replace placeholders in description with input values
    task_description = description.dup
    inputs.each do |key, value|
      task_description.gsub!("{#{key}}", value.to_s)
    end
    
    # Prepare task data for Python
    task_data = {
      description: task_description,
      expected_output: expected_output,
      agent_id: agent,
      tools: tools
    }
    
    # Call Python helper to create the task
    python_script = Rails.root.join('lib', 'crewai', 'create_task.py')
    
    # Verify that the Python script exists
    unless File.exist?(python_script)
      Rails.logger.error("CrewAI Python script not found: #{python_script}")
      raise "CrewAI Python script not found: #{python_script}"
    end
    
    # Execute the Python script with the task data
    command = "python #{python_script} '#{task_data.to_json.gsub("'", "\\'")}'"
    stdout, stderr, status = Open3.capture3(command)
    
    unless status.success?
      Rails.logger.error "Error creating CrewAI task: #{stderr}"
      raise "CrewAI is required but encountered an error: #{stderr}"
    end
    
    # Parse the JSON output to get the task ID
    result = JSON.parse(stdout)
    
    # Return the task ID from Python
    result["task_id"]
  rescue => e
    Rails.logger.error "Error creating CrewAI task: #{e.message}"
    raise "CrewAI is required but encountered an error: #{e.message}"
  end
end