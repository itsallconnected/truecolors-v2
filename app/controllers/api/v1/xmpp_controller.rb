# frozen_string_literal: true

class Api::V1::XmppController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :write }
  before_action :require_user!

  # GET /api/v1/xmpp/credentials
  def show
    # Get or create XMPP credentials
    @xmpp_credential = current_user.xmpp_credential || create_credential
    render json: @xmpp_credential, serializer: REST::XmppCredentialSerializer
  end

  # POST /api/v1/xmpp/regenerate
  def regenerate
    @xmpp_credential = current_user.xmpp_credential
    
    if @xmpp_credential.nil?
      @xmpp_credential = create_credential
    else
      @xmpp_credential.update!(password: SecureRandom.base58(24))
    end
    
    render json: @xmpp_credential, serializer: REST::XmppCredentialSerializer
  end

  private

  def create_credential
    jid = "#{current_account.username}@#{ENV.fetch('XMPP_DOMAIN', 'localhost')}"
    XmppCredential.create!(user: current_user, jid: jid)
  end
end 