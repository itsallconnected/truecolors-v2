# frozen_string_literal: true

namespace :xmpp do
  desc 'Ensure all users have XMPP credentials'
  task sync_users: :environment do
    domain = ENV.fetch('XMPP_DOMAIN', 'localhost')
    
    puts 'Syncing users with XMPP server...'
    
    User.includes(:account, :xmpp_credential).find_each do |user|
      next if user.account.nil? || user.account.username.blank?
      
      if user.xmpp_credential.nil?
        puts "Creating XMPP credentials for #{user.account.username}"
        
        jid = "#{user.account.username}@#{domain}"
        XmppCredential.create!(user: user, jid: jid)
      else
        puts "XMPP credentials already exist for #{user.account.username}"
      end
    end
    
    puts 'Done!'
  end
  
  desc 'Register users with XMPP server via Prosody REST API'
  task register_with_server: :environment do
    puts 'Registering users with XMPP server...'
    
    # Register each user
    XmppCredential.includes(user: :account).find_each do |credential|
      username = credential.user.account.username
      
      puts "Registering #{username} (#{credential.jid})..."
      
      begin
        prosody_client = ProsodyClient.new
        
        if prosody_client.register_user(
          username: username,
          password: credential.password
        )
          puts "  Successfully registered #{username}"
        else
          puts "  Failed to register #{username}"
        end
      rescue => e
        puts "  Error registering #{username}: #{e.message}"
      end
    end
    
    puts 'Done!'
  end
end 