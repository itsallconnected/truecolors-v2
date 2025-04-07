# frozen_string_literal: true

namespace :fix do
  desc 'Remove duplicate migration entries from schema.rb'
  task migrations: :environment do
    # Problematic migration timestamps
    problematic_versions = ['20180813113448', '20180813113449']
    
    # Path to the schema.rb file
    schema_path = Rails.root.join('db', 'schema.rb')
    
    puts "Checking for duplicate migrations in schema.rb..."
    
    # Read the schema file
    schema_content = File.read(schema_path)
    
    # We don't need to modify the schema.rb file since it doesn't list all migrations
    
    # Delete duplicate entries from schema_migrations table directly
    problematic_versions.each do |version|
      count = ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM schema_migrations WHERE version = '#{version}'").to_i
      
      if count > 1
        puts "Found #{count} entries for migration #{version} in schema_migrations table."
        puts "Removing duplicates..."
        ActiveRecord::Base.connection.execute("DELETE FROM schema_migrations WHERE version = '#{version}' LIMIT #{count - 1}")
        puts "Kept one entry for migration #{version}."
      elsif count == 1
        puts "Found one entry for migration #{version} - no duplicates to fix."
      else
        puts "Migration #{version} not found in schema_migrations table."
        puts "Adding the migration to schema_migrations table..."
        ActiveRecord::Base.connection.execute("INSERT INTO schema_migrations (version) VALUES ('#{version}')")
        puts "Added missing migration #{version}."
      end
    end
    
    # Remove the actual migration files if they exist
    problematic_versions.each do |version|
      Dir.glob(Rails.root.join("db/**/*#{version}*.rb")).each do |file_path|
        puts "Removing migration file: #{file_path}"
        FileUtils.rm(file_path)
      end
    end
    
    puts "Migration cleanup completed successfully!"
  end
end 