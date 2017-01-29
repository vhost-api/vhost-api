# frozen_string_literal: true
begin
  require 'logger'
  require 'sequel'
  require 'yaml'
  require 'safe_yaml'
  require 'benchmark'

  app_root = File.expand_path('../../', __FILE__)

  # read database config file
  @environment = ENV['RACK_ENV'] || 'development'
  @dbconfig = YAML.safe_load(
    File.read("#{app_root}/config/database.yml")
  )[@environment]

  case @dbconfig['db_adapter'].upcase
  when 'POSTGRES'
    require 'postgresql'
  when 'MYSQL'
    require 'mysql2'
    @dbconfig['db_adapter'] = 'mysql2'
  end

  Sequel.extension :migration

  MIGRATIONS_PATH = "#{app_root}/database/migrations"

  # setup database connection
  def db
    @db ||= begin
      @db = Sequel.connect(
        adapter:  @dbconfig['db_adapter'],
        host:     @dbconfig['db_host'],
        database: @dbconfig['db_name'],
        user:     @dbconfig['db_user'],
        password: @dbconfig['db_pass'],
        loggers: [Logger.new($stdout, level: :warn)]
      )
    end
  end

  namespace :db do
    desc 'Run migrations'
    task :migrate, [:version] do |t, args|
      puts '=> Migrating'
      time = Benchmark.realtime do
        before = begin
                   db.from(:schema_migrations).all
                 rescue
                   []
                 end

        if args[:version]
          puts "Migrating to version #{args[:version]}"
          Sequel::Migrator.run(db, MIGRATIONS_PATH, target: args[:version].to_i)
        else
          puts 'Migrating to latest'
          Sequel::Migrator.run(db, MIGRATIONS_PATH)
        end

        after = db.from(:schema_migrations).all
        migrations = (after - before).collect { |x| x[:filename] }.join(', ')

        puts "Migrated #{migrations}"
      end
      printf "<= %s done in %.2fs\n", t.name, time
    end
  end
end
