# frozen_string_literal: true

class RenameCreateXmppCredentials < ActiveRecord::Migration[6.1]
  def change
    # Skip this migration as it was renamed and refactored into a newer file
    # This prevents the duplicate migration issue
    # The actual implementation is in 20240328000001_create_xmpp_credentials.rb
  end
end 