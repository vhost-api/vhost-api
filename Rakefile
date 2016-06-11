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

@environment = ENV['RACK_ENV'] || 'development'
@dbconfig = YAML.load(File.read('config/database.yml'))[@environment]

def setup_dm
  DataMapper::Logger.new($stdout, @log_level)
  DataMapper::Model.raise_on_save_failure = true
  DataMapper.setup(:default, "#{@dbconfig[:db_adapter]}://" \
                   "#{@dbconfig[:db_user]}:#{@dbconfig[:db_pass]}" \
                   "@#{@dbconfig[:db_host]}/#{@dbconfig[:db_name]}")
end

# configure RuboCop Tasks
RuboCop::RakeTask.new

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

  desc 'Perform auto-migration (reset your db data)'
  task :migrate do |t|
    puts '=> Auto-migrating'
    time = Benchmark.realtime do
      DataMapper.auto_migrate!
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Perform non destructive auto-migration'
  task :upgrade do |t|
    puts '=> Auto-upgrading'
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
      case config[:db_adapter]
      when 'postgres'
        system('createdb', '-E', charset, '-h', host, '-U', user, database)
        DataMapper.auto_upgrade!
        DataMapper.auto_migrate!
      when 'mysql'
        query = [
          'mysql', '-B', '--skip-pager', "--user=#{user}",
          (password.empty? ? '' : "--password=#{password}"),
          (%w(127.0.0.1 localhost).include?(host) ? '-e' : "--host=#{host} -e"),
          "CREATE DATABASE #{database} DEFAULT CHARACTER SET #{charset}
          DEFAULT COLLATE #{collation}".inspect
        ]
        system(query.compact.join(' '))
        DataMapper.auto_upgrade!
        DataMapper.auto_migrate!
      when 'sqlite3'
        DataMapper.setup(DataMapper.repository.name, config)
        DataMapper.auto_migrate!
      else
        raise "Adapter #{config[:db_adapter]} not supported for
               creating databases yet."
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
      case config[:db_adapter]
      when 'postgres'
        system('dropdb', '-h', host, '-U', user, database)
      when 'mysql'
        query = [
          'mysql', '-B', '--skip-pager', "--user=#{user}",
          (password.empty? ? '' : "--password=#{password}"),
          (%w(127.0.0.1 localhost).include?(host) ? '-e' : "--host=#{host} -e"),
          "DROP DATABASE IF EXISTS #{database}".inspect
        ]
        system(query.compact.join(' '))
      when 'sqlite3'
        File.delete(config[:path]) if File.exist?(config[:path])
      else
        raise "Adapter #{config[:db_adapter]} not supported for
               dropping databases yet."
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

  desc 'Load the test seed data from database/seeds_test.rb'
  task :test do |t|
    puts '=> Loading test seed data'
    time = Benchmark.realtime do
      require './database/seeds_test.rb'
    end
    printf "<= %s done in %.2fs\n", t.name, time
  end

  desc 'Drop the database, create from scratch and init with the seed data'
  task reset: [:drop, :setup]

  desc 'Create the database, migrate and init with the seed data'
  task setup: [:create, :migrate, :seed]
end
