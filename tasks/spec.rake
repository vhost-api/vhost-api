begin
  require 'yaml'
  require 'benchmark'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  puts 'RSpec unavailable'
end
