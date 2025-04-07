namespace :crew_bot do
    desc "Start the CrewAI XMPP bot"
    task start: :environment do
      require 'open3'
      
      # Get bot credentials from database or environment
      bot_jid = ENV['XMPP_ADMIN_JID'] || Rails.application.credentials.crew_bot[:jid]
      bot_password = ENV['XMPP_ADMIN_PASSWORD'] || Rails.application.credentials.crew_bot[:password]
      
      # Construct database URL from individual credentials
      db_host = ENV['DB_HOST'] || 'localhost'
      db_port = ENV['DB_PORT'] || '5432'
      db_user = ENV['DB_USER'] || 'postgres'
      db_pass = ENV['DB_PASS'] || ''
      db_name = ENV['DATABASE'] || ENV['DB_NAME'] || 'truecolors_production'
      ssl_mode = ENV['SSL_MODE'] || 'prefer'
      
      db_url = "postgresql://#{db_user}:#{db_pass}@#{db_host}:#{db_port}/#{db_name}?sslmode=#{ssl_mode}"
      
      # Path to the bot script
      bot_script = Rails.root.join('lib', 'crewai', 'xmpp_bot.py')
      
      # Start the bot
      cmd = "python #{bot_script} --jid #{bot_jid} --password #{bot_password} --db-url #{db_url}"
      
      puts "Starting CrewAI XMPP bot..."
      Open3.popen2e(cmd) do |_stdin, stdout_err, wait_thr|
        while (line = stdout_err.gets)
          puts line
        end
        
        puts "Bot process exited with status: #{wait_thr.value}"
      end
    end
    
    desc "Load agents and tasks from YAML into database"
    task load_config: :environment do
      require 'yaml'
      
      # Load agents
      agents_yaml = YAML.load_file(Rails.root.join('config', 'agents.yaml'))
      agents_yaml.each do |name, config|
        ChatRoom.all.each do |room|
          agent = CrewAgent.find_or_initialize_by(chat_room: room, name: name)
          agent.update!(
            role: config['role'],
            goal: config['goal'],
            backstory: config['backstory'],
            active: true
          )
          puts "Added agent #{name} to room #{room.name}"
        end
      end
      
      # Load tasks
      tasks_yaml = YAML.load_file(Rails.root.join('config', 'tasks.yaml'))
      tasks_yaml.each do |name, config|
        CrewAgent.all.each do |agent|
          task = CrewTask.find_or_initialize_by(crew_agent: agent, name: name)
          task.update!(
            description: config['description'],
            expected_output: config['expected_output'],
            active: true
          )
          puts "Added task #{name} to agent #{agent.name}"
        end
      end
    end
    
    desc "Setup systemd service for CrewAI bot"
    task setup_service: :environment do
      require 'erb'
      
      # Get credentials
      bot_jid = ENV['XMPP_ADMIN_JID'] || Rails.application.credentials.crew_bot[:jid]
      bot_password = ENV['XMPP_ADMIN_PASSWORD'] || Rails.application.credentials.crew_bot[:password]
      
      # Construct database URL
      db_host = ENV['DB_HOST'] || 'localhost'
      db_port = ENV['DB_PORT'] || '5432'
      db_user = ENV['DB_USER'] || 'postgres'
      db_pass = ENV['DB_PASS'] || ''
      db_name = ENV['DATABASE'] || ENV['DB_NAME'] || 'truecolors_production'
      ssl_mode = ENV['SSL_MODE'] || 'prefer'
      
      db_url = "postgresql://#{db_user}:#{db_pass}@#{db_host}:#{db_port}/#{db_name}?sslmode=#{ssl_mode}"
      
      # Create service file from template
      template = <<~SERVICE
        [Unit]
        Description=CrewAI XMPP Bot
        After=network.target postgresql.service redis.service
        
        [Service]
        Type=simple
        User=<%= ENV['USER'] || 'mastodon' %>
        WorkingDirectory=<%= Rails.root %>
        Environment=RAILS_ENV=<%= Rails.env %>
        Environment=OLLAMA_HOST=<%= ENV['OLLAMA_HOST'] || 'http://localhost:11434' %>
        Environment=OLLAMA_MODEL=<%= ENV['OLLAMA_MODEL'] || 'mixtral' %>
        ExecStart=/usr/bin/python3 <%= Rails.root.join('lib', 'crewai', 'xmpp_bot.py') %> --jid <%= bot_jid %> --password <%= bot_password %> --db-url <%= db_url %>
        Restart=on-failure
        RestartSec=5
        
        [Install]
        WantedBy=multi-user.target
      SERVICE
      
      service_content = ERB.new(template).result(binding)
      service_path = Rails.root.join('tmp', 'crewai-xmpp-bot.service')
      
      File.write(service_path, service_content)
      
      puts "Service file created at #{service_path}"
      puts "Run the following commands to install the service:"
      puts "sudo cp #{service_path} /etc/systemd/system/"
      puts "sudo systemctl daemon-reload"
      puts "sudo systemctl enable crewai-xmpp-bot"
      puts "sudo systemctl start crewai-xmpp-bot"
    end

    desc "Initialize CrewAI bot and setup environment"
    task init_environment: :environment do
      # Check if Ollama is available
      puts "Checking Ollama connection..."
      require 'net/http'
      begin
        ollama_host = ENV['OLLAMA_HOST'] || 'http://localhost:11434'
        uri = URI("#{ollama_host}/api/tags")
        response = Net::HTTP.get_response(uri)
        
        if response.code == "200"
          puts "✅ Ollama is available"
        else
          puts "⚠️ Ollama returned error: #{response.code}"
        end
      rescue => e
        puts "❌ Ollama connection error: #{e.message}"
        puts "Make sure Ollama is installed and running"
      end
    end
  end

# Link to Ollama initialization when running in Docker
Rake::Task['crew_bot:start'].enhance do
  if ENV['OLLAMA_HOST']&.include?('ollama:11434')
    Rake::Task['ollama:init'].invoke
  end
end