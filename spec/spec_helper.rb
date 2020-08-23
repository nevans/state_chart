require "bundler/setup"
require "state_chart"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

end
