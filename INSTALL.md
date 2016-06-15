# Installation

1. Clone the git repository to a location of your choice
2. Depending on whether you want to use MySQL or PostgreSQL for the database:
   run either `bundle install --without postgres` or `bundle install --without mysql`
3. Prepare a database with user and password
4. Copy example configs for `application.yml` and `database.yml` from `config/*.example.yml` to `config/` and adjust to your preferences
5. Setup the database layout by running `bundle exec rake db:migrate`
6. Load initial seed data into the db by running `bundle exec rake db:seed`
7. Create a session secret for Rack::Session:Cookie by running `bundle exec rake session:invalidate`
8. Run the application: `RACK_ENV="production" bundle exec rackup`
9. Setup Apache or nginx as reverse proxy with SSL and stuff.


## Development setup

+ Instead of `bundle exec rake db:seed` use `db:dev` to fill the database with some testdata from `database/seeds_test.rb`
+ Run the application via `bundle exec shotgun config.ru` to enable auto-reloading of all files at runtime
+ To empty the database simply run `bundle exec rake db:reset` and you can load your seed data all over again
