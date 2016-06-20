begin
  require 'benchmark'

  # create a custom Task that loops through all tests
  desc 'Run RuboCop and Haml-Linter'
  task test: [:rubocop, :haml_lint]
end
