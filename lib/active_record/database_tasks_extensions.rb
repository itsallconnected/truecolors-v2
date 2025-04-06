# frozen_string_literal: true

require_relative '../truecolors/database'
require_relative '../truecolors/snowflake'

module ActiveRecord
  module Tasks
    module DatabaseTasks
      original_load_schema = instance_method(:load_schema)

      define_method(:load_schema) do |db_config, *args|
        Truecolors::Database.add_post_migrate_path_to_rails(force: true)

        ActiveRecord::Base.establish_connection(db_config)
        Truecolors::Snowflake.define_timestamp_id

        original_load_schema.bind_call(self, db_config, *args)

        Truecolors::Snowflake.ensure_id_sequences_exist
      end
    end
  end
end
