## [Unreleased]

## [1.0.3] - 2026-06-05

- Translate the database-level exclusion-constraint violation into a validation error instead of
  letting it surface as an unhandled `ActiveRecord::StatementInvalid`. This closes the gap left by
  the model validation's check-then-insert: a conflict introduced by a concurrent write or by
  `save(validate: false)` now adds the overlap error to the time range column (`save` returns
  `false`, `save!` raises `ActiveRecord::RecordInvalid`). Unrelated database errors still propagate.
- Run the test suite against ActiveRecord 7.1, 7.2, and 8.0 in CI to back the supported version range.

## [1.0.2] - 2026-05-31

- Update the README to match the current behavior: document the Ruby >= 3.2 and
  ActiveRecord >= 7.1 requirements, correct the migration example's version stamp, clarify
  that `validates_time_range_uniqueness` is available on all models, and list the
  validation/constraint behavior added in 1.0.0 and 1.0.1.

## [1.0.1] - 2026-05-31

- Fix the overlap validation to treat a `NULL` scope value as never-conflicting, matching
  the exclusion constraint (`NULL = NULL` is never true in PostgreSQL). Previously the
  validation reported a false overlap for rows the database would accept.
- Support models with a composite primary key in the overlap validation. Previously the
  validation raised `ArgumentError` when excluding the current record, so such models
  could not be validated or created.
- Raise `ArgumentError` when a custom `:name` exceeds PostgreSQL's 63-character identifier
  limit, instead of relying on the database to truncate it silently.

## [1.0.0] - 2026-05-31

- Require Ruby >= 3.2 and support ActiveRecord 7.1 through 8.x (and pg >= 1.5).
- Fix the overlap validation to honor the time range's bound inclusivity (`..` vs `...`)
  so it agrees with the PostgreSQL exclusion constraint. Previously a record whose
  inclusive endpoint touched an existing record passed validation but was rejected by
  the database with an unhandled `ExclusionViolation`.
- Use the model's primary key instead of assuming a column named `id` when excluding the
  current record from the overlap check.
- The model validation is now only extended onto `ActiveRecord::Base` (rather than also
  being included), so its helpers no longer leak onto every record instance.
- **Breaking:** `add_time_range_uniqueness` now raises `ArgumentError` when the `:with`
  option is omitted, matching `validates_time_range_uniqueness`.
- Generated constraint names are kept within PostgreSQL's 63-character identifier limit
  (long names are truncated with a digest suffix to stay deterministic and collision-free).
- Quote table and column identifiers in the generated migration and validation SQL.

## [0.1.0] - 2024-09-15

- Initial release
