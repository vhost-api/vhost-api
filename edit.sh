#!/bin/bash

# shellcheck disable=SC2046
exec vim vhost_api_app.rb init.rb Gemfile Rakefile config.ru $(find ./{config,database,models,controllers,helpers,views,public,policies,spec} -type f -not -iname 'jquery-*.js' -not -name '.keep' -not -iname '*.example.*' -not -iname '*.png'| tr '\n' ' ')
