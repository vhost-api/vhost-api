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
    abort 'YARD is not available. Run "gem install yard" if you want to use it.'
  end
end
