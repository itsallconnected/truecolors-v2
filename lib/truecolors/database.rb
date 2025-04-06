# frozen_string_literal: true

# This file is entirely lifted from GitLab.

# The original file:
# https://gitlab.com/gitlab-org/gitlab/-/blob/69127d59467185cf4ff1109d88ceec1f499f354f/lib/gitlab/database.rb#L244-258

# Copyright (c) 2011-present GitLab B.V.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module Truecolors
  # Database management utilities for Truecolors
  module Database
    # Migration paths
    SCHEMA_PATH          = 'db/schema.rb'
    MIGRATION_PATH       = 'db/migrate'
    POST_MIGRATION_PATH  = 'db/post_migrate'

    class << self
      # Ensures that post-migration tasks are run after initial schema load
      # 
      # @param force [Boolean] Force reload of paths even if already loaded
      def add_post_migrate_path_to_rails(force: false)
        return if !force && ActiveRecord::Base.connection.migration_context.migrations_paths.include?(POST_MIGRATION_PATH)

        ActiveRecord::Base.connection.migration_context.migrations_paths << POST_MIGRATION_PATH
        ActiveRecord::Tasks::DatabaseTasks.migrations_paths << POST_MIGRATION_PATH
      end

      # Get the database version
      #
      # @return [Integer] Current database version
      def schema_version
        if ActiveRecord::Base.connection.table_exists?(:schema_migrations)
          ActiveRecord::SchemaMigration.maximum(:version)&.to_i || 0
        else
          0
        end
      end

      # Get the database timestamp version
      #
      # @return [Time] Timestamp of the last migration
      def schema_version_as_time
        timestamp = schema_version
        timestamp ? Time.at(timestamp / 1000) : nil
      end
      
      # Check if the database is in a pre-migration state
      #
      # @return [Boolean] True if pre-migration
      def pre_migration?
        begin
          # Attempt to check for schema migrations
          ActiveRecord::Base.connection.table_exists?(:schema_migrations)
        rescue ActiveRecord::NoDatabaseError
          return true
        rescue ActiveRecord::StatementInvalid
          return true
        end
        
        false
      end
    end
  end
end
