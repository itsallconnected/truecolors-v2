# frozen_string_literal: true

class CreateChatRooms < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_rooms do |t|
      t.string :room_jid, null: false
      t.string :name, null: false
      t.string :encryption_key
      t.references :creator, foreign_key: { to_table: :users }
      t.boolean :public, default: false

      t.timestamps
    end

    add_index :chat_rooms, :room_jid, unique: true
  end
end