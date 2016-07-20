# frozen_string_literal: true
begin
  require 'yaml'
  require 'benchmark'

  namespace :session do
    desc 'Generate new session secret'
    task :invalidate do |t|
      puts '=> Generating new session secret'
      time = Benchmark.realtime do
        open('config/session.secret', 'w') do |f|
          f << SecureRandom.hex(16)
        end
      end
      printf "<= %s done in %.2fs\n", t.name, time
    end
  end
end
