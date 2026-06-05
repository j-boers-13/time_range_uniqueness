# frozen_string_literal: true

require 'spec_helper'

class ViolationModel < ActiveRecord::Base
  self.table_name = 'violation_events'
  validates_time_range_uniqueness with: :event_time_range, scope: :event_name
end

class CustomNameViolationModel < ActiveRecord::Base
  self.table_name = 'custom_violation_events'
  validates_time_range_uniqueness with: :event_time_range, scope: :event_name, name: 'custom_excl_constraint'
end

RSpec.describe TimeRangeUniqueness::ModelAdditions do
  let(:time_now) { Time.now }
  let(:existing_range) { time_now..(time_now + 1.hour) }
  let(:overlapping_range) { (time_now + 30.minutes)..(time_now + 90.minutes) }

  before(:all) do
    ActiveRecord::Base.connection.create_table(:violation_events, force: true) do |t|
      t.text :event_name, null: false
    end
    ActiveRecord::Base.connection.create_table(:custom_violation_events, force: true) do |t|
      t.text :event_name, null: false
    end
    migration = Class.new(ActiveRecord::Migration[7.1]).new
    migration.add_time_range_uniqueness(:violation_events, with: :event_time_range, scope: :event_name)
    migration.add_time_range_uniqueness(:custom_violation_events, with: :event_time_range, scope: :event_name,
                                                                  name: 'custom_excl_constraint')
  end

  before do
    ViolationModel.create!(event_name: 'Conference', event_time_range: existing_range)
  end

  after do
    ViolationModel.delete_all
    CustomNameViolationModel.delete_all
  end

  describe '#save when validations are skipped' do
    subject(:record) do
      ViolationModel.new(event_name: 'Conference', event_time_range: overlapping_range)
    end

    it 'returns false instead of raising' do
      expect(record.save(validate: false)).to be(false)
    end

    it 'adds the overlap error to the time range column' do
      record.save(validate: false)

      expect(record.errors[:event_time_range]).to include('overlaps with an existing record')
    end
  end

  describe '#save! when validations are skipped' do
    subject(:record) do
      ViolationModel.new(event_name: 'Conference', event_time_range: overlapping_range)
    end

    it 'raises RecordInvalid rather than StatementInvalid' do
      expect { record.save!(validate: false) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'populates the overlap error on the record' do
      record.save!(validate: false)
    rescue ActiveRecord::RecordInvalid
      expect(record.errors[:event_time_range]).to include('overlaps with an existing record')
    end
  end

  describe 'a non-overlap database error' do
    subject(:record) { ViolationModel.new(event_name: nil, event_time_range: overlapping_range) }

    it 're-raises instead of swallowing it as an overlap' do
      expect { record.save(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it 'does not add a spurious overlap error' do
      record.save(validate: false)
    rescue ActiveRecord::StatementInvalid
      expect(record.errors[:event_time_range]).to be_empty
    end
  end

  describe 'a non-conflicting range' do
    subject(:record) do
      ViolationModel.new(event_name: 'Conference', event_time_range: (time_now + 2.hours)..(time_now + 3.hours))
    end

    it 'saves without interference from the wrapper' do
      expect(record.save(validate: false)).to be(true)
    end
  end

  describe 'matching a constraint by its custom name' do
    subject(:record) do
      CustomNameViolationModel.new(event_name: 'Conference', event_time_range: overlapping_range)
    end

    before do
      CustomNameViolationModel.create!(event_name: 'Conference', event_time_range: existing_range)
    end

    it 'still translates the violation into an overlap error' do
      record.save(validate: false)

      expect(record.errors[:event_time_range]).to include('overlaps with an existing record')
    end
  end
end
