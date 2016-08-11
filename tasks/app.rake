# frozen_string_literal: true
begin
  require 'benchmark'

  # create a custom Task that loops through all tests
  desc 'Run RuboCop'
  task test: [:rubocop]
end
