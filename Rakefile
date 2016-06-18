# frozen_string_literal; false
# require 'bundler/setup'
require 'yaml'
# require 'logger'
require 'data_mapper'
require 'dm-migrations'
# require 'rake'
require 'rubocop/rake_task'
require 'haml_lint/rake_task'
require 'benchmark'
# require 'logger'
# require 'optparse'
require './init'

@log_level = :warn

def setup_dm
  DataMapper::Logger.new($stdout, @log_level)
  DataMapper::Model.raise_on_save_failure = true
  DataMapper.setup(:default, "#{@dbconfig[:db_adapter]}://" \
                   "#{@dbconfig[:db_user]}:#{@dbconfig[:db_pass]}" \
                   "@#{@dbconfig[:db_host]}/#{@dbconfig[:db_name]}")
end

# configure RuboCop Tasks
RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['-D', '-S', '-E']
end

# configure Haml Linter
HamlLint::RakeTask.new do |t|
  t.files = ['views/*.haml']
end

# create a custom Task that loops through all tests
desc 'Run RuboCop and Haml-Linter'
task test: [:rubocop, :haml_lint]

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

namespace :db do
  setup_dm

  desc 'Reset your db data and initialize layout'
  task :reset do |t|
    puts '=> Resetting'
    time = Benchmark.realtime do
      case @dbconfig[:db_adapter].upcase
      when 'POSTGRES'
        adapter = DataMapper.repository(:default).adapter
        adapter.execute('DROP VIEW IF EXISTS "dkim_lookup";')
        adapter.execute('DROP VIEW IF EXISTS "mail_alias_maps";')
        adapter.execute('DROP VIEW IF EXISTS "mail_sendas_maps";')
        adapter.execute('DROP VIEW IF EXISTS "sftp_user_maps";')
      end
      DataMapper.auto_migrate!
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Perform non destructive auto-migration'
  task :migrate do |t|
    puts '=> Auto-migrate'
    time = Benchmark.realtime do
      DataMapper.auto_upgrade!
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Create the database'
  task :create do |t|
    config = @dbconfig
    user = config[:db_user]
    password = config[:db_pass]
    host = config[:db_host]
    database = config[:db_name] || config[:path].sub(%r{/\//}, '')
    charset = config[:charset] || ENV['CHARSET'] || 'utf8'
    collation = config[:collation] || ENV['COLLATION'] || 'utf8_unicode_ci'

    puts "=> Creating database '#{database}'"

    time = Benchmark.realtime do
      case config[:db_adapter].upcase
      when 'POSTGRES'
        puts 'Creating databases with a PostgreSQL adapter is not supported.'
        puts 'You have to prepare the PostgreSQL database with user and password
              yourself.'
      when 'MYSQL'
        query = [
          'mysql', '-B', '--skip-pager', "--user=#{user}",
          (password.empty? ? '' : "--password=#{password}"),
          (%w(127.0.0.1 localhost).include?(host) ? '-e' : "--host=#{host} -e"),
          "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset}
          DEFAULT COLLATE #{collation}".inspect
        ]
        system(query.compact.join(' '))
      else
        raise 'Error: unsupported database adapter!'
      end
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Drop the database'
  task :drop do |t|
    config = @dbconfig
    user = config[:db_user]
    password = config[:db_pass]
    host = config[:db_host]
    database = config[:db_name] || config[:path].sub(%r{/\//}, '')

    puts "=> Dropping database '#{database}'"
    time = Benchmark.realtime do
      case config[:db_adapter].upcase
      when 'POSTGRES'
        puts 'Dropping databases with a PostgreSQL adapter is not supported.'
        puts 'You have to drop the PostgreSQL database yourself.'
      when 'MYSQL'
        query = [
          'mysql', '-B', '--skip-pager', "--user=#{user}",
          (password.empty? ? '' : "--password=#{password}"),
          (%w(127.0.0.1 localhost).include?(host) ? '-e' : "--host=#{host} -e"),
          "DROP DATABASE IF EXISTS #{database}".inspect
        ]
        system(query.compact.join(' '))
      else
        raise 'Error: unsupported database adapter!'
      end
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Load the seed data from database/seeds.rb'
  task :seed do |t|
    puts '=> Loading seed data'
    time = Benchmark.realtime do
      require './database/seeds.rb'
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Load the test seed data from database/seeds_test.rb for development'
  task :dev do |t|
    puts '=> Loading development seed data'
    time = Benchmark.realtime do
      require './database/seeds_dev.rb'
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Create the database, migrate and init with the seed data'
  task setup: [:create, :migrate, :seed]
end
