# frozen_string_literal: true

class Api::V1::XmppController < Api::BaseController
  before_action :require_user!
  
  def credentials
    credential = current_user.xmpp_credential
    
    if credential.nil?
      render json: {}, status: :not_found
    else
      render json: {
        username: credential.username,
        password: credential.password
      }
    end
  end
end 