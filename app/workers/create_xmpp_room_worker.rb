# frozen_string_literal: true

class CreateXmppRoomWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'default', retry: 5

  def perform(chat_room_id)
    chat_room = ChatRoom.find_by(id: chat_room_id)
    return if chat_room.nil?

    # Create the room on the XMPP server
    service = XmppRoomService.new(chat_room)
    service.create
  end
end