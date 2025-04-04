# frozen_string_literal: true

class XmppUsernameUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 5

  def perform(user_id, old_jid, new_jid)
    user = User.find_by(id: user_id)
    return if user.nil? || user.xmpp_credential.nil?
    
    # This handles username changes by recreating the account
    # Since Prosody doesn't have a direct username rename function
    old_username = old_jid.split('@').first
    new_username = new_jid.split('@').first
    
    prosody_client = ProsodyClient.new
    # Delete the old user account
    prosody_client.delete_user(username: old_username)
    
    # Create a new user account with the updated username
    prosody_client.register_user(
      username: new_username,
      password: user.xmpp_credential.password
    )
  rescue => e
    Rails.logger.error "Error updating XMPP username for user #{user_id} (#{old_jid} -> #{new_jid}): #{e.message}"
  end
end 