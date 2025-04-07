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

class ChatRoom < ApplicationRecord
  # The ChatRoom model represents an XMPP multi-user chat room (MUC)
  
  belongs_to :creator, class_name: 'User', optional: true
  has_many :chat_messages, foreign_key: 'room_id', dependent: :destroy, inverse_of: :room
  has_many :crew_agents, dependent: :destroy
  
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