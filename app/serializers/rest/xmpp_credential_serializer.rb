# frozen_string_literal: true

class REST::XmppCredentialSerializer < ActiveModel::Serializer
  attributes :jid, :password, :bosh_url, :websocket_url

  def bosh_url
    ENV.fetch('XMPP_BOSH_URL', "https://#{ENV.fetch('XMPP_DOMAIN', 'localhost')}/http-bind")
  end

  def websocket_url
    ENV.fetch('XMPP_WEBSOCKET_URL', "wss://#{ENV.fetch('XMPP_DOMAIN', 'localhost')}/xmpp-websocket")
  end
end 