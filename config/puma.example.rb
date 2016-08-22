# frozen_string_literal: true
environment 'production'

pidfile 'puma.pid'

threads 1, 4
workers 2
preload_app!
quiet

bind 'tcp://127.0.0.1:4567'
