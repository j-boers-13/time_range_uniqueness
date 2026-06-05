# time_range_uniqueness

**time_range_uniqueness** is a Ruby gem that provides ActiveRecord migrations and model validation to ensure that time ranges do not overlap within a table. 

It adds support for creating exclusion constraints on PostgreSQL `tstzrange` columns and validates the uniqueness of time ranges in models.

[![Gem Version](https://badge.fury.io/rb/time_range_uniqueness.svg?icon=si%3Arubygems)](https://badge.fury.io/rb/time_range_uniqueness)
[![rspec](https://github.com/j-boers-13/time_range_uniqueness/actions/workflows/ci.yml/badge.svg)](https://github.com/j-boers-13/time_range_uniqueness/actions/workflows/ci.yml)

## Features

- **Migration Additions**: Adds a custom method for generating exclusion constraints on time range columns in PostgreSQL using `tstzrange`.
- **Model Additions**: Adds validation to ensure time ranges do not overlap with existing records.
- Supports optional scoping to ensure time ranges are unique within specified contexts (e.g., unique per event name).
- Honors the time range's bound inclusivity (`..` vs `...`) so the model validation agrees with the database-level exclusion constraint.
- Translates a database-level exclusion-constraint violation (e.g. from a concurrent write or `save(validate: false)`) into a validation error instead of an unhandled exception.
- Treats a `NULL` scope value as never-conflicting, matching PostgreSQL's exclusion-constraint semantics (`NULL = NULL` is never true).
- Works with models that use a composite primary key.
- Keeps generated constraint names within PostgreSQL's 63-character identifier limit, and raises if a custom `:name` exceeds it.
- Quotes table and column identifiers in the generated migration and validation SQL.

## Requirements

- Ruby >= 3.2
- ActiveRecord >= 7.1, < 9.0
- PostgreSQL with the `btree_gist` extension available

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
class AddEventTimeRangeUniqueness < ActiveRecord::Migration[7.1]
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

The gem also provides model-level validation to ensure time ranges do not overlap. The `validates_time_range_uniqueness` class method is available on all ActiveRecord models, so you can declare it directly in your model like this:

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
