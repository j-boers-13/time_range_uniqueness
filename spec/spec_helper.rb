# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv/load'
require 'active_record'
require 'rspec'
require 'time_range_uniqueness'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

# Configure ActiveRecord to connect to a test database
ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: ENV.fetch('DB_NAME', nil),
  username: ENV.fetch('DB_USERNAME', nil),
  password: ENV.fetch('DB_PASSWORD', nil),
  host: 'localhost'
)

# Silence migration output
ActiveRecord::Migration.verbose = true

RSpec.configure do |config|
  config.before(:suite) do
    # Reset the schema and create the `events` table
    ActiveRecord::Base.connection.execute('DROP SCHEMA public CASCADE; CREATE SCHEMA public;')
    CreateTestTables.new.change
  end

  config.after(:suite) do
    ActiveRecord::Base.connection.execute('DROP SCHEMA public CASCADE; CREATE SCHEMA public;')
  end
end
