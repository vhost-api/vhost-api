# frozen_string_literal: true

begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files = ['./controllers/**/*.rb',
               './helpers/**/*.rb',
               './models/**/*.rb',
               './policies/**/*.rb']
  end
rescue LoadError
  task :yard do
    abort 'YARD is not available. In order to run yard, you must install yard'
  end
end
