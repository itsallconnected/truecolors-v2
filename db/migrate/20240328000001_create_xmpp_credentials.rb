class CreateXmppCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :xmpp_credentials do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :username, null: false
      t.string :password, null: false

      t.timestamps
    end
  end
end 