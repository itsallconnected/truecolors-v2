# frozen_string_literal: true

namespace :fix do
  desc 'Automatically detect and fix all duplicate migrations'
  task migrations: :environment do
    puts "Starting comprehensive duplicate migration detection and repair..."

    # Step 1: Scan all migration files and identify duplicates by timestamp
    migration_files = Dir.glob(Rails.root.join('db', '**', '[0-9]*_*.rb'))
    
    # Group migrations by timestamp (first part of filename)
    migrations_by_timestamp = {}
    migration_files.each do |file_path|
      timestamp = File.basename(file_path).split('_').first
      migrations_by_timestamp[timestamp] ||= []
      migrations_by_timestamp[timestamp] << file_path
    end
    
    # Find duplicates (any timestamp with more than one file)
    duplicates = migrations_by_timestamp.select { |_timestamp, files| files.size > 1 }
    
    if duplicates.empty?
      puts "No duplicate migrations detected! Your migrations are clean."
      exit 0
    end
    
    puts "Found #{duplicates.size} duplicate migration timestamps:"
    duplicates.each do |timestamp, files|
      puts "  Timestamp #{timestamp} has #{files.size} duplicate files:"
      files.each { |f| puts "    - #{f}" }
    end
    
    # Step 2: Ensure all migrations are marked as 'already run' in schema_migrations
    ActiveRecord::Base.connection.transaction do
      duplicates.each do |timestamp, files|
        # Keep only one file (preserving the one in db/migrate if possible)
        files_to_keep = files.select { |f| f.include?('/migrate/') }
        file_to_keep = files_to_keep.first || files.first
        
        # Mark the timestamp as already applied
        count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM schema_migrations WHERE version = '#{timestamp}'").to_i
        if count == 0
          puts "  Adding migration #{timestamp} to schema_migrations table"
          ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES ('#{timestamp}')")
        else
          puts "  Migration #{timestamp} is already in schema_migrations table"
        end
        
        # Remove all duplicate files except the one to keep
        files_to_remove = files - [file_to_keep]
        files_to_remove.each do |file|
          puts "  Removing duplicate migration file: #{file}"
          FileUtils.rm(file) if File.exist?(file)
        end
      end
    end
    
    # Step 3: Document what we've done
    open(Rails.root.join('log', 'fixed_migrations.log'), 'a') do |f|
      f.puts "#{Time.now}: Fixed #{duplicates.size} duplicate migrations"
      duplicates.each do |timestamp, files|
        f.puts "  Timestamp #{timestamp} had #{files.size} files:"
        files.each { |file| f.puts "    - #{file}" }
      end
    end
    
    puts "Migration cleanup completed successfully!"
    puts "A log of the changes has been saved to log/fixed_migrations.log"
  end
  
  desc 'Generate a script to prevent duplicates in CI environments'
  task generate_ci_script: :environment do
    script_path = Rails.root.join('script', 'ci', 'prevent_duplicate_migrations.rb')
    FileUtils.mkdir_p(File.dirname(script_path))
    
    File.open(script_path, 'w') do |f|
      f.puts <<~RUBY
        #!/usr/bin/env ruby
        # frozen_string_literal: true
        
        # This script is designed to run in CI to prevent duplicate migrations
        # It scans for migrations with the same timestamp and fixes the issue
        
        require 'fileutils'
        
        # Get all migration files from db directory
        migration_files = Dir.glob(File.join('db', '**', '[0-9]*_*.rb'))
        
        # Group migrations by timestamp
        migrations_by_timestamp = {}
        migration_files.each do |file_path|
          timestamp = File.basename(file_path).split('_').first
          migrations_by_timestamp[timestamp] ||= []
          migrations_by_timestamp[timestamp] << file_path
        end
        
        # Find duplicates
        duplicates = migrations_by_timestamp.select { |_timestamp, files| files.size > 1 }
        
        if duplicates.empty?
          puts "No duplicate migrations detected!"
          exit 0
        end
        
        puts "Found \#{duplicates.size} duplicate migration timestamps:"
        
        # Handle duplicates
        duplicates.each do |timestamp, files|
          puts "  Timestamp \#{timestamp} has \#{files.size} duplicate files:"
          files.each { |f| puts "    - \#{f}" }
          
          # Decide which file to keep (prefer db/migrate over db/post_migrate)
          files_to_keep = files.select { |f| f.include?('/migrate/') }
          file_to_keep = files_to_keep.first || files.first
          puts "  Keeping \#{file_to_keep}"
          
          # Remove the others
          files_to_remove = files - [file_to_keep]
          files_to_remove.each do |file|
            puts "  Removing \#{file}"
            File.delete(file) if File.exist?(file)
          end
          
          # Ensure there's a SQL instruction to fix the database
          puts "  Adding SQL statement to mark \#{timestamp} as migrated"
          File.open('ensure_migrations.sql', 'a') do |f|
            f.puts "INSERT INTO schema_migrations (version) VALUES ('\#{timestamp}') ON CONFLICT DO NOTHING;"
          end
        end
        
        puts "Created ensure_migrations.sql with fixes for duplicate migrations"
      RUBY
    end
    
    FileUtils.chmod(0755, script_path)
    puts "CI migration prevention script created at #{script_path}"
    puts "Add this to your CI workflow to prevent duplicate migrations"
  end
end 