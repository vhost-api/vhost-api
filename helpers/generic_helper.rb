# frozen_string_literal: true
def return_json_pretty(json)
  JSON.pretty_generate(JSON.load(json)) + "\n"
end

def return_authorized_resource(object: nil)
  return return_json_pretty(
    ApiResponseError.new(
      status_code: 403,
      error_id: 'Not authorized',
      message: $ERROR_INFO.to_s
    ).to_json
  ) if @user.nil?

  return return_json_pretty({}.to_json) if object.nil?

  permitted_attributes = Pundit.policy(@user, object).permitted_attributes
  return_json_pretty(object.to_json(only: permitted_attributes))
end

def return_authorized_collection(object: nil)
  return return_json_pretty(
    ApiResponseError.new(
      status_code: 403,
      error_id: 'Not authorized',
      message: $ERROR_INFO.to_s
    ).to_json
  ) if @user.nil?

  return return_json_pretty({}.to_json) if object.nil? || object.empty?

  permitted_attributes = Pundit.policy(@user, object).permitted_attributes
  return_json_pretty(object.sort.to_json(only: permitted_attributes))
end

def return_resource(object: nil)
  clazz = object.model.to_s.downcase.pluralize

  respond_to do |type|
    type.html do
      haml clazz.to_sym
    end

    type.json do
      return_json_pretty({ clazz => object }.to_json)
    end
  end
end

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

def gen_session_json(session: nil)
  if session.nil?
    '{}'
  else
    JSON.pretty_generate(JSON.load(session.to_hash.to_json))
  end
end

def return_apiresponse(response)
  if response.is_a?(ApiResponseSuccess)
    status response.status_code
    return_json_pretty response.to_json
  elsif response.is_a?(ApiResponseError)
    halt response.status_code, return_json_pretty(response.to_json)
  else
    halt 500
  end
end

def css(*stylesheets)
  stylesheets.map do |stylesheet|
    ['<link href="/', stylesheet, '.css" media="screen, projection"',
     ' rel="stylesheet" />'].join
  end.join
end

def set_title
  @title ||= settings.site_title
end

def set_sidebar_title
  @sidebar_title ||= 'Sidebar'
end

def gen_doveadm_pwhash(password)
  '{SHA512-CRYPT}' + password.crypt('$6$' + SecureRandom.hex(16))
end

def gen_mysql_pwhash(password)
  '*' + Digest::SHA1.hexdigest(Digest::SHA1.digest(password)).upcase
end

def parse_dovecot_quotausage(file)
  if File.exist?(file)
    Integer(IO.read(file).match(%r{/priv\/quota\/storage\n(.*)\n/m})[1])
  else
    'unknown'
  end
end

def mailaccount_quotausage(mailaccount)
  filename = [settings.mail_home,
              mailaccount.email.to_s.split('@')[1],
              mailaccount.email.to_s.split('@')[0],
              '.quotausage'].join('/')
  parse_dovecot_quotausage(filename)
end

def authenticate!
  @user = User.get(session[:user_id])
  # p 'User: ' + user?.to_s + ' ' + @user.to_s
  return_apiresponse(
    ApiResponseError.new(status_code: 403,
                         error_id: 'unauthorized',
                         message: unauthorized_msg)
  ) if @user.nil?
end

def nav_current?(path = '/')
  req_path = request.path.to_s.split('/')[1]
  req_path == path || req_path == path + '/' ? 'current' : nil
end

def sidebar_current?(path = '/')
  req_path = request.path.to_s.split('/')[2]
  req_path == path || req_path == path + '/' ? 'current' : nil
end
