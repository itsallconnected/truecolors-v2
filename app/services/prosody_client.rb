# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class ProsodyClient
  def initialize
    @domain = ENV.fetch('XMPP_DOMAIN', 'localhost')
    @admin_jid = ENV.fetch('XMPP_ADMIN_JID', "admin@#{@domain}")
    @admin_password = ENV.fetch('XMPP_ADMIN_PASSWORD', 'admin')
    @api_url = ENV.fetch('PROSODY_REST_API_URL', "http://localhost:5280/rest")
  end

  def register_user(username:, password:)
    authenticate do |token|
      uri = URI.parse("#{@api_url}/users/#{@domain}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, { 
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      })
      
      request.body = { 
        username: username,
        password: password 
      }.to_json
      
      response = http.request(request)
      
      if response.code.to_i == 409
        # User already exists, update password
        update_password(username: username, password: password, token: token)
      end
      
      response.code.to_i == 201 || response.code.to_i == 200
    end
  end
  
  def update_password(username:, password:, token: nil)
    authenticate(token) do |auth_token|
      uri = URI.parse("#{@api_url}/users/#{@domain}/#{username}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Put.new(uri.request_uri, { 
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{auth_token}"
      })
      
      request.body = { password: password }.to_json
      response = http.request(request)
      
      response.code.to_i == 200
    end
  end
  
  def delete_user(username:)
    authenticate do |token|
      uri = URI.parse("#{@api_url}/users/#{@domain}/#{username}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Delete.new(uri.request_uri, { 
        'Authorization' => "Bearer #{token}"
      })
      
      response = http.request(request)
      response.code.to_i == 200
    end
  end
  
  private
  
  def authenticate(token = nil)
    return yield(token) if token.present?
    
    uri = URI.parse("#{@api_url}/auth")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, { 'Content-Type' => 'application/json' })
    request.body = { username: @admin_jid, password: @admin_password }.to_json
    
    response = http.request(request)
    
    if response.code.to_i == 200
      auth_token = JSON.parse(response.body)['token']
      yield(auth_token)
    else
      Rails.logger.error "Failed to authenticate with XMPP server: #{response.body}"
      false
    end
  end
end 