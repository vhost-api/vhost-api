# frozen_string_literal: true
begin
  unless ENV['RACK_ENV'] == 'production'
    require 'haml_lint/rake_task'
    require 'benchmark'

    HamlLint::RakeTask.new do |t|
      t.files = ['views/*.haml']
    end
  end
end
