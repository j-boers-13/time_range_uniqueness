# frozen_string_literal: true

class CreateTestTables < ActiveRecord::Migration[6.1]
  def change
    create_table :events, force: true do |t|
      t.text :event_name, null: false
      t.timestamps
    end
  end
end

class AddTimeRangeUniqueness < ActiveRecord::Migration[6.1]
  def change
    add_time_range_uniqueness :events, with: :event_time_range, scope: :event_name
  end
end
