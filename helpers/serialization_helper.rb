# frozen_string_literal: true

# @param defaults [Hash]
# @param options [Hash]
# @return [Hash]
def model_serialization_opts(defaults: nil, options: {})
  return {} if defaults.nil? || defaults.empty?

  options = defaults.merge(options)

  # force exclude over only
  unless options[:only].nil?
    options[:exclude].each do |prop|
      options[:only].delete(prop) if options[:only].include?(prop)
    end
  end

  fix_options_override(options)
end

# @param options [Hash]
# @return [Hash]
def fix_options_override(options = nil)
  return nil if options.nil?
  # Fix options array if exclude/only parameters are given.
  if options.include?(:only) || options.include?(:exclude)
    # fix methods override
    unless options[:methods].nil?
      options[:methods] = cleanup_json_opts(options, :methods)
    end

    # fix relationships override
    unless options[:relationships].nil?
      options[:relationships] = cleanup_json_opts(options, :relationships)
    end
  end
  options
end

# @param options [Hash]
# @param child [Symbol]
# @return [Hash]
def cleanup_json_opts(options = nil, child = nil)
  only_props = Array(options[:only])
  excl_props = Array(options[:exclude])
  options[child].delete_if do |prop|
    if only_props.include?(prop)
      false
    else
      excl_props.include?(prop) ||
        !(only_props.empty? || only_props.include?(prop))
    end
  end
end
