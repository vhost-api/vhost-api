# VHost-API

This project is still under heavy development.

## Overview

VHost-API is build using Sinatra, a ruby DSL for creating web applications
in Ruby with minimal effort. The classic approach has been favoured over the
modular approach to keep it as simple as possible.

VHost-API rovides an interface that simplifies management of typical vhost-based
webhosting tasks.

Core features:
+ supports both PostgreSQL and MySQL for the internal database
+ managing clients (admin, reseller, client)
+ managing client-based apikeys for authentication
+ managing email domains, aliases, send-as permissions, forwardings (postfix+dovecot)
+ managing DKIM (opendkim)
+ managing quotas through packages, reseller can define their own packages,
	multiple packages can be assigned to users and resellers
+ managing DNS (powerdns is targeted) `not implemented yet`
+ managing virtual hosts and php-fpm pools `not implemented yet`
+ managing sftp accounts `not implemented yet`
+ managing MySQL databases and users for clients `not implemented yet`
+ (more to come...)

The database layout and service configurations are prepared for integration
with other applications. Example configurations for integrating Roundcube
webmail into this setup will be provided (including support for changing
password, vacation autoresponder and custom filter settings using 
pigeonhole/sieve).


The goal is to provide a system administrator with an application, that eases
management of webhosting tasks and gives a certain amount of freedom to
reseller accounts, enabling them to perform more tasks without the need for
an admin with super user privileges.


This application provides the core API and can be used standalone using HTTP
calls using a tool or library of your choice.
However this API is streamlined to be used in cojunction with vhost-api/web-ui,
which provides a webinterface for all the features of this project.

## Motivation

There are some other solutions out there with a comparable scope, namely
`ispconfig`, `cPanel`, `Plesk`, ..., the list goes on.
Those projects have one thing in common:
They are highly integrated and need to be installed using provided installers,
resulting in a setup that doesn't allow any external changes most of the time.

VHost-API is designed in a more flexible manner so that you can freely attach
services to it while retaining some pre-existing configs/setups.

## Requirements

+ Ruby 2.3.0 or above
+ Bundler 1.12.0 or above
+ Opendkim with MySQL/PostgreSQL support
+ Postfix with MySQL/PostgreSQL support
+ Dovecot with MySQL/PostgreSQL support

## Installation and Configuration

1. Clone the git repository to a location of your choice
2. Depending on whether you want to use MySQL or PostgreSQL for the database:
   run either `bundle install --path .vendor/bundle --without postgres development test` or `bundle install --path .vendor/bundle --without mysql development test`
3. Prepare an empty database with user and password
4. Copy example configs for `appconfig.yml` and `database.yml` from `config/*.example.yml` to `config/` and adjust to your preferences
5. Setup the database layout by running `RACK_ENV="production" bundle exec rake db:migrate`
6. Load initial seed data into the db by running `RACK_ENV="production" bundle exec rake db:seed` and make sure to remember the generated admin password
7. Run the application: `RACK_ENV="production" bundle exec rackup`
8. Setup Apache or nginx as reverse proxy with SSL and stuff.

In order for these services to work together you need to make sure everything has the correct permissions assigned.
Take the following hints into consideration and adjust to your preferences:

+ create a second database user for the vhost-api db, that is only granted SELECT for opendkim/postfix/dovecot
+ create the mail data dir: `/var/vmail`
+ add a `vmail` user with its own `vmail` group and `/var/vmail` as homedir
+ set the correct permissions on `/var/vmail` and make sure new folders will inherit correct permissions:
  + `find /var/vmail/ -type d -exec chmod 0750 {} +`
  + `find /var/vmail/ -type f -exec chmod 0640 {} +`
  + `find /var/vmail/ -type d -exec chmod g+s {} \;`
+ make sure the `postfix` user also belongs to the primary group of the `opendkim` user
+ make sure `/var/spool/opendkim/` is accessible by setting it to mode `0750`


### Development setup

+ Prepend `RACK_ENV="development"` for most stuff to set up the environment correctly
+ Install development and test gems by running `bundle install --path .vendor/bundle --with development test`
+ Run the application via `RACK_ENV="development" bundle exec shotgun config.ru` to enable auto-reloading of all files at runtime
+ To empty the database simply run `RACK_ENV="development" bundle exec rake db:reset` and you can load your seed data once again

## Getting started

1. Use the password from [Installation and Configuration: Step 6](#installation-and-configuration) to request an apikey:
   ```
   curl --compress --globoff -i -X POST --data 'user=admin&password=SECRET&apikey_comment=curl' 'https://api.example.com/api/v1/auth/login'
   ```
   You will receive an apiresponse containing the user_id and an apikey, similar to the following:
   ```
   {
     "user_id": 1,
     "apikey": "BJzqrTsgcnsBS4FgHrGlrQnWVctf9gMQblg8Rrn5Fj56MFbT4ltJkqDFq9W66kLp"
   }
   ```

2. Export user_id and apikey in environment variables for more convenience:
   ```
   export VHOSTAPI_USER='1'
   export VHOSTAPI_KEY='BJzqrTsgcnsBS4FgHrGlrQnWVctf9gMQblg8Rrn5Fj56MFbT4ltJkqDFq9W66kLp'
   ```

3. Create your first domain:
   ```
   curl --compress --globoff -i -H "Authorization: VHOSTAPI-KEY $(base64 <<< "${VHOSTAPI_USER}:${VHOSTAPI_KEY}" | tr -d '\n')" -X POST 'https://api.example.com/api/v1/domains?verbose' --data '{"name":"example.com","enabled":true, "user_id":1}'
   ```
   The `?verbose` urlparam is optional but will reveal more detailed error messages from the API, useful when getting started.

4. Looks like we forgot to enable the email feature for that domain, let's change it:
   ```
   curl --compress --globoff -i -H "Authorization: VHOSTAPI-KEY $(base64 <<< "${VHOSTAPI_USER}:${VHOSTAPI_KEY}" | tr -d '\n')" -X PATCH 'https://api.example.com/api/v1/domains/1?verbose' --data '{"mail_enabled":true}'
   ```

5. Create a DKIM keypair for that domain:
   ```
   curl --compress --globoff -i -H "Authorization: VHOSTAPI-KEY $(base64 <<< "${VHOSTAPI_USER}:${VHOSTAPI_KEY}" | tr -d '\n')" -X POST 'https://api.example.com/api/v1/dkims?verbose' --data '{"selector":"mail","enabled":true,"domain_id":1}'
   ```
   Use the public_key that was returned in the apiresonse, remove the `\n` characters and the headers/footer and create a DNS TXT record for `mail._domainkey.example.com` with `v=DKIM1; p=YOURDKIMPUBLICKEY;`.

6. Assign an author to the freshly generated DKIM keypair:
   ```
   curl --compress --globoff -i -H "Authorization: VHOSTAPI-KEY $(base64 <<< "${VHOSTAPI_USER}:${VHOSTAPI_KEY}" | tr -d '\n')" -X POST 'https://api.example.com/api/v1/dkimsignings?verbose' --data '{"author":"example.com","enabled":true,"dkim_id":1}'
   ```

7. Create a mailbox:
   ```
   curl --compress --globoff -i -H "Authorization: VHOSTAPI-KEY $(base64 <<< "${VHOSTAPI_USER}:${VHOSTAPI_KEY}" | tr -d '\n')" -X POST 'https://api.example.com/api/v1/mailaccounts?verbose' --data '{"realname":"Max Mustermann","email":"max@example.com","password":"AVERYSECRETPASSWORD","receiving_enabled":true,"enabled":true,"domain_id":1}'
   ```

8. Allow this mailaccount to also send from its own address (`max@example.com`):
   ```
   curl --compress --globoff -i -H "Authorization: VHOSTAPI-KEY $(base64 <<< "${VHOSTAPI_USER}:${VHOSTAPI_KEY}" | tr -d '\n')" -X POST 'https://api.example.com/api/v1/mailsources?verbose' --data '{"address":"max@example.com","src":[1],"enabled":true,"domain_id":1}'
   ```

If all services (opendkim, postfix, dovecot) are configured properly and running, you should be able to login to your Mailaccount and send & receive emails now, using a client like Thunderbird for example.

In case you receive any errors from the email client, make sure to look in the dovecot/postfix/opendkim log files as well as the log of the VHost-API application.

For a more detailed overview over all the endpoints, parameters and models, please take a look at [Reference documentation](#reference-documentation).


## Reference documentation

http://htmlpreview.github.io/?https://github.com/vhost-api/vhost-api/blob/0.1.3-alpha/resources/doc/html/index.html

## Contributing

### Community contributions

Pull requests and feedback are welcome.

### Bugs

If you believe that you have found a bug, please take a look at the existing issues.
In case no one else has reported the bug yet, please open a new issue and describe
the problem as detailed as possible.

## License

Licensed under the GNU Affero General Public License, Version 3 (the "License").
You may not use this software except in compliance with License.
You should have obtained a copy of the License together with this software,
if not you may obtain a copy at

```
https://www.gnu.org/licenses/agpl-3.0.en.html
```
