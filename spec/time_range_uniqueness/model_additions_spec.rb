# frozen_string_literal: true

require 'spec_helper'

class DummyModel < ActiveRecord::Base
  self.table_name = 'events'
  validates_time_range_uniqueness with: :event_time_range, scope: :event_name
end

class NullableScopeModel < ActiveRecord::Base
  self.table_name = 'nullable_scope_events'
  validates_time_range_uniqueness with: :event_time_range, scope: :group_name
end

class CompositeKeyModel < ActiveRecord::Base
  self.table_name = 'composite_key_events'
  self.primary_key = %i[shop_id booking_no]
  validates_time_range_uniqueness with: :event_time_range, scope: :room
end

RSpec.describe TimeRangeUniqueness::ModelAdditions do
  before(:all) do
    AddTimeRangeUniqueness.new.change
  end

  it 'adds a validation method to ActiveRecord::Base' do
    expect(DummyModel).to respond_to(:validates_time_range_uniqueness)
  end

  context 'when time ranges overlap' do
    let(:event_name) { 'Test Event' }
    let(:time_now) { Time.now }
    let(:event_time_range) { (time_now + 1.hour)..(time_now + 5.hours) }
    let(:overlapping_event) do
      DummyModel.new(
        event_name: event_name,
        event_time_range: (time_now + 2.hours)..(time_now + 6.hours)
      )
    end

    before do
      DummyModel.create!(event_name: event_name, event_time_range: event_time_range)
    end

    after do
      DummyModel.delete_all
    end

    it 'does not allow saving' do
      expect(overlapping_event.save).to be_falsey
    end

    it 'generates an error on save' do
      overlapping_event.save

      expect(overlapping_event.errors[:event_time_range]).to include('overlaps with an existing record')
    end
  end

  context 'when ranges touch at an inclusive boundary' do
    let(:event_name) { 'Boundary Event' }
    let(:time_now) { Time.now }
    let(:touching_event) do
      DummyModel.new(
        event_name: event_name,
        event_time_range: (time_now - 1.hour)..time_now
      )
    end

    before do
      DummyModel.create!(event_name: event_name, event_time_range: time_now..(time_now + 1.hour))
    end

    after do
      DummyModel.delete_all
    end

    it 'does not allow saving' do
      expect(touching_event.save).to be_falsey
    end

    it 'generates an error on save' do
      touching_event.save

      expect(touching_event.errors[:event_time_range]).to include('overlaps with an existing record')
    end
  end

  context 'when a scoped column is null' do
    let(:time_now) { Time.now }
    let(:duplicate) do
      NullableScopeModel.new(group_name: nil, event_time_range: time_now..(time_now + 1.hour))
    end

    before(:all) do
      ActiveRecord::Base.connection.create_table(:nullable_scope_events, force: true) { |t| t.text :group_name }
      Class.new(ActiveRecord::Migration[7.1]).new.add_time_range_uniqueness(
        :nullable_scope_events, with: :event_time_range, scope: :group_name
      )
    end

    before do
      NullableScopeModel.create!(group_name: nil, event_time_range: time_now..(time_now + 1.hour))
    end

    after do
      NullableScopeModel.delete_all
    end

    it 'permits overlapping ranges, matching the database which never conflicts on null scopes' do
      expect(duplicate.save).to be_truthy
    end
  end

  context 'with a composite primary key' do
    let(:time_now) { Time.now }
    let(:overlapping) do
      CompositeKeyModel.new(shop_id: 1, booking_no: 2, room: 'A',
                            event_time_range: (time_now + 30.minutes)..(time_now + 90.minutes))
    end

    before(:all) do
      ActiveRecord::Base.connection.create_table(:composite_key_events, primary_key: %i[shop_id booking_no],
                                                                        force: true) do |t|
        t.bigint :shop_id, null: false
        t.bigint :booking_no, null: false
        t.text :room, null: false
      end
      Class.new(ActiveRecord::Migration[7.1]).new.add_time_range_uniqueness(
        :composite_key_events, with: :event_time_range, scope: :room
      )
    end

    before do
      CompositeKeyModel.create!(shop_id: 1, booking_no: 1, room: 'A',
                                event_time_range: time_now..(time_now + 1.hour))
    end

    after do
      CompositeKeyModel.delete_all
    end

    it 'detects overlaps without raising on the composite key' do
      expect(overlapping.save).to be_falsey
    end

    it 'does not flag a persisted record as conflicting with itself' do
      expect(CompositeKeyModel.find([1, 1])).to be_valid
    end
  end
end
