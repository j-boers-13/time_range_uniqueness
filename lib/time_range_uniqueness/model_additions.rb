# frozen_string_literal: true

module TimeRangeUniqueness
  # The `ModelAdditions` module provides a custom validation for ensuring that time ranges
  # in ActiveRecord models are unique across records, optionally scoped by other columns.
  #
  # This module is extended onto ActiveRecord::Base so that models gain a
  # validation method to check for overlapping time ranges between records.
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
  # * +ModelAdditions.overlapping?+ - Internal helper that checks for overlapping time ranges.
  # * +ModelAdditions.scoped_relation+ - Internal helper that builds the scoped relation.
  #
  # Extending this onto ActiveRecord::Base adds the ability to ensure that
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
      message = options[:message] || 'overlaps with an existing record'

      TimeRangeUniqueness::ModelAdditions.register_constraint(self, time_range_column, scope_columns, message,
                                                              options[:name])

      validate do
        overlapping = TimeRangeUniqueness::ModelAdditions.overlapping?(self, time_range_column, scope_columns)
        errors.add(time_range_column, message) if overlapping
      end
    end

    def self.register_constraint(model, time_range_column, scope_columns, message, name)
      unless model.respond_to?(:time_range_uniqueness_constraints)
        model.class_attribute :time_range_uniqueness_constraints, instance_accessor: false, default: []
        model.prepend(ViolationHandling)
      end

      model.time_range_uniqueness_constraints += [
        { column: time_range_column, scope_columns: scope_columns, message: message, name: name }
      ]
    end

    def self.violation_constraint_name(error)
      cause = error.cause
      return nil unless defined?(PG::ExclusionViolation) && cause.is_a?(PG::ExclusionViolation)

      result = cause.respond_to?(:result) ? cause.result : nil
      result&.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
    end

    def self.constraint_name_for(model, config)
      return config[:name].to_s if config[:name]

      TimeRangeUniqueness::ConstraintNaming.default_constraint_name(
        model.table_name, config[:scope_columns], config[:column]
      )
    end

    def self.matched_constraint(record, error)
      name = violation_constraint_name(error)
      return unless name

      record.class.time_range_uniqueness_constraints.find do |config|
        constraint_name_for(record.class, config) == name
      end
    end

    module ViolationHandling
      def save(...)
        super
      rescue ActiveRecord::StatementInvalid => e
        apply_time_range_uniqueness_error(e)
        false
      end

      def save!(...)
        super
      rescue ActiveRecord::StatementInvalid => e
        apply_time_range_uniqueness_error(e)
        raise ActiveRecord::RecordInvalid, self
      end

      private

      def apply_time_range_uniqueness_error(error)
        config = TimeRangeUniqueness::ModelAdditions.matched_constraint(self, error)
        raise error unless config

        errors.add(config[:column], config[:message])
      end
    end

    # Checks whether the record's time range overlaps any other record, optionally scoped.
    #
    # @param record [ActiveRecord::Base] The record being validated.
    # @param time_range_column [Symbol] The name of the time range column.
    # @param scope_columns [Array<Symbol>] The columns to scope the uniqueness check.
    # @return [Boolean] True if there is an overlap, false otherwise.
    def self.overlapping?(record, time_range_column, scope_columns)
      time_range = record.public_send(time_range_column)
      return false if time_range.nil?

      # A NULL scope value can never satisfy the exclusion constraint's `=` comparison,
      # so such a record can never conflict at the database level. Mirror that here.
      return false if scope_columns.any? { |col| record.public_send(col).nil? }

      column = record.class.connection.quote_column_name(time_range_column)
      bounds = time_range.exclude_end? ? '[)' : '[]'

      scoped_relation(record, scope_columns)
        .where("#{column} && tstzrange(?, ?, ?)", time_range.begin, time_range.end, bounds)
        .exists?
    end

    # Builds the set of other records to check against, optionally scoped by the given columns.
    #
    # @param record [ActiveRecord::Base] The record being validated.
    # @param scope_columns [Array<Symbol>] The columns to scope the uniqueness check.
    # @return [ActiveRecord::Relation] All other records, scoped by the given columns.
    def self.scoped_relation(record, scope_columns)
      klass = record.class
      # Pair each primary key column with its value so this works for both single
      # and composite primary keys (record.id is an array for composite keys).
      excluded = Array(klass.primary_key).zip(Array(record.id)).to_h
      relation = klass.where.not(excluded)

      scope_columns.each do |col|
        relation = relation.where(col => record.public_send(col))
      end

      relation
    end
  end
end
