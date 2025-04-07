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
  
  private
  
  def set_default_config
    self.config ||= {
      'model' => ENV.fetch('OLLAMA_MODEL', 'phi3'),
      'temperature' => 0.7,
      'max_tokens' => 2000
    }
  end
end