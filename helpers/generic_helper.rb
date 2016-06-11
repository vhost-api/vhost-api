def return_json_pretty(json)
  JSON.pretty_generate(JSON.load(json)) + "\n"
end

def return_resource(object: nil)
  clazz = object.model.to_s.downcase.pluralize

  respond_to do |type|
    type.html do
      haml clazz.to_sym
    end

    type.json do
      return_json_pretty({clazz => object}.to_json)
    end
  end
end

def gen_session_json(session: nil)
  unless session.nil?
    JSON.pretty_generate(JSON.load(session.to_hash.to_json))
  else
    "{}"
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
      "<link href=\"/#{stylesheet}.css\" media=\"screen, projection\" rel=\"stylesheet\" />"
    end.join
end

def set_title
  @title ||= $appconfig[:site_title]
end
def set_sidebar_title
  @sidebar_title ||= 'Sidebar'
end

def gen_doveadm_pwhash(password)
  "{SHA512-CRYPT}" + password.crypt('$6$' + SecureRandom.hex(16))
end

def gen_mysql_pwhash(password)
  "*" + Digest::SHA1.hexdigest(Digest::SHA1.digest(password)).upcase
end

def parse_dovecot_quotausage(file)
  if File.exist?(file)
   Integer(IO.read(file).match(/priv\/quota\/storage\n(.*)\n/m)[1])
  else
    'unknown'
  end
end

def mailaccount_quotausage(mailaccount)
  filename = "#{$appconfig[:mail_home]}/" \
             "#{mailaccount.email.to_s.split('@')[1]}/" \
             "#{mailaccount.email.to_s.split('@')[0]}/.quotausage"
  parse_dovecot_quotausage(filename)
end

def authenticate!
  unless is_user?
    flash[:error] = 'You need to be logged in!'
    session[:return_to] = request.path_info
    redirect '/login' 
  end
end

def nav_current?(path='/')
 (request.path.to_s.split('/')[1]==path || request.path.to_s.split('/')[1]==path+'/') ? "current": nil
end

def sidebar_current?(path='/')
 (request.path.to_s.split('/')[2]==path || request.path.to_s.split('/')[2]==path+'/') ? "current": nil
end

def is_user?
  @user != nil
end

# @return alphanumeric string of given length
# def gen_alphanum(length)
  # return false unless length > 0
  # [*('a'..'z'), *('A'..'Z'), *('0'..'9')].to_a.shuffle[0, length.to_i].join
# end
