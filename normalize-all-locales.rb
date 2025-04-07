#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'

# Normalize all locale files in the config/locales directory
Dir.glob('config/locales/**/*.yml').each do |file_path|
  puts "Normalizing #{file_path}..."

  # Load the YAML file
  begin
    # First pass - read the file as text to check for --- at the beginning
    content = File.read(file_path)
    
    # Ensure it starts with --- on a line by itself
    content = "#{content.start_with?('---' + "\n") ? '' : "---\n"}#{content.sub(/^---\s*\n/, '')}"
    
    # Parse the YAML
    data = YAML.load(content)
    
    # Second pass - write it back with proper formatting
    File.open(file_path, 'w') do |file|
      file.puts '---'
      # Write the converted YAML without the initial ---
      yaml_output = YAML.dump(data)
      file.puts yaml_output.sub(/^---\s*\n/, '')
    end
    
    puts '  ✓ Successfully normalized'
  rescue => e
    puts "  ✗ Error: #{e.message}"
  end
end

puts 'All locale files have been normalized.' 