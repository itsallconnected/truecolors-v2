# frozen_string_literal: true

class XmppController < ApplicationController
  before_action :require_user!

  def credentials
    credential = current_user.xmpp_credential

    if credential.nil?
      render json: {}, status: 404
    else
      render json: {
        username: credential.username,
        password: credential.password,
      }
    end
  end
end
