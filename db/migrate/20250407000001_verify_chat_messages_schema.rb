class VerifyChatMessagesSchema < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:chat_messages, :agent_name)
      add_column :chat_messages, :agent_name, :string
    end
    
    unless column_exists?(:chat_messages, :task_name)
      add_column :chat_messages, :task_name, :string
    end
    
    # Ensure correct indices for performance
    unless index_exists?(:chat_messages, [:room_id, :created_at])
      add_index :chat_messages, [:room_id, :created_at]
    end
  end
end
