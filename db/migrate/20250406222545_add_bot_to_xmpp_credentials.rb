# frozen_string_literal: true

class AddBotToXmppCredentials < ActiveRecord::Migration[7.0]
  def change
    add_column :xmpp_credentials, :bot, :boolean, default: false
    add_index :xmpp_credentials, :bot
  end
end