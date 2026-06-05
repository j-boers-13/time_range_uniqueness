# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TimeRangeUniqueness::ConstraintNaming do
  it 'matches the name the migration generates' do
    migration = Class.new(ActiveRecord::Migration[7.1]).new
    generated = migration.send(:generate_constraint_name, :events, [:event_name], :event_time_range)

    expect(described_class.default_constraint_name(:events, [:event_name], :event_time_range)).to eq(generated)
  end

  it 'truncates long names within the identifier limit' do
    name = described_class.default_constraint_name(:events, [], ('a' * 80).to_sym)

    expect(name.length).to be <= 63
  end
end
