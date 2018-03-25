# frozen_string_literal: true

RSpec::Matchers.define :permit do |action|
  match do |policy|
    policy.public_send("#{action}?")
  end

  failure_message do |policy|
    "#{policy.class} does not permit #{action} on #{policy.record} for \
#{policy.user.inspect}."
  end

  failure_message_when_negated do |policy|
    "#{policy.class} does not forbid #{action} on #{policy.record} for \
#{policy.user.inspect}."
  end
end

RSpec::Matchers.define :permit_args do |action, args|
  match do |policy|
    # rubocop:disable Lint/UnneededSplatExpansion
    policy.public_send("#{action}?", *[args])
    # rubocop:enable Lint/UnneededSplatExpansion
  end

  failure_message do |policy|
    "#{policy.class} does not permit #{action} with #{args} on \
#{policy.record.inspect} for #{policy.user.inspect}."
  end

  failure_message_when_negated do |policy|
    "#{policy.class} does not forbid #{action} with #{args} on \
#{policy.record.inspect} for #{policy.user.inspect}."
  end
end
