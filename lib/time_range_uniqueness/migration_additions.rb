# frozen_string_literal: true

module TimeRangeUniqueness
  # This module provides methods for adding and managing time range uniqueness
  # constraints in ActiveRecord migrations.
  #
  # It allows you to add an exclusion constraint to ensure that time ranges do not
  # overlap within a table.
  #
  # == Example
  #
  #   class AddEventTimeRangeUniqueness < ActiveRecord::Migration[6.1]
  #     def change
  #       add_time_range_uniqueness :events,
  #         with: :event_time_range,
  #         scope: :event_name,
  #         name: 'unique_event_time_ranges'
  #     end
  #   end
  #
  # == Options
  #
  # * +:with+ - The name of the column that stores the time range (required).
  # * +:scope+ - (Optional) An array of columns to scope the uniqueness check.
  # * +:name+ - (Optional) The name of the constraint.
  #
  # == Methods
  #
  # * +add_time_range_uniqueness(table, options = {})+ - Adds the time range column and the exclusion constraint.
  # * +CommandRecorder+ - Records the `add_time_range_uniqueness` command so it can be replayed during rollback.
  module MigrationAdditions
    # Adds a time range column and an exclusion constraint to the specified table.
    #
    # This method creates or modifies a column to store time ranges and ensures that
    # no two time ranges overlap for records with the same scoped columns.
    #
    # @param table [Symbol, String] The name of the table to which the time range uniqueness constraint will be added.
    # @param options [Hash] The options for the constraint.
    # @option options [Symbol] :with The name of the time range column.
    # @option options [Array<Symbol>] :scope (Optional) Columns to scope the uniqueness check.
    # @option options [String] :name (Optional) The name of the constraint.
    def add_time_range_uniqueness(table, options = {})
      time_range_column = options[:with] || :time_range
      scope_columns = Array(options[:scope])
      column_type = :tstzrange
      constraint_name = options[:name] || generate_constraint_name(table, scope_columns, time_range_column)

      reversible do |dir|
        dir.up { apply_up_migration(table, time_range_column, column_type, options, constraint_name, scope_columns) }
        dir.down { apply_down_migration(table, time_range_column, constraint_name) }
      end
    end

    private

    # Applies the changes for the up migration.
    #
    # @param table [Symbol, String] The name of the table.
    # @param time_range_column [Symbol] The time range column name.
    # @param column_type [Symbol] The type of the column.
    # @param options [Hash] Additional options for the column.
    # @param constraint_name [String] The name of the constraint.
    # @param scope_columns [Array<Symbol>] The columns used in the scope.
    def apply_up_migration(table, time_range_column, column_type, options, constraint_name, scope_columns)
      setup_extension
      add_column_to_table(table, time_range_column, column_type, options)
      add_exclusion_constraint(table, constraint_name, scope_columns, time_range_column)
    end

    # Applies the changes for the down migration.
    #
    # @param table [Symbol, String] The name of the table.
    # @param time_range_column [Symbol] The time range column name.
    # @param constraint_name [String] The name of the constraint.
    def apply_down_migration(table, time_range_column, constraint_name)
      remove_exclusion_constraint(table, constraint_name)
      remove_column_from_table(table, time_range_column)
    end

    # Generates a default constraint name based on table and columns.
    #
    # @param table [Symbol, String] The name of the table.
    # @param scope_columns [Array<Symbol>] The columns used in the scope.
    # @param time_range_column [Symbol] The time range column name.
    # @return [String] The generated constraint name.
    def generate_constraint_name(table, scope_columns, time_range_column)
      "exclude_#{table}_on_#{[scope_columns, time_range_column].flatten.join('_')}"
    end

    # Ensures the btree_gist extension is enabled.
    def setup_extension
      enable_extension 'btree_gist' unless extension_enabled?('btree_gist')
    end

    # Adds a column to the table if it does not exist.
    #
    # @param table [Symbol, String] The name of the table.
    # @param time_range_column [Symbol] The time range column name.
    # @param column_type [Symbol] The type of the column.
    # @param options [Hash] Additional options for the column.
    def add_column_to_table(table, time_range_column, column_type, options)
      return if column_exists?(table, time_range_column)

      add_column table, time_range_column, column_type, **options.slice(:null, :default)
    end

    # Adds an exclusion constraint to the table.
    #
    # @param table [Symbol, String] The name of the table.
    # @param constraint_name [String] The name of the constraint.
    # @param scope_columns [Array<Symbol>] The columns used in the scope.
    # @param time_range_column [Symbol] The time range column name.
    def add_exclusion_constraint(table, constraint_name, scope_columns, time_range_column)
      columns = scope_columns.map { |col| "#{col} WITH =" }
      columns << "#{time_range_column} WITH &&"
      expression = columns.join(', ')

      execute <<-SQL
        ALTER TABLE #{table}
        ADD CONSTRAINT #{constraint_name}
        EXCLUDE USING GIST (#{expression});
      SQL
    end

    # Removes an exclusion constraint from the table.
    #
    # @param table [Symbol, String] The name of the table.
    # @param constraint_name [String] The name of the constraint.
    def remove_exclusion_constraint(table, constraint_name)
      execute <<-SQL
        ALTER TABLE #{table}
        DROP CONSTRAINT IF EXISTS #{constraint_name};
      SQL
    end

    # Removes a column from the table if it exists.
    #
    # @param table [Symbol, String] The name of the table.
    # @param time_range_column [Symbol] The time range column name.
    def remove_column_from_table(table, time_range_column)
      remove_column table, time_range_column if column_exists?(table, time_range_column)
    end

    # This module extends the ActiveRecord::Migration::CommandRecorder to record
    # the custom `add_time_range_uniqueness` command so that it can be replayed
    # during rollback operations.
    module CommandRecorder
      # Records the `add_time_range_uniqueness` command.
      #
      # @param table [Symbol, String] The name of the table.
      # @param options [Hash] The options for the constraint.
      def add_time_range_uniqueness(table, options = {})
        # Record the command so it can be replayed during rollback
        record(:add_time_range_uniqueness, table, options)
      end
    end
  end
end
