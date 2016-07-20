# frozen_string_literal: true
# vim:ft=ruby
guard :rspec, cmd: 'bundle exec rspec' do
  watch('spec/spec_helper.rb') { 'spec' }
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^spec/factories/.*\.rb$})
  watch(%r{^(controllers|helpers|models|policies)/.*\.rb$})
  watch(%r{^views/.*\.haml$})
end
