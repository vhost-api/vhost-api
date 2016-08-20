# Installation

1. Clone the git repository to a location of your choice
2. Depending on whether you want to use MySQL or PostgreSQL for the database:
   run either `bundle install --without postgres development test` or `bundle install --without mysql development test`
3. Prepare an empty database with user and password
4. Copy example configs for `appconfig.yml` and `database.yml` from `config/*.example.yml` to `config/` and adjust to your preferences
5. Setup the database layout by running `RACK_ENV="production" bundle exec rake db:migrate`
6. Load initial seed data into the db by running `RACK_ENV="production" bundle exec rake db:seed`
7. Run the application: `RACK_ENV="production" bundle exec rackup`
8. Setup Apache or nginx as reverse proxy with SSL and stuff.


## Development setup

+ Prepend `RACK_ENV="development"` for most stuff to set up the environment correctly
+ Install development and test gems by running `bundle install --with development test`
+ Instead of `db:seed` use `db:dev` to fill the database with some testdata from `database/seeds_test.rb`
+ Run the application via `RACK_ENV="development" bundle exec shotgun config.ru` to enable auto-reloading of all files at runtime
+ To empty the database simply run `RACK_ENV="development" bundle exec rake db:reset` and you can load your seed data once again
