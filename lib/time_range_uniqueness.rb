# frozen_string_literal: true

require_relative 'time_range_uniqueness/version'
require 'active_record'
require_relative 'time_range_uniqueness/migration_additions'
require_relative 'time_range_uniqueness/model_additions'

module TimeRangeUniqueness
  class Error < StandardError; end

  ActiveRecord::Migration::CommandRecorder.include TimeRangeUniqueness::MigrationAdditions::CommandRecorder

  # Include migration additions into ActiveRecord::Migration
  ActiveRecord::Migration.include TimeRangeUniqueness::MigrationAdditions
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.extend TimeRangeUniqueness::ModelAdditions
  ActiveRecord::Base.include TimeRangeUniqueness::ModelAdditions
end
