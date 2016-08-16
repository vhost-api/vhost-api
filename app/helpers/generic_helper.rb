# frozen_string_literal: true
def gen_doveadm_pwhash(password)
  '{SHA512-CRYPT}' + password.crypt('$6$' + SecureRandom.hex(16))
end

def gen_mysql_pwhash(password)
  '*' + Digest::SHA1.hexdigest(Digest::SHA1.digest(password)).upcase
end

def extract_object_errors(object: nil)
  return {} if object.nil?
  object.errors.map do |v|
    { field: object.errors.invert[v], errors: v }
  end
end

def extract_selected_errors(object: nil, selected: nil)
  return {} if object.nil? || selected.nil?
  all_errors = extract_object_errors(object: object)

  # extract only relevant errors for selected
  all_errors.map do |e|
    e if selected.include?(e[:field])
  end.compact
end

def log_user(level = 'debug', message = '')
  formatted = "user: #{@user.login} (#{@user.id}), #{message}"
  settings.app_logger.send(level, formatted)
end

def log_app_error(message)
  settings.app_logger.info(message)
end

def log_app_action(message)
  settings.app_logger.info(message)
end

# @param program [String]
# @return [Boolean]
def tool_installed?(program)
  _stdout = system("#{program} >/dev/null 2>&1")
  result = $CHILD_STATUS
  exit_code = result.exitstatus
  !exit_code.eql?(127)
end

# @param path [String]
# @return [Boolean]
def check_sieve_script(path = nil)
  return true if path.nil?
  raise(LoadError, 'sievec not found') unless tool_installed?('sievec')

  # perform syntax check
  _stdout = system("sievec #{path} -d - >/dev/null 2>&1")
  exit_code = $CHILD_STATUS.exitstatus

  return_api_error(ApiErrors.[](:invalid_sieve_script)) unless exit_code.eql?(0)

  true
end

# @param path [String]
# @return [String]
def compile_sieve_script(path = nil)
  raise ArgumentError if path.nil?
  raise(LoadError, 'sievec not found') unless tool_installed?('sievec')

  check_sieve_script(path)

  `sievec #{path} -d - 2>&1`
end

# @param svbin [String]
# @return [Fixnum]
def count_sieve_actions(svbin = nil)
  raise ArgumentError if svbin.nil?

  lines = svbin.split("\n")
  actions = 0

  lines.each do |l|
    fields = l.split(':')
    actions += 1 if fields[2].to_s.upcase =~ %r{(REJECT|FILEINTO|KEEP|DISCARD)}
  end

  actions
end

# @param svbin [String]
# @return [Fixnum]
def count_sieve_redirects(svbin = nil)
  raise ArgumentError if svbin.nil?

  lines = svbin.split("\n")
  redirects = 0

  lines.each do |l|
    fields = l.split(':')
    redirects += 1 if fields[2].to_s.upcase =~ %r{(REDIRECT)}
  end

  redirects
end
