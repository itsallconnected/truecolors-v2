# frozen_string_literal: true

# == Schema Information
#
# Table name: chat_messages
#
# id             :bigint(8)        not null, primary key
# room_id        :bigint(8)        not null
# sender_id      :bigint(8)
# content        :text             not null
# encrypted      :boolean          default(TRUE)
# agent_name     :string
# task_name      :string
# created_at     :datetime         not null
# updated_at     :datetime         not null
#
# Indexes
#
#  index_chat_messages_on_room_id                (room_id)
#  index_chat_messages_on_room_id_and_created_at (room_id, created_at)
#  index_chat_messages_on_sender_id              (sender_id)
#
# Foreign Keys
#
#  fk_rails_...  (room_id => chat_rooms.id)
#  fk_rails_...  (sender_id => users.id)
#

class ChatMessage < ApplicationRecord
  # The ChatMessage model stores messages sent in XMPP chat rooms
  # Messages can be from regular users or AI agents
  
  belongs_to :room, class_name: 'ChatRoom'
  belongs_to :sender, class_name: 'User', optional: true
  
  validates :content, presence: true
  
  # Encrypt the message content in the database
  encrypts :content
  
  # Scopes for filtering messages
  scope :recent, -> { order(created_at: :desc) }
  scope :by_agent, ->(agent_name) { where(agent_name: agent_name) }
  scope :by_task, ->(task_name) { where(task_name: task_name) }
  
  # Method to check if this message is from an AI agent
  def from_agent?
    agent_name.present?
  end
  
  # Method to summarize or get excerpt of message
  def excerpt(length = 100)
    return '' if content.blank?
    
    if encrypted && sender_id.blank?
      '[Encrypted message]'
    else
      content.truncate(length)
    end
  end
end