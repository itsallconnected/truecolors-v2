# frozen_string_literal: true

namespace :ollama do
  desc "Initialize Ollama models"
  task init: :environment do
    puts "Initializing Ollama..."
    
    ollama_host = ENV['OLLAMA_HOST'] || 'http://ollama:11434'
    model_name = ENV['OLLAMA_MODEL'] || 'phi3:mini'
    
    require 'net/http'
    require 'json'
    
    # Wait for Ollama to be ready
    max_retries = 30
    count = 0
    ollama_ready = false
    
    until ollama_ready || count >= max_retries
      begin
        uri = URI("#{ollama_host}/api/tags")
        response = Net::HTTP.get_response(uri)
        ollama_ready = response.code == "200"
      rescue => e
        puts "Waiting for Ollama: #{e.message}"
      end
      
      unless ollama_ready
        count += 1
        puts "Waiting for Ollama service... (#{count}/#{max_retries})"
        sleep 10
      end
    end
    
    unless ollama_ready
      puts "Ollama service not available after #{max_retries} attempts."
      exit 1
    end
    
    # Check if model exists
    uri = URI("#{ollama_host}/api/tags")
    response = Net::HTTP.get(uri)
    models = JSON.parse(response)
    
    # API changed in recent Ollama versions - handle both formats
    models_array = models['models'] || models
    model_exists = models_array.any? { |m| 
      (m.is_a?(Hash) && m['name'] == model_name) || 
      (m.is_a?(String) && m == model_name)
    }
    
    unless model_exists
      puts "Pulling #{model_name} model (this may take a while)..."
      uri = URI("#{ollama_host}/api/pull")
      request = Net::HTTP::Post.new(uri)
      request.body = JSON.generate({name: model_name})
      request['Content-Type'] = 'application/json'
      
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end
      
      if response.code == "200"
        puts "Model #{model_name} pulled successfully!"
      else
        puts "Error pulling model: #{response.body}"
        exit 1
      end
    else
      puts "Model #{model_name} already exists"
    end
  end
  
  desc "Check Ollama connection"
  task check: :environment do
    puts "Checking Ollama connection..."
    require 'net/http'
    begin
      ollama_host = ENV['OLLAMA_HOST'] || 'http://localhost:11434'
      uri = URI("#{ollama_host}/api/tags")
      response = Net::HTTP.get_response(uri)
      
      if response.code == "200"
        puts "✅ Ollama is available"
        
        # Check if model is available
        model_name = ENV['OLLAMA_MODEL'] || 'mixtral:instruct'
        models = JSON.parse(response.body)
        models_array = models['models'] || models
        
        if models_array.any? { |m| 
          (m.is_a?(Hash) && m['name'] == model_name) || 
          (m.is_a?(String) && m == model_name)
        }
          puts "✅ Model #{model_name} is available"
        else
          puts "⚠️ Model #{model_name} is not available. Run rake ollama:init to pull it."
        end
      else
        puts "⚠️ Ollama returned error: #{response.code}"
      end
    rescue => e
      puts "❌ Ollama connection error: #{e.message}"
      puts "Make sure Ollama is installed and running"
    end
  end
  
  desc "Pull Ollama model specified in OLLAMA_MODEL env var"
  task pull: :environment do
    model_name = ENV['OLLAMA_MODEL'] || 'mixtral:instruct'
    ollama_host = ENV['OLLAMA_HOST'] || 'http://localhost:11434'
    
    puts "Pulling Ollama model: #{model_name} from #{ollama_host}..."
    
    require 'net/http'
    require 'json'
    
    uri = URI("#{ollama_host}/api/pull")
    request = Net::HTTP::Post.new(uri)
    request.body = JSON.generate({name: model_name})
    request['Content-Type'] = 'application/json'
    
    begin
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.read_timeout = 3600  # 1 hour timeout for large models
        http.request(request)
      end
      
      if response.code == "200"
        puts "✅ Model #{model_name} pulled successfully!"
      else
        puts "❌ Error pulling model: #{response.body}"
      end
    rescue => e
      puts "❌ Error pulling model: #{e.message}"
    end
  end
end
