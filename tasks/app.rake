# frozen_string_literal: true

begin
  require 'benchmark'

  # create a custom Task that loops through all tests
  desc 'Run RuboCop'
  task test: [:rubocop]

  desc 'Reset user password'
  task :reset_password, [:username] do |t, args|
    require 'data_mapper'
    require './init'

    if args[:username].nil?
      puts 'ERROR: Please specify a username!'
      next
    end

    puts '=> Generating new password'
    time = Benchmark.realtime do
      user = User.first(login: args[:username])
      if user.nil?
        puts "ERROR: No user found with login: #{args[:username]}"
        next
      end
      password = SecureRandom.hex(8)
      user.password = password
      user.save
      puts "Generated new password for user #{args[:username]}: #{password}"
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end
end
