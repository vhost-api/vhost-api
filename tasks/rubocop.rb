# frozen_string_literal: true
begin
  unless ENV['RACK_ENV'] == 'production'
    require 'rubocop/rake_task'
    require 'benchmark'

    RuboCop::RakeTask.new(:rubocop) do |t|
      t.options = ['-D', '-S', '-E']
    end
  end
end
