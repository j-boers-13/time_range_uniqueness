# frozen_string_literal: true

require 'spec_helper'

class DummyModel < ActiveRecord::Base
  self.table_name = 'events'
  validates_time_range_uniqueness with: :event_time_range, scope: :event_name
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
end
