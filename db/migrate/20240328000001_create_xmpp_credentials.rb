class CreateXmppCredentialsInitial < ActiveRecord::Migration[6.1]
  def change
    # Skip if the table already exists (helps prevent migration conflicts)
    return if table_exists?(:xmpp_credentials)
    
    create_table :xmpp_credentials do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :username, null: false
      t.string :password, null: false

      t.timestamps
    end
  end
end 