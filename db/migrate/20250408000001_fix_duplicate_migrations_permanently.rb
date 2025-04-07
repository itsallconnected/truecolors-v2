# frozen_string_literal: true

class FixDuplicationsMigrationsPermanently < ActiveRecord::Migration[6.1]
  def up
    # This migration ensures that the problematic duplicate migrations from 2018
    # are permanently marked as run, regardless of whether they exist as files
    problematic_versions = [
      '20180813113448',
      '20180813113449'
    ]

    # First, check if these migrations are in the schema_migrations table
    problematic_versions.each do |version|
      if !migration_exists?(version)
        # Add the migration as "already run" to the schema_migrations table
        execute("INSERT INTO schema_migrations (version) VALUES ('#{version}')")
        puts "Added missing migration record: #{version}"
      else
        puts "Migration #{version} already exists in schema_migrations table"
      end
    end

    # Ensure the database structure doesn't have the columns these migrations were trying to remove
    # Only run this if the columns actually exist
    if table_exists?(:statuses) && column_exists?(:statuses, :reblogs_count)
      remove_column :statuses, :reblogs_count
      puts "Removed reblogs_count column from statuses table"
    end

    if table_exists?(:statuses) && column_exists?(:statuses, :favourites_count)
      remove_column :statuses, :favourites_count
      puts "Removed favourites_count column from statuses table"
    end

    puts "Duplicate migration issue permanently fixed!"
  end

  def down
    # No rollback - this is a one-way fix
    puts "This migration cannot be rolled back as it's a permanent fix"
  end

  private

  def migration_exists?(version)
    count = execute("SELECT COUNT(*) as count FROM schema_migrations WHERE version = '#{version}'").first["count"]
    count.to_i > 0
  end
end 