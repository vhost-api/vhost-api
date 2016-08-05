# frozen_string_literal: true
def fix_options_override(options = nil)
  return nil if options.nil?
  # Fix options array if exclude/only parameters are given.
  if options.include?(:only) || options.include?(:exclude)
    return options if options[:methods].nil?
    options[:methods] = cleanup_options_hash(options)
  end
  options
end

def cleanup_options_hash(options = nil)
  only_props = Array(options[:only])
  excl_props = Array(options[:exclude])
  options[:methods].delete_if do |prop|
    if only_props.include?(prop)
      false
    else
      excl_props.include?(prop) ||
        !(only_props.empty? || only_props.include?(prop))
    end
  end
end
