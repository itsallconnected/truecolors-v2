class CreateXmppCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :xmpp_credentials do |t|
      t.belongs_to :user, null: false, foreign_key: true, index: true
      t.string :jid, null: false, index: { unique: true }
      t.string :password, null: false
      
      t.timestamps
    end
    
    add_index :xmpp_credentials, [:user_id, :jid], unique: true
    
    # Add comment describing the table purpose for future developers
    execute <<-SQL
      COMMENT ON TABLE xmpp_credentials IS 'XMPP/Jabber credentials for chat functionality with OMEMO encryption';
    SQL
  end
end 