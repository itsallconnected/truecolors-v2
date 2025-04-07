# frozen_string_literal: true

# == Schema Information
#
# Table name: chat_rooms
#
# id                 :bigint(8)        not null, primary key
# room_jid           :string           not null
# name               :string           not null
# encryption_key     :string
# creator_id         :bigint(8)
# public             :boolean          default(FALSE)
# created_at         :datetime         not null
# updated_at         :datetime         not null
#
# Indexes
#
#  index_chat_rooms_on_room_jid    (room_jid) UNIQUE
#  index_chat_rooms_on_creator_id  (creator_id)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#

# Use Python integration to access CrewAI
require 'open3'
require 'json'
require 'securerandom'
require 'shellwords'
require 'tempfile'

class ChatRoom < ApplicationRecord
  # The ChatRoom model represents an XMPP multi-user chat room (MUC)
  
  belongs_to :creator, class_name: 'User', optional: true
  has_many :chat_messages, foreign_key: 'room_id', dependent: :destroy, inverse_of: :room
  has_many :crew_agents, dependent: :destroy
  has_many :crew_tasks, dependent: :destroy
  
  validates :room_jid, presence: true, uniqueness: true
  validates :name, presence: true
  
  # Encrypt the encryption key in the database
  encrypts :encryption_key
  
  # Scope to find public chat rooms
  scope :public_rooms, -> { where(public: true) }
  
  # Generate a random room JID if not set
  before_validation :ensure_room_jid, on: :create
  
  # Method to check if the room has AI agents enabled
  def ai_enabled?
    # Check if there are any CrewAgent records associated with this room
    CrewAgent.exists?(chat_room_id: id)
  rescue => e
    Rails.logger.error("Error checking for AI agents: #{e.message}")
    raise "CrewAI is required but encountered an error: #{e.message}"
  end
  
  # Method to create a CrewAI crew with all agents for this room through Python
  def create_crew(tasks = [])
    agents = crew_agents.active.map(&:to_crew_ai_agent).compact
    raise "No active agents available for this room" if agents.empty?
    
    # Prepare crew data for Python
    crew_data = {
      agents: agents,
      tasks: tasks,
      verbose: Rails.env.development?
    }
    
    # Call Python helper to create the crew
    python_script = Rails.root.join('lib', 'crewai', 'create_crew.py')
    
    # Verify that the Python script exists
    unless File.exist?(python_script)
      Rails.logger.error("CrewAI Python script not found: #{python_script}")
      raise "CrewAI Python script not found: #{python_script}"
    end
    
    # Write JSON data to a temp file instead of passing via command line
    temp_file = Tempfile.new(['crew_data', '.json'])
    begin
      temp_file.write(crew_data.to_json)
      temp_file.close
      
      # Execute the Python script with the file path
      command = ["python", python_script.to_s, temp_file.path]
      stdout, stderr, status = Open3.capture3(*command)
      
      unless status.success?
        Rails.logger.error("Error creating CrewAI crew: #{stderr}")
        raise "CrewAI is required but encountered an error: #{stderr}"
      end
      
      # Parse the JSON output to get the crew ID
      result = JSON.parse(stdout)
      
      # Return the crew ID from Python
      result["crew_id"]
    ensure
      temp_file.unlink
    end
  rescue => e
    Rails.logger.error("Error creating CrewAI crew: #{e.message}")
    raise "CrewAI is required but encountered an error: #{e.message}"
  end
  
  # Method to run a crew's tasks and get the result
  def run_crew(crew_id)
    # Call Python helper to run the crew
    python_script = Rails.root.join('lib', 'crewai', 'run_crew.py')
    
    # Verify that the Python script exists
    unless File.exist?(python_script)
      Rails.logger.error("CrewAI Python script not found: #{python_script}")
      raise "CrewAI Python script not found: #{python_script}"
    end
    
    # Execute the Python script with the crew ID
    command = ["python", python_script.to_s, crew_id.to_s]
    stdout, stderr, status = Open3.capture3(*command)
    
    unless status.success?
      Rails.logger.error("Error running CrewAI crew: #{stderr}")
      raise "CrewAI is required but encountered an error: #{stderr}"
    end
    
    # Parse the JSON output to get the result
    result = JSON.parse(stdout)
    
    # Return the result
    result["result"]
  rescue => e
    Rails.logger.error("Error running CrewAI crew: #{e.message}")
    raise "CrewAI is required but encountered an error: #{e.message}"
  end
  
  private
  
  def ensure_room_jid
    return if room_jid.present?
    
    # Generate a random room JID using SecureRandom if not set
    random_suffix = SecureRandom.alphanumeric(8).downcase
    domain = ENV.fetch('XMPP_DOMAIN', 'localhost')
    self.room_jid = "room_#{random_suffix}@conference.#{domain}"
  end
  
  def fernet_cipher
    @fernet_cipher ||= begin
      require 'fernet'
      Fernet::Cipher.new(encryption_key)
    end
  end
end