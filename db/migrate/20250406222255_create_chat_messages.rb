# frozen_string_literal: true

class CreateChatMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :chat_messages do |t|
      t.references :room, null: false, foreign_key: { to_table: :chat_rooms }
      t.references :sender, foreign_key: { to_table: :users }
      t.text :content, null: false
      t.boolean :encrypted, default: true
      t.string :agent_name
      t.string :task_name

      t.timestamps
    end

    add_index :chat_messages, [:room_id, :created_at]
  end
end