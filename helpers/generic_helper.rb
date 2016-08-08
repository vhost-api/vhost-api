# frozen_string_literal: true
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
