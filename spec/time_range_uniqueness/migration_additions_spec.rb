# frozen_string_literal: true

require 'spec_helper'
require 'active_record'

class AddTimeRangeUniqueness < ActiveRecord::Migration[6.1]
  def change
    add_time_range_uniqueness :events, with: :event_time_range, scope: :event_name
  end
end

class AddTimeRangeUniquenessNoScope < ActiveRecord::Migration[6.1]
  def change
    add_time_range_uniqueness :events, with: :event_time_range # No scope provided
  end
end

class AddTimeRangeUniquenessWithCustomName < ActiveRecord::Migration[6.1]
  def change
    add_time_range_uniqueness :events, with: :event_time_range, scope: :event_name, name: 'custom_time_range_constraint'
  end
end

RSpec.describe TimeRangeUniqueness::MigrationAdditions, type: :migration do
  let(:table_name) { :events }
  let(:time_range_column) { :event_time_range }
  let(:scope_column) { :event_name }
  let(:default_constraint_name) { "exclude_#{table_name}_on_#{scope_column}_#{time_range_column}" }

  let(:default_constraint_query) do
    <<-SQL
      SELECT conname
      FROM pg_constraint
      WHERE conname = '#{default_constraint_name}';
    SQL
  end

  let(:custom_constraint_query) do
    <<-SQL
      SELECT conname
      FROM pg_constraint
      WHERE conname = 'custom_time_range_constraint';
    SQL
  end

  let(:result) do
    ActiveRecord::Base.connection.execute(default_constraint_query)
  end

  describe 'when applying and reverting the time range uniqueness constraint' do
    before :all do
      # Apply the time range uniqueness constraint with default scope
      AddTimeRangeUniqueness.new.change
    end

    it 'adds the time range column to the table' do
      expect(ActiveRecord::Base.connection).to be_column_exists(table_name, time_range_column)
    end

    it 'creates the exclusion constraint' do
      expect(result).to be_any
    end

    context 'when rolling back the time range uniqueness constraint' do
      before do
        # Revert the migration to remove the uniqueness constraint and time range column
        ActiveRecord::Migration.revert(AddTimeRangeUniqueness)
      end

      it 'removes the exclusion constraint' do
        expect(result).to be_none
      end

      it 'removes the time range column from the table' do
        expect(ActiveRecord::Base.connection).not_to be_column_exists(table_name, time_range_column)
      end
    end
  end

  describe 'when no scope is provided' do
    before :all do
      AddTimeRangeUniquenessNoScope.new.change
    end

    it 'adds the time range column to the table' do
      expect(ActiveRecord::Base.connection).to be_column_exists(table_name, time_range_column)
    end

    it 'creates the exclusion constraint without scope' do
      query_no_scope = <<-SQL
        SELECT conname
        FROM pg_constraint
        WHERE conname = 'exclude_#{table_name}_on_#{time_range_column}';
      SQL

      result_no_scope = ActiveRecord::Base.connection.execute(query_no_scope)

      expect(result_no_scope).to be_any
    end

    context 'when rolling back the migration with no scope' do
      before do
        ActiveRecord::Migration.revert(AddTimeRangeUniquenessNoScope)
      end

      it 'removes the exclusion constraint' do
        query_no_scope = <<-SQL
          SELECT conname
          FROM pg_constraint
          WHERE conname = 'exclude_#{table_name}_on_#{time_range_column}';
        SQL

        result_no_scope = ActiveRecord::Base.connection.execute(query_no_scope)

        expect(result_no_scope).to be_none
      end

      it 'removes the time range column from the table' do
        expect(ActiveRecord::Base.connection).not_to be_column_exists(table_name, time_range_column)
      end
    end
  end

  describe 'when a custom constraint name is provided' do
    before :all do
      AddTimeRangeUniquenessWithCustomName.new.change
    end

    it 'creates the exclusion constraint with the custom name' do
      result_custom = ActiveRecord::Base.connection.execute(custom_constraint_query)

      expect(result_custom).to be_any
    end

    context 'when rolling back the migration with custom name' do
      before do
        ActiveRecord::Migration.revert(AddTimeRangeUniquenessWithCustomName)
      end

      it 'removes the custom exclusion constraint' do
        result_custom = ActiveRecord::Base.connection.execute(custom_constraint_query)

        expect(result_custom).to be_none
      end

      it 'removes the time range column from the table' do
        expect(ActiveRecord::Base.connection).not_to be_column_exists(table_name, time_range_column)
      end
    end
  end
end
