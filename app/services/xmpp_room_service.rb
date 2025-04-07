# frozen_string_literal: true

class XmppRoomService
  attr_reader :room, :prosody_client

  def initialize(room)
    @room = room
    @prosody_client = ProsodyClient.new
  end

  def create
    # Create a new room on the XMPP server
    result = prosody_client.create_room(
      room_jid: room.room_jid, 
      name: room.name,
      persistent: true,
      public: room.public
    )
    
    result
  end

  def destroy
    # Remove a room from the XMPP server
    prosody_client.delete_room(room_jid: room.room_jid)
  end

  def join_bot_to_room(room_jid, bot_jid)
    # Logic to make the bot join the room
    # This would be handled by the bot itself in practice
  end
end