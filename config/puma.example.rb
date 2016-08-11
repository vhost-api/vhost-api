# frozen_string_literal: true
environment 'production'

pidfile 'puma.pid'

threads 0, 1
workers 1
preload_app!

# daemonize true

bind 'tcp://127.0.0.1:4567'
