# frozen_string_literal: true

module TimeRangeUniqueness
  # The `ModelAdditions` module provides a custom validation for ensuring that time ranges
  # in ActiveRecord models are unique across records, optionally scoped by other columns.
  #
  # This module is intended to be included in ActiveRecord models and used to add
  # validation methods to check for overlapping time ranges between records.
  #
  # == Example
  #
  #   class Event < ApplicationRecord
  #     validates_time_range_uniqueness(
  #       with: :event_time_range,
  #       scope: :event_name,
  #       message: 'cannot overlap with an existing event'
  #     )
  #   end
  #
  # This example ensures that the `event_time_range` column in the `Event` model does not overlap
  # with other records having the same `event_name`. If a new event's time range overlaps, an
  # error is added to the `event_time_range` field.
  #
  # == Options
  #
  # * +:with+ - The name of the time range column (required).
  # * +:scope+ - (Optional) An array of columns to scope the uniqueness check (e.g., event name).
  # * +:message+ - (Optional) A custom error message when validation fails. Defaults to
  #   'overlaps with an existing record' if not provided.
  #
  # == Methods
  #
  # * +validates_time_range_uniqueness+ - Adds a validation for time range uniqueness.
  # * +validate_records+ - Internal method to perform the validation.
  # * +time_range_column_overlapping?+ - Internal method to check for overlapping time ranges.
  #
  # When included in an ActiveRecord model, this module adds the ability to ensure that
  # the specified time range does not overlap with other records' time ranges, optionally
  # scoped by additional fields.
  module ModelAdditions
    # Adds a custom validation method to ensure that the specified time range column
    # is unique across all records, optionally scoped by other columns.
    #
    # Raises an ArgumentError if the +:with+ option is not specified.
    #
    # @param options [Hash] The options for the validation.
    # @option options [Symbol] :with The name of the time range column.
    # @option options [Array<Symbol>] :scope (Optional) Columns to scope the uniqueness check.
    # @option options [String] :message (Optional) Custom error message when validation fails.
    def validates_time_range_uniqueness(options = {})
      raise ArgumentError, 'You must specify the :with option with the time range column name' unless options[:with]

      time_range_column = options[:with]
      scope_columns = Array(options[:scope])

      validate_records(time_range_column, scope_columns, options)
    end

    private

    # Defines the validation logic for ensuring time range uniqueness.
    #
    # This method is called internally by the validation and checks whether a record's
    # time range overlaps with any other records, optionally scoped by other columns.
    #
    # @param time_range_column [Symbol] The name of the time range column.
    # @param scope_columns [Array<Symbol>] The columns to scope the uniqueness check.
    # @param options [Hash] The options for the validation.
    def validate_records(time_range_column, scope_columns, options)
      validate do
        time_range = public_send(time_range_column)

        next if time_range.nil?

        relation = self.class.where.not(id: id)

        scope_columns.each do |col|
          relation = relation.where(col => public_send(col))
        end

        overlapping = time_range_column_overlapping?(relation, time_range_column, time_range)

        errors.add(time_range_column, options[:message] || 'overlaps with an existing record') if overlapping
      end
    end

    # Checks if the given time range overlaps with any existing records.
    #
    # This method performs the actual overlap check by querying the database using the
    # GiST index for range data types in PostgreSQL.
    #
    # @param relation [ActiveRecord::Relation] The scope of records to check against.
    # @param time_range_column [Symbol] The name of the time range column.
    # @param time_range [Range] The time range to check for overlap.
    # @return [Boolean] True if there is an overlap, false otherwise.
    def time_range_column_overlapping?(relation, time_range_column, time_range)
      relation.where(
        "#{time_range_column} && tstzrange(?, ?, '[)')",
        time_range.begin,
        time_range.end
      ).exists?
    end
  end
end
