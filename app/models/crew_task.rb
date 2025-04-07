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
end