# frozen_string_literal: true

class XmppRegistrationWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 5

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.nil? || user.xmpp_credential.nil?
    
    # Register with the XMPP server
    prosody_client = ProsodyClient.new
    prosody_client.register_user(
      username: user.account.username,
      password: user.xmpp_credential.password
    )
  rescue => e
    Rails.logger.error "Error registering XMPP user #{user&.account&.username}: #{e.message}"
  end
end 