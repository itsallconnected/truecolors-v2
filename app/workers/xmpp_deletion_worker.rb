# frozen_string_literal: true

class XmppDeletionWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 5

  def perform(jid)
    username = jid.split('@').first
    
    # Delete the user from the XMPP server
    prosody_client = ProsodyClient.new
    prosody_client.delete_user(username: username)
  rescue => e
    Rails.logger.error "Error deleting XMPP user #{jid}: #{e.message}"
  end
end 