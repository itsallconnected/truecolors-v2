class FixDuplicateMigrations < ActiveRecord::Migration[6.1]
  def up
    # This migration ensures that duplicate migrations with the timestamp 20180813113448 don't conflict
    
    # Check for duplicate entries in schema_migrations table
    conflicting_version = '20180813113448'
    duplicate_count = execute("SELECT COUNT(*) FROM schema_migrations WHERE version = '#{conflicting_version}'").first['count'].to_i
    
    if duplicate_count > 1
      # Handle duplicate by removing extra entries
      execute("DELETE FROM schema_migrations WHERE version = '#{conflicting_version}' LIMIT #{duplicate_count - 1}")
      puts "Fixed duplicate migration entry: #{conflicting_version}"
    end
    
    # Check for other potential duplicate timestamps (uncommon but possible)
    duplicates = execute(
      "SELECT version, COUNT(*) 
       FROM schema_migrations 
       GROUP BY version 
       HAVING COUNT(*) > 1"
    )
    
    duplicates.each do |row|
      version = row['version']
      count = row['count'].to_i
      
      # Keep one entry and remove duplicates
      execute("DELETE FROM schema_migrations WHERE version = '#{version}' LIMIT #{count - 1}")
      puts "Fixed duplicate migration entry: #{version}"
    end
  end

  def down
    # No rollback needed as this is a data fix
  end
end 