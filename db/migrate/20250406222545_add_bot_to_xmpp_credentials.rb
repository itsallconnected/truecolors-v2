# frozen_string_literal: true

class AddBotToXmppCredentials < ActiveRecord::Migration[6.1]
  def change
    # Only add the column if it doesn't already exist
    add_column :xmpp_credentials, :bot, :boolean, default: false unless column_exists?(:xmpp_credentials, :bot)
    add_index :xmpp_credentials, :bot
  end
end