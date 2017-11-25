# frozen_string_literal: true
begin
  require 'data_mapper'
  require 'dm-migrations'
  require 'benchmark'
  require './init'

  @log_level = :warn

  def setup_dm
    DataMapper::Logger.new($stdout, @log_level)
    DataMapper::Model.raise_on_save_failure = true
    DataMapper.setup(:default,
                     [@dbconfig[:db_adapter], '://',
                      @dbconfig[:db_user], ':', @dbconfig[:db_pass], '@',
                      @dbconfig[:db_host], ':', @dbconfig[:db_port], '/',
                      @dbconfig[:db_name]].join)
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

      puts '=> Creating database ' + database.to_s

      time = Benchmark.realtime do
        case config[:db_adapter].upcase
        when 'POSTGRES'
          puts 'Creating databases with a PostgreSQL adapter is not supported.'
          puts 'You have to prepare the PostgreSQL database with user and'
          puts 'password yourself.'
        when 'MYSQL'
          query = [
            'mysql', '-B', '--skip-pager', '--user=' + user.to_s,
            (password.empty? ? '' : '--password=' + password.to_s),
            (%w(127.0.0.1 localhost).include?(host) ? '-e' : '--host=' +
            host.to_s + ' -e'),
            'CREATE DATABASE ' + database.to_s + ' DEFAULT CHARACTER SET ' +
              charset.to_s + ' DEFAULT COLLATE ' + collation.to_s
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

      puts '=> Dropping database ' + database.to_s
      time = Benchmark.realtime do
        case config[:db_adapter].upcase
        when 'POSTGRES'
          puts 'Dropping databases with a PostgreSQL adapter is not supported.'
          puts 'You have to drop the PostgreSQL database yourself.'
        when 'MYSQL'
          query = [
            'mysql', '-B', '--skip-pager', '--user=' + user.to_s,
            (password.empty? ? '' : '--password=' + password.to_s),
            (%w(127.0.0.1 localhost).include?(host) ? '-e' : '--host=' +
            host.to_s + ' -e'),
            'DROP DATABASE IF EXISTS ' + database.to_s
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

    desc 'Create the database, migrate and init with the seed data'
    task setup: [:create, :migrate, :seed]
  end
end
