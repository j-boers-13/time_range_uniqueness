# time_range_uniqueness

**time_range_uniqueness** is a Ruby gem that provides ActiveRecord migrations and model validation to ensure that time ranges do not overlap within a table. 

It adds support for creating exclusion constraints on PostgreSQL `tstzrange` columns and validates the uniqueness of time ranges in models.

[![rspec](https://github.com/j-boers-13/time_range_uniqueness/actions/workflows/ci.yml/badge.svg)](https://github.com/j-boers-13/time_range_uniqueness/actions/workflows/ci.yml)

## Features

- **Migration Additions**: Adds a custom method for generating exclusion constraints on time range columns in PostgreSQL using `tstzrange`.
- **Model Additions**: Adds validation to ensure time ranges do not overlap with existing records.
- Supports optional scoping to ensure time ranges are unique within specified contexts (e.g., unique per event name).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'time_range_uniqueness'
```

Then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install time_range_uniqueness
```

## Usage

### Migration Additions

In your migrations, you can use the `add_time_range_uniqueness` method to add a time range column with an exclusion constraint. This will prevent overlapping time ranges in your table.

#### Options:
- `with`: **(Required)** The name of the column that stores the time range.
- `scope`: **(Optional)** An array of columns to scope the uniqueness check (e.g., `:event_name`).
- `name`: **(Optional)** The name of the exclusion constraint. If not provided, a default name is generated.

### Example

```ruby
class AddEventTimeRangeUniqueness < ActiveRecord::Migration[6.1]
  def change
    add_time_range_uniqueness :events,
                              with: :event_time_range,
                              scope: :event_name, # Optional scope
                              name: 'unique_event_time_ranges' # Optional custom constraint name
  end
end
```

This example ensures that the `event_time_range` column in the `events` table is unique within the scope of the `event_name` column.

### Model Additions

The gem also provides model-level validation to ensure time ranges do not overlap. You can include this validation in your models like this:

#### Options:
- `with`: **(Required)** The name of the time range column to validate.
- `scope`: **(Optional)** An array of columns to scope the uniqueness check (e.g., `:event_name`).
- `message`: **(Optional)** A custom error message when validation fails (default: `'overlaps with an existing record'`).

#### Examples:

```ruby
class Event < ActiveRecord::Base
  validates_time_range_uniqueness(
    with: :event_time_range,
    scope: :event_name,
    message: 'cannot overlap with an existing event'
  )
end
```

This example ensures that the `event_time_range` in the `Event` model does not overlap with other events with the same `event_name` and will display the message `cannot overlap with an existing event` when it does.

### PostgreSQL Requirements

Ensure that your PostgreSQL instance has the `btree_gist` extension enabled. The gem will automatically attempt to enable this extension when applying the migration.

```sql
CREATE EXTENSION IF NOT EXISTS btree_gist;
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/j-boers-13/time_range_uniqueness](https://github.com/j-boers-13/time_range_uniqueness)

## License

The gem is available as open-source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
